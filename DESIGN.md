# CyberHawk RE — GhidraMCP Design Document

> **Living document.** Any change to architecture, patching, or operational procedure MUST be recorded here AND in `README.md`.

---

## Overview

This document describes the technical architecture of the `cyberhawk-ghidra` service, the three upstream bugs discovered in bethington/ghidra-mcp v5.12.0, the four patches applied, and the complete operational runbook.

---

## Architecture

### Layer Stack

```
Claude Code (MCP client)
    │
    │  streamable-http :8083
    ▼
┌─────────────────────────────────────────┐
│  cyberhawk-ghidra  (Docker container)   │
│                                         │
│  bridge_mcp_ghidra.py                   │
│  └─ Python MCP bridge                   │
│     FastMCP + streamable-http           │
│     Binds: 0.0.0.0:8081                 │
│     Host port: 8083                     │
│     183 tools registered on startup     │
│                                         │
│     ↕ HTTP /check_connection            │
│     ↕ (all tool calls → REST)           │
│                                         │
│  GhidraMCPHeadlessServer (Java)         │
│  └─ com.xebyte.headless.*               │
│     Binds: 127.0.0.1:8089  ← LOOPBACK  │
│     Ghidra 12.1 analysis engine         │
│     Project store: /workspace/ghidra-projects
│     Data dir: /data                     │
└─────────────────────────────────────────┘
    │
    │  Docker named volume: cyberhawk-data
    ▼
/workspace/
  upload/          ← evidence drop zone
  investigations/  ← case artifacts
  ghidra-projects/ ← Ghidra project files
```

### Why Java Binds to 127.0.0.1

The GhidraMCPHeadlessServer enforces an auth token (`GHIDRA_MCP_AUTH_TOKEN`) when bound to `0.0.0.0`. Since we don't set that token, binding to loopback (`127.0.0.1`) skips the check and allows the Python bridge to communicate freely within the container. The bridge itself only exposes port `8081` externally.

### Transport

- **Java ↔ Bridge:** HTTP REST on `127.0.0.1:8089`
- **Bridge ↔ Claude Code:** streamable-http MCP on `0.0.0.0:8081` (host port `8083`)
- **Claude Code config (`.mcp.json`):** `"ghidra": { "type": "http", "url": "http://<server-ip>:8083/mcp" }`

---

## Upstream Bugs in bethington/ghidra-mcp v5.12.0

Three bugs were discovered through operational failure (bridge stopped recovering after Java server restarts):

### Bug 1 — Duplicate Lock (Dead Code)

**File:** `bridge_mcp_ghidra.py` (global scope, near top)

**Code:**
```python
_ghidra_lock = asyncio.Lock()      # ← defined first
...
_ghidra_lock = threading.Lock()    # ← immediately overrides the above
```

The `asyncio.Lock()` line is dead code — it is immediately overwritten. The `asyncio.Lock` is never used; the bridge uses `threading.Lock` throughout. No functional impact in the current codebase, but it was confusing and could silently break if code is refactored to use the first definition.

### Bug 2 — No TCP Reconnect Path in `_try_reconnect()`

**File:** `bridge_mcp_ghidra.py`, function `_try_reconnect()`

**Code (upstream):**
```python
def _try_reconnect() -> bool:
    # Only scanned UDS socket paths — no TCP fallback
    for candidate in uds_candidates:
        ...
    return False  # ← always returns False in headless TCP mode
```

In the headless container, the Java server uses TCP only — there is no Unix Domain Socket (UDS). So when the Java server restarted (e.g. OOM recovery), `_try_reconnect()` scanned UDS paths, found nothing, and returned `False`. The bridge stayed in `_transport_mode = "none"` forever, making all 183 tools permanently fail until the container was manually restarted.

### Bug 3 — No Heartbeat / Keepalive

**File:** `bridge_mcp_ghidra.py`, `main()` function

The bridge connected once at startup (`_auto_connect()`) and never checked again. If the Java server died and recovered between tool calls, the bridge had no mechanism to detect the recovery. Combined with Bug 2, this meant:

- Java server dies → bridge enters `_transport_mode = "none"`
- Java server recovers → bridge has no way to know
- All tool calls return errors indefinitely

---

## Patches Applied (v5.12.0-cyberhawk)

All patches are documented in the module docstring at the top of `bridge_mcp_ghidra.py`.

### Patch 1 — Remove Duplicate Lock

Removed the `asyncio.Lock()` line. Only `threading.Lock()` remains.

