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

### Step 3 — Deep RE with Ghidra (183 MCP Tools)

All 183 tools are directly callable by Claude Code. Organized by category:

#### 📂 Program & Project Management (19 tools)

| Tool | Purpose |
|---|---|
| `import_file` | Import binary + auto-analyze into Ghidra project |
| `open_program` / `close_program` | Open/close a loaded program |
| `open_project` / `close_project` | Open/close a Ghidra project |
| `create_project` | Create a new Ghidra project |
| `load_program` | Load program from file path |
| `load_program_from_project` | Load existing program from project |
| `list_instances` | List active Ghidra project instances |
| `connect_instance` | Switch to a different instance |
| `list_open_programs` | List all currently open programs |
| `get_project_info` | Project metadata and stats |
| `get_current_program_info` | Currently active program info |
| `get_metadata` | Binary metadata (arch, OS, compiler, format) |
| `list_project_files` | Files inside the Ghidra project |
| `save_program` / `save_all_programs` | Save analysis state |
| `switch_program` | Switch active program context |
| `delete_file` | Remove file from project |
| `create_folder` | Create folder in project |
| `get_entry_points` | Get binary entry points |

#### 🔬 Decompile & Disassemble (17 tools)

| Tool | Purpose |
|---|---|
| `decompile_function` | Decompile function to C pseudocode |
| `force_decompile` | Decompile with forced re-analysis |
| `disassemble_function` | Full assembly listing for a function |
| `disassemble_bytes` | Disassemble raw bytes at address |
| `batch_decompile` | Decompile multiple functions at once |
| `get_function_pcode` | Get P-Code (Ghidra IR) for a function |
| `get_assembly_context` | Assembly with surrounding context |
| `analyze_control_flow` | Control flow graph analysis |
| `analyze_dataflow` | Data flow / taint analysis |
| `analyze_function_complete` | Full function analysis pass |
| `analyze_function_completeness` | Check analysis coverage |
| `analyze_call_graph` | Call graph for a function |
| `analyze_api_call_chains` | Trace API call chains |
| `batch_analyze_completeness` | Batch completeness check |
| `analysis_status` | Current analysis status |
| `reanalyze` | Re-run analysis on program |
| `run_analysis` | Run specific analyzer |
| `list_analyzers` | List available analyzers |

#### 🔧 Functions (31 tools)

| Tool | Purpose |
|---|---|
| `list_functions` | All functions in binary |
| `list_functions_enhanced` | Functions with extra metadata |
| `search_functions` | Search functions by name |
| `search_functions_enhanced` | Advanced function search |
| `search_functions_by_tag` | Find functions by tag |
| `get_function_by_address` | Get function at address |
| `get_function_count` | Total function count |
| `get_function_signature` | Function signature / prototype |
| `get_function_variables` | Local variables and params |
| `get_function_callers` | Who calls this function |
| `get_function_callees` | Who this function calls |
| `get_function_call_graph` | Full call graph for function |
| `get_full_call_graph` | Whole-binary call graph |
| `get_function_xrefs` | All cross-references to/from function |
| `get_function_jump_targets` | Jump targets inside function |
| `get_function_hash` | Hash for function similarity |
| `get_bulk_function_hashes` | Hash many functions at once |
| `get_function_labels` | Labels defined in function |
| `get_function_tags` | Tags attached to function |
| `get_function_documentation` | Docs/comments on function |
| `create_function` | Create function at address |
| `delete_function` | Remove function definition |
| `rename_function` | Rename a function by name |
| `rename_function_by_address` | Rename function by address |
| `set_function_prototype` | Set full function signature |
| `set_function_no_return` | Mark function as noreturn |
| `create_function_signature` | Create/update signature |
| `validate_function_prototype` | Validate prototype syntax |
| `find_similar_functions` | Find functionally similar functions |
| `find_similar_functions_fuzzy` | Fuzzy similarity matching |
| `find_next_undefined_function` | Next unanalyzed function |
| `find_dead_code` | Detect unreachable code |
| `find_code_gaps` | Find gaps in code coverage |

#### 🏷️ Labels & Naming (7 tools)

