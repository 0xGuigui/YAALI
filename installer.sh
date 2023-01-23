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
if [ $? -eq 0 ]; then
    echo -e '\033[32mKeyboard layout set.\033[0m\n'
else
    echo -e '\033[31mKeyboard layout setting failed.\033[0m\n'
    exit 1
fi


# Connect to the internet
echo -e '==============='
echo -e 'Connecting to the internet...'
echo -e '==============='
ping -c 3 archlinux.org > /dev/null
if [ $? -eq 0 ]; then
    echo -e '\033[32mConnected to the internet.\033[0m\n'
else
    echo -e '\033[31mConnection to the internet failed.\033[0m\n'
    echo -e '\033[31mPlease check your internet connection and try again.\033[0m\n'
    exit 1
fi

# Update the system clock
echo -e '\n==============='
echo -e 'Updating the system clock...'
echo -e '==============='
timedatectl set-ntp true
timedatectl status | grep 'System clock synchronized: yes' > /dev/null
if [ $? -eq 0 ]; then
    echo -e '\033[32mClock is synchronized.\033[0m\n'
else
    echo -e '\033[31mClock synchronization failed.\033[0m\n'
    echo -e '\033[31mPlease check your internet connection and try again.\033[0m\n'
    exit 1
fi

# Ask partition size
echo -e '==============='
echo -e 'Enter the size of the partition in Mo:'
echo -e '===============\n'
echo -e 'Size of boot partition (default 512): '
read boot_size
if [ $boot_size -lt 150 ]; then
    echo -e '\033[31mBoot partition size must be at least 150 Mo.\033[0m\n'
    exit 1
fi
if [ -z $boot_size ]; then
    boot_size=512
fi
echo -e 'Size of root partition (default 1024): '
read root_size
if [ $root_size -lt 1024 ]; then
    echo -e '\033[31mRoot partition size must be at least 1024 Mo.\033[0m\n'
    exit 1
fi
if [ -z $root_size ]; then
    root_size=1024
fi
echo -e 'Size of swap partition (default 512): '
read swap_size
if [ $swap_size -lt 200 ]; then
    echo -e '\033[31mSwap partition size must be at least 200 Mo.\033[0m\n'
    exit 1
fi
if [ -z $swap_size ]; then
    swap_size=512
fi
echo -e 'Size of home partition (default 1024): '
read home_size
if [ $home_size -lt 1024 ]; then
    echo -e '\033[31mHome partition size must be at least 1024 Mo.\033[0m\n'
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
    echo -e '\033[32mDisk partitioned.\033[0m\n'
else
    echo -e '\033[31mDisk partitioning failed.\033[0m\n'
    exit 1
fi

# Create the EFI System Partition
echo -e '\n==============='
echo -e 'Creating the EFI System Partition...'
echo -e '==============='
pvcreate /dev/sda1
if [ $? -eq 0 ]; then
    echo -e '\033[32mLVM Partition created.\033[0m\n'
else
    echo -e '\033[31mLVM Partition creation failed.\033[0m\n'
    exit 1
fi
vgcreate vg1 /dev/sda1
if [ $? -eq 0 ]; then
    echo -e '\033[32mVolume group created.\033[0m\n'
else
    echo -e '\033[31mVolume group creation failed.\033[0m\n'
    exit 1
fi
lvcreate -L "$boot_size"M -n boot vg1
if [ $? -eq 0 ]; then
    echo -e '\033[32mBoot Partition created.\033[0m\n'
else
    echo -e '\033[31mBoot Partition creation failed.\033[0m\n'
    exit 1
fi
lvcreate -L "$root_size"M -n root vg1
if [ $? -eq 0 ]; then
    echo -e '\033[32mRoot Partition created.\033[0m\n'
else
    echo -e '\033[31mRoot Partition creation failed.\033[0m\n'
    exit 1
fi
lvcreate -L "$swap_size"M -n swap vg1
if [ $? -eq 0 ]; then
    echo -e '\033[32mSwap Partition created.\033[0m\n'
else
    echo -e '\033[31mSwap Partition creation failed.\033[0m\n'
    exit 1
fi
lvcreate -L "$home_size"M -n home vg1
if [ $? -eq 0 ]; then
    echo -e '\033[32mHome Partition created.\033[0m\n'
else
    echo -e '\033[31mHome Partition creation failed.\033[0m\n'
    exit 1
fi

