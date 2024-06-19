#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ]; then
    echo
    echo "This script should not be run as root. Run it as a regular user."
    echo
    exit 1
fi

# Improve compression of AUR packages
sudo sed -i 's/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/# COMPRESSZST=(zstd -c -T0 --ultra -20 -)/g' /etc/makepkg.conf

# Update the system and install required packages with sudo
echo
echo "Updating the system and installing required packages..."
echo
sleep 2
sudo pacman -Syu --noconfirm --needed base-devel git dialog

# List of packages to install via pacman without choice
DEFAULT_PKGS=(
    alsa-utils # Advanced Linux Sound Architecture utilities
    arandr # GUI for XRandR
    archlinux-contrib # Various useful Arch Linux utilities
    ark # Archiving tool for KDE
    atuin # Magical shell history
    bat # Cat clone with syntax highlighting
    bluedevil # Integrate Bluetooth with KDE workspace
    breeze-grub # Breeze theme for GRUB
    breeze-gtk # Breeze theme for GTK
    breeze-plymouth # Breeze theme for Plymouth
    chromium # Open-source web browser
    discover # KDE software center
    dolphin # File manager for KDE
    dolphin-plugins # Plugins for Dolphin
    drkonqi # Crash handler for KDE
    expac # Query information about installed packages
    eza # Modern replacement for ls
    gnome-keyring # Stores passwords and encryption keys
    gparted # GNOME Partition Editor
    grub-customizer # GRUB configuration editor
    gufw # GUI for Uncomplicated Firewall
    gwenview # Image viewer for KDE
    intel-ucode # Microcode update files for Intel CPUs
    kate # Advanced text editor for KDE
    kde-gtk-config # KDE configuration module for GTK
    kdeplasma-addons # Addons for KDE Plasma
    kgamma # Adjust display gamma settings
    kinfocenter # System information viewer
    kio-admin # Manage files as administrator
    konsole # Terminal emulator for KDE
    kscreen # Screen management software
    ksshaskpass # SSH password dialog for KDE
    ksystemlog # System log viewer for KDE
    kwallet-pam # PAM integration for KWallet
    kwrited # KDE daemon for writing to users
    lsb-release # Linux Standard Base release tool
    man-db # Manual page browser
    man-pages # Manual pages
    nano # Simple text editor
    ocean-sound-theme # Sound theme inspired by the ocean
    okular # Document viewer for KDE
    openssh # OpenSSH server and client
    os-prober # Utility to detect other OSes on a system
    oxygen # Oxygen theme
    oxygen-sounds # Sound theme for KDE
    packagekit-qt6 # Qt frontend for PackageKit
    pacmanlogviewer # Viewer for pacman log files
    papirus-icon-theme # Icon theme
    pavucontrol # PulseAudio Volume Control
    plasma-browser-integration # Browser integration for Plasma
    plasma-desktop # KDE Plasma desktop
    plasma-disks # Disk management for Plasma
    plasma-firewall # Firewall settings for Plasma
    plasma-nm # Network management for Plasma
    plasma-pa # Audio volume settings for Plasma
    plasma-systemmonitor # System monitor for Plasma
    plasma-thunderbolt # Thunderbolt management for Plasma
    plasma-vault # Encrypted vaults for Plasma
    plasma-welcome # Welcome screen for Plasma
    plasma-workspace-wallpapers # Wallpapers for Plasma workspace
    powerdevil # Power management for KDE
    print-manager # Printer management for KDE
    pulseaudio-equalizer-ladspa # PulseAudio equalizer module
    sddm-kcm # SDDM configuration module for KDE
    seahorse # GNOME application for managing encryption keys
    speedtest-cli # Command line interface for speedtest.net
    terminus-font # Monospace font for the console
    timeshift # System restore tool
    tlp # Advanced power management for Linux
    unzip # Extract compressed files in a ZIP archive
    vlc # Multimedia player
    wget # Network downloader
    wl-clipboard # Command-line copy/paste utilities for Wayland
    xdg-desktop-portal-kde # XDG desktop portal backend for KDE
    zram-generator # Systemd unit generator for zram swap
    zsh # Z shell
    zsh-completions # Additional completions for Zsh
    zsh-syntax-highlighting # Syntax highlighting for Zsh
    zoxide # A smarter cd command for your terminal
    fzf # Command-line fuzzy finder
)

