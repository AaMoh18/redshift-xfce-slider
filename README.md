# Warmth Slider for Linux Mint / Xfce

A lightweight, native-feeling screen color temperature slider built using Python GTK3 and Redshift. Designed to match the look and feel of built-in system menus (like volume and brightness pop-ups).

## Features
* **Native GTK3 Interface:** Undecorated window that automatically inherits your desktop theme, fonts, and styling.
* **Smart Cursor Positioning:** Instantly pops up right where your mouse cursor clicked on the panel (powered by `xdotool`).
* **Intuitive Control:** Sliding right increases warmth smoothly from 0% to 100%.
* **Live Dynamic Toggle:** Switch on-the-fly between percentage view and exact Kelvin temperature (`6500K` down to `2000K`).
* **Persistent Memory:** Automatically restores your preferred screen warmth on system boot.
* **Optimized Performance:** Debounced live updates during drag prevent process thrashing, writing safely to disk only on release.

## Requirements
* `redshift`
* `xdotool` (required for cursor-aware window positioning)
* `python3` with `python3-gi` (PyGObject)

## Installation

Open your terminal and run:

```bash
git clone [https://github.com/AaMoh18/redshift-xfce-slider.git]
cd redshift-xfce-slider
chmod +x install.sh
./install.sh
```
(This automatically installs dependencies, configures boot-restore, and registers Warmth Slider as a system application).

## Usage
After installation, Warmth Slider is registered in your system applications. You can add it to your panel easily:
* Right-click your Xfce panel and choose Add New Items.
* Select Launcher and click Add.
* Click the folder/plus icon in the launcher settings to browse installed applications, select Warmth Slider, and click Add.


## Autostart on Login (Optional)
The install.sh script automatically handles boot restoration. If you ever need to set it up manually with a custom startup delay, run this command:


  ```bash
mkdir -p ~/.config/autostart && echo -e "[Desktop Entry]\nType=Application\nName=Warmth Slider Boot\nExec=bash -c 'sleep 4 && \"$HOME/.config/warmth-slider/warmth-slider.sh\" boot'\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true" > ~/.config/autostart/warmth-slider.desktop
```
(If it triggers too early, you can adjust the sleep 4 delay value).

## Keyboard Shortcuts (Optional)
You can assign global keyboard shortcuts to adjust your screen warmth instantly without needing to open the slider window.

1. Open **Settings Manager** > **Keyboard** > **Application Shortcuts**.
2. Click **Add** and paste any of the following commands:

* **Increase Warmth (+5%):**
  ```bash
  bash -c "$HOME/.config/warmth-slider/warmth-slider.sh +5%"
  
* **Decrease Warmth (-5%):**
  ```bash
  bash -c "$HOME/.config/warmth-slider/warmth-slider.sh -5%"

* **Reset to Normal (0%):**
  ```bash
  bash -c "$HOME/.config/warmth-slider/warmth-slider.sh 0%"
