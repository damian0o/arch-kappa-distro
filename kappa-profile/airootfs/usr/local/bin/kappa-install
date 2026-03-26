#!/usr/bin/env bash
# =============================================================================
# kappa-install — Kappa Linux installer
# Run from the live session as root (or via sudo).
# Usage: kappa-install [--yes]
# =============================================================================
set -euo pipefail

DRY_RUN=true
TARGET=/mnt
KAPPA_VERSION="1.0"

for arg in "$@"; do
  [[ "$arg" == "--yes" ]] && DRY_RUN=false
done

log()  { echo "[kappa-install] $*"; }
die()  { echo "[kappa-install] ERROR: $*" >&2; exit 1; }
run()  {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# ---- 1. Preflight checks -----------------------------------------------------

[[ "$EUID" -eq 0 ]] || die "Must be run as root."
command -v pacstrap &>/dev/null || die "pacstrap not found. Is arch-install-scripts installed?"

if $DRY_RUN; then
  log "DRY RUN mode. Pass --yes to actually write to disk."
fi

# ---- 2. Disk selection -------------------------------------------------------

log "Available disks:"
lsblk -dpno NAME,SIZE,TYPE | grep disk

read -rp "Target disk (e.g. /dev/sda): " DISK
[[ -b "$DISK" ]] || die "$DISK is not a block device."

log "WARNING: All data on $DISK will be destroyed."
read -rp "Type 'yes' to confirm: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || die "Aborted."

# ---- 3. Partitioning ---------------------------------------------------------

log "Partitioning $DISK..."
run sgdisk --zap-all "$DISK"
run sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System"  "$DISK"
run sgdisk -n 2:0:0     -t 2:8300 -c 2:"Kappa Linux"  "$DISK"

# Refresh partition table
run partprobe "$DISK"
sleep 1

# Derive partition device names (handles /dev/sda → sda1, /dev/nvme0n1 → nvme0n1p1)
if [[ "$DISK" =~ nvme|mmcblk ]]; then
  EFI="${DISK}p1"
  ROOT="${DISK}p2"
else
  EFI="${DISK}1"
  ROOT="${DISK}2"
fi

# ---- 4. Filesystems ----------------------------------------------------------

log "Formatting partitions..."
run mkfs.fat -F32 "$EFI"
run mkfs.ext4 -L kappa "$ROOT"

# ---- 5. Mount ----------------------------------------------------------------

log "Mounting target..."
run mount "$ROOT" "$TARGET"
run mkdir -p "$TARGET/boot"
run mount "$EFI" "$TARGET/boot"

# ---- 6. Install base system --------------------------------------------------

PACKAGES=(
  base base-devel linux linux-firmware linux-headers mkinitcpio
  systemd-sysvcompat efibootmgr networkmanager
  network-manager-applet wpa_supplicant bluez bluez-utils
  btrfs-progs e2fsprogs dosfstools ntfs-3g gptfdisk parted
  pacman reflector
  plasma plasma-wayland-session sddm sddm-kcm
  dolphin konsole kate gwenview okular ark spectacle kcalc kfind partitionmanager
  firefox vlc
  ttf-liberation ttf-dejavu noto-fonts noto-fonts-emoji ttf-hack
  git curl wget rsync unzip zip man-db bash-completion htop neofetch sudo
)

log "Installing packages with pacstrap..."
run pacstrap -K "$TARGET" "${PACKAGES[@]}"

# ---- 7. fstab ----------------------------------------------------------------

log "Generating fstab..."
if ! $DRY_RUN; then
  genfstab -U "$TARGET" >> "$TARGET/etc/fstab"
fi

# ---- 8. Chroot configuration -------------------------------------------------

log "Configuring installed system..."

run arch-chroot "$TARGET" /bin/bash -s <<'CHROOT'
set -euo pipefail

# Locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Timezone (default UTC — user can change after install)
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Hostname
echo "kappa" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   kappa.localdomain kappa
EOF

# Initramfs
mkinitcpio -P

# Root password
echo "root:kappa" | chpasswd

# Regular user
useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash kappa
echo "kappa:kappa" | chpasswd

# wheel group sudoers
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# Services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm
systemctl enable reflector.timer

# Bootloader — systemd-boot
bootctl install

# Loader config
cat > /boot/loader/loader.conf <<EOF
default kappa.conf
timeout 4
console-mode max
editor no
EOF

# Boot entry
PARTUUID="$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)")"
cat > /boot/loader/entries/kappa.conf <<EOF
title   Kappa Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$PARTUUID rw quiet splash
EOF

# Kappa branding
cat > /etc/os-release <<EOF
NAME="Kappa Linux"
PRETTY_NAME="Kappa Linux 1.0"
ID=kappa
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;100;149;237"
HOME_URL="https://kappa.example.org"
LOGO=kappa-logo
EOF

CHROOT

# ---- 9. Remove live-only sudoers file if it was copied ----------------------

run rm -f "$TARGET/etc/sudoers.d/kappa-live" 2>/dev/null || true

# ---- 10. Unmount -------------------------------------------------------------

log "Unmounting..."
run umount -R "$TARGET"

log ""
log "Installation complete!"
log "Default credentials: kappa / kappa  (change after first login)"
log "Remove the installation medium and reboot."
