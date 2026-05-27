<div align="center">

<img src="https://media.cyberhawkthreatintel.com/general/1771234479938-y9566.png" width="120" alt="CyberHawk Logo"/>

# CyberHawk RE — AI-Powered Cyber Investigation Platform

**by CyberHawk Threat Intel**

_The complete cyber investigation suite — now with AI-driven reverse engineering powered by Ghidra 12.1 and 183 MCP tools_

[![X](https://img.shields.io/badge/X-@cyberhawkintel-black?logo=x)](https://x.com/cyberhawkintel)
[![Telegram](https://img.shields.io/badge/Telegram-@cyberhawkthreatintel-blue?logo=telegram)](https://t.me/cyberhawkthreatintel)
[![YouTube](https://img.shields.io/badge/YouTube-@cyberhawkconsultancy-red?logo=youtube)](https://youtube.com/@cyberhawkconsultancy)
[![TikTok](https://img.shields.io/badge/TikTok-@cyberhawkthreatintel-black?logo=tiktok)](https://tiktok.com/@cyberhawkthreatintel)
[![Web](https://img.shields.io/badge/Web-cyberhawkthreatintel.com-orange)](https://www.cyberhawkthreatintel.com)

</div>

---

## What Is This?

**CyberHawk RE** is the complete CyberHawk cyber investigation platform with **AI-driven reverse engineering** as the centrepiece. Every component is pre-wired and ready to go — upload evidence through the web UI, and Claude Code analyzes it using the full tool suite including Ghidra 12.1 with 183 MCP-exposed RE tools.

This is not just Ghidra. It is the entire CyberHawk stack:

| Component | Role |
|---|---|
| **cyberhawk-ui** | Web interface — upload evidence, browse cases, view reports |
| **cyberhawk-api** | Core MCP server — 755 skills, file management, triage, analysis |
| **cyberhawk-ghidra** | ⭐ **RE engine** — Ghidra 12.1 headless, 183 MCP tools, decompile/disassemble/debug |
| **sift-remnux** | Forensics — SIFT + REMnux full suite, disk/memory/malware analysis |
| **cracking** | hashcat v7.1.1 + John the Ripper — password cracking |
| **crypto-email** | GPG + email forensics — eml/msg analysis, OpenSSL |
| **kali** | Pentest tools — on-demand profile |

All containers share a single Docker volume — evidence uploaded via the UI is **instantly visible** to Ghidra and every other tool.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           Your Analyst Machine                            │
│                                                                           │
│  Browser ──────────────────────────────────────────────► :8090 (UI)      │
│                                                                           │
│  Claude Code                                                              │
│    ├── MCP: cyberhawk ──────────────────────────────────► :3002 (API)    │
│    └── MCP: ghidra ─────────────────────────────────────► :8083 (RE)     │
└──────────────────────────────────────────────────────────────────────────┘
                │                              │
    ┌───────────▼───────────┐      ┌───────────▼──────────────────┐
    │    cyberhawk-api       │      │      cyberhawk-ghidra         │
    │                       │      │                               │
    │  FastAPI + uvicorn    │      │  Java Headless Server :8089   │
    │  755 skills           │      │  Ghidra 12.1                  │
    │  File triage          │      │  183 REST endpoints           │
    │  MCP server :3002     │      │                               │
    └───────────┬───────────┘      │  Python MCP Bridge :8081      │
                │                  │  streamable-http → :8083      │
    ┌───────────▼───────────┐      └───────────────┬───────────────┘
    │    cyberhawk-ui        │                      │
    │                       │      ┌───────────────▼───────────────┐
    │  React SPA :8090      │      │       cyberhawk-data           │
    │  Upload evidence      │      │       (Docker volume)          │
    │  Browse cases         │      │                               │
    │  View reports         │      │  /workspace/                  │
    └───────────────────────┘      │    upload/     ← evidence     │
                                   │    investigations/ ← cases    │
    ┌──────────────────────┐       │    .agents/skills/ ← 42 RE    │
    │  sift-remnux         │       └───────────────────────────────┘
    │  cracking            │◄──────────── all containers
    │  crypto-email        │               share this volume
    │  kali (on-demand)    │
    └──────────────────────┘
```

---

## Quick Start

### 1. Clone

```bash
git clone https://github.com/rudraverma/cyberhawk-re-investigation-docker.git
cd cyberhawk-re-investigation-docker
```

### 2. Configure

```bash
cp .env.example .env
# Edit .env — add API keys if you want external enrichment (optional)
```

### 3. Build and start core stack

```bash
docker compose build
docker compose up -d
```

### 4. Start Ghidra RE engine (on-demand)

```bash
docker compose --profile reverse-eng up -d ghidra
```

Watch Ghidra initialize (~30–90s):
```bash
docker logs -f cyberhawk-ghidra
```

Ready when you see:
```
[GhidraMCP] Headless server UP after 33s ✓
INFO: Auto-connected, registered 183 tools
INFO: MCP endpoint: http://0.0.0.0:8081/mcp
```

### 5. Connect Claude Code

Edit `.mcp.json` — replace `<your-server-ip>` with your server IP:

```json
{
  "mcpServers": {
    "cyberhawk": { "type": "http", "url": "http://<your-server-ip>:3002/mcp" },
    "ghidra":    { "type": "http", "url": "http://<your-server-ip>:8083/mcp" }
  }
}
```

Restart Claude Code. Both MCP servers connect automatically.

> ⚠️ After any Ghidra container restart, restart Claude Code to refresh the MCP session.

---

## Analysis Workflow

### Step 1 — Upload evidence via the UI

Open `http://<your-server-ip>:8090` → Upload Zone → drop your binary/APK/firmware.

The file lands in `/workspace/upload/` — **immediately visible to Ghidra and all other containers**.

### Step 2 — Let Claude triage and analyze

Open Claude Code. Ask:

```
New evidence uploaded: malware.exe
Triage it, identify the type, find matching skills, and begin RE analysis with Ghidra.
```

Claude will:
1. Call `mcp__cyberhawk__triage_file` — identify file type
2. Call `mcp__cyberhawk__list_skills` — find matching RE skills
3. Call `mcp__cyberhawk__run_skill` — execute the skill methodology
4. Call `mcp__ghidra__import_file` — load into Ghidra with auto-analysis
5. Use Ghidra RE tools to decompile, trace xrefs, extract crypto, identify C2

### Step 3 — Deep RE with Ghidra tools

183 tools are available. Key ones:

| Tool | Purpose |
|---|---|
| `import_file` | Import binary into Ghidra project with auto-analysis |
| `decompile_function` | Decompile any function to C pseudocode |
| `list_functions` | All functions in the binary |
| `list_imports` | All imported symbols |
| `get_xrefs_to` / `get_xrefs_from` | Trace call graphs |
| `search_strings` | Extract all strings |
| `detect_crypto_constants` | Find AES/RC4/SHA S-boxes automatically |
| `detect_malware_behaviors` | Flag suspicious patterns |
| `extract_iocs_with_context` | Extract IOCs with surrounding context |
| `search_byte_patterns` | Scan for byte sequences |
| `rename_function` / `rename_variable` | Annotate as you understand the code |
| `batch_decompile` | Decompile multiple functions at once |
| `debugger_*` | Full debugger suite — attach, breakpoints, step, memory |

---

## Bundled RE Skills (42 Specialist Workflows)

Skills guide Claude's analysis methodology for each binary type — no configuration needed.

| Category | Skills Included |
|---|---|
| **Core RE** | `reverse-engineering-malware-with-ghidra`, `analyzing-linux-elf-malware`, `performing-static-malware-analysis-with-pe-studio`, `analyzing-packed-malware-with-upx-unpacker` |
| **Ransomware** | `analyzing-ransomware-encryption-mechanisms`, `reverse-engineering-ransomware-encryption-routine` |
| **Rootkits / Bootkits** | `analyzing-bootkit-and-rootkit-samples`, `analyzing-linux-kernel-rootkits`, `analyzing-uefi-bootkit-persistence` |
| **C2 & Implants** | `analyzing-cobalt-strike-beacon-configuration`, `extracting-config-from-agent-tesla-rat`, `analyzing-network-covert-channels-in-malware`, `analyzing-network-traffic-of-malware` |
| **Exploitation** | `performing-binary-exploitation-analysis`, `analyzing-heap-spray-exploitation` |
| **Memory Forensics** | `analyzing-memory-dumps-with-volatility`, `performing-memory-forensics-with-volatility3`, `performing-memory-forensics-with-volatility3-plugins`, `extracting-credentials-from-memory-dump`, `extracting-memory-artifacts-with-rekall`, `analyzing-memory-forensics-with-lime-and-volatility` |
| **IOC & YARA** | `extracting-iocs-from-malware-samples`, `performing-malware-ioc-extraction`, `performing-malware-triage-with-yara`, `performing-yara-rule-development-for-detection`, `performing-threat-hunting-with-yara-rules` |
| **Go / Rust / .NET** | `analyzing-golang-malware-with-ghidra`, `reverse-engineering-rust-malware`, `reverse-engineering-dotnet-malware-with-dnspy` |
| **Mobile** | `analyzing-android-malware-with-apktool`, `reverse-engineering-android-malware-with-jadx`, `analyzing-ios-app-security-with-objection`, `reverse-engineering-ios-app-with-frida` |
| **Firmware** | `performing-firmware-extraction-with-binwalk`, `performing-firmware-malware-analysis`, `performing-plc-firmware-security-analysis` |
| **Deobfuscation** | `deobfuscating-javascript-malware`, `deobfuscating-powershell-obfuscated-malware` |
| **Steganography** | `performing-steganography-detection`, `performing-hash-cracking-with-hashcat` |
| **PDF Malware** | `analyzing-malicious-pdf-with-peepdf`, `analyzing-pdf-malware-with-pdfid` |

---

## Port Reference

| Port | Service |
|---|---|
| `8090` | CyberHawk UI — web interface |
| `3002` | CyberHawk API MCP — Claude Code connects here |
| `8083` | Ghidra MCP bridge — Claude Code connects here (profile: `reverse-eng`) |
| `2233` | SIFT/REMnux SSH — `ssh forensics@<server> -p 2233` |

---

## Folder Structure

```
cyberhawk-re-investigation-docker/
├── docker-compose.yml        ← Full stack (api + ui + ghidra + forensics tools)
├── .mcp.json                 ← Claude Code MCP config (edit server IP)
├── .env.example              ← Environment template
├── cyberhawk-api/            ← Core MCP API container
├── cyberhawk-ui/             ← React web interface
├── cyberhawk-ghidra/         ← ⭐ CyberHawk GhidraMCP RE engine
│   ├── Dockerfile            ← Ghidra 12.1 headless multi-stage build
│   ├── entrypoint.sh         ← Java server → Python MCP bridge
│   └── load_binary.sh        ← Fallback binary importer
├── sift-remnux/              ← SIFT + REMnux forensics container
├── cracking/                 ← hashcat + John the Ripper
├── crypto-email/             ← GPG + email forensics
├── kali/                     ← Pentest tools (profile: pentest)
├── skills/                   ← 42 bundled RE specialist skills
│   └── <skill-name>/
│       ├── SKILL.md
│       └── scripts/agent.py
└── workspace/
    └── config/               ← CyberHawk branding config
```

---

## Security Notes

- **All binaries are hostile.** Malware is analyzed statically — never executed inside containers.
- **Ghidra binds to loopback.** The Java server listens on `127.0.0.1:8089` only. Only the MCP bridge is externally accessible on port `8083`.
- **Evidence isolation.** The `cyberhawk-data` Docker volume is shared only between containers — never mounted to your host filesystem.
- **Never commit `.env`.** Your API keys and secrets stay in `.env`, which is gitignored.

---

## Troubleshooting

**Ghidra MCP shows "Session not found"**
→ Container restarted and Claude Code is using a stale session. Restart Claude Code.

**Container shows "unhealthy" for 60–90s**
→ Normal. Ghidra takes time to initialize. Watch `docker logs -f cyberhawk-ghidra` and wait for `Headless server UP`.

**Out of memory / Ghidra crash**
→ Increase heap in `docker-compose.yml`: `JAVA_OPTS=-Xmx8g -XX:+UseG1GC`

---

<div align="center">

**CyberHawk Threat Intel**

[cyberhawkthreatintel.com](https://www.cyberhawkthreatintel.com) · [app.cyberhawkthreatintel.com](https://app.cyberhawkthreatintel.com)

[@cyberhawkintel](https://x.com/cyberhawkintel) · [@cyberhawkthreatintel](https://t.me/cyberhawkthreatintel) · [@cyberhawkconsultancy](https://youtube.com/@cyberhawkconsultancy) · [@cyberhawkthreatintel](https://tiktok.com/@cyberhawkthreatintel)

`#cyberhawkthreatintel` `#cyberhawkconsultancy`

</div>
