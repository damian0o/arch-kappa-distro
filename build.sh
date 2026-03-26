#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
IMAGE="archlinux:latest"
OUT_DIR="$REPO_ROOT/out"

mkdir -p "$OUT_DIR"

# Detect whether we're running on Arch Linux natively or need Docker.
if [[ "$(uname -s)" == "Linux" ]] && command -v pacman &>/dev/null; then
  # --- Native Arch Linux build ---
  if ! command -v mkarchiso &>/dev/null; then
    echo "Installing archiso..."
    sudo pacman -Sy --noconfirm archiso
  fi

  echo "Building Kappa Linux ISO (native)..."
  sudo mkarchiso -v -w /tmp/kappa-work -o "$OUT_DIR" "$REPO_ROOT/kappa-profile"
else
  # --- macOS (or other non-Arch) — build via Docker ---
  if ! command -v docker &>/dev/null; then
    echo "Error: docker is not installed or not in PATH." >&2
    echo "Install Docker Desktop: https://www.docker.com/products/docker-desktop/" >&2
    exit 1
  fi

  echo "Pulling latest Arch Linux Docker image..."
  docker pull --platform linux/amd64 "$IMAGE"

  echo "Building Kappa Linux ISO (Docker)..."
  docker run --rm \
    --platform linux/amd64 \
    --privileged \
    --security-opt seccomp=unconfined \
    -v "$REPO_ROOT/kappa-profile:/work/kappa-profile:ro" \
    -v "$REPO_ROOT/out:/out" \
    -v "$REPO_ROOT/scripts/build-inner.sh:/build-inner.sh:ro" \
    "$IMAGE" \
    bash /build-inner.sh
fi

echo ""
echo "Build complete. ISO:"
ls -lh "$OUT_DIR"/kappa-*.iso 2>/dev/null || echo "  (no ISO found in out/)"
