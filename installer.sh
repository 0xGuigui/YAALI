#!/bin/sh
"Arch Installer"
echo "==============="
echo "This script will install Arch Linux on your computer."
echo "It will erase all data on the disk."
echo "Press any key to continue."
read -n 1

# Set the keyboard layout
echo "\n==============="
echo "Setting the keyboard layout..."
echo "==============="
loadkeys fr
echo "Keyboard layout set to fr.\n"


# Connect to the internet
echo "==============="
echo "Connecting to the internet..."
echo "===============\n"
ping -c 3 archlinux.org > /dev/null
if [ $? -eq 0 ]; then
    echo "Connected to the internet."
else
    echo "Not connected to the internet."
    echo "Please connect to the internet and try again."
    exit 1
fi

# Update the system clock
echo "\n==============="
echo "Updating the system clock..."
echo "==============="
timedatectl set-ntp true
timedatectl status | grep "System clock synchronized: yes" > /dev/null
if [ $? -eq 0 ]; then
    echo "Clock is synchronized.\n"
else
    echo "Clock is not synchronized."
    echo "Please check your internet connection and try again."
    exit 1
fi

# Ask partition size
echo "==============="
echo "Enter the size of the partition in Mo:"
echo "===============\n"
echo "Size of boot partition (default 512): "
read boot_size
if [ $boot_size -lt 150 ]; then
    echo "Boot partition size must be at least 150 Mo."
    exit 1
fi
if [ -z $boot_size ]; then
    boot_size=512
fi
echo "Size of root partition (default 1024): "
read root_size
if [ $root_size -lt 1024 ]; then
    echo "Root partition size must be at least 1024 Mo."
    exit 1
fi
if [ -z $root_size ]; then
    root_size=1024
fi
echo "Size of swap partition (default 512): "
read swap_size
if [ $swap_size -lt 200 ]; then
    echo "Swap partition size must be at least 200 Mo."
    exit 1
fi
if [ -z $swap_size ]; then
    swap_size=512
fi
echo "Size of home partition (default 1024): "
read home_size
if [ $home_size -lt 1024 ]; then
    echo "Home partition size must be at least 1024 Mo."
    exit 1
fi
if [ -z $home_size ]; then
    home_size=1024
fi

# Partition the disks
echo "\n==============="
echo "Partitioning the disks..."
echo "==============="
fdisk /dev/sda <<EOF

n
p
1


w
EOF
if [ $? -eq 0 ]; then
    echo "Disk partitioned."
else
    echo "Disk partitioning failed."
    exit 1
fi
echo "Press any key to continue."
read -n 1

# Create the EFI System Partition
echo "\n==============="
echo "Creating the EFI System Partition..."
echo "==============="
pvcreate /dev/sda1
vgcreate vg1 /dev/sda1
lvcreate -L boot_size -n boot vg1
lvcreate -L root_size -n root vg1
lvcreate -L swap_size -n swap vg1
lvcreate -L home_size -n home vg1
echo "Press any key to continue."
read -n 1