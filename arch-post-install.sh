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
    alsa-utils
    arandr
    archlinux-contrib
    ark
    atuin
    bat
    bluedevil
    breeze-grub
    breeze-gtk
    breeze-plymouth
    chromium
    discover
    dolphin
    dolphin-plugins
    drkonqi
    expac
    eza
    gnome-keyring
    gparted
    grub-customizer
    gufw
    gwenview
    intel-ucode
    kate
    kde-gtk-config
    kdeplasma-addons
    kgamma
    kinfocenter
    konsole
    kscreen
    ksshaskpass
    ksystemlog
    kwallet-pam
    kwrited
    lsb-release
    man-db
    man-pages
    nano
    ocean-sound-theme
    okular
    openssh
    os-prober
    oxygen
    oxygen-sounds
    packagekit-qt6
    pacmanlogviewer
    papirus-icon-theme
    pavucontrol
    plasma-browser-integration
    plasma-desktop
    plasma-disks
    plasma-firewall
    plasma-nm
    plasma-pa
    plasma-systemmonitor
    plasma-thunderbolt
    plasma-vault
    plasma-welcome
    plasma-workspace-wallpapers
    powerdevil
    print-manager
    pulseaudio-equalizer-ladspa
    sddm-kcm
    seahorse
    speedtest-cli
    terminus-font
    timeshift
    tlp
    unzip
    vlc
    wget
    wl-clipboard
    xdg-desktop-portal-kde
    zram-generator
    zsh
    zsh-completions
    zsh-syntax-highlighting
    zoxide
    fzf
)

# List of packages to install via pacman with choice
OPTIONAL_PKGS_PACMAN=(
    "linux-headers Kernel headers for building modules"
    "linux-lts Long-term support Linux kernel"
    "linux-lts-headers Headers for the LTS kernel"
    "linux-zen Linux kernel optimized for desktop usage"
    "linux-zen-headers Headers for the Zen kernel"
    "bleachbit Disk cleanup utility"
    "chezmoi Manage your dotfiles across multiple machines"
    "code Visual Studio Code editor"
    "deluge-gtk BitTorrent client"
    "fastfetch Neofetch-like tool for displaying system information"
    "firefox Web browser"
    "gimp GNU Image Manipulation Program"
    "inkscape Vector graphics editor"
    "kbackup Backup tool for KDE"
    "kcolorchooser Color picker for KDE"
    "kompare File comparison tool"
    "kvantum SVG-based theme engine for Qt"
    "kvantum-qt5 Qt5 version of Kvantum"
    "linssid Wireless network scanner"
    "marker Markdown editor"
    "mc Midnight Commander file manager"
    "virtualbox Virtualization software"
)

# List of packages to install via yay with choice
OPTIONAL_PKGS_YAY=(
    "brave-bin Brave web browser"
    "caffeine-ng Prevent screen from going to sleep"
    "catppuccin-gtk-theme-mocha Catppuccin Mocha theme for GTK"
    "downgrade Easily downgrade packages"
    "dropbox Cloud storage"
    "klassy A simple and modern Plasma theme"
    "konsave Save and restore Plasma configurations"
    "pamac-aur A Gtk3 frontend for libalpm"
    "paru-bin AUR helper"
    "plasma6-applets-panel-colorizer Colorize Plasma panel"
    "popcorntime-bin Stream movies and TV shows"
    "sddm-theme-catppuccin Catppuccin theme for SDDM"
    "tlpui-git User interface for TLP"
    "update-grub Update GRUB configuration"
    "ventoy-bin Create bootable USB drive"
    "xcursor-arch-cursor-complete Complete Arch cursor theme"
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
    while [ $# -gt 0 ]; do
        local pkg_desc=$1
        local pkg=$(echo "$pkg_desc" | awk '{print $1}')
        local desc=$(echo "$pkg_desc" | cut -d' ' -f2-)
        options+=("$pkg" "$desc" "$default_status")
        shift
    done
    echo "${options[@]}"
}

# Generate dialog options for optional pacman (default ON) and yay (default OFF) packages
optional_pacman_options=$(generate_dialog_options "on" "${OPTIONAL_PKGS_PACMAN[@]}")
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
selected_optional_pacman=($(echo "$selected_optional_pacman" | tr -d '"'))
selected_optional_yay=($(echo "$selected_optional_yay" | tr -d '"'))

# Confirm selections with the user
while true; do
    echo
    echo "You've selected these packages to install via pacman: ${selected_optional_pacman[@]}"
    echo "You've selected these packages to install via yay: ${selected_optional_yay[@]}"
    echo
    read -p "Do you want to proceed with these selections? (y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        break
    elif [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        clear
        selected_optional_pacman=$(dialog --separate-output --checklist "Select optional packages to install via pacman" 20 78 15 ${optional_pacman_options} 3>&1 1>&2 2>&3)
        clear
        dialog --msgbox "Warning: Installing packages from the AUR can take time to build. Please choose carefully which packages to install." 10 60
        clear
        selected_optional_yay=$(dialog --separate-output --checklist "Select optional packages to install via yay" 20 78 15 ${optional_yay_options} 3>&1 1>&2 2>&3)
        clear
        selected_optional_pacman=($(echo "$selected_optional_pacman" | tr -d '"'))
        selected_optional_yay=($(echo "$selected_optional_yay" | tr -d '"'))
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
