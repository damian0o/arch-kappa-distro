#!/usr/bin/env bash
# Runs inside the archiso chroot after all packages are installed.
set -euo pipefail

# --- Locale ---
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# --- Console keymap (required by sd-vconsole mkinitcpio hook) ---
echo "KEYMAP=us" > /etc/vconsole.conf

# --- Timezone ---
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# --- Live user ---
useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash kappa
echo "kappa:kappa" | chpasswd
echo "root:kappa" | chpasswd

# --- sudoers ---
# (file is already placed by airootfs overlay with correct permissions)

# --- Services ---
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm
systemctl enable reflector.timer

# --- SDDM auto-login for the live session ---
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=kappa
Session=plasma
Relogin=false
EOF

# --- Plasma first-run suppression (skip wizard in live session) ---
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/plasma-welcomerc <<EOF
[General]
ShouldShow=false
EOF

# --- yay AUR helper (built from source) ---
# Build as a non-root user since makepkg refuses to run as root.
# The kappa user already exists at this point.
BUILD_DIR=/home/kappa/yay-build
mkdir -p "$BUILD_DIR"
chown kappa:kappa "$BUILD_DIR"
su - kappa -s /bin/bash -c "
  git clone https://aur.archlinux.org/yay.git '$BUILD_DIR'
  cd '$BUILD_DIR'
  makepkg -si --noconfirm
"
rm -rf "$BUILD_DIR"

# Remove go after yay is built — it's only needed to compile yay and adds ~500 MB.
pacman -Rns --noconfirm go

# --- Kappa environment marker ---
cat > /etc/profile.d/kappa.sh <<EOF
export KAPPA_VERSION="1.0"
export DISTRO_NAME="Kappa Linux"
EOF

echo "customize_airootfs.sh complete."
