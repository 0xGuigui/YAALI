#!/bin/sh
echo -e 'Arch Installer'
echo -e '==============='
echo -e 'This script will install Arch Linux on your computer.'
echo -e 'It will erase all data on the disk.'
echo -e 'Press any key to continue.'
read -n 1

# Set the keyboard layout
echo -e '\n==============='
echo -e 'Setting the keyboard layout...'
echo -e '==============='
loadkeys fr
echo -e 'Keyboard layout set to fr.\n'


# Connect to the internet
echo -e '==============='
echo -e 'Connecting to the internet...'
echo -e '===============\n'
ping -c 3 archlinux.org > /dev/null
if [ $? -eq 0 ]; then
    echo -e 'Connected to the internet.'
else
    echo -e 'Not connected to the internet.'
    echo -e 'Please connect to the internet and try again.'
    exit 1
fi

# Update the system clock
echo -e '\n==============='
echo -e 'Updating the system clock...'
echo -e '==============='
timedatectl set-ntp true
timedatectl status | grep 'System clock synchronized: yes' > /dev/null
if [ $? -eq 0 ]; then
    echo -e 'Clock is synchronized.\n'
else
    echo -e 'Clock is not synchronized.'
    echo -e 'Please check your internet connection and try again.'
    exit 1
fi

# Ask partition size
echo -e '==============='
echo -e 'Enter the size of the partition in Mo:'
echo -e '===============\n'
echo -e 'Size of boot partition (default 512): '
read boot_size
if [ $boot_size -lt 150 ]; then
    echo -e 'Boot partition size must be at least 150 Mo.'
    exit 1
fi
if [ -z $boot_size ]; then
    boot_size=512
fi
echo -e 'Size of root partition (default 1024): '
read root_size
if [ $root_size -lt 1024 ]; then
    echo -e 'Root partition size must be at least 1024 Mo.'
    exit 1
fi
if [ -z $root_size ]; then
    root_size=1024
fi
echo -e 'Size of swap partition (default 512): '
read swap_size
if [ $swap_size -lt 200 ]; then
    echo -e 'Swap partition size must be at least 200 Mo.'
    exit 1
fi
if [ -z $swap_size ]; then
    swap_size=512
fi
echo -e 'Size of home partition (default 1024): '
read home_size
if [ $home_size -lt 1024 ]; then
    echo -e 'Home partition size must be at least 1024 Mo.'
    exit 1
fi
if [ -z $home_size ]; then
    home_size=1024
fi

# Partition the disks
echo -e '\n==============='
echo -e 'Partitioning the disks...'
echo -e '==============='
fdisk /dev/sda <<EOF

n
p
1


w
EOF
if [ $? -eq 0 ]; then
    echo -e 'Disk partitioned.'
else
    echo -e 'Disk partitioning failed.'
    exit 1
fi
echo -e 'Press any key to continue.'
read -n 1

# Create the EFI System Partition
echo -e '\n==============='
echo -e 'Creating the EFI System Partition...'
echo -e '==============='
pvcreate /dev/sda1
vgcreate vg1 /dev/sda1
lvcreate -L "$boot_size"M -n boot vg1
lvcreate -L "$root_size"M -n root vg1
lvcreate -L "$swap_size"M -n swap vg1
lvcreate -L "$home_size"M -n home vg1
echo -e 'Press any key to continue.'
read -n 1

# Format the partitions
echo -e "\n==============="
echo -e "Formatting the partitions..."
echo -e "==============="
mkfs.ext4 /dev/vg1/boot
mkfs.ext4 /dev/vg1/root
mkfs.ext4 /dev/vg1/home
mkswap /dev/vg1/swap
swapon /dev/vg1/swap
echo -e "Press any key to continue."
read -n 1

# Mount the file systems
echo -e "\n==============="
echo -e "Mounting the file systems..."
echo -e "==============="
mount /dev/vg1/root /mnt
mkdir /mnt/boot
mount /dev/vg1/boot /mnt/boot
mkdir /mnt/home
mount /dev/vg1/home /mnt/home
echo -e "Press any key to continue."
read -n 1

# Install essential packages
echo -e "\n==============="
echo -e "Installing essential packages..."
echo -e "==============="
pacstrap /mnt base base-devel
echo -e "Press any key to continue."
read -n 1

# Generate an fstab file
echo -e "\n==============="
echo -e "Generating an fstab file..."
echo -e "==============="
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "Press any key to continue."
read -n 1

# Chroot
echo "\n==============="
echo "Chrooting..."
echo "==============="
arch-chroot /mnt /bin/bash <<EOF
echo "Arch Linux" > /etc/hostname
echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc --utc
mkinitcpio -p linux
passwd
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S networkmanager
systemctl enable NetworkManager
pacman -S xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset
pacman -S xf86-video-intel
pacman -S i3-gaps i3status i3lock i3blocks
pacman -S dmenu
pacman -S rxvt-unicode
pacman -S firefox
pacman -S alsa-utils pulseaudio pulseaudio-alsa
pacman -S pavucontrol
pacman -S feh
pacman -S scrot
pacman -S rofi
EOF

# Reboot
echo "\n==============="
echo "Installation finished."
echo "==============="
echo "Press any key to reboot."
read -n 1
reboot


# By the way, I'm French so I'm sorry for my English mistakes.
# By Guigui1901