#!/bin/bash

# Effacer l'écran
clear

# Fonction pour afficher le logo
display_logo() {
    echo -e "\033[1;34m
██╗░░░██╗░█████╗░░█████╗░██╗░░░░░██╗
╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██║
░╚████╔╝░███████║███████║██║░░░░░██║
░░╚██╔╝░░██╔══██║██╔══██║██║░░░░░██║
░░░██║░░░██║░░██║██║░░██║███████╗██║
░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝ v0.18\033[0m"

    echo -e "\033[1;34m========================================\033[0m"
    echo -e "Ce script va installer Arch Linux sur votre ordinateur."
    echo -e "\033[1;31mAttention : Toutes les données sur le disque seront effacées.\033[0m"
    echo -e "\033[1;34m========================================\033[0m"
    read -n 1 -s -r -p "Appuyez sur une touche pour continuer..."
}

# Fonction pour vérifier si le script est exécuté sur Arch Linux
check_archlinux() {
    echo -e "\n\033[1;34m[VÉRIFICATION] Le script s'exécute-t-il sur Arch Linux ?\033[0m"
    if [ -f /etc/arch-release ]; then
        echo -e "\033[1;32m[OK] Le script s'exécute sur Arch Linux.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Ce script doit être exécuté sur Arch Linux.\033[0m"
        exit 1
    fi
}

# Fonction pour configurer le clavier
configure_keyboard() {
    echo -e "\n\033[1;34m[CONFIGURATION] Configuration du clavier\033[0m"
    read -p "Disposition du clavier (par défaut 'fr') : " keyboard_layout
    keyboard_layout=${keyboard_layout:-fr}
    if loadkeys "$keyboard_layout"; then
        echo -e "\033[1;32m[OK] Disposition du clavier définie sur '$keyboard_layout'.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Impossible de définir la disposition du clavier.\033[0m"
        exit 1
    fi
}

# Fonction pour vérifier la connexion internet
check_internet() {
    echo -e "\n\033[1;34m[CONNEXION] Vérification de la connexion internet\033[0m"
    if ping -c 3 archlinux.org > /dev/null 2>&1; then
        echo -e "\033[1;32m[OK] Connecté à Internet.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Impossible de se connecter à Internet.\033[0m"
        exit 1
    fi
}

# Fonction pour synchroniser l'horloge système
synchronize_clock() {
    echo -e "\n\033[1;34m[SYNCHRONISATION] Mise à jour de l'horloge système\033[0m"
    timedatectl set-ntp true
    if timedatectl status | grep -q 'System clock synchronized: yes'; then
        echo -e "\033[1;32m[OK] Horloge synchronisée.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Synchronisation de l'horloge échouée.\033[0m"
        exit 1
    fi
}

# Fonction pour effacer les partitions sur /dev/sda
wipe_partitions() {
    echo -e "\n\033[1;34m[PARTITIONNEMENT] Effacement des partitions sur /dev/sda\033[0m"
    echo -e "\033[1;31mAttention : Toutes les données sur /dev/sda seront perdues.\033[0m"
    read -n 1 -s -r -p "Appuyez sur une touche pour confirmer..."
    if sgdisk --zap-all /dev/sda; then
        echo -e "\033[1;32m[OK] Partitions effacées sur /dev/sda.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Échec de l'effacement des partitions sur /dev/sda.\033[0m"
        exit 1
    fi
}

# Fonction pour recueillir les informations utilisateur
collect_user_info() {
    echo -e "\n\033[1;34m[INFORMATIONS] Saisie des informations utilisateur\033[0m"
    read -p "Nom d'utilisateur : " username
    if [ -z "$username" ]; then
        echo -e "\033[1;31m[ERREUR] Le nom d'utilisateur ne peut pas être vide.\033[0m"
        exit 1
    fi

    read -s -p "Mot de passe : " password
    echo
    if [ -z "$password" ]; then
        echo -e "\033[1;31m[ERREUR] Le mot de passe ne peut pas être vide.\033[0m"
        exit 1
    fi

    read -p "Nom d'hôte (hostname) : " hostname
    if [ -z "$hostname" ]; then
        echo -e "\033[1;31m[ERREUR] Le nom d'hôte ne peut pas être vide.\033[0m"
        exit 1
    fi
}

# Fonction pour définir les tailles des partitions
define_partition_sizes() {
    echo -e "\n\033[1;34m[PARTITIONS] Définition des tailles des partitions (en Mo)\033[0m"
    read -p "Taille de la partition /boot (par défaut 512) : " boot_size
    boot_size=${boot_size:-512}
    if ! [[ "$boot_size" =~ ^[0-9]+$ ]] || [ "$boot_size" -lt 150 ]; then
        echo -e "\033[1;31m[ERREUR] Taille de /boot invalide (minimum 150 Mo).\033[0m"
        exit 1
    fi

    read -p "Taille de la partition / (root) (par défaut 20480) : " root_size
    root_size=${root_size:-20480}
    if ! [[ "$root_size" =~ ^[0-9]+$ ]] || [ "$root_size" -lt 1024 ]; then
        echo -e "\033[1;31m[ERREUR] Taille de / invalide (minimum 1024 Mo).\033[0m"
        exit 1
    fi

    read -p "Taille de la partition swap (par défaut 2048) : " swap_size
    swap_size=${swap_size:-2048}
    if ! [[ "$swap_size" =~ ^[0-9]+$ ]] || [ "$swap_size" -lt 512 ]; then
        echo -e "\033[1;31m[ERREUR] Taille de swap invalide (minimum 512 Mo).\033[0m"
        exit 1
    fi

    # Calcul de la taille restante pour /home
    disk_size=$(lsblk -b -dn -o SIZE /dev/sda)
    used_size=$(($boot_size * 1024 * 1024 + $root_size * 1024 * 1024 + $swap_size * 1024 * 1024 + 512 * 1024 * 1024)) # 512M pour l'EFI
    home_size=$(( ($disk_size - $used_size) / (1024 * 1024) ))

    if [ "$home_size" -lt 1024 ]; then
        echo -e "\033[1;31m[ERREUR] Espace insuffisant pour la partition /home.\033[0m"
        exit 1
    fi

    echo -e "\033[1;32m[OK] Taille de /home définie à ${home_size} Mo.\033[0m"
}

# Fonction pour créer les partitions
create_partitions() {
    echo -e "\n\033[1;34m[PARTITIONNEMENT] Création de la table de partition\033[0m"
    (
    echo g # Créer une nouvelle table de partition GPT
    echo n # Nouvelle partition (EFI)
    echo   # Partition par défaut (1)
    echo   # Premier secteur par défaut
    echo +512M # Taille de la partition EFI
    echo t
    echo 1 # Type EFI

    echo n # Nouvelle partition (/boot)
    echo   # Partition par défaut (2)
    echo   # Premier secteur par défaut
    echo +${boot_size}M # Taille de /boot

    echo n # Nouvelle partition (root)
    echo   # Partition par défaut (3)
    echo   # Premier secteur par défaut
    echo +${root_size}M # Taille de /

    echo n # Nouvelle partition (swap)
    echo   # Partition par défaut (4)
    echo   # Premier secteur par défaut
    echo +${swap_size}M # Taille de swap

    echo n # Nouvelle partition (/home)
    echo   # Partition par défaut (5)
    echo   # Premier secteur par défaut
    echo   # Dernier secteur par défaut (reste du disque pour /home)

    echo w # Écrire les modifications
    ) | fdisk /dev/sda

    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m[OK] Table de partition créée.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Échec de la création de la table de partition.\033[0m"
        exit 1
    fi
}

# Fonction pour formater les partitions
format_partitions() {
    echo -e "\n\033[1;34m[FORMATAGE] Formatage des partitions\033[0m"
    mkfs.fat -F32 /dev/sda1 && echo -e "\033[1;32m[OK] /dev/sda1 formatée en FAT32 (EFI).\033[0m"
    mkfs.ext4 /dev/sda2 && echo -e "\033[1;32m[OK] /dev/sda2 formatée en ext4 (/boot).\033[0m"
    mkfs.ext4 /dev/sda3 && echo -e "\033[1;32m[OK] /dev/sda3 formatée en ext4 (/).\033[0m"
    mkfs.ext4 /dev/sda5 && echo -e "\033[1;32m[OK] /dev/sda5 formatée en ext4 (/home).\033[0m"
    mkswap /dev/sda4 && echo -e "\033[1;32m[OK] /dev/sda4 formatée en swap.\033[0m"
    swapon /dev/sda4 && echo -e "\033[1;32m[OK] Swap activée.\033[0m"
}

# Fonction pour monter les partitions
mount_partitions() {
    echo -e "\n\033[1;34m[MONTAGE] Montage des partitions\033[0m"
    mount /dev/sda3 /mnt && echo -e "\033[1;32m[OK] / montée.\033[0m"
    mkdir -p /mnt/boot && mount /dev/sda2 /mnt/boot && echo -e "\033[1;32m[OK] /boot montée.\033[0m"
    mkdir -p /mnt/boot/efi && mount /dev/sda1 /mnt/boot/efi && echo -e "\033[1;32m[OK] Partition EFI montée.\033[0m"
    mkdir -p /mnt/home && mount /dev/sda5 /mnt/home && echo -e "\033[1;32m[OK] /home montée.\033[0m"
}

# Fonction pour installer les paquets essentiels
install_base_packages() {
    echo -e "\n\033[1;34m[INSTALLATION] Installation des paquets essentiels\033[0m"
    pacstrap /mnt base base-devel linux linux-firmware vim nano

    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m[OK] Paquets essentiels installés.\033[0m"
    else
        echo -e "\033[1;31m[ERREUR] Échec de l'installation des paquets essentiels.\033[0m"
        exit 1
    fi
}

# Fonction pour générer le fichier fstab
generate_fstab() {
    echo -e "\n\033[1;34m[FSTAB] Génération du fichier fstab\033[0m"
    genfstab -U /mnt >> /mnt/etc/fstab
    echo -e "\033[1;32m[OK] Fichier fstab généré.\033[0m"
}

# Fonction pour configurer le système dans chroot
configure_system() {
    echo -e "\n\033[1;34m[CONFIGURATION] Configuration du système\033[0m"

    # Créer un script de configuration à exécuter dans chroot
    cat <<EOF > /mnt/root/arch_install.sh
#!/bin/bash

# Configuration du fuseau horaire
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

# Localisation
echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=$keyboard_layout" > /etc/vconsole.conf

# Nom d'hôte
echo "$hostname" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $hostname.localdomain $hostname
HOSTS

# Installation de GRUB
pacman --noconfirm -S grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Mot de passe root
echo "root:$password" | chpasswd

# Création de l'utilisateur
useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$password" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Activer les services nécessaires
pacman --noconfirm -S networkmanager
systemctl enable NetworkManager

# Nettoyage
rm /root/arch_install.sh
EOF

    # Rendre le script exécutable et l'exécuter dans chroot
    chmod +x /mnt/root/arch_install.sh
    arch-chroot /mnt /root/arch_install.sh
}

# Fonction principale
main() {
    display_logo
    check_archlinux
    configure_keyboard
    check_internet
    synchronize_clock
    wipe_partitions
    collect_user_info
    define_partition_sizes
    create_partitions
    format_partitions
    mount_partitions
    install_base_packages
    generate_fstab
    configure_system

    # Fin de l'installation
    echo -e "\n\033[1;32m[FIN] Installation terminée avec succès !\033[0m"
    echo -e "Vous pouvez redémarrer votre système."

    # Demander à l'utilisateur de redémarrer
    read -n 1 -s -r -p "Appuyez sur une touche pour redémarrer..."
    umount -R /mnt
    swapoff -a
    reboot
}

# Exécuter la fonction principale
main
