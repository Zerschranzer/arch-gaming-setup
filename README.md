# Arch Linux Gaming Setup

This repository contains two Bash scripts designed to simplify the process of installing and configuring Arch Linux for gaming.

## Scripts

### 1. arch-auto-installer.sh

A user-friendly, interactive Bash script for automating Arch Linux installation.

#### Key Features:
- Interactive keyboard layout and locale selection
- Automated or manual disk partitioning with optional swap
- Flexible filesystem choice for manual partitioning
- Automatic base system installation and configuration
- User account creation and sudo setup
- GRUB bootloader installation for UEFI systems
- Basic network configuration with NetworkManager
- Option to copy the gaming setup script to the new user's home directory

This script is ideal for both newcomers to Arch Linux and experienced users looking to streamline their installation process. It aims to make Arch Linux more accessible while still maintaining the flexibility and customization options that Arch is known for.

**Note**: This script is intended for use on systems with UEFI firmware.

### 2. arch-gaming-setup.sh

An interactive Bash script to automate the setup of an Arch Linux system for gaming.

#### Features:
- Enables multilib repository
- Installs Yay AUR helper
- Offers installation of AMD or NVIDIA GPU drivers and tools
- Optional: Choose between KDE, Gnome, Xfce, and Cinnamon desktop environments
- Installs popular gaming software and utilities (Steam, Lutris, Wine, GE-Proton, Mangohud, vkbasalt, etc.)
- Optional: Pamac-all package manager installation
- Optional: Choose between Liquorix or Zen Kernel
- Configures system for optimal gaming performance

This script allows users to easily transform a fresh Arch Linux installation into a gaming-ready system with just a few interactive prompts. It's designed to be user-friendly while still offering customization options.

## Usage

### Using arch-auto-installer.sh

To use the `arch-auto-installer.sh` script, follow these steps:

1. Create an Arch Linux live USB stick and boot from it.
2. Once booted into the live environment, update the package databases:
   ```
   pacman -Sy
   ```
3. Install git:
   ```
   pacman -S git
   ```
4. Clone this repository:
   ```
   git clone https://github.com/Zerschranzer/arch-gaming-setup
   ```
5. Change to the repository directory:
   ```
   cd arch-gaming-setup
   ```
6. Make the script executable:
   ```
   chmod +x arch-auto-installer.sh
   ```
7. Run the script:
   ```
   ./arch-auto-installer.sh
   ```
8. Follow the on-screen prompts to complete the installation.

At the end of the installation process, you will be asked if you want to copy the `arch-gaming-setup.sh` script to your new user's home directory. If you choose to do so, you can easily run the gaming setup script after rebooting into your new Arch Linux system.

### Using arch-gaming-setup.sh

After you've installed Arch Linux using `arch-auto-installer.sh` and rebooted into your new system:

If you chose to copy the script during installation:
1. Log in to your new user account.
2. Run the script:
   ```
   ./arch-gaming-setup.sh
   ```

If you didn't copy the script or want to use the latest version:
1. Clone this repository:
   ```
   git clone https://github.com/Zerschranzer/arch-gaming-setup
   ```
2. Change to the repository directory:
   ```
   cd arch-gaming-setup
   ```
3. Make the script executable:
   ```
   chmod +x arch-gaming-setup.sh
   ```
4. Run the script:
   ```
   ./arch-gaming-setup.sh
   ```

5. Follow the on-screen prompts to configure your system for gaming.

## Warnings

- Always review scripts before running them, especially those that modify system partitions or require root privileges.
- The `arch-gaming-setup.sh` script should be run on a fresh Arch Linux installation.
- Use these scripts at your own risk. While they are designed to be safe and user-friendly, unforeseen issues can occur.

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Zerschranzer/arch-gaming-setup/issues).

## License

[MIT License](https://opensource.org/licenses/MIT)
