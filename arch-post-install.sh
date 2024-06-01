#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root. Run it as a regular user."
    exit 1
fi

   #--improve compression of AUR packages--#
sudo sed -i 's/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/# COMPRESSZST=(zstd -c -T0 --ultra -20 -)/g' /etc/makepkg.conf

# Update the system and install required packages with sudo
echo "Updating the system and installing required packages..."
sudo pacman -Syu --noconfirm --needed base-devel git dialog

# List of packages to install via pacman
PKGS_PACMAN=(
        linux-headers
        alsa-utils
        arandr
        archlinux-contrib
        ark
        bleachbit
        bluedevil
        breeze-gtk
        breeze-plymouth
        chezmoi
        chromium              
        code
        deluge-gtk
        discover
        dolphin
        dolphin-plugins
        drkonqi
        expac
        eza
        fastfetch
        firefox             
        gimp
        gnome-keyring                   
        gparted
        grub-customizer
        gufw                  
        gwenview
        inkscape
        intel-ucode
        kate
        kbackup
        kcolorchooser
        kde-gtk-config
        kdeplasma-addons
        keepassxc
        kgamma
        kinfocenter
        kio-admin
        kompare
        konsole
        kscreen
        ksshaskpass
        ksystemlog
        kvantum
        kvantum-qt5
        kwallet-pam
        kwrited
        linssid
        lsb-release
        man-db
        man-pages
        marker
        mc
        nano
        ocean-sound-theme
        okular
        openssh 
        oxygen
        oxygen-sounds
        packagekit-qt6
        pacmanlogviewer              
        papirus-icon-theme
        partitionmanager
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
        plasma-wayland-protocols
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
        virtualbox
        vlc
        wget
        xdg-desktop-portal-kde
        zram-generator                   
)

# List of packages to install via yay
PKGS_YAY=(
        brave-bin
        caffeine-ng    
        catppuccin-gtk-theme-mocha
        catppuccin-konsole-theme-git
        downgrade
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

# Generate dialog options for pacman (default ON) and yay (default OFF) packages
pacman_options=$(generate_dialog_options "on" "${PKGS_PACMAN[@]}")
yay_options=$(generate_dialog_options "off" "${PKGS_YAY[@]}")

# Ask user which packages to install via pacman using dialog
selected_pacman=$(dialog --separate-output --checklist "Select packages to install via pacman" 20 78 15 ${pacman_options} 3>&1 1>&2 2>&3)
clear

# Display a warning message about yay packages
dialog --msgbox "Warning: Installing packages from the AUR can take time to build. Please choose carefully which packages to install." 10 60
clear

# Ask user which packages to install via yay using dialog
selected_yay=$(dialog --separate-output --checklist "Select packages to install via yay" 20 78 15 ${yay_options} 3>&1 1>&2 2>&3)
clear

# Convert selected packages from dialog output
selected_pacman=($(echo $selected_pacman | sed 's/"//g'))
selected_yay=($(echo $selected_yay | sed 's/"//g'))

# Debug output to verify selections
echo "Selected pacman packages: ${selected_pacman[@]}"
echo "Selected yay packages: ${selected_yay[@]}"

# Install yay if it is not already installed
if ! command -v yay &> /dev/null; then
    echo "yay not found, installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay is already installed"
fi

# Install selected packages with pacman
if [ ${#selected_pacman[@]} -ne 0 ]; then
    echo "Installing selected packages with pacman..."
    sudo pacman -S --noconfirm --needed "${selected_pacman[@]}"
fi
    sudo pacman -S --needed --noconfirm atuin bat zsh zsh-completions zsh-syntax-highlighting

# Install selected packages with yay
if [ ${#selected_yay[@]} -ne 0 ]; then
    echo "Installing selected packages with yay..."
    yay -S --noconfirm --needed "${selected_yay[@]}"
fi

# Enable selected services if they are installed
for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        echo "Enabling service: ${service}"
        sudo systemctl enable "${service}.service"
    fi
done

# Set Plasma session as default if selected
if [[ " ${selected_pacman[@]} " =~ " plasma-meta " ]]; then
    echo "Setting Plasma session as default..."
    sudo tee /etc/sddm.conf > /dev/null <<EOT
[Desktop]
Session=plasma.desktop
EOT
fi

# List of files to copy to the home directory
FILES_TO_COPY=(
    ".zshrc"
    ".zsh-aliases"
    ".zsh-functions"
)

# Change default shell to zsh
    chsh -s /usr/bin/zsh
    
# Copy files from the script directory to the home directory
echo "Copying files from the script directory to the home directory..."
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
for FILE in "${FILES_TO_COPY[@]}"; do
    if [ -f "$SCRIPT_DIR/assets/$FILE" ]; then
        cp "$SCRIPT_DIR/assets/$FILE" ~/
        # Set the proper permissions
        chmod 644 ~/"$FILE"
        echo "Copied and set permissions for $FILE"
    else
        echo "File $SCRIPT_DIR/assets/$FILE does not exist"
    fi
done

# Reboot prompt
read -p "Installation complete. Do you want to reboot now? (y/n): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    clear
    echo
    echo
    echo "Installation complete. Don't forget to reboot your system!"
fi
zsh
exit 0

