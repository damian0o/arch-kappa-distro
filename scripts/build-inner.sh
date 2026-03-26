#!/usr/bin/env bash
# Runs INSIDE the Arch Linux Docker container.
set -euo pipefail

echo "Installing archiso..."
pacman -Sy --noconfirm archiso

echo "Running mkarchiso..."
mkarchiso -v -w /tmp/work -o /out /work/kappa-profile

echo "Done."
