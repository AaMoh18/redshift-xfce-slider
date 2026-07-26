#!/bin/bash

MIN_KELVIN=2000
MAX_KELVIN=6500
STEPS=100
STEP_SIZE=$(( (MAX_KELVIN - MIN_KELVIN) / STEPS ))

SAVE_FILE="$HOME/.config/warmth-slider/saved_warmth_val"
CONFIG_DIR="$HOME/.config/warmth-slider"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Restore previous temperature setting on boot
if [ "$1" == "boot" ]; then
    if [ -f "$SAVE_FILE" ]; then
        VAL=$(cat "$SAVE_FILE")
        if [ "$VAL" -lt "$MAX_KELVIN" ]; then
            redshift -P -O "$VAL"
        else
            redshift -x
        fi
    fi
    exit 0
fi

CURRENT=$(cat "$SAVE_FILE" 2>/dev/null || echo "$MAX_KELVIN")

# Handle percentage syntax: relative (+5%, -5%) or absolute (50%)
if [[ "$1" =~ ^([+-]?)([0-9]+)%$ ]]; then
    SIGN="${BASH_REMATCH[1]}"
    VAL_PCT="${BASH_REMATCH[2]}"
    
    if [ -n "$SIGN" ]; then
        DELTA=$(( VAL_PCT * STEP_SIZE ))
        if [ "$SIGN" == "+" ]; then
            VAL=$(( CURRENT - DELTA ))
        else
            VAL=$(( CURRENT + DELTA ))
        fi
    else
        VAL=$(( MAX_KELVIN - (VAL_PCT * STEP_SIZE) ))
    fi

    [ "$VAL" -lt "$MIN_KELVIN" ] && VAL="$MIN_KELVIN"
    [ "$VAL" -gt "$MAX_KELVIN" ] && VAL="$MAX_KELVIN"
    
    echo "$VAL" > "$SAVE_FILE"
    
    if [ "$VAL" -ge "$MAX_KELVIN" ]; then
        redshift -x 2>/dev/null
    else
        redshift -P -O "$VAL" 2>/dev/null
    fi
    exit 0
fi

# Re-apply saved warmth in the background ONLY when opening the GUI window
if [ "$CURRENT" -lt "$MAX_KELVIN" ]; then
    redshift -P -O "$CURRENT" 2>/dev/null &
else
    redshift -x 2>/dev/null &
fi

# --- INSTANTLY CAPTURE MOUSE COORDS IN BASH AT T=0ms ---
if command -v xdotool &> /dev/null; then
    eval $(xdotool getmouselocation --shell 2>/dev/null)
    MOUSE_X=${X:-500}
    MOUSE_Y=${Y:-500}
else
    MOUSE_X=500
    MOUSE_Y=800
fi

python3 - "$SAVE_FILE" "$CURRENT" "$MOUSE_X" "$MOUSE_Y" "$MIN_KELVIN" "$MAX_KELVIN" << 'EOF'
import os, sys, subprocess
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

save_file = sys.argv[1]
try:
    current_kelvin = int(sys.argv[2])
except ValueError:
    current_kelvin = 6500

try:
    mouse_x = int(sys.argv[3])
    mouse_y = int(sys.argv[4])
except (IndexError, ValueError):
    mouse_x, mouse_y = 500, 500

try:
    min_kelvin = int(sys.argv[5])
    max_kelvin = int(sys.argv[6])
except (IndexError, ValueError):
    min_kelvin, max_kelvin = 2000, 6500

step_size = (max_kelvin - min_kelvin) / 100.0

# Map range to 0-100% scale
current_pct = max(0, min(100, int((max_kelvin - current_kelvin) / step_size)))

class WarmthWindow(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_border_width(10)
        self.set_default_size(250, -1)
        
        self.move(mouse_x - 125, mouse_y - 130)
        
        self.connect("focus-out-event", lambda w, e: Gtk.main_quit())
        self.connect("key-press-event", self.on_key)
        
        self.timeout_id = None
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)
        
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        spacer = Gtk.Box()
        spacer.set_size_request(32, -1)
        title_box.pack_start(spacer, False, False, 0)
        
        label = Gtk.Label()
        label.set_markup("<b>Warmth</b>")
        label.set_xalign(0)
        title_box.pack_start(label, True, True, 0)
        vbox.pack_start(title_box, False, False, 0)
        
        slider_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        icon_theme = Gtk.IconTheme.get_default()
        image = Gtk.Image()
        for icon_name in ["redshift", "gammastep", "preferences-desktop-display"]:
            if icon_theme.has_icon(icon_name):
                image.set_from_icon_name(icon_name, Gtk.IconSize.LARGE_TOOLBAR)
                image.set_valign(Gtk.Align.START)
                slider_box.pack_start(image, False, False, 0)
                break
                
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
            kelv = int(max_kelvin - (pct * step_size))
            return f"{kelv}K"
        return f"{pct}%"

    def on_switch_toggled(self, switch, gparam):
        self.show_kelvin = switch.get_active()
        self.scale.queue_draw()

    def apply_redshift(self, kelvin):
        self.timeout_id = None
        if kelvin >= max_kelvin:
            subprocess.run(["redshift", "-x"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.run(["redshift", "-P", "-O", str(kelvin)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return False

    def on_change(self, scale):
        pct = int(scale.get_value())
        kelvin = int(max_kelvin - (pct * step_size))
        
        # Debounce redshift calls during fast dragging to prevent process thrashing
        if self.timeout_id is not None:
            GLib.source_remove(self.timeout_id)
        
        self.timeout_id = GLib.timeout_add(35, lambda: self.apply_redshift(kelvin))

    def on_release(self, widget, event):
        # Clear any pending debounced call and apply immediately on release
        if self.timeout_id is not None:
            GLib.source_remove(self.timeout_id)
            self.timeout_id = None
            
        pct = int(self.scale.get_value())
        kelvin = int(max_kelvin - (pct * step_size))
        
        if kelvin >= max_kelvin:
            subprocess.run(["redshift", "-x"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.run(["redshift", "-P", "-O", str(kelvin)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

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

Gtk.main()
EOF
