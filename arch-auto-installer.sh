#!/bin/bash

# Interactive Arch Linux Installation Script

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${NC}"
}

# Function to select keyboard layout
select_keyboard_layout() {
    print_color "$YELLOW" "Common keyboard layouts:"
    print_color "$MAGENTA" "1) US English (us)"
    print_color "$MAGENTA" "2) UK English (uk)"
    print_color "$MAGENTA" "3) German (de)"
    print_color "$MAGENTA" "4) French (fr)"
    print_color "$MAGENTA" "5) Spanish (es)"
    print_color "$MAGENTA" "6) Italian (it)"
    print_color "$MAGENTA" "7) Other (list all)"
    
    read -p "Please select a number (1-7): " layout_choice
    
    case $layout_choice in
        1) keyboard_layout="us" ;;
        2) keyboard_layout="uk" ;;
        3) keyboard_layout="de" ;;
        4) keyboard_layout="fr" ;;
        5) keyboard_layout="es" ;;
        6) keyboard_layout="it" ;;
        7)
            print_color "$BLUE" "Available keyboard layouts:"
            localectl list-keymaps
            read -p "Please enter the desired keyboard layout: " keyboard_layout
            ;;
        *)
            print_color "$RED" "Invalid choice. Defaulting to US English."
            keyboard_layout="us"
            ;;
    esac
    
    loadkeys $keyboard_layout
    print_color "$GREEN" "Keyboard layout set to $keyboard_layout."
}

# Function to select locale
select_locale() {
    print_color "$YELLOW" "Common locales:"
    print_color "$MAGENTA" "1) en_US.UTF-8"
    print_color "$MAGENTA" "2) en_GB.UTF-8"
    print_color "$MAGENTA" "3) de_DE.UTF-8"
    print_color "$MAGENTA" "4) fr_FR.UTF-8"
    print_color "$MAGENTA" "5) es_ES.UTF-8"
    print_color "$MAGENTA" "6) it_IT.UTF-8"
    print_color "$MAGENTA" "7) Other (manual input)"
    
    read -p "Please select a number (1-7): " locale_choice
    
    case $locale_choice in
        1) user_locale="en_US.UTF-8" ;;
        2) user_locale="en_GB.UTF-8" ;;
        3) user_locale="de_DE.UTF-8" ;;
        4) user_locale="fr_FR.UTF-8" ;;
        5) user_locale="es_ES.UTF-8" ;;
        6) user_locale="it_IT.UTF-8" ;;
        7) 
            read -p "Please enter your desired locale (e.g., ja_JP.UTF-8): " user_locale
            ;;
        *)
            print_color "$RED" "Invalid choice. Defaulting to en_US.UTF-8."
            user_locale="en_US.UTF-8"
            ;;
    esac
    
    print_color "$GREEN" "Selected locale: $user_locale"
}

# Function to select disk and partitioning method
select_disk() {
    print_color "$YELLOW" "Available disks:"
    lsblk
    echo -e "${YELLOW}Please enter the device name of the disk to be used (e.g., sda):${NC} "
    read disk
    print_color "$BLUE" "You have selected /dev/$disk."
    print_color "$MAGENTA" "1) Automatic partitioning (will erase all data on selected disk)"
    print_color "$MAGENTA" "2) Manual partitioning"
    echo -e "${YELLOW}Choose partitioning method (1/2):${NC} "
    read part_method
    
    if [[ $part_method == "1" ]]; then
        print_color "$RED" "Automatic partitioning will erase all data on /dev/$disk."
    else
        print_color "$BLUE" "Manual partitioning selected. You will use cfdisk to partition the disk."
    fi
    
    echo -e "${YELLOW}Continue? (y/n):${NC} "
    read confirm
    if [[ $confirm != "y" ]]; then
        print_color "$RED" "Aborted."
        exit 1
    fi
}

