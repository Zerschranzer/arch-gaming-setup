#!/bin/bash

# Interactive Arch Linux Installation Script

# Function to select keyboard layout
select_keyboard_layout() {
    echo "Common keyboard layouts:"
    echo "1) US English (us)"
    echo "2) UK English (uk)"
    echo "3) German (de)"
    echo "4) French (fr)"
    echo "5) Spanish (es)"
    echo "6) Italian (it)"
    echo "7) Other (list all)"

    read -p "Please select a number (1-7): " layout_choice

    case $layout_choice in
        1) keyboard_layout="us" ;;
        2) keyboard_layout="uk" ;;
        3) keyboard_layout="de" ;;
        4) keyboard_layout="fr" ;;
        5) keyboard_layout="es" ;;
        6) keyboard_layout="it" ;;
        7)
            echo "Available keyboard layouts:"
            localectl list-keymaps
            read -p "Please enter the desired keyboard layout: " keyboard_layout
            ;;
        *)
            echo "Invalid choice. Defaulting to US English."
            keyboard_layout="us"
            ;;
    esac

    loadkeys $keyboard_layout
    echo "Keyboard layout set to $keyboard_layout."
}

# Function to select locale
select_locale() {
    echo "Common locales:"
    echo "1) en_US.UTF-8"
    echo "2) en_GB.UTF-8"
    echo "3) de_DE.UTF-8"
    echo "4) fr_FR.UTF-8"
    echo "5) es_ES.UTF-8"
    echo "6) it_IT.UTF-8"
    echo "7) Other (manual input)"

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
            echo "Invalid choice. Defaulting to en_US.UTF-8."
            user_locale="en_US.UTF-8"
            ;;
    esac

    echo "Selected locale: $user_locale"
}

# Function to select disk and partitioning method
select_disk() {
    # Get available disks
    available_disks=($(lsblk -dno name -e 7,11))

    while true; do
        echo "Available disks:"
        for i in "${!available_disks[@]}"; do
            echo "$((i+1))) ${available_disks[i]} ($(lsblk -dno size /dev/${available_disks[i]}))"
        done

        read -p "Please enter the number of the disk to be used to install Arch Linux: " disk_number

        if [[ "$disk_number" =~ ^[0-9]+$ ]] && [ "$disk_number" -ge 1 ] && [ "$disk_number" -le "${#available_disks[@]}" ]; then
            disk=${available_disks[$((disk_number-1))]}
            echo "You have selected /dev/$disk."
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    while true; do
        echo "1) Automatic partitioning (will erase all data on selected disk)"
        echo "2) Manual partitioning"
        read -p "Choose partitioning method (1/2): " part_method

        if [[ $part_method == "1" || $part_method == "2" ]]; then
            break
        else
            echo "Invalid selection. Please enter 1 or 2."
        fi
    done

    if [[ $part_method == "1" ]]; then
        echo "Automatic partitioning will erase all data on /dev/$disk."
    else
        echo "Manual partitioning selected. You will use cfdisk to partition the disk."
    fi

    while true; do
        read -p "Continue? (y/n): " confirm
        if [[ $confirm =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Invalid input. Please enter y or n."
        fi
    done

    if [[ $confirm =~ ^[Nn]$ ]]; then
        echo "Aborted."
        exit 1
    fi
}

# Function to automatically partition the disk
auto_partition() {
    local disk=$1
    local efi_size=512  # Size in MiB
    local swap_size=0   # Size in MiB, 0 means no swap

    echo "Do you want to create a swap partition?"
    echo "1) Yes"
    echo "2) No"
    read -p "Enter your choice (1/2): " swap_choice

    if [[ $swap_choice == "1" ]]; then
        read -p "Enter the size of swap partition in MiB: " swap_size
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

    echo "Disk $disk has been automatically partitioned:"
    echo "EFI System Partition: /dev/${efi_partition} (${efi_size} MiB)"
    if [[ $swap_size -gt 0 ]]; then
        echo "Swap Partition: /dev/${swap_partition} (${swap_size} MiB)"
    fi
    echo "Root Partition: /dev/${root_partition} (remaining space)"

    # Format partitions
    mkfs.fat -F32 /dev/${efi_partition}
    if [[ $swap_size -gt 0 ]]; then
        mkswap /dev/${swap_partition}
        swapon /dev/${swap_partition}
    fi
    mkfs.ext4 -F /dev/${root_partition}

    # Mount partitions
    mount /dev/${root_partition} /mnt
    mkdir /mnt/boot
    mount /dev/${efi_partition} /mnt/boot
}

# Function for manual partitioning
manual_partition() {
    local disk=$1

    echo "We will now proceed with manual partitioning using cfdisk."
    echo "Please create your desired partitions. Remember to create at least:"
    echo "1. An EFI System Partition (at least 500M, type: EFI System)"
    echo "2. A Root Partition (type: Linux filesystem)"
    echo "3. Optionally, a Home Partition (type: Linux filesystem)"
    echo "4. Optionally, a Swap Partition (type: Linux swap)"
    read -p "Press Enter to continue to cfdisk..."
    cfdisk /dev/$disk

    echo "Partitioning complete. Now we'll format the partitions."
    echo "Available partitions:"
    lsblk /dev/$disk

    # Function to format a partition
    format_partition() {
    local partition=$1
    echo "Select filesystem for /dev/$partition:"
    echo "1) ext4"
    echo "2) btrfs"
    echo "3) xfs"
    echo "4) f2fs"
    echo "5) FAT32 (for EFI partition)"
    echo "6) Swap"
    read -p "Enter your choice (1-6): " fs_choice

    case $fs_choice in
        1) mkfs.ext4 -F /dev/$partition && echo "Formatted /dev/$partition as ext4" ;;
        2) mkfs.btrfs -f /dev/$partition && echo "Formatted /dev/$partition as btrfs" ;;
        3) mkfs.xfs -f /dev/$partition && echo "Formatted /dev/$partition as xfs" ;;
        4) mkfs.f2fs -f /dev/$partition && echo "Formatted /dev/$partition as f2fs" ;;
        5) mkfs.fat -F32 /dev/$partition && echo "Formatted /dev/$partition as FAT32" ;;
        6) mkswap /dev/$partition && swapon /dev/$partition && echo "Formatted and enabled /dev/$partition as swap" ;;
        *) echo "Invalid choice. Partition not formatted." && return 1 ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Formatting successful."
    else
        echo "Error: Formatting failed. Please check the partition and try again."
        return 1
    fi
}

    # Format partitions
    while true; do
        read -p "Enter partition to format (e.g., ${disk}1), or 'done' when finished: " partition
        if [[ $partition == "done" ]]; then
            break
        elif [[ -e /dev/$partition ]]; then
            format_partition $partition
        else
            echo "Partition /dev/$partition does not exist."
        fi
    done

    # Mount partitions
    echo "Available partitions:"
    lsblk -f
    echo "Now we'll mount the partitions."
    
    while true; do
        read -p "Enter the root partition (e.g., ${disk}2): " root_partition
        if [[ -e /dev/$root_partition ]]; then
            if mount /dev/$root_partition /mnt; then
                echo "Root partition mounted successfully."
                break
            else
                echo "Failed to mount root partition. Please try again."
            fi
        else
            echo "Partition /dev/$root_partition does not exist."
        fi
    done

    while true; do
        read -p "Enter the EFI partition (e.g., ${disk}1): " efi_partition
        if [[ -e /dev/$efi_partition ]]; then
            mkdir -p /mnt/boot
            if mount /dev/$efi_partition /mnt/boot; then
                echo "EFI partition mounted successfully."
                break
            else
                echo "Failed to mount EFI partition. Please try again."
            fi
        else
            echo "Partition /dev/$efi_partition does not exist."
        fi
    done

    # Optionally mount home partition
    read -p "Enter the home partition (leave blank if none): " home_partition
    if [[ -n $home_partition ]]; then
        if [[ -e /dev/$home_partition ]]; then
            mkdir -p /mnt/home
            if mount /dev/$home_partition /mnt/home; then
                echo "Home partition mounted successfully."
            else
                echo "Failed to mount home partition."
            fi
        else
            echo "Partition /dev/$home_partition does not exist."
        fi
    fi

    # Optionally enable swap
    read -p "Enter the swap partition (leave blank if none): " swap_partition
    if [[ -n $swap_partition ]]; then
        if [[ -e /dev/$swap_partition ]]; then
            if swapon /dev/$swap_partition; then
                echo "Swap partition enabled successfully."
            else
                echo "Failed to enable swap partition."
            fi
        else
            echo "Partition /dev/$swap_partition does not exist."
        fi
    fi

    echo "Partitioning and mounting complete."
    echo "Current mount status:"
    lsblk -f
}

