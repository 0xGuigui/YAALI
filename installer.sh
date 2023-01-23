echo "Arch Installer"
echo "==============="
echo "This script will install Arch Linux on your computer."
echo "It will erase all data on the disk."
echo "Press any key to continue."
read -n 1

# Set the keyboard layout
echo "==============="
echo "Setting the keyboard layout..."
echo "==============="
loadkeys fr

# Connect to the internet
echo "==============="
echo "Connecting to the internet..."
echo "==============="
ping -c 3 archlinux.org

# Ask partition size
echo "==============="
echo "Enter the size of the partition in MB:"
echo "==============="
echo "Size of boot partition: "
read boot_size
echo "Size of root partition: "
read root_size
echo "Size of swap partition: "
read swap_size
echo "Size of home partition: "
read home_size

# Update the system clock
echo "==============="
echo "Updating the system clock..."
echo "==============="
timedatectl set-ntp true

# Partition the disks
echo "==============="
echo "Partitioning the disks..."
echo "==============="
fdisk /dev/sda <<EOF

n
p
1


w
EOF

# Create the EFI System Partition
echo "==============="
echo "Creating the EFI System Partition..."
echo "==============="
pvcreate /dev/sda1
vgcreate vg1 /dev/sda1
lvcreate -L 512M -n efi vg1