```python
# BEFORE:
_ghidra_lock = asyncio.Lock()
...
_ghidra_lock = threading.Lock()

# AFTER:
_ghidra_lock = threading.Lock()
```

### Patch 2 — TCP Reconnect Path in `_try_reconnect()`

Added TCP fallback after the UDS scan loop:

```python
# TCP fallback: if Java server restarted, try reconnecting via TCP
tcp_url = _active_tcp or os.getenv("GHIDRA_MCP_URL", DEFAULT_TCP_URL)
if tcp_url and validate_server_url(tcp_url):
    try:
        _active_tcp = tcp_url
        _transport_mode = "tcp"
        _fetch_and_register_schema()
        logger.info(f"[reconnect] Reconnected via TCP to {tcp_url}")
        return True
    except Exception as e:
        _active_tcp = None
        _transport_mode = "none"
        logger.warning(f"[reconnect] TCP reconnect failed: {e}")
return False
```

### Patch 3 — Heartbeat Daemon `_start_heartbeat()`

New function inserted between `_auto_connect()` and the Debugger tools section:

```python
def _start_heartbeat(interval: int = 30) -> None:
    """Daemon thread: ping Java server every interval seconds, reconnect if dead."""
    def _loop():
        global _active_tcp, _transport_mode
        while True:
            time.sleep(interval)
            tcp_url = _active_tcp or os.getenv("GHIDRA_MCP_URL", DEFAULT_TCP_URL)
            try:
                _, status = tcp_request(tcp_url, "GET", "/check_connection", timeout=5)
                if status != 200:
                    raise ConnectionError(f"HTTP {status}")
                if _transport_mode == "none":
                    logger.info("[keepalive] Java server alive but bridge lost state — reconnecting")
                    _auto_connect()
            except Exception as e:
                logger.warning(f"[keepalive] Java server unreachable ({e}) — reconnecting")
                _active_tcp = None
                _transport_mode = "none"
                _auto_connect()
    t = threading.Thread(target=_loop, name="ghidra-keepalive", daemon=True)
    t.start()
    logger.info(f"[keepalive] Heartbeat started (interval={interval}s)")
```

**Important Python scoping rule:** `global _active_tcp, _transport_mode` MUST be the FIRST statement inside `_loop()`. Python resolves global declarations at compile time for the entire function scope — any reference to these names before the `global` declaration causes `SyntaxError: name used prior to global declaration`.

### Patch 4 — Wire Heartbeat into `main()`

In `main()`, immediately after `_auto_connect()`:

```python
_auto_connect()
_start_heartbeat(int(os.getenv("GHIDRA_MCP_HEARTBEAT_INTERVAL", "30")))
```

The interval is configurable via the `GHIDRA_MCP_HEARTBEAT_INTERVAL` environment variable (default: `30` seconds).

---

## Dockerfile Changes

The upstream Dockerfile downloaded `bridge_mcp_ghidra.py` directly from GitHub at build time:

```dockerfile
# UPSTREAM (broken — no way to inject patches):
RUN curl -sL ".../bridge_mcp_ghidra.py" -o /app/bridge_mcp_ghidra.py \
    && curl -sL ".../requirements.txt" ...
```

**Patched Dockerfile** splits requirements from the bridge and COPYs the patched file:

```dockerfile
# Install bridge requirements from upstream release
RUN curl -sL ".../requirements.txt" \
        -o /tmp/bridge_requirements.txt \
    && pip3 install --no-cache-dir -r /tmp/bridge_requirements.txt \
    && rm /tmp/bridge_requirements.txt

# Patched bridge: TCP reconnect + keepalive heartbeat (replaces upstream download)
COPY bridge_mcp_ghidra.py /app/bridge_mcp_ghidra.py
```

This means:
- The patched bridge is in source control alongside the Dockerfile
- Any future rebuild automatically uses the patched version
- The heavy Maven/Ghidra layers are cached — only the COPY layer rebuilds (fast)
- `ENV GHIDRA_MCP_HEARTBEAT_INTERVAL=30` is set as a default

---

## File Inventory

