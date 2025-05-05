#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="installer.log"

function log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

function validate_dependencies() {
    log '\n==============='
    log 'Validating dependencies...'
    log '==============='
    local dependencies=("curl" "timedatectl" "loadkeys" "setxkbmap" "pacman")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log "\033[31mError: Required command '$cmd' is not installed.\033[0m"
            exit 2
        fi
    done
    log '\033[32mAll dependencies are installed.\033[0m\n'
}

function display_header() {
    clear
    log "\033[34m██╗░░░██╗░█████╗░░█████╗░██╗░░░░░██╗"
    log "╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██║"
    log "░╚████╔╝░███████║███████║██║░░░░░██║"
    log "░░╚██╔╝░░██╔══██║██╔══██║██║░░░░░██║"
    log "░░░██║░░░██║░░██║██║░░██║███████╗██║"
    log "░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝ v1.0a\033[0m"
    log '==============='
    log 'Arch Linux Installer Script'
    log '\033[1;31mNOT FOR PRODUCTION USE - FOR TESTING ONLY\033[0m'
    log '\033[1;31mState: Alpha - Not all features are implemented yet.\033[0m'
    log '\033[1;31mNOT TESTED\033[0m'
    log 'This script will install Arch Linux on your computer.'
    log 'It will erase all data on the disk.'
    log 'Press any key to continue.'
    read -n 1
    log '==============='
}

function check_arch_linux() {
    log '\n==============='
    log 'Checking if the script is running on Arch Linux...'
    log '==============='
    if [ -f /etc/arch-release ] || [ -f /etc/archlinux-release ] || [ -f /etc/os-release ]; then
        log '\033[32mThe script is running on Arch Linux.\033[0m\n'
    else
        log '\033[31mThe script is not running on Arch Linux.\033[0m\n'
        log '\033[31mPlease run the script on Arch Linux.\033[0m\n'
        exit 3
    fi
}

function check_root() {
    log '\n==============='
    log 'Checking if the script is run as root...'
    log '==============='
    if [ "$(id -u)" -eq 0 ]; then
        log '\033[32mThe script is run as root.\033[0m\n'
    else
        log '\033[31mThe script is not run as root.\033[0m\n'
        log '\033[31mPlease run the script as root.\033[0m\n'
        exit 4
    fi
}

function set_keyboard_layout() {
    log '\n==============='
    log 'Setting the keyboard layout...'
    log '==============='
    keyboard_layout=${1:-fr} # Allow passing layout as an argument
    while true; do
        if command -v loadkeys &> /dev/null; then
            if loadkeys -q $keyboard_layout &> /dev/null; then
                log '\033[32mKeyboard layout set to '$keyboard_layout'.\033[0m\n'
                break
            else
                log '\033[31mInvalid keyboard layout, please specify a valid one.\033[0m\n'
            fi
        elif command -v setxkbmap &> /dev/null; then
            if setxkbmap $keyboard_layout &> /dev/null; then
                log '\033[32mKeyboard layout set to '$keyboard_layout'.\033[0m\n'
                break
            else
                log '\033[31mInvalid keyboard layout, please specify a valid one.\033[0m\n'
            fi
        else
            log '\033[31mNo keyboard layout command found.\033[0m\n'
            log '\033[31m Installing loadkeys.\033[0m\n'
            pacman -S --noconfirm kbd
            log '\033[32mloadkeys installed.\033[0m\n'
            clear
            set_keyboard_layout "$@"
            exit 5
        fi
        log 'Keyboard layout (default fr): '
        read keyboard_layout
        [[ -z $keyboard_layout ]] && keyboard_layout=fr
    done
}

function check_internet() {
    log '\n==============='
    log 'Checking internet connection...'
    log '==============='
    if curl -s --head http://www.google.com | grep "200 OK" > /dev/null; then
        log '\033[32mInternet connection is available.\033[0m\n'
    else
        log '\033[31mNo internet connection.\033[0m\n'  
        log '\033[31mPlease check your internet connection.\033[0m\n'
        log '\033[31mExiting the script.\033[0m\n'
        exit 6
    fi
}

function system_clock() {
    log '\n==============='
    log 'Updating the system clock...'
    log '==============='
    timedatectl set-ntp true
    timedatectl status | grep 'System clock synchronized: yes' > /dev/null
    if [ $? -eq 0 ]; then
        log '\033[32mClock is synchronized.\033[0m\n'
    else
        log '\033[31mClock synchronization failed.\033[0m\n'
        log '\033[31mPlease check your internet connection and try again.\033[0m\n'
        exit 7
    fi
}

# Main script execution
validate_dependencies
display_header
check_arch_linux
check_root
set_keyboard_layout "$@"
check_internet
system_clock