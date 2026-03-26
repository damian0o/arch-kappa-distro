#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO="$(ls -t "$REPO_ROOT/out"/kappa-*.iso 2>/dev/null | head -1)"

if [[ -z "$ISO" ]]; then
  echo "No ISO found in out/. Run ./build.sh first."
  exit 1
fi

DISK="$REPO_ROOT/out/kappa-test.qcow2"
if [[ ! -f "$DISK" ]]; then
  echo "Creating 20G virtual disk at $DISK..."
  qemu-img create -f qcow2 "$DISK" 20G
fi

echo "Booting: $ISO"

# OVMF firmware path (installed by Homebrew qemu)
OVMF_CODE=""
for p in \
  /opt/homebrew/share/qemu/edk2-x86_64-code.fd \
  /usr/local/share/qemu/edk2-x86_64-code.fd; do
  if [[ -f "$p" ]]; then
    OVMF_CODE="$p"
    break
  fi
done

QEMU_FLAGS=(
  -m 4096
  -smp 2
  -cdrom "$ISO"
  -drive "file=$DISK,format=qcow2"
  -boot d
  -vga virtio
  -display cocoa
  -net nic
  -net user
)

if [[ -n "$OVMF_CODE" ]]; then
  QEMU_FLAGS+=(-drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE")
  echo "UEFI mode: using $OVMF_CODE"
else
  echo "OVMF firmware not found — booting in BIOS mode."
fi

# On Apple Silicon use HVF; on Intel use KVM if available, otherwise software
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  qemu-system-x86_64 "${QEMU_FLAGS[@]}" -accel tcg -cpu qemu64 || true
else
  qemu-system-x86_64 "${QEMU_FLAGS[@]}" -enable-kvm 2>/dev/null || \
  qemu-system-x86_64 "${QEMU_FLAGS[@]}"
fi
