<div align="center">

<img src="https://media.cyberhawkthreatintel.com/general/1771234479938-y9566.png" width="120" alt="CyberHawk Logo"/>

# CyberHawk RE — AI-Powered Reverse Engineering Platform

**by CyberHawk Threat Intel**

_Drop a binary. Claude analyzes it. You get answers — powered by Ghidra 12.1 and 183 MCP tools_

[![X](https://img.shields.io/badge/X-@cyberhawkintel-black?logo=x)](https://x.com/cyberhawkintel)
[![Telegram](https://img.shields.io/badge/Telegram-@cyberhawkthreatintel-blue?logo=telegram)](https://t.me/cyberhawkthreatintel)
[![YouTube](https://img.shields.io/badge/YouTube-@cyberhawkconsultancy-red?logo=youtube)](https://youtube.com/@cyberhawkconsultancy)
[![TikTok](https://img.shields.io/badge/TikTok-@cyberhawkthreatintel-black?logo=tiktok)](https://tiktok.com/@cyberhawkthreatintel)
[![Web](https://img.shields.io/badge/Web-cyberhawkthreatintel.com-orange)](https://www.cyberhawkthreatintel.com)

</div>

---

## What Is This?

**CyberHawk RE** is a self-contained Docker platform that connects **Ghidra 12.1** — the industry-standard reverse engineering suite — directly to **Claude Code** via MCP (Model Context Protocol).

Claude can decompile functions, trace cross-references, rename variables, search memory, run debugger operations, and navigate a binary's entire symbol space — all autonomously, without an analyst clicking through a GUI.

**No GUI. No Xvfb. Fully headless. 183 tools.**

You drop a malware sample. Claude analyzes it. You get a full report.

---

## Why This Exists

Traditional RE is slow. You load a binary in Ghidra, wait for auto-analysis, manually navigate to interesting functions, read decompiled C, cross-reference imports, trace execution paths — all by hand. For a complex malware sample this takes hours or days.

**CyberHawk RE changes that:**

- Claude understands what to look for (crypto routines, C2 comms, persistence, anti-debug)
- It decompiles entire call graphs automatically
- It correlates imports, strings, and xrefs to build a complete behavioral picture
- It writes YARA rules and analysis reports from the binary itself
- 41 specialist RE skills guide the workflow from triage to final report

The analyst's job shifts from clicking through Ghidra to reviewing findings and asking follow-up questions.

---

## How It Works

```
┌───────────────────────────────────────────────────────────────────┐
│                        Your Machine                                │
│                                                                     │
│  Claude Code (Pro plan)                                             │
│       │                                                             │
│       └── MCP (streamable-http) ──────────────────────► :8081      │
└────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────▼──────────────────────┐
                    │          cyberhawk-re-ghidra               │
                    │                                            │
                    │  Java Headless Server  :8089 (internal)   │
                    │  ├─ Ghidra 12.1                           │
                    │  ├─ 183 REST endpoints                    │
                    │  └─ CyberHawk GhidraMCP Engine             │
                    │                                            │
                    │  Python MCP Bridge     :8081 (external)   │
                    │  └─ streamable-http transport              │
                    └──────────────────┬─────────────────────────┘
                                       │
                    ┌──────────────────▼─────────────────────────┐
                    │              ./workspace/                    │
                    │                                              │
                    │  binaries/         ← drop samples here      │
                    │  ghidra-projects/  ← Ghidra project data    │
                    │  reports/          ← analysis output         │
                    │  .agents/skills/   ← 41 RE skills            │
                    └──────────────────────────────────────────────┘
```

---

## MCP Tools Available (183 total)

### Core Analysis
| Tool | What It Does |
|---|---|
| `import_file` | Import + auto-analyze a binary into a Ghidra project |
| `list_instances` | List active Ghidra project instances |
| `connect_instance` | Switch between Ghidra projects |
| `decompile_function` | Decompile any function to C pseudocode |
| `disassemble_function` | Get raw assembly listing for a function |
| `list_functions` | List every function in the binary |
| `list_imports` | All imported symbols and libraries |
| `list_exports` | All exported functions |
| `get_xrefs_to` | Find everything that calls a function/address |
| `get_xrefs_from` | Find everything a function calls |
| `search_functions_by_name` | Find functions by name pattern |
| `rename_function` | Annotate functions with meaningful names |
| `rename_variable` | Rename local variables in decompiled output |
| `set_decompiler_comment` | Add analysis notes at any address |
| `list_segments` | PE/ELF/DEX section layout |
| `get_strings` | Extract all strings from binary |
| `search_memory` | Byte pattern search across the binary |
| `get_function_count` | Total function count |
| `list_namespaces` | Classes and namespaces (.NET, Go, C++) |
| `list_data_types` | Defined data types and structs |

### Debugger Suite
| Tool | What It Does |
|---|---|
| `debugger_attach` | Attach Ghidra debugger to a process |
| `debugger_set_breakpoint` | Set breakpoint at address |
| `debugger_continue` | Continue execution |
| `debugger_step_into` / `step_over` | Step through execution |
| `debugger_registers` | Read CPU register state |
| `debugger_read_memory` | Read memory at address |
| `debugger_stack_trace` | Get current stack trace |
| `debugger_modules` | List loaded modules |
| `debugger_watch_memory` | Watch memory region for changes |
| `debugger_trace_function` | Trace function execution |

---

## Included RE Skills (41 Specialist Workflows)

Skills guide Claude's analysis methodology for each binary type. Populated by `setup-skills.sh`.

### Binary & Malware Analysis
| Skill | Purpose |
|---|---|
| `reverse-engineering-malware-with-ghidra` | Core Ghidra RE — functions, imports, xrefs, decompilation |
| `analyzing-linux-elf-malware` | ELF binary analysis — GOT/PLT, dynamic linking, syscall patterns |
| `performing-static-malware-analysis-with-pe-studio` | Windows PE header, imports, entropy, section analysis |
| `analyzing-packed-malware-with-upx-unpacker` | UPX/packer detection and unpacking |
| `analyzing-bootkit-and-rootkit-samples` | Low-level boot/kernel hooks, MBR analysis |
| `analyzing-linux-kernel-rootkits` | Linux kernel module rootkits, syscall table hooks |
| `analyzing-uefi-bootkit-persistence` | UEFI firmware analysis, EFI module extraction |

### Ransomware & Crypto RE
| Skill | Purpose |
|---|---|
| `analyzing-ransomware-encryption-mechanisms` | Identify crypto routines, key generation |
| `reverse-engineering-ransomware-encryption-routine` | Deep crypto RE — AES/RSA/ChaCha20 in assembly |

### C2 & Implant Analysis
| Skill | Purpose |
|---|---|
| `analyzing-cobalt-strike-beacon-configuration` | Extract CS beacon config from memory/binary |
| `extracting-config-from-agent-tesla-rat` | AgentTesla RAT config extraction |
| `analyzing-network-covert-channels-in-malware` | Identify covert C2 channels in binary |
| `analyzing-network-traffic-of-malware` | Correlate binary network calls with traffic |

### Exploit & Shellcode Analysis
| Skill | Purpose |
|---|---|
| `performing-binary-exploitation-analysis` | Stack/heap overflows, ROP gadgets, exploit primitives |
| `analyzing-heap-spray-exploitation` | Heap spray, use-after-free, type confusion |

### Deobfuscation & Unpacking
| Skill | Purpose |
|---|---|
| `deobfuscating-javascript-malware` | JS malware deobfuscation — eval chains, string encoding |
| `deobfuscating-powershell-obfuscated-malware` | PowerShell obfuscation layers |

### Memory Forensics (RE angle)
| Skill | Purpose |
|---|---|
| `analyzing-memory-dumps-with-volatility` | Process injection, hooks, hidden modules |
| `analyzing-memory-forensics-with-lime-and-volatility` | Live memory acquisition + analysis |
| `performing-memory-forensics-with-volatility3` | Volatility3 plugins for artifact extraction |
| `performing-memory-forensics-with-volatility3-plugins` | Advanced Volatility3 plugin usage |
| `extracting-credentials-from-memory-dump` | Credential material from memory images |
| `extracting-memory-artifacts-with-rekall` | Rekall framework for process/module extraction |

### IOC & YARA
| Skill | Purpose |
|---|---|
| `performing-malware-triage-with-yara` | YARA-based triage and family identification |
| `performing-threat-hunting-with-yara-rules` | YARA hunting across sample collections |
| `performing-yara-rule-development-for-detection` | Write YARA rules from binary features |
| `performing-malware-ioc-extraction` | Extract all IOCs from a binary sample |
| `extracting-iocs-from-malware-samples` | IOC extraction — strings, hashes, network indicators |

### Golang / Rust / .NET
| Skill | Purpose |
|---|---|
| `analyzing-golang-malware-with-ghidra` | Go binary RE — symbol recovery, goroutine analysis |
| `reverse-engineering-rust-malware` | Rust binary RE — trait dispatch, panic handlers |
| `reverse-engineering-dotnet-malware-with-dnspy` | .NET IL decompilation, obfuscated assembly |

### Mobile Malware RE
| Skill | Purpose |
|---|---|
| `analyzing-android-malware-with-apktool` | APK decompilation, smali analysis, manifest abuse |
| `reverse-engineering-android-malware-with-jadx` | JADX Java decompilation, dynamic analysis prep |
| `analyzing-ios-app-security-with-objection` | iOS IPA analysis, runtime hooks |
| `reverse-engineering-ios-app-with-frida` | Frida dynamic instrumentation on iOS |

### Firmware
| Skill | Purpose |
|---|---|
| `performing-firmware-extraction-with-binwalk` | Firmware image extraction — filesystem, bootloader |
| `performing-firmware-malware-analysis` | Malware embedded in firmware images |
| `performing-plc-firmware-security-analysis` | Industrial PLC firmware RE |

### Steganography & Crypto
| Skill | Purpose |
|---|---|
| `performing-steganography-detection` | Hidden data in images/audio — LSB, DCT, EOF |
| `performing-hash-cracking-with-hashcat` | Hash identification and offline cracking |

### PDF Malware
| Skill | Purpose |
|---|---|
| `analyzing-malicious-pdf-with-peepdf` | PDF stream analysis, JS extraction, exploit detection |
| `analyzing-pdf-malware-with-pdfid` | pdfid/pdf-parser for suspicious PDF triage |

---

## Prerequisites

- **Docker** and **Docker Compose** installed on your server or workstation
- **Claude Code** (Pro plan) on your analyst machine
- **4GB RAM minimum** for Ghidra (8GB recommended for large binaries)
- Port **8081** free on the host

---

## Setup

### 1. Clone and configure

```bash
git clone https://github.com/cyberhawkthreatintel/cyberhawk-re-investigation-docker.git
cd cyberhawk-re-investigation-docker
cp .env.example .env
```

### 2. Populate RE skills

The `skills/` folder is empty by default. Run the setup script to populate it from your CyberHawk skills library:

```bash
# Linux / macOS
chmod +x scripts/setup-skills.sh
./scripts/setup-skills.sh [/path/to/your/skills/source]

# Windows
.\scripts\setup-skills.ps1 [-SourcePath "C:\path\to\skills"]
```

> Default source path: `../cyberhawk-docker/skills` (if this repo sits next to the main cyberhawk-docker project)

### 3. Build and start

```bash
docker compose build    # ~10-15 min first time (downloads Ghidra 12.1, Maven build)
docker compose up -d    # subsequent starts are instant
```

Watch startup:
```bash
docker logs -f cyberhawk-re-ghidra
```

You'll see:
```
[GhidraMCP] Building classpath...
[GhidraMCP] Starting Ghidra headless server on :8089
[GhidraMCP] Headless server UP after 33s ✓
[GhidraMCP] Starting MCP bridge on :8081
INFO: Auto-connected via TCP to http://127.0.0.1:8089, registered 183 tools
INFO: MCP endpoint: http://0.0.0.0:8081/mcp
```

### 4. Connect Claude Code

Edit `.mcp.json` — replace `<your-server-ip>` with your actual server IP (or `localhost` for local):

```json
{
  "mcpServers": {
    "ghidra": {
      "type": "http",
      "url": "http://<your-server-ip>:8081/mcp"
    }
  }
}
```

**Restart Claude Code** — the `ghidra` MCP tools will appear automatically.

> ⚠️ **Important:** After any container restart/rebuild, restart Claude Code to refresh the MCP session.

---

## Analysis Workflow

### Step 1 — Drop the binary

Copy your sample into the workspace:

```bash
cp /path/to/malware.exe workspace/binaries/
# or on Windows:
copy C:\samples\malware.exe workspace\binaries\
```

### Step 2 — Import into Ghidra

**Preferred — via Claude Code MCP tool:**
```
Use the mcp__ghidra__import_file tool:
  file_path: /workspace/binaries/malware.exe
  auto_analyze: true
```

**Alternative — via shell:**
```bash
docker exec cyberhawk-re-ghidra /load_binary.sh \
  /workspace/binaries/malware.exe malware_analysis
```

Auto-analysis takes 1–10 minutes depending on binary size. Watch `docker logs -f cyberhawk-re-ghidra`.

### Step 3 — Let Claude analyze

Open Claude Code with the ghidra MCP connected. Examples:

```
Analyze malware.exe using the reverse-engineering-malware-with-ghidra skill.
Start by listing all imports and suspicious strings, then decompile the main
entry point and any functions making network calls. Identify C2 communication
logic, persistence mechanisms, and write a YARA detection rule.
```

```
This is an Android banking trojan APK. Use the reverse-engineering-android-malware-with-jadx
skill. The DEX is AES-256 encrypted — find the loader stub, locate the decryption
routine, and extract the AES key and Firebase project ID.
```

Claude will autonomously call `list_imports`, `get_strings`, `decompile_function`,
`get_xrefs_to`, rename functions as it understands them, and build a complete analysis.

### Step 4 — Review the report

Reports are saved to `workspace/reports/` by the RE skills.

---

## Folder Structure

```
cyberhawk-re-investigation-docker/
├── README.md                     ← This file
├── docker-compose.yml            ← Standalone RE stack
├── .mcp.json                     ← Claude Code MCP config (edit server IP)
├── .env.example                  ← Environment template
├── .gitignore
├── cyberhawk-ghidra/             ← CyberHawk GhidraMCP container
│   ├── Dockerfile                ← Multi-stage: eclipse-temurin:21-jdk builder
│   ├── entrypoint.sh             ← Headless: Java server → Python bridge
│   └── load_binary.sh            ← Fallback binary importer
├── skills/                       ← 41 RE specialist skills (populated by setup script)
│   └── <skill-name>/
│       ├── SKILL.md
│       └── scripts/agent.py
├── workspace/                    ← Analysis workspace (bind-mounted into container)
│   ├── binaries/                 ← Drop malware samples here
│   ├── ghidra-projects/          ← Ghidra project data
│   └── reports/                  ← Analysis output
└── scripts/
    ├── setup-skills.sh           ← Populate skills (Linux/macOS)
    └── setup-skills.ps1          ← Populate skills (Windows)
```

---

## Configuration

### Increasing Ghidra memory for large binaries

Edit `docker-compose.yml`:

```yaml
environment:
  - JAVA_OPTS=-Xmx8g -XX:+UseG1GC   # increase from default 4g
```

Then restart: `docker compose up -d`

### Running on a remote server

Set the server IP in `.mcp.json`. Only port `8081` needs to be accessible from your analyst machine — the internal Ghidra Java server on port `8089` is never exposed.

---

## Security Notes

- **All binaries are hostile.** The container provides isolation — malware is analyzed statically by Ghidra, never executed.
- **Workspace is bind-mounted.** Files in `./workspace/` are accessible from the host. Keep this folder isolated from your production environment.
- **No GHIDRA_MCP_AUTH_TOKEN needed** because the Java server binds to `127.0.0.1` (loopback only). The Python bridge handles external MCP connections on port 8081.
- Never run `load_binary.sh` against files you haven't verified — always treat uploads as untrusted.

---

## Troubleshooting

### Container starts but shows "unhealthy"

Ghidra takes ~30–90s to initialize. The healthcheck polls `/check_connection` — this is normal. Watch `docker logs -f cyberhawk-re-ghidra` and wait for `Headless server UP`.

### MCP tools show "Session not found"

This happens when Claude Code's cached session ID becomes stale (after a container restart). **Restart Claude Code** to create a fresh session.

### Out of memory / Ghidra crash

Increase `JAVA_OPTS` memory in `docker-compose.yml`:
```yaml
environment:
  - JAVA_OPTS=-Xmx8g -XX:+UseG1GC
```

### Build fails at Maven step

The Maven build downloads Ghidra 12.1 from GitHub. Ensure the server has outbound internet access during the build. The build is cached after first run.

---

<div align="center">

**CyberHawk Threat Intel**

[cyberhawkthreatintel.com](https://www.cyberhawkthreatintel.com) · [app.cyberhawkthreatintel.com](https://app.cyberhawkthreatintel.com)

[@cyberhawkintel](https://x.com/cyberhawkintel) · [@cyberhawkthreatintel](https://t.me/cyberhawkthreatintel) · [@cyberhawkconsultancy](https://youtube.com/@cyberhawkconsultancy) · [@cyberhawkthreatintel](https://tiktok.com/@cyberhawkthreatintel)

`#cyberhawkthreatintel` `#cyberhawkconsultancy`

</div>
