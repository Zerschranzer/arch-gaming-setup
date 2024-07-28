#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect disks and partitions
detect_disks() {
    echo -e "${YELLOW}Detected disks and partitions:${NC}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
}

# Function to start cfdisk
run_cfdisk() {
    echo -e "${YELLOW}Available disks:${NC}"
    disks=($(lsblk -ndo NAME,TYPE | awk '$2 == "disk" {print $1}'))

    for i in "${!disks[@]}"; do
        echo "$((i+1))) ${disks[i]} ($(lsblk -ndo SIZE /dev/${disks[i]}))"
    done

    while true; do
        read -p "Select the number of the disk to partition: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#disks[@]}" ]; then
            disk=${disks[$((choice-1))]}
            cfdisk /dev/"$disk"
            break
        else
            echo -e "${RED}Invalid selection. Please choose a number between 1 and ${#disks[@]}.${NC}"
        fi
    done
}

# Function to format a partition
format_partition() {
    echo -e "${YELLOW}Available partitions:${NC}"
    partitions=($(lsblk -nlo NAME,TYPE | awk '$2 == "part" {print $1}'))

    if [ ${#partitions[@]} -eq 0 ]; then
        echo -e "${RED}No partitions found. Please create partitions first.${NC}"
        return
    fi

    for i in "${!partitions[@]}"; do
        echo "$((i+1))) ${partitions[i]} ($(lsblk -nlo SIZE /dev/${partitions[i]}))"
    done

    while true; do
        read -p "Select the number of the partition to format: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#partitions[@]}" ]; then
            partition=${partitions[$((choice-1))]}
            break
        else
            echo -e "${RED}Invalid selection. Please choose a number between 1 and ${#partitions[@]}.${NC}"
        fi
    done

    echo -e "${YELLOW}Choose the filesystem for /dev/$partition:${NC}"
    filesystems=("ext4" "ext3" "ext2" "btrfs" "xfs" "f2fs" "reiserfs" "jfs" "fat32" "exfat" "ntfs")

    for i in "${!filesystems[@]}"; do
        echo "$((i+1))) ${filesystems[i]}"
    done

    while true; do
        read -p "Your choice (1-${#filesystems[@]}): " fs_choice
        if [[ "$fs_choice" =~ ^[0-9]+$ ]] && [ "$fs_choice" -ge 1 ] && [ "$fs_choice" -le "${#filesystems[@]}" ]; then
            filesystem=${filesystems[$((fs_choice-1))]}
            break
        else
            echo -e "${RED}Invalid selection. Please choose a number between 1 and ${#filesystems[@]}.${NC}"
        fi
    done

    case $filesystem in
        "ext4") mkfs.ext4 /dev/"$partition" ;;
        "ext3") mkfs.ext3 /dev/"$partition" ;;
        "ext2") mkfs.ext2 /dev/"$partition" ;;
        "btrfs") mkfs.btrfs /dev/"$partition" ;;
        "xfs") mkfs.xfs /dev/"$partition" ;;
        "f2fs") mkfs.f2fs /dev/"$partition" ;;
        "reiserfs") mkfs.reiserfs /dev/"$partition" ;;
        "jfs") mkfs.jfs /dev/"$partition" ;;
        "fat32") mkfs.fat -F32 /dev/"$partition" ;;
        "exfat") mkfs.exfat /dev/"$partition" ;;
        "ntfs")
            if ! command -v mkfs.ntfs &> /dev/null; then
                echo -e "${YELLOW}NTFS-3G is not installed. Installing it now...${NC}"
                sudo pacman -S --noconfirm ntfs-3g
            fi
            mkfs.ntfs /dev/"$partition"
            ;;
        *) echo -e "${RED}Unknown filesystem. Formatting aborted.${NC}"; return ;;
    esac

    echo -e "${GREEN}Partition /dev/$partition has been formatted with $filesystem.${NC}"
}

# Function to mount a partition
mount_partition() {
    echo -e "${YELLOW}Available partitions:${NC}"
    partitions=($(lsblk -nlo NAME,TYPE | awk '$2 == "part" {print $1}'))

    for i in "${!partitions[@]}"; do
        echo "$((i+1))) ${partitions[i]} ($(lsblk -nlo SIZE,FSTYPE,MOUNTPOINT /dev/${partitions[i]}))"
    done

    while true; do
        read -p "Select the number of the partition to mount: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#partitions[@]}" ]; then
            partition=${partitions[$((choice-1))]}
            break
        else
            echo -e "${RED}Invalid selection. Please choose a number between 1 and ${#partitions[@]}.${NC}"
        fi
    done

    read -p "Enter the mount point (e.g., /mnt for root, /mnt/boot/efi for EFI): " mountpoint
    mkdir -p "$mountpoint"
    if mount /dev/"$partition" "$mountpoint"; then
        echo -e "${GREEN}Partition /dev/$partition has been mounted at $mountpoint.${NC}"
    else
        echo -e "${RED}Error mounting /dev/$partition at $mountpoint.${NC}"
    fi
}

# Function to create and activate swap
create_swap() {
    echo -e "${YELLOW}Available partitions:${NC}"
    partitions=($(lsblk -nlo NAME,TYPE | awk '$2 == "part" {print $1}'))

    for i in "${!partitions[@]}"; do
        echo "$((i+1))) ${partitions[i]} ($(lsblk -nlo SIZE,FSTYPE,MOUNTPOINT /dev/${partitions[i]}))"
    done

    while true; do
        read -p "Select the number of the swap partition (or 0 to cancel): " choice
        if [ "$choice" -eq 0 ]; then
            echo -e "${YELLOW}Swap creation cancelled.${NC}"
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#partitions[@]}" ]; then
            swap_partition=${partitions[$((choice-1))]}
            break
        else
            echo -e "${RED}Invalid selection. Please choose a number between 0 and ${#partitions[@]}.${NC}"
        fi
    done

    mkswap /dev/"$swap_partition"
    swapon /dev/"$swap_partition"
    echo -e "${GREEN}Swap on /dev/$swap_partition has been created and activated.${NC}"
}

# Main menu
while true; do
    echo -e "\n${YELLOW}Arch Linux Disk Preparation${NC}"
    echo "1) Show disks and partitions"
    echo "2) Start cfdisk (partitioning)"
    echo "3) Format a partition"
    echo "4) Mount a partition"
    echo "5) Create and activate swap"
    echo "6) Exit"

    read -p "Choose an option (1-6): " choice

    case $choice in
        1) detect_disks ;;
        2) run_cfdisk ;;
        3) format_partition ;;
        4) mount_partition ;;
        5) create_swap ;;
        6) echo -e "${GREEN}Disk preparation completed. You can now proceed with the Arch installation.${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please choose 1-6.${NC}" ;;
    esac

    echo "Press Enter to continue..."
    read
done
