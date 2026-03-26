# Kappa Linux

A custom Arch Linux-based desktop distribution for x86_64, featuring KDE Plasma and PipeWire audio, built with [archiso](https://wiki.archlinux.org/title/Archiso).

## Features

- KDE Plasma desktop (Wayland + X11)
- PipeWire audio stack (with PulseAudio and JACK compatibility)
- systemd-boot (UEFI only)
- pacman package manager
- Live session with auto-login
- Shell-script installer (`kappa-install`)

## Requirements

**On macOS:**
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- QEMU (`brew install qemu`)

**On Arch Linux:**
- `archiso` (`sudo pacman -S archiso`)
- `qemu-full` (`sudo pacman -S qemu-full`) — for testing

Run the dependency check:

```bash
./scripts/checkdeps.sh
```

## Build

```bash
./build.sh
```

On macOS, this pulls an `archlinux:latest` Docker image and runs `mkarchiso` inside it. On Arch Linux, it runs `mkarchiso` directly. The resulting ISO is written to `out/`.

## Test

```bash
./scripts/qemu-test.sh
```

Boots the latest ISO in QEMU with a 20 GB virtual disk. UEFI mode is used automatically if OVMF firmware is found.

## Install to disk

Boot the live ISO, open a terminal, and run:

```bash
sudo kappa-install --yes
```

This will:
1. Prompt for a target disk
2. Partition (GPT: 512 MB EFI + root)
3. Install all packages via `pacstrap`
4. Configure locale, hostname, users, and services
5. Install systemd-boot

> **Default credentials:** username `kappa`, password `kappa` for both the live session and the installed system. Change your password after first login with `passwd`.

## Project structure

```
arch-kappa-distro/
├── build.sh                        # Entry point — detects macOS vs Arch and builds accordingly
├── scripts/
│   ├── build-inner.sh              # Runs inside the Docker container
│   ├── qemu-test.sh                # Boots the ISO in QEMU
│   └── checkdeps.sh                # Verifies host dependencies
├── kappa-profile/                  # archiso profile
│   ├── profiledef.sh               # ISO metadata and boot modes
│   ├── packages.x86_64             # Package manifest
│   ├── pacman.conf                 # pacman config used during build
│   ├── customize_airootfs.sh       # Post-install chroot configuration
│   └── airootfs/                   # Files overlaid onto the live root filesystem
├── installer/
│   └── kappa-install.sh            # OS installer (source — copied into airootfs at build time)
├── branding/                       # Wallpaper, logo, themes (place assets here)
└── out/                            # Build output — gitignored
```

## Branding

Place custom assets in `branding/`:

| File | Purpose |
|---|---|
| `branding/wallpaper.png` | Default desktop wallpaper |
| `branding/logo.png` | Distro logo |

## License

MIT
