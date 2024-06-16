#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ]; then
    echo

    echo "This script should not be run as root. Run it as a regular user."

    echo
    sleep 3
    exit 1
fi

# --improve compression of AUR packages--#
sudo sed -i 's/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/# COMPRESSZST=(zstd -c -T0 --ultra -20 -)/g' /etc/makepkg.conf

# Update the system and install required packages with sudo
echo

echo "Updating the system and installing required packages..."

echo
sleep 3
sudo pacman -Syu --noconfirm --needed base-devel git dialog

# List of packages to install via pacman without choice
ESSENTIAL_PKGS=(
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
    linux-headers    
    bleachbit
    chezmoi
    chromium              
    code
    deluge-gtk    
    fastfetch
    firefox             
    gimp
    inkscape    
    kbackup
    kcolorchooser
    kompare
    kvantum
    kvantum-qt5
    linssid    
    marker
    mc    
    virtualbox
                        
)

# List of packages to install via yay with choice
OPTIONAL_PKGS_YAY=(
    brave-bin
    caffeine-ng    
    catppuccin-gtk-theme-mocha
    catppuccin-konsole-theme-git
    downgrade
    dropbox
    klassy
    konsave
    pamac-aur
    paru-bin
    plasma6-applets-panel-colorizer
    popcorntime-bin
    sddm-theme-catppuccin
    tlpui-git
    update-grub
    ventoy-bin
    xcursor-arch-cursor-complete
)

# List of services to enable if installed
SERVICES=(
    sddm
    tlp
    ufw
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
sleep 3

echo

echo "Selected optional yay packages: ${selected_optional_yay[@]}"

echo
sleep 3

# Install yay if it is not already installed
if ! command -v yay &> /dev/null; then
    echo

    echo "yay not found, installing yay..."

    echo
    sleep 3
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo

    echo "yay is already installed"

    echo
    sleep 3
fi

# Install essential packages with pacman
echo

echo "Installing essential packages with pacman..."

echo
sleep 3
sudo pacman -S --noconfirm --needed "${ESSENTIAL_PKGS[@]}"

# Install optional packages with pacman
if [ ${#selected_optional_pacman[@]} -ne 0 ]; then
    echo

    echo "Installing selected optional packages with pacman..."

    echo
    sleep 3
    sudo pacman -S --noconfirm --needed "${selected_optional_pacman[@]}"
fi

# Install selected optional packages with yay
if [ ${#selected_optional_yay[@]} -ne 0 ]; then
    echo

    echo "Installing selected optional packages with yay..."

    echo
    sleep 3
    yay -S --noconfirm --needed "${selected_optional_yay[@]}"
fi

# Enable selected services if they are installed
for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        echo

        echo "Enabling service: ${service}"

        echo
        sleep 3
        sudo systemctl enable "${service}.service"
    fi
done

# Set Plasma session as default if selected
if [[ " ${ESSENTIAL_PKGS[@]} ${selected_optional_pacman[@]} " =~ " plasma-meta " ]]; then
    echo

    echo "Setting Plasma session as default..."

    echo
    sleep 3
    sudo tee /etc/sddm.conf > /dev/null <<EOT
[Desktop]
Session=plasma.desktop
EOT
fi

echo

echo "Installing oh-my-zsh & oh-my-posh..."

echo
sleep 3
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mkdir -p ~/.local/bin
mkdir -p ~/.config/oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# List of files to copy to the home directory
FILES_TO_COPY=(
    ".zshrc"
    ".zsh-aliases"
    ".zsh-functions"
)

# Change default shell to zsh
chsh -s /usr/bin/zsh

# Copy files from the script directory to the home directory
echo

echo "Copying files from the script directory to the home directory..."

echo
sleep 3
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
for FILE in "${FILES_TO_COPY[@]}"; do
    if [ -f "$SCRIPT_DIR/assets/$FILE" ]; then
        cp "$SCRIPT_DIR/assets/$FILE" ~/
        # Set the proper permissions
        chmod 644 ~/"$FILE"
        echo "Copied and set permissions for $FILE"
    else
        echo "File $SCRIPT_DIR/assets/$FILE does not exist"
        sleep 3
    fi
done
cp $SCRIPT_DIR/assets/mytheme.omp.json ~/.config/oh-my-posh
# Reboot prompt
read -p "Installation complete. Do you want to reboot now? (y/n): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    clear
    echo

    echo

    echo "Installation complete. Don't forget to reboot your system!"

    echo
    sleep 3
fi
zsh
exit 0