| Tool | Purpose |
|---|---|
| `create_label` | Create label at address |
| `rename_label` | Rename existing label |
| `delete_label` | Remove label |
| `batch_create_labels` | Create many labels at once |
| `batch_delete_labels` | Delete many labels at once |
| `rename_or_label` | Rename or create if absent |
| `can_rename_at_address` | Check if rename is valid |

#### 📝 Variables & Parameters (10 tools)

| Tool | Purpose |
|---|---|
| `rename_variable` | Rename local variable |
| `rename_variables` | Rename multiple variables |
| `batch_rename_function_components` | Bulk rename vars/params |
| `set_variable_storage` | Set storage location for variable |
| `set_variables` | Set multiple variable properties |
| `set_local_variable_type` | Set type of local variable |
| `set_parameter_type` | Set type of function parameter |
| `get_field_access_context` | Context around struct field access |
| `suggest_field_names` | AI-suggest names for struct fields |
| `audit_globals_in_function` | Audit global usage in function |

#### 💬 Comments & Documentation (13 tools)

| Tool | Purpose |
|---|---|
| `set_decompiler_comment` | Add comment in decompiler view |
| `set_disassembly_comment` | Add comment in disassembly |
| `set_plate_comment` | Set function header comment |
| `get_plate_comment` | Get function header comment |
| `clear_function_comments` | Clear all comments in function |
| `batch_set_comments` | Set many comments at once |
| `set_function_tag_comment` | Comment on a function tag |
| `apply_function_documentation` | Apply docs to function |
| `analyze_for_documentation` | Suggest documentation |
| `compare_programs_documentation` | Diff docs between programs |
| `merge_program_documentation` | Merge docs from another program |
| `find_undocumented_by_string` | Find functions with matching strings but no docs |
| `archive_ingest_function` | Ingest function into archive |
| `archive_ingest_program` | Ingest program into archive |

#### 🧱 Data Types & Structures (26 tools)

| Tool | Purpose |
|---|---|
| `create_struct` | Create a new struct type |
| `add_struct_field` | Add field to struct |
| `remove_struct_field` | Remove field from struct |
| `modify_struct_field` | Modify existing struct field |
| `get_struct_layout` | Full struct memory layout |
| `analyze_struct_field_usage` | How struct fields are accessed |
| `create_typedef` | Create type alias |
| `create_union` | Create union type |
| `create_enum` | Create enum type |
| `get_enum_values` | Get all enum values |
| `create_array_type` | Create array type |
| `create_pointer_type` | Create pointer type |
| `clone_data_type` | Clone existing type |
| `delete_data_type` | Remove data type |
| `apply_data_type` | Apply type to address |
| `apply_data_classification` | Classify data (code/data/etc) |
| `validate_data_type` | Validate type definition |
| `validate_data_type_exists` | Check type exists |
| `search_data_types` | Search type library |
| `get_valid_data_types` | List valid types for address |
| `list_data_types` | All data types in program |
| `list_data_type_categories` | Data type categories |
| `create_data_type_category` | Create type category |
| `move_data_type_to_category` | Move type to category |
| `import_data_types` | Import types from header/archive |
| `get_type_size` | Get size of data type |

#### 🔗 Imports, Exports & Cross-References (9 tools)

| Tool | Purpose |
|---|---|
| `list_imports` | All imported symbols |
| `list_exports` | All exported symbols |
| `get_xrefs_to` | Cross-references TO an address |
| `get_xrefs_from` | Cross-references FROM an address |
| `get_bulk_xrefs` | Bulk xref lookup |
| `list_data_items` | All defined data items |
| `list_data_items_by_xrefs` | Data items filtered by xrefs |
| `list_external_locations` | External library references |
| `get_external_location` | Detail on external location |
| `rename_external_location` | Rename external symbol |

#### 🦠 Malware Analysis (8 tools)

| Tool | Purpose |
|---|---|
| `detect_crypto_constants` | Find AES/RC4/SHA/DES S-boxes automatically |
| `detect_malware_behaviors` | Flag suspicious API patterns and behaviors |
| `extract_iocs_with_context` | Extract IOCs with surrounding code context |
| `find_anti_analysis_techniques` | Detect anti-debug, anti-VM, obfuscation |
| `emulate_function` | Emulate function execution |
| `emulate_hash_batch` | Emulate hash routines in batch |
| `detect_array_bounds` | Detect array bounds (overflow research) |
| `diff_functions` | Diff two functions for similarity/diff |

