# ── CyberHawk RE — Skill Setup (Windows PowerShell) ──────────────────────────
# Copies the 41 RE-relevant skills from cyberhawk-docker\skills\ into
# this repo's skills\ directory.
#
# Usage:
#   .\scripts\setup-skills.ps1 [-Source <path>]
#
# Default source: ..\cyberhawk-docker\skills
# ─────────────────────────────────────────────────────────────────────────────

param(
    [string]$Source = "..\cyberhawk-docker\skills"
)

$RepoRoot = Split-Path $PSScriptRoot -Parent
$Dest = Join-Path $RepoRoot "skills"

$ReSkills = @(
    "analyzing-android-malware-with-apktool",
    "analyzing-bootkit-and-rootkit-samples",
    "analyzing-cobalt-strike-beacon-configuration",
    "analyzing-golang-malware-with-ghidra",
    "analyzing-heap-spray-exploitation",
    "analyzing-ios-app-security-with-objection",
    "analyzing-linux-elf-malware",
    "analyzing-linux-kernel-rootkits",
    "analyzing-malicious-pdf-with-peepdf",
    "analyzing-memory-dumps-with-volatility",
    "analyzing-memory-forensics-with-lime-and-volatility",
    "analyzing-network-covert-channels-in-malware",
    "analyzing-network-traffic-of-malware",
    "analyzing-packed-malware-with-upx-unpacker",
    "analyzing-pdf-malware-with-pdfid",
    "analyzing-ransomware-encryption-mechanisms",
    "analyzing-uefi-bootkit-persistence",
    "deobfuscating-javascript-malware",
    "deobfuscating-powershell-obfuscated-malware",
    "extracting-config-from-agent-tesla-rat",
    "extracting-credentials-from-memory-dump",
    "extracting-iocs-from-malware-samples",
    "extracting-memory-artifacts-with-rekall",
    "performing-binary-exploitation-analysis",
    "performing-firmware-extraction-with-binwalk",
    "performing-firmware-malware-analysis",
    "performing-hash-cracking-with-hashcat",
    "performing-malware-ioc-extraction",
    "performing-malware-triage-with-yara",
    "performing-memory-forensics-with-volatility3",
    "performing-memory-forensics-with-volatility3-plugins",
    "performing-plc-firmware-security-analysis",
    "performing-static-malware-analysis-with-pe-studio",
    "performing-steganography-detection",
    "performing-threat-hunting-with-yara-rules",
    "performing-yara-rule-development-for-detection",
    "reverse-engineering-android-malware-with-jadx",
    "reverse-engineering-dotnet-malware-with-dnspy",
    "reverse-engineering-ios-app-with-frida",
    "reverse-engineering-malware-with-ghidra",
    "reverse-engineering-ransomware-encryption-routine",
    "reverse-engineering-rust-malware"
)

Write-Host "[setup-skills] Source: $Source"
Write-Host "[setup-skills] Dest:   $Dest"
Write-Host ""

if (-not (Test-Path $Source)) {
    Write-Error "Source directory not found: $Source`nUsage: .\scripts\setup-skills.ps1 [-Source <path\to\cyberhawk-docker\skills>]"
    exit 1
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$Copied = 0
$Missing = 0

foreach ($skill in $ReSkills) {
    $srcPath = Join-Path $Source $skill
    if (Test-Path $srcPath) {
        Copy-Item -Recurse -Force $srcPath $Dest
        Write-Host "  √  $skill" -ForegroundColor Green
        $Copied++
    } else {
        Write-Host "  ✗  MISSING: $skill" -ForegroundColor Yellow
        $Missing++
    }
}

Write-Host ""
Write-Host "[setup-skills] Done — $Copied copied, $Missing missing"
if ($Missing -gt 0) {
    Write-Host "[setup-skills] Missing skills must be added manually to $Dest\" -ForegroundColor Yellow
}
