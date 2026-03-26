#!/usr/bin/env bash
# Runs INSIDE the Arch Linux Docker container.
set -euo pipefail

echo "Installing archiso..."
# Disable pacman's sandbox — required when running x86_64 emulation on Apple Silicon
# via Docker/QEMU where seccomp filtering blocks the alpm sandbox user.
echo "DisableSandbox" >> /etc/pacman.conf
pacman -Sy --noconfirm archiso

echo "Running mkarchiso..."
mkarchiso -v -w /tmp/work -o /out /work/kappa-profile

echo "Done."