# List of packages to install via pacman with choice
OPTIONAL_PKGS_PACMAN=(
    linux-headers # Kernel headers for building modules
    linux-lts # Long-term support Linux kernel
    linux-lts-headers # Headers for the LTS kernel
    linux-zen # Linux kernel optimized for desktop usage
    linux-zen-headers # Headers for the Zen kernel
    bleachbit # Disk cleanup utility
    chezmoi # Manage your dotfiles across multiple machines
    code # Visual Studio Code editor
    deluge-gtk # BitTorrent client
    fastfetch # Neofetch-like tool for displaying system information
    firefox # Web browser
    gimp # GNU Image Manipulation Program
    inkscape # Vector graphics editor
    kbackup # Backup tool for KDE
    kcolorchooser # Color picker for KDE
    kompare # File comparison tool
    kvantum # SVG-based theme engine for Qt
    kvantum-qt5 # Qt5 version of Kvantum
    linssid # Wireless network scanner
    marker # Markdown editor
    mc # Midnight Commander file manager
    virtualbox # Virtualization software
)

# List of packages to install via yay with choice
OPTIONAL_PKGS_YAY=(
    brave-bin # Brave web browser
    caffeine-ng # Prevent screen from going to sleep
    catppuccin-gtk-theme-mocha # Catppuccin Mocha theme for GTK
    downgrade # Easily downgrade packages
    dropbox # Cloud storage
    klassy # A simple and modern Plasma theme
    konsave # Save and restore Plasma configurations
    pamac-aur # A Gtk3 frontend for libalpm
    paru-bin # AUR helper
    plasma6-applets-panel-colorizer # Colorize Plasma panel
    popcorntime-bin # Stream movies and TV shows
    sddm-theme-catppuccin # Catppuccin theme for SDDM
    tlpui-git # User interface for TLP
    update-grub # Update GRUB configuration
    ventoy-bin # Create bootable USB drive
    xcursor-arch-cursor-complete # Complete Arch cursor theme
)

# List of services to enable if installed
SERVICES=(
    sddm # Simple Desktop Display Manager
    tlp # Power management service
    ufw # Uncomplicated Firewall
)

# Convert package arrays to a format suitable for dialog
generate_dialog_options() {
    local options=()
    local default_status=$1
    shift
    for pkg in "$@"; do
        options+=("$pkg" "$pkg" "$default_status")
    done
    echo "${options[@]}"
}

# Generate dialog options for optional pacman (default ON) and yay (default OFF) packages
optional_pacman_options=$(generate_dialog_options "off" "${OPTIONAL_PKGS_PACMAN[@]}")
optional_yay_options=$(generate_dialog_options "off" "${OPTIONAL_PKGS_YAY[@]}")

# Ask user which packages to install via pacman using dialog
selected_optional_pacman=$(dialog --separate-output --checklist "Select optional packages to install via pacman" 20 78 15 ${optional_pacman_options} 3>&1 1>&2 2>&3)
clear

# Display a warning message about yay packages
dialog --msgbox "Warning: Installing packages from the AUR can take time to build. Please choose carefully which packages to install." 10 60
clear

# Ask user which packages to install via yay using dialog
selected_optional_yay=$(dialog --separate-output --checklist "Select optional packages to install via yay" 20 78 15 ${optional_yay_options} 3>&1 1>&2 2>&3)
clear

# Convert selected packages from dialog output
selected_optional_pacman=($(echo $selected_optional_pacman | sed 's/"//g'))
selected_optional_yay=($(echo $selected_optional_yay | sed 's/"//g'))