#### 🧠 Memory & Segments (10 tools)

| Tool | Purpose |
|---|---|
| `read_memory` | Read raw bytes from address |
| `inspect_memory_content` | Inspect and interpret memory content |
| `search_byte_patterns` | Scan for byte sequences / shellcode |
| `search_instructions` | Search for instruction patterns |
| `create_memory_block` | Create new memory block |
| `set_image_base` | Rebase image to new address |
| `get_address_spaces` | All address spaces |
| `list_segments` | Memory segments / sections |
| `get_language_metadata` | Processor language metadata |
| `convert_number` | Convert between number bases |

#### 🔍 Strings & Search (5 tools)

| Tool | Purpose |
|---|---|
| `list_strings` | All strings in binary |
| `search_strings` | Search strings by pattern |
| `batch_string_anchor_report` | Batch string → function mapping |
| `bulk_fuzzy_match` | Fuzzy match functions/strings |
| `find_undocumented_by_string` | Find funcs with strings but no comments |

#### 🏷️ Tags & Bookmarks (11 tools)

| Tool | Purpose |
|---|---|
| `create_function_tag` | Create a new function tag |
| `delete_function_tag` | Delete a function tag |
| `add_function_tag` | Add tag to function |
| `remove_function_tag` | Remove tag from function |
| `batch_add_function_tags` | Tag many functions at once |
| `batch_remove_function_tags` | Remove tags from many functions |
| `list_function_tags` | All defined tags |
| `get_function_tags` | Tags on a specific function |
| `set_bookmark` | Set bookmark at address |
| `delete_bookmark` | Remove bookmark |
| `list_bookmarks` | All bookmarks in program |

#### 🏛️ Classes, Namespaces & Globals (11 tools)

| Tool | Purpose |
|---|---|
| `list_classes` | All classes (OOP binaries) |
| `list_methods` | Methods in a class |
| `list_namespaces` | All namespaces |
| `list_globals` | All global variables |
| `audit_global` | Audit usage of a global |
| `set_global` | Set value of global |
| `rename_global_variable` | Rename global variable |
| `rename_data` | Rename data item |
| `list_calling_conventions` | Available calling conventions |

#### 🐛 Debugger Suite (22 tools)

| Tool | Purpose |
|---|---|
| `debugger_attach` | Attach debugger to process |
| `debugger_detach` | Detach debugger |
| `debugger_status` | Current debugger state |
| `debugger_set_breakpoint` | Set breakpoint at address |
| `debugger_remove_breakpoint` | Remove breakpoint |
| `debugger_list_breakpoints` | All active breakpoints |
| `debugger_continue` | Resume execution |
| `debugger_step_into` | Step into next instruction |
| `debugger_step_over` | Step over next instruction |
| `debugger_registers` | Read all register values |
| `debugger_read_memory` | Read memory via debugger |
| `debugger_stack_trace` | Full call stack |
| `debugger_modules` | Loaded modules/libraries |
| `debugger_read_args` | Read function arguments |
| `debugger_resolve_ordinal` | Resolve import by ordinal |
| `debugger_trace_function` | Start function trace |
| `debugger_trace_list` | List active traces |
| `debugger_trace_log` | Get trace log output |
| `debugger_trace_stop` | Stop tracing |
| `debugger_watch_memory` | Watch memory address for changes |
| `debugger_watch_log` | Get memory watch log |
| `debugger_watch_stop` | Stop memory watch |

#### 📜 Scripts (3 tools)

| Tool | Purpose |
|---|---|
| `list_scripts` | List available Ghidra scripts |
| `run_ghidra_script` | Run a named Ghidra script |
| `run_script_inline` | Execute inline Groovy/Python script |

#### ⚙️ Tool Groups & Server (6 tools)

| Tool | Purpose |
|---|---|
| `server_status` | Ghidra headless server health |
| `check_tools` | Verify available tools |
| `list_tool_groups` | List lazy-loaded tool categories |
| `load_tool_group` | Load tool group into session |
| `unload_tool_group` | Unload tool group |

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
