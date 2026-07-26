#!/bin/bash

echo "Installing Warmth Slider..."

# Get the directory where this install.sh script is currently running from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Check and install required system dependencies (including xdotool)
if ! command -v redshift &> /dev/null || ! command -v xdotool &> /dev/null || ! python3 -c "import gi" &> /dev/null; then
    echo "Installing missing dependencies (redshift, xdotool, python3-gi, python3-cairo)..."
    sudo apt update && sudo apt install -y redshift xdotool python3-gi python3-cairo
fi

# 2. Create config directory and move files safely using absolute paths
CONFIG_DIR="$HOME/.config/warmth-slider"
mkdir -p "$CONFIG_DIR"

if [ -f "$DIR/warmth-slider.sh" ]; then
    cp "$DIR/warmth-slider.sh" "$CONFIG_DIR/warmth-slider.sh"
    chmod +x "$CONFIG_DIR/warmth-slider.sh"
else
    echo "Error: warmth-slider.sh not found!"
    exit 1
fi

if [ -f "$DIR/WarmRedshift.png" ]; then
    cp "$DIR/WarmRedshift.png" "$CONFIG_DIR/WarmRedshift.png"
else
    echo "Warning: WarmRedshift.png not found."
fi

# 3. Register auto-start / boot restoration
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat << EOF > "$AUTOSTART_DIR/warmth-slider.desktop"
[Desktop Entry]
Type=Application
Name=Warmth Slider Boot Restore
Exec=$CONFIG_DIR/warmth-slider.sh boot
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo "=================================================="
echo "Installation complete!"
echo "To use: Add a custom Application Launcher to your panel,"
echo "set the command to: bash -c '$CONFIG_DIR/warmth-slider.sh'"
echo "and choose your WarmRedshift.png icon!"
echo "=================================================="