# Confirm selections with the user
while true; do
    echo
    echo "You've selected these packages to install via pacman: ${selected_optional_pacman[@]}"
    echo "You've selected these packages to install via yay: ${selected_optional_yay[@]}"
    echo
    read -p "Do you want to continue? (y/n): " CONFIRM
    echo

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        break
    elif [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        selected_optional_pacman=$(dialog --separate-output --checklist "Select optional packages to install via pacman" 20 78 15 ${optional_pacman_options} 3>&1 1>&2 2>&3)
        clear
        dialog --msgbox "Warning: Installing packages from the AUR can take time to build. Please choose carefully which packages to install." 10 60
        clear
        selected_optional_yay=$(dialog --separate-output --checklist "Select optional packages to install via yay" 20 78 15 ${optional_yay_options} 3>&1 1>&2 2>&3)
        clear
        selected_optional_pacman=($(echo $selected_optional_pacman | sed 's/"//g'))
        selected_optional_yay=($(echo $selected_optional_yay | sed 's/"//g'))
    else
        echo "Please answer y or n."
    fi
done

# Debug output to verify selections
echo
echo "Selected optional pacman packages: ${selected_optional_pacman[@]}"
echo
echo "Selected optional yay packages: ${selected_optional_yay[@]}"
echo

# Install yay if it is not already installed
if ! command -v yay &> /dev/null; then
    echo
    echo "yay not found, installing yay..."
    echo
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo
    echo "yay is already installed"
    echo
fi

# Install essential packages with pacman
echo
echo "Installing essential packages with pacman..."
echo
sudo pacman -S --noconfirm --needed "${DEFAULT_PKGS[@]}"

# Install optional packages with pacman
if [ ${#selected_optional_pacman[@]} -ne 0 ]; then
    echo
    echo "Installing selected optional packages with pacman..."
    echo
    sudo pacman -S --noconfirm --needed "${selected_optional_pacman[@]}"
fi

# Install selected optional packages with yay
if [ ${#selected_optional_yay[@]} -ne 0 ]; then
    echo
    echo "Installing selected optional packages with yay..."
    echo
    yay -S --noconfirm --needed "${selected_optional_yay[@]}"
fi

yay -S --noconfirm --needed catppuccin-konsole-theme-git

# Enable selected services if they are installed
for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        echo
        echo "Enabling service: ${service}"
        echo
        sudo systemctl enable "${service}.service"
    fi
done

# Set Plasma session as default if selected
if [[ " ${DEFAULT_PKGS[@]} ${selected_optional_pacman[@]} " =~ " plasma-meta " ]]; then
    echo
    echo "Setting Plasma session as default..."
    echo
    sudo tee /etc/sddm.conf > /dev/null <<EOT
[Desktop]
Session=plasma.desktop
EOT
fi

echo
echo "Installing oh-my-zsh & oh-my-posh..."
echo
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mkdir -p ~/.local/bin
mkdir -p ~/.config/oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# List of files to copy to the home directory
FILES_TO_COPY=(
    ".zshrc" ".zsh-aliases" ".zsh-functions"
)

# Change default shell to zsh
chsh -s /usr/bin/zsh

# Copy files from the script directory to the home directory
echo
echo "Copying files from the script directory to the home directory..."
echo
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
for FILE in "${FILES_TO_COPY[@]}"; do
    if [ -f "$SCRIPT_DIR/assets/$FILE" ]; then
        cp "$SCRIPT_DIR/assets/$FILE" ~/
        chmod 644 ~/"$FILE"
        echo "Copied and set permissions for $FILE"
    else
        echo "File $SCRIPT_DIR/assets/$FILE does not exist"
    fi
done

# Copy additional files with the appropriate permissions
echo "Copying mytheme.omp.json to ~/.config/oh-my-posh"
cp "$SCRIPT_DIR/assets/mytheme.omp.json" ~/.config/oh-my-posh && chmod 644 ~/.config/oh-my-posh/mytheme.omp.json && echo "Copied and set permissions for mytheme.omp.json"

echo "Creating directory ~/.local/share/fonts"
mkdir -p ~/.local/share/fonts && echo "Directory ~/.local/share/fonts created"

echo "Copying OperatorMonoNerdFont_Medium.otf to ~/.local/share/fonts"
cp "$SCRIPT_DIR/assets/OperatorMonoNerdFont_Medium.otf" ~/.local/share/fonts && chmod 644 ~/.local/share/fonts/OperatorMonoNerdFont_Medium.otf && echo "Copied and set permissions for OperatorMonoNerdFont_Medium.otf"

echo "Creating directory ~/.local/share/konsole"
mkdir -p ~/.local/share/konsole && echo "Directory ~/.local/share/konsole created"

echo "Copying konsolerc to ~/.config"
cp "$SCRIPT_DIR/assets/konsolerc" ~/.config && chmod 644 ~/.config/konsolerc && echo "Copied and set permissions for konsolerc"

echo "Copying 'Catppuccin Mocha.profile' to ~/.local/share/konsole"
cp "$SCRIPT_DIR/assets/'Catppuccin Mocha.profile'" ~/.local/share/konsole && chmod 644 ~/.local/share/konsole/'Catppuccin Mocha.profile' && echo "Copied and set permissions for 'Catppuccin Mocha.profile'"

echo
echo "Installing catppuccin theme, follow install.sh..."
echo
git clone --depth=1 https://github.com/catppuccin/kde catppuccin-kde && cd catppuccin-kde
./install.sh

# Reboot prompt
read -p "Installation complete. Do you want to reboot now? (y/n): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    clear
    echo
    echo "Installation complete. Don't forget to reboot your system!"
    echo
fi

exit 0