# Function to automatically partition the disk
auto_partition() {
    local disk=$1
    local efi_size=512  # Size in MiB
    local swap_size=0   # Size in MiB, 0 means no swap
    
    print_color "$YELLOW" "Do you want to create a swap partition?"
    print_color "$MAGENTA" "1) Yes"
    print_color "$MAGENTA" "2) No"
    echo -e "${YELLOW}Enter your choice (1/2):${NC} "
    read swap_choice
    
    if [[ $swap_choice == "1" ]]; then
        echo -e "${YELLOW}Enter the size of swap partition in MiB:${NC} " 
        read swap_size
    fi
    
    # Calculate the remaining space for root partition (in sectors)
    local total_sectors=$(fdisk -l /dev/$disk | grep "$disk:" | awk '{print $7}')
    local efi_sectors=$((efi_size * 2048))  # Convert MiB to sectors (2048 sectors = 1 MiB)
    local swap_sectors=$((swap_size * 2048))
    local root_sectors=$((total_sectors - efi_sectors - swap_sectors))

    # Create partition table and partitions
    if [[ $swap_size -gt 0 ]]; then
        parted --script /dev/$disk \
            mklabel gpt \
            mkpart primary fat32 1MiB ${efi_size}MiB \
            set 1 esp on \
            mkpart primary linux-swap ${efi_size}MiB $((efi_size + swap_size))MiB \
            mkpart primary ext4 $((efi_size + swap_size))MiB 100%
    else
        parted --script /dev/$disk \
            mklabel gpt \
            mkpart primary fat32 1MiB ${efi_size}MiB \
            set 1 esp on \
            mkpart primary ext4 ${efi_size}MiB 100%
    fi

    # Set partition variables
    efi_partition="${disk}1"
    if [[ $swap_size -gt 0 ]]; then
        swap_partition="${disk}2"
        root_partition="${disk}3"
    else
        root_partition="${disk}2"
    fi

    print_color "$GREEN" "Disk $disk has been automatically partitioned:"
    print_color "$BLUE" "EFI System Partition: /dev/${efi_partition} (${efi_size} MiB)"
    if [[ $swap_size -gt 0 ]]; then
        print_color "$BLUE" "Swap Partition: /dev/${swap_partition} (${swap_size} MiB)"
    fi
    print_color "$BLUE" "Root Partition: /dev/${root_partition} (remaining space)"

    # Format partitions
    mkfs.fat -F32 /dev/${efi_partition}
    if [[ $swap_size -gt 0 ]]; then
        mkswap /dev/${swap_partition}
        swapon /dev/${swap_partition}
    fi
    mkfs.ext4 /dev/${root_partition}

    # Mount partitions
    mount /dev/${root_partition} /mnt
    mkdir /mnt/boot
    mount /dev/${efi_partition} /mnt/boot
}

# Function to select filesystem
select_filesystem() {
    print_color "$YELLOW" "Select filesystem for the root partition:"
    print_color "$MAGENTA" "1) ext4 (default)"
    print_color "$MAGENTA" "2) btrfs"
    print_color "$MAGENTA" "3) xfs"
    print_color "$MAGENTA" "4) f2fs"
    
    echo -e "${YELLOW}Please select a number (1-4):${NC} " 
    read fs_choice
    
    case $fs_choice in
        1) filesystem="ext4" ;;
        2) filesystem="btrfs" ;;
        3) filesystem="xfs" ;;
        4) filesystem="f2fs" ;;
        *)
            print_color "$RED" "Invalid choice. Defaulting to ext4."
            filesystem="ext4"
            ;;
    esac
    
    print_color "$GREEN" "Selected filesystem: $filesystem"
}

# Main script
print_color "$CYAN" "Welcome to the interactive Arch Linux installation script!"

# Update system clock
print_color "$BLUE" "Updating system clock..."
timedatectl set-ntp true

# Select keyboard layout
select_keyboard_layout

# Select locale
select_locale

# Select disk and partitioning method
select_disk

# Partitioning
if [[ $part_method == "1" ]]; then
    auto_partition $disk
