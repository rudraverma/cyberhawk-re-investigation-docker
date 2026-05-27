#!/bin/bash
# ── CyberHawk RE — Skill Setup ───────────────────────────────────────────────
# Copies the 41 RE-relevant skills from cyberhawk-docker/skills/ into
# this repo's skills/ directory.
#
# Usage:
#   ./scripts/setup-skills.sh [source_skills_path]
#
# Default source: ../cyberhawk-docker/skills
# ─────────────────────────────────────────────────────────────────────────────

SOURCE="${1:-../cyberhawk-docker/skills}"
DEST="$(dirname "$0")/../skills"

RE_SKILLS=(
  "analyzing-android-malware-with-apktool"
  "analyzing-bootkit-and-rootkit-samples"
  "analyzing-cobalt-strike-beacon-configuration"
  "analyzing-golang-malware-with-ghidra"
  "analyzing-heap-spray-exploitation"
  "analyzing-ios-app-security-with-objection"
  "analyzing-linux-elf-malware"
  "analyzing-linux-kernel-rootkits"
  "analyzing-malicious-pdf-with-peepdf"
  "analyzing-memory-dumps-with-volatility"
  "analyzing-memory-forensics-with-lime-and-volatility"
  "analyzing-network-covert-channels-in-malware"
  "analyzing-network-traffic-of-malware"
  "analyzing-packed-malware-with-upx-unpacker"
  "analyzing-pdf-malware-with-pdfid"
  "analyzing-ransomware-encryption-mechanisms"
  "analyzing-uefi-bootkit-persistence"
  "deobfuscating-javascript-malware"
  "deobfuscating-powershell-obfuscated-malware"
  "extracting-config-from-agent-tesla-rat"
  "extracting-credentials-from-memory-dump"
  "extracting-iocs-from-malware-samples"
  "extracting-memory-artifacts-with-rekall"
  "performing-binary-exploitation-analysis"
  "performing-firmware-extraction-with-binwalk"
  "performing-firmware-malware-analysis"
  "performing-hash-cracking-with-hashcat"
  "performing-malware-ioc-extraction"
  "performing-malware-triage-with-yara"
  "performing-memory-forensics-with-volatility3"
  "performing-memory-forensics-with-volatility3-plugins"
  "performing-plc-firmware-security-analysis"
  "performing-static-malware-analysis-with-pe-studio"
  "performing-steganography-detection"
  "performing-threat-hunting-with-yara-rules"
  "performing-yara-rule-development-for-detection"
  "reverse-engineering-android-malware-with-jadx"
  "reverse-engineering-dotnet-malware-with-dnspy"
  "reverse-engineering-ios-app-with-frida"
  "reverse-engineering-malware-with-ghidra"
  "reverse-engineering-ransomware-encryption-routine"
  "reverse-engineering-rust-malware"
)

echo "[setup-skills] Source: $SOURCE"
echo "[setup-skills] Dest:   $DEST"
echo ""

if [ ! -d "$SOURCE" ]; then
  echo "ERROR: Source directory not found: $SOURCE"
  echo "Usage: ./scripts/setup-skills.sh [path/to/cyberhawk-docker/skills]"
  exit 1
fi

mkdir -p "$DEST"

COPIED=0
MISSING=0

for skill in "${RE_SKILLS[@]}"; do
  if [ -d "$SOURCE/$skill" ]; then
    cp -r "$SOURCE/$skill" "$DEST/"
    echo "  ✓  $skill"
    ((COPIED++))
  else
    echo "  ✗  MISSING: $skill"
    ((MISSING++))
  fi
done

echo ""
echo "[setup-skills] Done — $COPIED copied, $MISSING missing"
[ "$MISSING" -gt 0 ] && echo "[setup-skills] Missing skills must be added manually to $DEST/"
