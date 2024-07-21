#!/bin/bash

set -e

# Function to check and enable multilib repository
enable_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "Enabling multilib repository..."
        sudo tee -a /etc/pacman.conf > /dev/null <<EOT

[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
        echo "Multilib repository has been enabled."
    else
        echo "Multilib repository is already enabled."
    fi
}

# Function to install yay
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin || exit
        makepkg -si --noconfirm
        cd .. && rm -rf yay-bin
        export PATH="$PATH:$HOME/.local/bin"
    else
        echo "yay is already installed."
    fi
}

# Function to install KDE and KDE software
install_kde() {
    echo "Installing KDE Plasma and applications..."
    sudo pacman -S --needed --noconfirm xorg sddm
    sudo systemctl enable sddm

    sudo pacman -S --noconfirm plasma-desktop dolphin konsole systemsettings plasma-pa plasma-nm kscreen kde-gtk-config breeze-gtk powerdevil sddm-kcm kwalletmanager

    sudo systemctl enable NetworkManager
}

install_amd() {
    echo "Installing AMD GPU drivers and tools"
    # Install AMD drivers and tools
    sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader
    yay -S --noconfirm lact
    }

install_nvidia() {
    echo "Installing Nvidia GPU drivers"
    # Install Nvidia drivers and tools
    sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia
}

# Main installation
main_installation() {
    echo "Starting the main installation for gaming. This may take some time."

    # Enable TRIM for SSDs
    sudo systemctl enable fstrim.timer

    # Install gaming packages and utilities with pacman
    sudo pacman -S --noconfirm \
        steam lutris wine-staging winetricks gamemode lib32-gamemode \
        giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap \
        gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal \
        v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error \
        alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib \
        libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite \
        libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader \
        libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 \
        gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader \
        obs-studio discord flatpak mangohud lib32-mangohud goverlay gamescope solaar kate kio-admin

    echo "Installing AUR packages with yay..."
    yay -S --noconfirm \
        vkbasalt lib32-vkbasalt proton-ge-custom-bin xone-dkms dxvk-bin

    echo "Main installation completed."
}

# Function to install Pamac and Flathub
pamac_installation() {
    echo "Installing pamac"

    # Install Pamac
    sudo pacman -S glib2-devel glib2
    yay -S --noconfirm libpamac-full pamac-all

    # Add Flathub
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "Pamac installation completed."
}

# Main program
echo "This script will configure your system for gaming and install software."
echo "Please make sure you have a backup of your important data."
echo "Do you want to proceed? (y/n)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Installation aborted."
    exit 1
fi

# Ask for sudo rights
sudo -v

# Keep sudo rights
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

enable_multilib
sudo pacman -Syyu --noconfirm
install_yay

# Ask about AMD installation
echo "Do you want to install AMD GPU drivers? (y/n)"
read -r amd_response
if [[ "$amd_response" =~ ^[Yy]$ ]]; then
    install_amd
else
    echo "AMD GPU installation skipped."
fi

# Ask about Nvidia installation
echo "Do you want to install Nvidia GPU drivers? (y/n)"
read -r nvidia_response
if [[ "$nvidia_response" =~ ^[Yy]$ ]]; then
    install_nvidia
else
    echo "Nvidia GPU installation skipped."
fi

# Ask about KDE installation
echo "Do you want to install KDE Plasma and a minimal set of associated applications? (y/n)"
read -r kde_response
if [[ "$kde_response" =~ ^[Yy]$ ]]; then
    install_kde
else
    echo "KDE installation skipped."
fi

# Ask about Main installation
echo "Do you want to start the main installation for gaming-related software? (y/n)"
read -r main_response
if [[ "$main_response" =~ ^[Yy]$ ]]; then
    main_installation
else
    echo "Main installation skipped."
fi

# Ask about Pamac installation
echo "Do you want to install Pamac? (y/n)"
read -r pamac_response
if [[ "$pamac_response" =~ ^[Yy]$ ]]; then
    pamac_installation
else
    echo "Pamac installation skipped."
fi

echo "Script completed. Please restart your system to apply all changes."