# Main script
echo "Welcome to the interactive Arch Linux installation script!"

# Update system clock
echo "Updating system clock..."
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
    manual_partition $disk
fi

# Install base package and Linux kernel
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Gather user input before chroot
echo "Please enter the following information:"
read -p "Desired hostname: " hostname
read -p "Desired username: " username
read -p "Desired time zone (e.g., Europe/London): " timezone

# Set passwords
echo "Setting up passwords:"
read -s -p "Enter root password: " root_password
echo
read -s -p "Confirm root password: " root_password_confirm
echo
if [[ "$root_password" != "$root_password_confirm" ]]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

read -s -p "Enter password for $username: " user_password
echo
read -s -p "Confirm password for $username: " user_password_confirm
echo
if [[ "$user_password" != "$user_password_confirm" ]]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

# Chroot and configure the system
echo "Configuring the system..."
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
pacman -S --noconfirm grub efibootmgr os-prober
echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install network manager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# Exit base system
exit
EOF

# Ask if the user wants to copy the gaming setup script
echo "Would you like to copy the arch-gaming-setup.sh script to the new user's home directory?"
read -p "This will allow you to easily run it after rebooting. (y/n): " copy_script

if [[ $copy_script =~ ^[Yy]$ ]]; then
    # Check if the source file exists
    if [ ! -f ./arch-gaming-setup.sh ]; then
        echo "Error: Source file ./arch-gaming-setup.sh not found in the current directory."
        echo "Please make sure you're running this script from the cloned 'arch-gaming-setup' directory."
    else
        # Copy the script to the new user's home directory
        if cp ./arch-gaming-setup.sh /mnt/home/$username/; then
            # Set the correct ownership
            arch-chroot /mnt chown $username:$username /home/$username/arch-gaming-setup.sh
            # Make the script executable
            arch-chroot /mnt chmod +x /home/$username/arch-gaming-setup.sh
            echo "The arch-gaming-setup.sh script has been successfully copied to /home/$username/"
            echo "After rebooting and logging in as $username, you can run it with: ./arch-gaming-setup.sh"
        else
            echo "Error: Failed to copy the script. Please check permissions and try again."
        fi
    fi
else
    echo "The script was not copied. You can still clone the repository and run it after rebooting if you want."
fi

# Clear sensitive variables
unset root_password root_password_confirm user_password user_password_confirm

# Unmount and reboot
umount -R /mnt
echo "Installation completed. System will now reboot."
read -p "Press Enter to reboot..."
reboot