# Format the partitions
echo -e '\n==============='
echo -e 'Formatting the partitions...'
echo -e '==============='
mkfs.ext4 /dev/vg1/boot
if [ $? -eq 0 ]; then
    echo -e '\033[32mBoot partition formatted.\033[0m\n'
else
    echo -e '\033[31mBoot partition formatting failed.\033[0m\n'
    exit 1
fi
mkfs.ext4 /dev/vg1/root
if [ $? -eq 0 ]; then
    echo -e '\033[32mRoot partition formatted.\033[0m\n'
else
    echo -e '\033[31mRoot partition formatting failed.\033[0m\n'
    exit 1
fi
mkfs.ext4 /dev/vg1/home
if [ $? -eq 0 ]; then
    echo -e '\033[32mHome partition formatted.\033[0m\n'
else
    echo -e '\033[31mHome partition formatting failed.\033[0m\n'
    exit 1
fi
mkswap /dev/vg1/swap
if [ $? -eq 0 ]; then
    echo -e '\033[32mSwap partition formatted.\033[0m\n'
else
    echo -e '\033[31mSwap partition formatting failed.\033[0m\n'
    exit 1
fi
swapon /dev/vg1/swap
if [ $? -eq 0 ]; then
    echo -e '\033[32mSwap partition activated.\033[0m\n'
else
    echo -e '\033[31mSwap partition activation failed.\033[0m\n'
    exit 1
fi


# Mount the file systems
echo -e '\n==============='
echo -e 'Mounting the file systems...'
echo -e '==============='
mount /dev/vg1/root /mnt
if [ $? -eq 0 ]; then
    echo -e '\033[32mFile root systems mounted.\033[0m\n'
else
    echo -e '\033[31mFile root systems mounting failed.\033[0m\n'
    exit 1
fi
mkdir /mnt/boot
if [ $? -eq 0 ]; then
    echo -e '\033[32mFile boot systems mounted.\033[0m\n'
else
    echo -e '\033[31mFile boot systems creating failed.\033[0m\n'
    exit 1
fi
mount /dev/vg1/boot /mnt/boot
if [ $? -eq 0 ]; then
    echo -e '\033[32mFile boot systems created.\033[0m\n'
else
    echo -e '\033[31mFile boot systems mounting failed.\033[0m\n'
    exit 1
fi
mkdir /mnt/home
if [ $? -eq 0 ]; then
    echo -e '\033[32mFile home systems created.\033[0m\n'
else
    echo -e '\033[31mFile home systems creating failed.\033[0m\n'
    exit 1
fi
mount /dev/vg1/home /mnt/home
if [ $? -eq 0 ]; then
    echo -e '\033[32mFile home systems mounted.\033[0m\n'
else
    echo -e '\033[31mFile home systems mounting failed.\033[0m\n'
    exit 1
fi

# Install essential packages
echo -e '\n==============='
echo -e 'Installing essential packages...'
echo -e '==============='
pacstrap /mnt base base-devel
if [ $? -eq 0 ]; then
    echo -e '\033[32mEssential packages installed.\033[0m\n'
else
    echo -e '\033[31mEssential packages installation failed.\033[0m\n'
    exit 1
fi

# Generate an fstab file
echo -e '\n==============='
echo -e 'Generating an fstab file...'
echo -e '==============='
genfstab -U /mnt >> /mnt/etc/fstab
if [ $? -eq 0 ]; then
    echo -e '\033[32mFstab file generated.\033[0m\n'
else
    echo -e '\033[31mFstab file generation failed.\033[0m\n'
    exit 1
fi

# Chroot
echo -e '\n==============='
echo -e 'Chrooting...'
echo -e '==============='
arch-chroot /mnt /bin/bash <<EOF
echo -e 'ArchLinux' > /etc/hostname
echo -e 'fr_FR.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
echo -e 'LANG=fr_FR.UTF-8' > /etc/locale.conf
echo -e 'KEYMAP=fr' > /etc/vconsole.conf
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
pacman -S ttf-dejavu
pacman -S ttf-liberation
pacman -S ttf-ubuntu-font-family
EOF
if [ $? -eq 0 ]; then
    echo -e '\033[32mChrooted.\033[0m\n'
else
    echo -e '\033[31mChrooting failed.\033[0m\n'
    exit 1
fi

# Reboot
echo -e '\n==============='
echo -e 'Installation finished.'
echo -e '==============='
echo -e 'Press any key to reboot.'
read -n 1
reboot


# By the way, I'm French so I'm sorry for my English mistakes.
# By Guigui1901