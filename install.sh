#!/bin/bash

# Exit on error
set -e

# Visual logging helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$*"
}

error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*"
}

success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"
}

prompt_yes_no() {
    local question="$1"
    local default="${2:-Y}"
    local prompt_str
    if [[ "$default" == "Y" ]]; then
        prompt_str="[Y/n]"
    else
        prompt_str="[y/N]"
    fi
    
    read -rp "$(printf "${YELLOW}%s${NC} %s " "$question" "$prompt_str")" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            [[ "$default" == "Y" ]] && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Determine script and repository locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG_DIR="$SCRIPT_DIR/config"
TARGET_CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
BACKUP_CREATED=false

# 1. Package Installation (Arch Linux specific)
if [ -f "/etc/arch-release" ]; then
    info "Arch Linux detected. Verifying packages..."
    
    # Check native packages
    if [ -f "$SCRIPT_DIR/packages.txt" ]; then
        missing_native=()
        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            # Remove comments and whitespace
            pkg=$(echo "$pkg" | sed -e 's/#.*//' -e 's/[[:space:]]//g')
            [[ -z "$pkg" ]] && continue
            if ! pacman -Qq "$pkg" &>/dev/null; then
                missing_native+=("$pkg")
            fi
        done < "$SCRIPT_DIR/packages.txt"
        
        if [ ${#missing_native[@]} -gt 0 ]; then
            warn "Missing native packages: ${missing_native[*]}"
            if prompt_yes_no "Would you like to install missing native packages?"; then
                sudo pacman -S --needed --noconfirm "${missing_native[@]}"
            fi
        else
            success "All native packages are already installed."
        fi
    fi

    # Check AUR packages
    if [ -f "$SCRIPT_DIR/packages.aur.txt" ]; then
        missing_aur=()
        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            pkg=$(echo "$pkg" | sed -e 's/#.*//' -e 's/[[:space:]]//g')
            [[ -z "$pkg" ]] && continue
            # Skip checking 'antigravity-cli' or the AUR helper itself to avoid bootstrap loops
            if [[ "$pkg" == "antigravity-cli" || "$pkg" == "yay" || "$pkg" == "paru" ]]; then
                continue
            fi
            if ! pacman -Qq "$pkg" &>/dev/null; then
                missing_aur+=("$pkg")
            fi
        done < "$SCRIPT_DIR/packages.aur.txt"
        
        if [ ${#missing_aur[@]} -gt 0 ]; then
            warn "Missing AUR packages: ${missing_aur[*]}"
            if prompt_yes_no "Would you like to install missing AUR packages?"; then
                # Find AUR helper
                AUR_HELPER=""
                if command -v yay &>/dev/null; then
                    AUR_HELPER="yay"
                elif command -v paru &>/dev/null; then
                    AUR_HELPER="paru"
                fi
                
                if [ -n "$AUR_HELPER" ]; then
                    $AUR_HELPER -S --needed --noconfirm "${missing_aur[@]}"
                else
                    error "No AUR helper (yay or paru) found. Please install them manually: ${missing_aur[*]}"
                fi
            fi
        else
            success "All AUR packages are already installed."
        fi
    fi
else
    warn "Non-Arch Linux system or /etc/arch-release not found. Skipping package verification."
fi

# Ensure target configuration directory exists
mkdir -p "$TARGET_CONFIG_DIR"

backup_item() {
    local item_path="$1"
    local dest_subpath="$2"
    
    if [ -e "$item_path" ] || [ -L "$item_path" ]; then
        # Check if it is already a symlink pointing to our repository config
        local link_target
        if [ -L "$item_path" ]; then
            link_target=$(readlink -f "$item_path")
            if [[ "$link_target" == "$REPO_CONFIG_DIR"* ]]; then
                info "Already symlinked to repository: $(basename "$item_path")"
                return 0
            fi
        fi
        
        # We need to back it up
        if [ "$BACKUP_CREATED" = false ]; then
            info "Creating backup directory at $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
            BACKUP_CREATED=true
        fi
        
        local backup_dest="$BACKUP_DIR/$dest_subpath"
        mkdir -p "$(dirname "$backup_dest")"
        info "Backing up: $item_path -> $backup_dest"
        mv "$item_path" "$backup_dest"
    fi
}

# 2. Link Configuration Directories & Files
configs_to_link=(
    "cava"
    "fish"
    "gtk-3.0"
    "gtk-4.0"
    "hypr"
    "kitty"
    "rofi"
    "starship.toml"
    "swaync"
    "waybar"
)

info "Installing configuration symlinks..."

for config_name in "${configs_to_link[@]}"; do
    src_path="$REPO_CONFIG_DIR/$config_name"
    target_path="$TARGET_CONFIG_DIR/$config_name"
    
    if [ -e "$src_path" ]; then
        backup_item "$target_path" "$config_name"
        
        # Create symlink (use -sf and -n to avoid nesting directories if target is already a symlink/dir)
        info "Linking: $target_path -> $src_path"
        ln -sfn "$src_path" "$target_path"
    else
        warn "Source path not found in repository: config/$config_name"
    fi
done

# 3. Special case: VSCodium settings.json
vscodium_src="$REPO_CONFIG_DIR/VSCodium/User/settings.json"
vscodium_target_dir="$TARGET_CONFIG_DIR/VSCodium/User"
vscodium_target_file="$vscodium_target_dir/settings.json"

if [ -f "$vscodium_src" ]; then
    mkdir -p "$vscodium_target_dir"
    backup_item "$vscodium_target_file" "VSCodium/User/settings.json"
    
    info "Linking VSCodium settings.json"
    ln -sf "$vscodium_src" "$vscodium_target_file"
fi

# 4. Link Wallpapers
wallpaper_src="$SCRIPT_DIR/wallpapers"
wallpaper_target="$HOME/Pictures/Wallpapers"

if [ -d "$wallpaper_src" ]; then
    info "Installing wallpapers..."
    mkdir -p "$(dirname "$wallpaper_target")"
    backup_item "$wallpaper_target" "Pictures/Wallpapers"
    
    info "Linking: $wallpaper_target -> $wallpaper_src"
    ln -sfn "$wallpaper_src" "$wallpaper_target"
fi

# 5. LibreWolf Configuration & Extensions
if command -v librewolf &>/dev/null; then
    info "Configuring LibreWolf (Search, Cookies, Extensions, gwfox Theme)..."
    
    # 5.1 System-wide policies.json
    LIBREWOLF_DIST_DIR="/usr/lib/librewolf/distribution"
    if [ -f "$REPO_CONFIG_DIR/librewolf/policies.json" ]; then
        sudo mkdir -p "$LIBREWOLF_DIST_DIR"
        sudo cp "$REPO_CONFIG_DIR/librewolf/policies.json" "$LIBREWOLF_DIST_DIR/policies.json"
        success "LibreWolf policies installed."
    fi

    # 5.2 System-wide overrides
    if [ -f "$REPO_CONFIG_DIR/librewolf/librewolf.overrides.cfg" ]; then
        sudo cp "$REPO_CONFIG_DIR/librewolf/librewolf.overrides.cfg" "/usr/lib/librewolf/librewolf.overrides.cfg"
        success "LibreWolf system overrides installed."
    fi

    # 5.3 Integrated gwfox theme and profile setup (Ultimate Shotgun)
    info "Deploying gwfox theme to all profiles..."
    
    REPO_URL="https://github.com/akkva/gwfox"
    TEMP_DIR="/tmp/gwfox_theme"
    rm -rf "$TEMP_DIR"
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &>/dev/null

    BASE_DIRS=( "$HOME/.librewolf" "$HOME/.config/librewolf/librewolf" )
    
    for base in "${BASE_DIRS[@]}"; do
        if [ -d "$base" ]; then
            # Find EVERY profile (any dir with prefs.js)
            while IFS= read -r prefs_file; do
                pdir=$(dirname "$prefs_file")
                info "  -> Applying gwfox to: $pdir"
                mkdir -p "$pdir/chrome"
                cp "$TEMP_DIR/userChrome.css" "$pdir/chrome/"
                cp "$TEMP_DIR/userContent.css" "$pdir/chrome/"
                
                # Activate theme, dark mode, and persistence in this profile
                cat >> "$pdir/user.js" <<EOF
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.newtabpage.activity-stream.nova.enabled", false);
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
user_pref("layout.css.color-mix.enabled", true);
user_pref("browser.search.defaultenginename", "Google");
user_pref("browser.search.selectedEngine", "Google");
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("network.cookie.lifetimePolicy", 0);
user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.fingerprintingProtection.overrides", "+AllTargets,-CSSPrefersColorScheme");
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 2);
user_pref("browser.in-content.dark-mode", true);
user_pref("browser.theme.content-theme", 2);
user_pref("browser.theme.toolbar-theme", 2);
user_pref("devtools.theme", "dark");
EOF
            done < <(find "$base" -name "prefs.js")

            # Global/Directory level overrides (Strongest)
            cat > "$base/librewolf.overrides.cfg" <<EOF
defaultPref("privacy.clearOnShutdown.cookies", false);
defaultPref("privacy.sanitize.sanitizeOnShutdown", false);
defaultPref("network.cookie.lifetimePolicy", 0);
defaultPref("browser.search.defaultenginename", "Google");
defaultPref("browser.search.selectedEngine", "Google");
defaultPref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
defaultPref("svg.context-properties.content.enabled", true);
defaultPref("widget.gtk.rounded-bottom-corners.enabled", true);
defaultPref("privacy.resistFingerprinting", false);
defaultPref("ui.systemUsesDarkTheme", 1);
defaultPref("layout.css.prefers-color-scheme.content-override", 2);
defaultPref("browser.in-content.dark-mode", true);
defaultPref("browser.theme.content-theme", 2);
defaultPref("browser.theme.toolbar-theme", 2);
defaultPref("devtools.theme", "dark");
EOF
        fi
    done
    success "gwfox theme and persistence applied."
fi

# 6. Set Fish as default shell
if [[ "$SHELL" != *"/fish" ]]; then
    if command -v fish &>/dev/null; then
        if prompt_yes_no "Would you like to set Fish as your default shell?"; then
            info "Changing default shell to Fish..."
            chsh -s "$(command -v fish)"
            success "Default shell changed to Fish. (Please log out and log back in for this to take effect)"
        fi
    fi
fi

success "Dotfiles installation and symlinking complete!"
if [ "$BACKUP_CREATED" = true ]; then
    info "Your old configurations have been backed up to: $BACKUP_DIR"
fi
