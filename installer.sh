#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

function display_header() {
    clear
    echo -e "\033[34m██╗░░░██╗░█████╗░░█████╗░██╗░░░░░██╗"
    echo -e "╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██║"
    echo -e "░╚████╔╝░███████║███████║██║░░░░░██║"
    echo -e "░░╚██╔╝░░██╔══██║██╔══██║██║░░░░░██║"
    echo -e "░░░██║░░░██║░░██║██║░░██║███████╗██║"
    echo -e "░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝ v1.0a\033[0m"
    echo -e '==============='
    echo -e 'Arch Linux Installer Script'
    echo -e '\033[1;31mNOT FOR PRODUCTION USE - FOR TESTING ONLY\033[0m'
    echo -e '\033[1;31mState: Alpha - Not all features are implemented yet.\033[0m'
    echo -e '\033[1;31mNOT TESTED\033[0m'
    echo -e 'This script will install Arch Linux on your computer.'
    echo -e 'It will erase all data on the disk.'
    echo -e 'Press any key to continue.'
    read -n 1
    echo -e '==============='
}

function check_arch_linux() {
    echo -e '\n==============='
    echo -e 'Checking if the script is running on Arch Linux...'
    echo -e '==============='
    if [ -f /etc/arch-release ] || [ -f /etc/archlinux-release ] || [ -f /etc/os-release ]; then
        echo -e '\033[32mThe script is running on Arch Linux.\033[0m\n'
    else
        echo -e '\033[31mThe script is not running on Arch Linux.\033[0m\n'
        echo -e '\033[31mPlease run the script on Arch Linux.\033[0m\n'
        exit 1
    fi
}

function check_root() {
    echo -e '\n==============='
    echo -e 'Checking if the script is run as root...'
    echo -e '==============='
    if [ "$(id -u)" -eq 0 ]; then
        echo -e '\033[32mThe script is run as root.\033[0m\n'
    else
        echo -e '\033[31mThe script is not run as root.\033[0m\n'
        echo -e '\033[31mPlease run the script as root.\033[0m\n'
        exit 1
    fi
}

function set_keyboard_layout() {
    echo -e '\n==============='
    echo -e 'Setting the keyboard layout...'
    echo -e '==============='
    keyboard_layout=${1:-fr} # Allow passing layout as an argument
    while true; do
        if command -v loadkeys &> /dev/null; then
            if loadkeys -q $keyboard_layout &> /dev/null; then
                echo -e '\033[32mKeyboard layout set to '$keyboard_layout'.\033[0m\n'
                break
            else
                echo -e '\033[31mInvalid keyboard layout, please specify a valid one.\033[0m\n'
            fi
        elif command -v setxkbmap &> /dev/null; then
            if setxkbmap $keyboard_layout &> /dev/null; then
                echo -e '\033[32mKeyboard layout set to '$keyboard_layout'.\033[0m\n'
                break
            else
                echo -e '\033[31mInvalid keyboard layout, please specify a valid one.\033[0m\n'
            fi
        else
            echo -e '\033[31mNo keyboard layout command found.\033[0m\n'
            echo -e '\033[31m Installing loadkeys.\033[0m\n'
            pacman -S --noconfirm kbd
            echo -e '\033[32mloadkeys installed.\033[0m\n'
            clear
            set_keyboard_layout("$@")
            exit 1
        fi
        echo -e 'Keyboard layout (default fr): '
        read keyboard_layout
        [[ -z $keyboard_layout ]] && keyboard_layout=fr
    done
}

# Main script execution
display_header
check_arch_linux
check_root
set_keyboard_layout "$@"