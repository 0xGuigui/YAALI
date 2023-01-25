#!/bin/bash
clear
echo -e "\033[34m██╗░░░██╗░█████╗░░█████╗░██╗░░░░░██╗"
echo -e "╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██║"
echo -e "░╚████╔╝░███████║███████║██║░░░░░██║"
echo -e "░░╚██╔╝░░██╔══██║██╔══██║██║░░░░░██║"
echo -e "░░░██║░░░██║░░██║██║░░██║███████╗██║"
echo -e "░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝ v0.15b\033[0m"
echo -e '==============='
echo -e 'This script will install Arch Linux on your computer.'
echo -e 'It will erase all data on the disk.'
echo -e 'Press any key to continue.'
read -n 1

# Check if the script is runned on Arch Linux
echo -e '\n==============='
echo -e 'Checking if the script is runned on Arch Linux...'
echo -e '==============='
if [ -f /etc/arch-release ]; then
    echo -e '\033[32mThe script is runned on Arch Linux.\033[0m\n'
else
    echo -e '\033[31mThe script is not runned on Arch Linux.\033[0m\n'
    echo -e '\033[31mPlease run the script on Arch Linux.\033[0m\n'
    exit 1
fi

# Set the keyboard layout
echo -e '\n==============='
echo -e 'Setting the keyboard layout...'
echo -e '==============='
echo -e 'Keyboard layout (default fr): '
read keyboard_layout
if [[ -z $keyboard_layout ]]; then
    keyboard_layout=fr
fi
loadkeys $keyboard_layout
if [ $? -eq 0 ]; then
    echo -e '\033[32mKeyboard layout set to $keyboard_layout.\033[0m\n'
else
    echo -e '\033[31mFailed to set the keyboard layout.\033[0m\n'
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

# Formatting the disks to remove all data and all partitions
echo -e '==============='
echo -e 'Removing partitions from sda...'
echo -e '==============='
for i in $(ls /dev/sda*); do
    if [ "$i" != "/dev/sda" ]; then
        echo -e "Removing partition $i ..."
        sgdisk --zap-all $i
        if [ $? -ne 0 ]; then
            echo -e '\033[31mFailed to remove partition $i.\033[0m\n'
            exit 1
        fi
    fi
done
echo -e '\033[32mSuccessfully removed all partitions from sda.\033[0m\n'


# Get user infos
echo -e '\n==============='
echo -e 'Enter your user informations:'
echo -e '===============\n'
echo -e 'Username: '
read username
if [ -z $username ]; then
    echo -e '\033[31mUsername cannot be empty.\033[0m\n'
    exit 1
fi
echo -e 'Password: '
read -s password
if [ -z $password ]; then
    echo -e '\033[31mPassword cannot be empty.\033[0m\n'
    exit 1
fi
echo -e 'Hostname: '
read hostname
if [ -z $hostname ]; then
    echo -e '\033[31mHostname cannot be empty.\033[0m\n'
    exit 1
fi

# Ask partition size
echo -e '==============='
echo -e 'Enter the size of the partition in MO:'
echo -e '===============\n'
echo -e 'Size of boot partition (default 512): '
read boot_size
if [[ $boot_size -lt 150 ]]; then
    echo -e '\033[31mBoot partition size must be at least 150 MO.\033[0m\n'
    exit 1
fi
if [[ -z $boot_size ]]; then
    boot_size=512
fi
if [[ ! $boot_size =~ ^[0-9]+$ ]]; then
    echo -e '\033[31mBoot partition size must be a number.\033[0m\n'
    exit 1
fi
echo -e 'Size of root partition (default 1024): '
read root_size
if [[ $root_size -lt 1024 ]]; then
    echo -e '\033[31mRoot partition size must be at least 1024 MO.\033[0m\n'
    exit 1
fi
if [[ -z $root_size ]]; then
    root_size=1024
fi
if [[ ! $root_size =~ ^[0-9]+$ ]]; then
    echo -e '\033[31mRoot partition size must be a number.\033[0m\n'
    exit 1
