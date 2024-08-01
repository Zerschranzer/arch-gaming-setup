#!/bin/bash

RED='\033[1;31m'        # ${RED}
YELLOW='\033[1;33m'    # ${YELLOW}
GREEN='\033[1;32m'    # ${GREEN}
NC='\033[0m'         # ${NC}


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

    sudo pacman -S --noconfirm plasma-desktop dolphin konsole systemsettings plasma-pa plasma-nm kscreen kde-gtk-config breeze-gtk powerdevil sddm-kcm kwalletmanager \
        kio-admin bluedevil

    sudo systemctl enable NetworkManager
}

# Function to install GNOME and GNOME software
install_gnome() {
    echo "Installing GNOME and applications..."
    sudo pacman -S --needed --noconfirm xorg sddm
    sudo systemctl enable sddm

    sudo pacman -S --noconfirm gnome gnome-extra networkmanager

    sudo systemctl enable NetworkManager
}

# Function to install XFCE and XFCE software
install_xfce() {
    echo "Installing XFCE and applications..."
    sudo pacman -S --needed --noconfirm xorg sddm
    sudo systemctl enable sddm

    sudo pacman -S --noconfirm xfce4 xfce4-goodies networkmanager


    sudo systemctl enable NetworkManager
}

# Function to install Cinnamon and Cinnamon software
install_cinnamon() {
    echo "Installing Cinnamon and applications..."
    sudo pacman -S --needed --noconfirm xorg sddm
    sudo systemctl enable sddm

    sudo pacman -S --noconfirm cinnamon nemo-fileroller networkmanager

    sudo systemctl enable NetworkManager
}


install_amd() {
    echo "Installing AMD GPU drivers and tools"
    echo -e "${YELLOW}Warning: The Git version of Mesa may be unstable and requires frequent updates. It's recommended for advanced users or for testing purposes.${NC}"
    
    while true; do
        echo -e "${YELLOW}Do you want to install the stable version or the git version of Mesa? (stable/git)${NC}"
        read -r mesa_version

        if [[ "$mesa_version" == "git" ]]; then
            echo "Installing Git version of Mesa and Vulkan drivers..."
          MAKEFLAGS="-j$(nproc)" yay -S --noconfirm amdonly-gaming-mesa-git
            break
        elif [[ "$mesa_version" == "stable" ]]; then
            echo "Installing stable version of Mesa and Vulkan drivers..."
            sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
            break
        else
            echo -e "${RED}Invalid input. Please enter either 'stable' or 'git'.${NC}"
        fi
    done

    # Common packages for both versions
    sudo pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
   MAKEFLAGS="-j$(nproc)" yay -S --noconfirm lact
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
    sudo pacman -S --noconfirm steam lutris wine-staging winetricks gamemode lib32-gamemode giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal \
    v4l-utils lib32-v4l-utils libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama \
    lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader \
    lib32-vulkan-icd-loader obs-studio discord mangohud lib32-mangohud goverlay gamescope solaar bluez bluez-utils pipewire pipewire-pulse pipewire-alsa linux-headers xwaylandvideobridge

    echo "Installing AUR packages with yay..."
    MAKEFLAGS="-j$(nproc)" yay -S --noconfirm \
        vkbasalt lib32-vkbasalt proton-ge-custom-bin xone-dkms-git dxvk-bin

    echo "Main installation completed."
}

# Function to install Pamac and Flathub
pamac_installation() {
    echo "Installing pamac"

    # Install Pamac
    sudo pacman -S --noconfirm glib2-devel glib2
    MAKEFLAGS="-j$(nproc)" yay -S --noconfirm libpamac-full pamac-all

    # Add Flathub
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "Pamac installation completed."
}

