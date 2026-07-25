# Warmth Slider for Linux Mint / Xfce

A lightweight, native-feeling screen color temperature slider built using Python GTK3 and Redshift. Designed to match the look and feel of built-in system menus (like volume and brightness pop-ups).

## Features
* **Native GTK3 Interface:** Undecorated window that automatically inherits your desktop theme, fonts, and styling.
* **Intuitive Control:** Sliding right increases warmth smoothly from 0% to 100%.
* **Live Dynamic Toggle:** Switch on-the-fly between percentage view and exact Kelvin temperature (`6500K` down to `2000K`).
* **Persistent Memory:** Automatically restores your preferred screen warmth on system boot.
* **Optimized Performance:** Live visual updates during drag, writing safely to disk only on release to prevent lag.

## Requirements
* `redshift`
* `python3` with `python3-gi` (PyGObject)

## Installation

Open your terminal and run:


`git clone https://github.com/AaMoh18/redshift-xfce-slider.git` 

` cd redshift-xfce-slider` 

` chmod +x install.sh` 

` ./install.sh` 


## Usage
After installation, right-click your Xfce panel, choose **Add New Items**, select **Launcher**, and click **Add new empty item**. Edit the launcher and set:
* **Name:** Redshift slider
* **Command:** `bash -c "$HOME/.config/warmth-slider/warmth-slider.sh"`
* **Icon:** Select your custom `WarmRedshift.png` icon.