fi
echo -e 'Size of swap partition (default 512): '
read swap_size
if [[ $swap_size -lt 200 ]]; then
    echo -e '\033[31mSwap partition size must be at least 200 MO.\033[0m\n'
    exit 1
fi
if [[ -z $swap_size ]]; then
    swap_size=512
fi
if [[ ! $swap_size =~ ^[0-9]+$ ]]; then
    echo -e '\033[31mSwap partition size must be a number.\033[0m\n'
    exit 1
fi
echo -e 'Size of home partition (default 1024): '
read home_size
if [[ $home_size -lt 1024 ]]; then
    echo -e '\033[31mHome partition size must be at least 1024 MO.\033[0m\n'
    exit 1
fi
if [[ -z $home_size ]]; then
    home_size=1024
fi
if [[ ! $home_size =~ ^[0-9]+$ ]]; then
    echo -e '\033[31mHome partition size must be a number.\033[0m\n'
    exit 1
fi

# Partition the disks
echo -e '\n==============='
echo -e 'Partitioning the disks...'
echo -e '==============='
fdisk /dev/sda <<EOF
n
p
1


t
8e
i
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
echo -e "$hostname" > /etc/hostname
if [ $? -eq 0 ]; then
    echo -e '\033[32mHostname set.\033[0m\n'
else
    echo -e '\033[31mHostname setting failed.\033[0m\n'
    exit 1
fi
echo -e 'fr_FR.UTF-8 UTF-8' > /etc/locale.gen
if [ $? -eq 0 ]; then
    echo -e '\033[32mLocale generated.\033[0m\n'
else
    echo -e '\033[31mLocale generation failed.\033[0m\n'
    exit 1
fi
locale-gen
if [ $? -eq 0 ]; then
    echo -e '\033[32mLocale generated.\033[0m\n'
else
    echo -e '\033[31mLocale generation failed.\033[0m\n'
    exit 1
fi
echo -e 'LANG=fr_FR.UTF-8' > /etc/locale.conf
if [ $? -eq 0 ]; then
    echo -e '\033[32mLocale set.\033[0m\n'
else
    echo -e '\033[31mLocale setting failed.\033[0m\n'
    exit 1
fi
echo -e 'KEYMAP=fr' > /etc/vconsole.conf
if [ $? -eq 0 ]; then
    echo -e '\033[32mKeymap set.\033[0m\n'
else
    echo -e '\033[31mKeymap setting failed.\033[0m\n'
    exit 1
fi
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
if [ $? -eq 0 ]; then
    echo -e '\033[32mTimezone set.\033[0m\n'
else
    echo -e '\033[31mTimezone setting failed.\033[0m\n'
    exit 1
fi
hwclock --systohc --utc
if [ $? -eq 0 ]; then
    echo -e '\033[32mHardware clock set.\033[0m\n'
else
    echo -e '\033[31mHardware clock setting failed.\033[0m\n'
    exit 1
fi
pacman -S --noconfirm xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset xf86-video-intel i3-gaps i3status i3lock i3blocks dmenu rxvt-unicode firefox alsa-utils pulseaudio pulseaudio-alsa pavucontrol feh scrot rofi ttf-dejavu ttf-liberation ttf-ubuntu-font-family lvm2 mdadm mkinitcpio linux linux-firmware linux-headers dosfstools grub efibootmgr networkmanager xfce4 xfce4-goodies lightdm lightdm-gtk-greeter iw wpa_supplicant dialog 2>&1 | tee /tmp/pacman.log
if [ $? -ne 0 ]; then
    echo -e '\033[31mOne or more package installation failed.\033[0m\n'
    echo -e '\033[31mFailed packages: \033[0m\n'
    grep "error:" /tmp/pacman.log
    rm /tmp/pacman.log
    exit 1
else
    echo -e '\033[32mAll packages installed.\033[0m\n'
    rm /tmp/pacman.log
fi

echo 'HOOKS="consolefont keyboard keymap base udev modconf block mdadm_udev encrypt lvm2 resume filesystems autodetect shutdown"' > /etc/mkinitcpio.conf
if [ $? -eq 0 ]; then
    echo -e '\033[32mMkinitcpio hooks configured.\033[0m\n'
