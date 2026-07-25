#!/bin/bash

echo "Installing Warmth Slider..."

# 1. Check and install required system dependencies
if ! command -v redshift &> /dev/null || ! python3 -c "import gi" &> /dev/null; then
    echo "Installing missing dependencies (redshift and python3-gi)..."
    sudo apt update && sudo apt install -y redshift python3-gi python3-cairo
fi

# 2. Create config directory and move files
CONFIG_DIR="$HOME/.config/warmth-slider"
mkdir -p "$CONFIG_DIR"

if [ -f "warmth-slider.sh" ]; then
    cp warmth-slider.sh "$CONFIG_DIR/warmth-slider.sh"
    chmod +x "$CONFIG_DIR/warmth-slider.sh"
else
    echo "Error: warmth-slider.sh not found in current directory!"
    exit 1
fi

if [ -f "WarmRedshift.png" ]; then
    cp WarmRedshift.png "$CONFIG_DIR/WarmRedshift.png"
else
    echo "Warning: WarmRedshift.png not found. You can add it manually later."
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
echo "set the command to: $CONFIG_DIR/warmth-slider.sh"
echo "and choose your WarmRedshift.png icon!"
echo "=================================================="#!/bin/bash

echo "Installing Warmth Slider..."

# 1. Check and install required system dependencies
if ! command -v redshift &> /dev/null || ! python3 -c "import gi" &> /dev/null; then
    echo "Installing missing dependencies (redshift and python3-gi)..."
    sudo apt update && sudo apt install -y redshift python3-gi python3-cairo
fi

# 2. Create config directory and move files
CONFIG_DIR="$HOME/.config/warmth-slider"
mkdir -p "$CONFIG_DIR"

if [ -f "warmth-slider.sh" ]; then
    cp warmth-slider.sh "$CONFIG_DIR/warmth-slider.sh"
    chmod +x "$CONFIG_DIR/warmth-slider.sh"
else
    echo "Error: warmth-slider.sh not found in current directory!"
    exit 1
fi

if [ -f "WarmRedshift.png" ]; then
    cp WarmRedshift.png "$CONFIG_DIR/WarmRedshift.png"
else
    echo "Warning: WarmRedshift.png not found. You can add it manually later."
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
echo "set the command to: $CONFIG_DIR/warmth-slider.sh"
echo "and choose your WarmRedshift.png icon!"
echo "=================================================="
