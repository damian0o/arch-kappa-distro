#!/usr/bin/env bash
# Verify that all host dependencies are present before building.
set -euo pipefail

MISSING=()

check() {
  if ! command -v "$1" &>/dev/null; then
    MISSING+=("$1")
    echo "  [MISSING] $1"
  else
    echo "  [OK]      $1  ($(command -v "$1"))"
  fi
}

NATIVE_ARCH=false
if [[ "$(uname -s)" == "Linux" ]] && command -v pacman &>/dev/null; then
  NATIVE_ARCH=true
fi

echo "Checking dependencies..."

if $NATIVE_ARCH; then
  echo "  (Arch Linux detected — native build mode)"
  check mkarchiso
  check qemu-system-x86_64
  check qemu-img
else
  echo "  (non-Arch detected — Docker build mode)"
  check docker
  check qemu-system-x86_64
  check qemu-img
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "Missing: ${MISSING[*]}"
  echo ""
  if $NATIVE_ARCH; then
    echo "Install with:"
    echo "  sudo pacman -S archiso qemu-full"
  else
    echo "Install with:"
    echo "  brew install qemu"
    echo "  # Docker Desktop: https://www.docker.com/products/docker-desktop/"
  fi
  exit 1
fi

echo ""
echo "All dependencies found."
