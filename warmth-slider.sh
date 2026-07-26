#!/bin/bash

SAVE_FILE="$HOME/.config/warmth-slider/saved_warmth_val"
CONFIG_DIR="$HOME/.config/warmth-slider"

# Restore previous temperature setting on boot
if [ "$1" == "boot" ]; then
    if [ -f "$SAVE_FILE" ]; then
        VAL=$(cat "$SAVE_FILE")
        if [ "$VAL" -lt 6500 ]; then
            redshift -P -O "$VAL"
        else
            redshift -x
        fi
    fi
    exit 0
fi

CURRENT=$(cat "$SAVE_FILE" 2>/dev/null || echo 6500)

# Handle percentage syntax: relative (+5%, -5%) or absolute (50%)
if [[ "$1" =~ ^([+-]?)([0-9]+)%$ ]]; then
    SIGN="${BASH_REMATCH[1]}"
    VAL_PCT="${BASH_REMATCH[2]}"
    
    if [ -n "$SIGN" ]; then
        # Relative adjustment: 1% = 45 Kelvin
        # +5% increases warmth (subtracts Kelvin), -5% decreases warmth (adds Kelvin)
        DELTA=$(( VAL_PCT * 45 ))
        if [ "$SIGN" == "+" ]; then
            VAL=$(( CURRENT - DELTA ))
        else
            VAL=$(( CURRENT + DELTA ))
        fi
    else
        # Absolute adjustment: e.g., passing "50%" jumps directly to 50% warmth
        VAL=$(( 6500 - (VAL_PCT * 45) ))
    fi

    # Clamp safety limits between 2000K (100% warmth) and 6500K (0% warmth)
    [ "$VAL" -lt 2000 ] && VAL=2000
    [ "$VAL" -gt 6500 ] && VAL=6500
    
    echo "$VAL" > "$SAVE_FILE"
    
    if [ "$VAL" -ge 6500 ]; then
        redshift -x 2>/dev/null
    else
        redshift -P -O "$VAL" 2>/dev/null
    fi
    exit 0
fi

python3 - "$SAVE_FILE" "$CURRENT" << 'EOF'
import os, sys, subprocess
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

save_file = sys.argv[1]
try:
    current_kelvin = int(sys.argv[2])
except ValueError:
    current_kelvin = 6500

# Map 6500K-2000K range to a 0-100% scale
current_pct = max(0, min(100, int((6500 - current_kelvin) / 45)))

class WarmthWindow(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_border_width(10)
        self.set_default_size(250, -1)
        self.set_position(Gtk.WindowPosition.MOUSE)
        
        # Close when losing focus or pressing Escape
        self.connect("focus-out-event", lambda w, e: Gtk.main_quit())
        self.connect("key-press-event", self.on_key)
        
# Main layout is a vertical stack from top to bottom
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)
        
        # --- TOP ROW: Icon spacer + Bold Title (Auto-aligned!) ---
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        
        # Create an invisible placeholder box that matches the exact width of your icon
        # This automatically forces the "Warmth" label to align with the slider below it.
        spacer = Gtk.Box()
        spacer.set_size_request(32, -1)  # Matches LARGE_TOOLBAR icon width (~32px)
        title_box.pack_start(spacer, False, False, 0)
        
        label = Gtk.Label()
        label.set_markup("<b>Warmth</b>")
        label.set_xalign(0)
        title_box.pack_start(label, True, True, 0)
        
        vbox.pack_start(title_box, False, False, 0)
        
        # --- SECOND ROW: Icon + Slider ---
        slider_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        
        icon_theme = Gtk.IconTheme.get_default()
        image = Gtk.Image()
        for icon_name in ["redshift", "gammastep", "preferences-desktop-display"]:
            if icon_theme.has_icon(icon_name):
                image.set_from_icon_name(icon_name, Gtk.IconSize.LARGE_TOOLBAR)
                image.set_valign(Gtk.Align.START)
                slider_box.pack_start(image, False, False, 0)
                break
                
        # Slider setup
        adj = Gtk.Adjustment(value=current_pct, lower=0, upper=100, step_increment=1, page_increment=10)
        self.scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=adj)
        
        self.scale.set_digits(0)
        self.scale.set_draw_value(True)
        self.scale.set_value_pos(Gtk.PositionType.BOTTOM)
        
        self.show_kelvin = False
        self.scale.connect("format-value", self.format_scale_value)
        self.scale.connect("value-changed", self.on_change)
        self.scale.connect("button-release-event", self.on_release)
        self.scale.connect("key-release-event", self.on_release)
        
        slider_box.pack_start(self.scale, True, True, 0)
        vbox.pack_start(slider_box, True, True, 0)
        
        # Toggle switch row at the bottom
        switch_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        switch_label = Gtk.Label(label="Show warmth value (Kelvin)")
        switch_label.set_xalign(0)
        
        self.toggle_switch = Gtk.Switch()
        self.toggle_switch.set_active(False)
        self.toggle_switch.connect("notify::active", self.on_switch_toggled)
        
        switch_box.pack_start(switch_label, True, True, 0)
        switch_box.pack_end(self.toggle_switch, False, False, 0)
        vbox.pack_start(switch_box, False, False, 4)
        
    def format_scale_value(self, scale, val):
        pct = int(val)
        if self.show_kelvin:
            return f"{6500 - (pct * 45)}K"
        return f"{pct}%"

    def on_switch_toggled(self, switch, gparam):
        self.show_kelvin = switch.get_active()
        self.scale.queue_draw()

    def on_change(self, scale):
        # Instant visual screen preview during drag (avoids file I/O lag)
        pct = int(scale.get_value())
        kelvin = 6500 - (pct * 45)
            
        if kelvin >= 6500 or pct == 0:
            subprocess.run(["redshift", "-x"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.run(["redshift", "-P", "-O", str(kelvin)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def on_release(self, widget, event):
        # Writes to disk ONLY once when mouse click or key release finishes
        pct = int(self.scale.get_value())
        kelvin = 6500 - (pct * 45)
        
        try:
            with open(save_file, "w") as f:
                f.write(str(kelvin))
        except Exception:
            pass
        return False

    def on_key(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

win = WarmthWindow()
win.show_all()

win.on_change(win.scale)

Gtk.main()
EOF