| File | Location | Purpose |
|---|---|---|
| `Dockerfile` | `cyberhawk-ghidra/` | Multi-stage build: JDK builder → JRE runtime. COPYs patched bridge. |
| `bridge_mcp_ghidra.py` | `cyberhawk-ghidra/` | Patched MCP bridge with 4 CyberHawk fixes |
| `entrypoint.sh` | `cyberhawk-ghidra/` | Container entrypoint: builds classpath → starts Java server → starts Python bridge |
| `load_binary.sh` | `cyberhawk-ghidra/` | Fallback binary importer using `analyzeHeadless` (prefer `mcp__ghidra__import_file`) |

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GHIDRA_HOME` | `/opt/ghidra` | Ghidra installation path |
| `GHIDRA_MCP_PORT` | `8089` | Java headless server port (loopback) |
| `GHIDRA_MCP_URL` | `http://127.0.0.1:8089` | Bridge → Java server URL |
| `MCP_BRIDGE_PORT` | `8081` | Python MCP bridge port (external) |
| `JAVA_OPTS` | `-Xmx4g -XX:+UseG1GC` | JVM heap and GC settings |
| `GHIDRA_MCP_HEARTBEAT_INTERVAL` | `30` | Seconds between keepalive pings to Java server |

---

## Operational Runbook

### Starting the Ghidra RE Container

```bash
cd /home/cyberhawk/docker/compose-files/cyberhawk-docker
docker compose --profile reverse-eng up -d ghidra

# Watch initialization
docker logs -f cyberhawk-ghidra
# Ready when: "Headless server UP" + "registered 183 tools" + "Heartbeat started"
```

### Stopping

```bash
docker compose --profile reverse-eng stop ghidra
```

### Checking Health

```bash
# Java server alive?
curl -sf http://localhost:8089/check_connection && echo "Java OK"

# MCP bridge alive?
curl -sf http://localhost:8083/mcp && echo "Bridge OK"

# Recent errors?
docker logs --tail=100 cyberhawk-ghidra | grep -E "(ERROR|WARN|keepalive|reconnect)"
```

### Rebuilding After Bridge Changes

```bash
# Edit bridge locally then sync to server, OR edit directly on server:
# /home/cyberhawk/docker/compose-files/cyberhawk-docker/cyberhawk-ghidra/bridge_mcp_ghidra.py

# Rebuild (fast — only COPY layer changes, Ghidra/Maven cached)
cd /home/cyberhawk/docker/compose-files/cyberhawk-docker
docker compose build ghidra
docker compose --profile reverse-eng up -d ghidra
```

### After Any Container Restart

**Claude Code must be restarted.** HTTP sessions established before the restart are stale. There is no way to refresh them without restarting Claude Code.

### Common Recovery: Bridge Disconnected, Container Still Running

```bash
# Check if Java server is actually up
curl -sf http://localhost:8089/check_connection

# If Java server is up but bridge is stuck, the heartbeat should self-heal within 30s.
# Check logs to confirm:
docker logs --tail=50 cyberhawk-ghidra | grep -E "(keepalive|reconnect|registered)"

# If bridge is still stuck after 2 minutes, restart the container:
docker restart cyberhawk-ghidra
# Then restart Claude Code.
```

### Full Reset

```bash
docker compose --profile reverse-eng stop ghidra
docker compose --profile reverse-eng up -d ghidra
# Wait for "registered 183 tools" in logs
# Restart Claude Code
```

---

## Log Reference

| Log line | Meaning |
|---|---|
| `[GhidraMCP] Headless server UP after Xs ✓` | Java server ready |
| `INFO: Auto-connected, registered 183 tools` | Bridge connected successfully |
| `INFO: [keepalive] Heartbeat started (interval=30s)` | Keepalive daemon running |
| `WARNING [keepalive] Java server unreachable (...)` | Java server died; reconnect starting |
| `INFO: [reconnect] Reconnected via TCP to ...` | Auto-recovery succeeded |
| `WARNING [reconnect] TCP reconnect failed: ...` | Java server still down; will retry |
| `connected: false, port: 13100` | **Normal** — Team Server not configured |
| `WARNING: headless server did not respond in 120s` | Java slow to start; bridge up, retrying |
| `[GhidraMCP] Bridge starting anyway` | Bridge up despite slow Java start |

---

## Known Limitations

1. **Claude Code session refresh required after container restart.** There is no way to inject a new session ID into an active Claude Code instance.
2. **Heartbeat does not trigger Claude Code refresh.** Even if the bridge reconnects automatically, tool calls through a pre-restart Claude Code session will still fail. Bridge reconnect helps only when Java server restarts within the same container lifecycle.
3. **`server_status` tool reports Team Server (port 13100), not MCP health.** Use `list_instances` or `get_current_program_info` to verify the bridge is functional.
4. **Large binaries (>500MB) may OOM with default heap.** Set `JAVA_OPTS=-Xmx8g` in docker-compose for such cases.

---

## Change Log

| Date | Change |
|---|---|
| 2026-05-27 | Initial document — full architecture, 3 upstream bugs, 4 patches, operational runbook |