else
    print_color "$YELLOW" "We will now proceed with manual partitioning."
    print_color "$BLUE" "It is recommended to create at least two partitions:"
    print_color "$BLUE" "1. An EFI System Partition (at least 500M)"
    print_color "$BLUE" "2. A Root Partition (rest of the disk)"
    read -p "Press Enter to continue..."
    cfdisk /dev/$disk

    # Format partitions
    print_color "$YELLOW" "Please enter the partition numbers:"
    read -p "EFI System Partition (e.g., 1 for ${disk}1): " efi_partition
    read -p "Root Partition (e.g., 2 for ${disk}2): " root_partition

    # Select filesystem for root partition
    select_filesystem

    print_color "$BLUE" "Formatting partitions..."
    mkfs.fat -F32 /dev/${disk}${efi_partition}

    # Format root partition with selected filesystem
    case $filesystem in
        ext4)
            mkfs.ext4 /dev/${disk}${root_partition}
            ;;
        btrfs)
            mkfs.btrfs /dev/${disk}${root_partition}
            ;;
        xfs)
            mkfs.xfs /dev/${disk}${root_partition}
            ;;
        f2fs)
            mkfs.f2fs /dev/${disk}${root_partition}
            ;;
    esac

    # Mount partitions
    print_color "$BLUE" "Mounting partitions..."
    mount /dev/${disk}${root_partition} /mnt
    mkdir /mnt/boot
    mount /dev/${disk}${efi_partition} /mnt/boot
fi

# Install base package and Linux kernel
print_color "$CYAN" "Installing base system..."
pacstrap /mnt base linux linux-firmware

# If btrfs was selected, install btrfs-progs
if [ "$filesystem" == "btrfs" ]; then
    print_color "$BLUE" "Installing btrfs-progs..."
    pacstrap /mnt btrfs-progs
fi

# Generate fstab
print_color "$BLUE" "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Gather user input before chroot
print_color "$YELLOW" "Please enter the following information:"
read -p "Desired hostname: " hostname
read -p "Desired username: " username
read -p "Desired time zone (e.g., Europe/London): " timezone

# Set passwords
print_color "$YELLOW" "Setting up passwords:"
read -s -p "Enter root password: " root_password
echo
read -s -p "Confirm root password: " root_password_confirm
echo
if [[ "$root_password" != "$root_password_confirm" ]]; then
    print_color "$RED" "Passwords do not match. Exiting."
    exit 1
fi

read -s -p "Enter password for $username: " user_password
echo
read -s -p "Confirm password for $username: " user_password_confirm
echo
if [[ "$user_password" != "$user_password_confirm" ]]; then
    print_color "$RED" "Passwords do not match. Exiting."
    exit 1
fi

# Chroot and configure the system
print_color "$CYAN" "Configuring the system..."
arch-chroot /mnt /bin/bash << EOF
# Set time zone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Localization
echo "$user_locale UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$user_locale" > /etc/locale.conf

# Set keyboard layout for the new installation
echo "KEYMAP=$keyboard_layout" > /etc/vconsole.conf
echo "XKBLAYOUT=$keyboard_layout" >> /etc/vconsole.conf

# Network configuration
echo $hostname > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

# Set root password
echo "root:$root_password" | chpasswd

# Create user and set password
useradd -m -G wheel -s /bin/bash $username
echo "$username:$user_password" | chpasswd

# Install sudo and add user to sudoers
pacman -S --noconfirm sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install bootloader (GRUB for UEFI)
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install network manager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# Exit base system
exit
EOF

# Ask if the user wants to copy the gaming setup script
print_color "$YELLOW" "Would you like to copy the arch-gaming-setup.sh script to the new user's home directory?"
read -p "This will allow you to easily run it after rebooting. (y/n): " copy_script

if [[ $copy_script == "y" || $copy_script == "Y" ]]; then
    # Copy the script to the new user's home directory
    cp /root/arch-gaming-setup/arch-gaming-setup.sh /mnt/home/$username/
    # Set the correct ownership
    arch-chroot /mnt chown $username:$username /home/$username/arch-gaming-setup.sh
    # Make the script executable
    arch-chroot /mnt chmod +x /home/$username/arch-gaming-setup.sh
    print_color "$GREEN" "The arch-gaming-setup.sh script has been copied to /home/$username/"
    print_color "$BLUE" "After rebooting, you can run it with: ./arch-gaming-setup.sh"
else
    print_color "$BLUE" "The script was not copied. You can still clone the repository and run it after rebooting if you want."
fi

# Clear sensitive variables
unset root_password root_password_confirm user_password user_password_confirm

# Unmount and reboot
umount -R /mnt
print_color "$GREEN" "Installation completed. System will now reboot."
read -p "Press Enter to reboot..."
reboot