else
    echo -e '\033[31mMkinitcpio hooks configuration failed.\033[0m\n'
    exit 1
fi

mkinitcpio -p linux
if [ $? -eq 0 ]; then
    echo -e '\033[32mLinux initcpio generated.\033[0m\n'
else
    echo -e '\033[31mLinux initcpio generation failed.\033[0m\n'
    exit 1
fi
echo -e 'root:$password' | chpasswd
if [ $? -eq 0 ]; then
    echo -e '\033[32mRoot password set.\033[0m\n'
else
    echo -e '\033[31mRoot password setting failed.\033[0m\n'
    exit 1
fi
useradd -m -g users -G wheel -s /bin/bash "$username"
if [ $? -eq 0 ]; then
    echo -e '\033[32mUser created.\033[0m\n'
else
    echo -e '\033[31mUser creation failed.\033[0m\n'
    exit 1
fi
echo -e "$username:$password" | chpasswd
if [ $? -eq 0 ]; then
    echo -e '\033[32mUser password set.\033[0m\n'
else
    echo -e '\033[31mUser password setting failed.\033[0m\n'
    exit 1
fi
echo -e '%wheel ALL=(ALL) ALL' >> /etc/sudoers
if [ $? -eq 0 ]; then
    echo -e '\033[32mSudoers file edited.\033[0m\n'
else
    echo -e '\033[31mSudoers file edition failed.\033[0m\n'
    exit 1
fi
grub-install --target=i386-pc /dev/sda
if [ $? -eq 0 ]; then
    echo -e '\033[32mGrub installed.\033[0m\n'
else
    echo -e '\033[31mGrub installation failed.\033[0m\n'
    exit 1
fi
grub-mkconfig -o /boot/grub/grub.cfg
if [ $? -eq 0 ]; then
    echo -e '\033[32mGrub config generated.\033[0m\n'
else
    echo -e '\033[31mGrub config generation failed.\033[0m\n'
    exit 1
fi
systemctl enable NetworkManager
if [ $? -eq 0 ]; then
    echo -e '\033[32mNetworkManager enabled.\033[0m\n'
else
    echo -e '\033[31mNetworkManager enabling failed.\033[0m\n'
    exit 1
fi
timedatectl set-timezone Europe/Paris
if [ $? -eq 0 ]; then
    echo -e '\033[32mTimezone set.\033[0m\n'
else
    echo -e '\033[31mTimezone setting failed.\033[0m\n'
    exit 1
fi
tzdata-country-clock -c France
if [ $? -eq 0 ]; then
    echo -e '\033[32mTimezone set.\033[0m\n'
else
    echo -e '\033[31mTimezone setting failed.\033[0m\n'
    exit 1
fi
systemctl enable lightdm
if [ $? -eq 0 ]; then
    echo -e '\033[32mLightdm enabled.\033[0m\n'
else
    echo -e '\033[31mLightdm enabling failed.\033[0m\n'
    exit 1
fi
echo -e 'exec startxfce4' >> /home/"$username"/.xinitrc
if [ $? -eq 0 ]; then
    echo -e '\033[32mXfce4 set as default desktop environment.\033[0m\n'
else
    echo -e '\033[31mXfce4 setting as default desktop environment failed.\033[0m\n'
    exit 1
fi
echo -e 'Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "'"$keyboard_layout"'"
EndSection' > /etc/X11/xorg.conf.d/00-keyboard.conf
if [ $? -eq 0 ]; then
    echo -e '\033[32mXfce4 keymaps set.\033[0m\n'
else
    echo -e '\033[31mXfce4 keymaps setting failed.\033[0m\n'
    exit 1
fi
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
echo -e 'Thank you for using this script.'
echo -e 'Check the script on https://github.com/Guigui1901/ArchLinuxInstaller'
echo -e '==============='
echo -e 'Press any key to reboot.'
read -n 1
umount -R /mnt
reboot


# # By the way, I'm French so I'm sorry for my English mistakes.
# # By Guigui1901