# Function to prompt for Desktop Environment selection
prompt_de_selection() {
    echo -e "${YELLOW}Which Desktop Environment do you want to install?${NC}"
    echo -e "1) KDE Plasma ${GREEN}(recommended)${NC}"
    echo -e "2) GNOME ${YELLOW}(experimental)${NC}"
    echo -e "3) XFCE ${YELLOW}(experimental)${NC}"
    echo -e "4) Cinnamon ${YELLOW}(experimental)${NC}"
    echo -e "5) None"
    read -r de_choice

    case $de_choice in
        1)
            install_kde
            ;;
        2)
            echo -e "You have selected GNOME (experimental)."
            install_gnome
            ;;
        3)
            echo -e "You have selected XFCE (experimental)."
            install_xfce
            ;;
        4)
            echo -e "You have selected Cinnamon (experimental)."
            install_cinnamon
            ;;
        5)
            echo -e "${RED}No Desktop Environment will be installed.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select a valid option."
            prompt_de_selection
            ;;
    esac
}

# Main program
echo -e "${YELLOW}This script will configure your system for gaming and install software using and installing yay.${NC}"
echo -e "${YELLOW}Please make sure you have a backup of your important data.${NC}"
echo -e  "${YELLOW}Do you want to proceed? (y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation aborted.${NC}"
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
echo -e "${YELLOW}Do you want to install AMD GPU drivers? (y/n)${NC}"
read -r amd_response
if [[ "$amd_response" =~ ^[Yy]$ ]]; then
    install_amd
else
    echo -e "${RED}AMD GPU installation skipped.${NC}"
fi

# Ask about Nvidia installation
echo -e "${YELLOW}Do you want to install Nvidia GPU drivers? (y/n)${NC}"
read -r nvidia_response
if [[ "$nvidia_response" =~ ^[Yy]$ ]]; then
    install_nvidia
else
    echo -e "${RED}Nvidia GPU installation skipped.${NC}"
fi

# Function to ask about desktop environment
prompt_de_selection

# Ask about Main installation
echo -e "${YELLOW}Do you want to start the main installation for gaming-related software? (y/n)${NC}"
read -r main_response
if [[ "$main_response" =~ ^[Yy]$ ]]; then
    main_installation
else
    echo -e "${RED}Main installation skipped.${NC}"
fi

# Ask about Pamac installation
echo -e "${YELLOW}Do you want to install Pamac? (y/n)${NC}"
read -r pamac_response
if [[ "$pamac_response" =~ ^[Yy]$ ]]; then
    pamac_installation
else
    echo -e "${RED}Pamac installation skipped.${NC}"
fi

# Ask about Kernel installation
while true; do
    # Kernel selection
    echo -e "${YELLOW}Which kernel would you like to install?${NC}"
    echo -e "${YELLOW}Liquorix kernel most times offers slightly better performance, but it needs to be compiled on the computer, which takes way more time.${NC}"
    echo -e "${YELLOW}Zen kernel most times offers better performance for gaming compared to the standard kernel, but its not quite as powerful as the Liquorix kernel${NC}"
    echo -e "1) Liquorix Kernel"
    echo -e "2) Zen Kernel"
    echo -e "3) Do not install any custom kernel"
    read -r kernel_choice

    case $kernel_choice in
        1)
            MAKEFLAGS="-j$(nproc)" yay -S --noconfirm linux-lqx linux-lqx-headers
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            break
            ;;
        2)
            sudo pacman -S --noconfirm linux-zen linux-zen-headers
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            break
            ;;
        3)
            echo -e "${RED}No kernel installation selected.${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid selection. Please choose 1, 2, or 3.${NC}"
            ;;
    esac
done

echo -e "${YELLOW}Process completed.${NC}"

        sudo rm -R /var/lib/pacman/sync
        sudo pacman -Syy
        sudo pacman -Syu
# Ask about restart
echo -e "${GREEN}Script completed succesfully. Do you want to restart your system to apply all changes now?(y/n)${NC}"
read -r restart_response
if [[ "$restart_response" =~ ^[Yy]$ ]]; then
    sudo reboot now
else
    echo -e "${RED}No restart selected${NC}"
fi
