#!/bin/bash

# File containing the image path
IMAGE_FILE="$HOME/.cache/swww/eDP-1"

# Check if the file exists
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Error: $IMAGE_FILE does not exist. Please create the file and add the image path."
  exit 1
fi

# Read the image path from the file and remove hidden characters
# IMAGE_PATH=$(cat "$IMAGE_FILE" | tr -d '\n' | xargs)
IMAGE_PATH=$(grep "/home/*" $IMAGE_FILE)

# Debug: Print the image path
echo "Image path from file: '$IMAGE_PATH'"

# Check if the image path is valid
if [ ! -f "$IMAGE_PATH" ]; then
  echo "Error: The image path in $IMAGE_FILE is invalid or does not exist."
  exit 1
fi

# Escape special characters
ESCAPED_IMAGE_PATH=$(printf '%q' "$IMAGE_PATH")

# Debug: Print the escaped path
echo "Escaped image path: '$ESCAPED_IMAGE_PATH'"

# Generate Pywal colors
wal -i "$IMAGE_PATH"
# wallust run "$IMAGE_PATH" -s

# Create Ghostty theme
python3 <<EOF
import json
import os

# Load Pywal colors
with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
    colors = json.load(f)

special = colors.get('special', {})
fg = special.get('foreground', colors['colors'].get('color7', '#ffffff'))
bg = special.get('background', colors['colors'].get('color0', '#000000'))
cursor = special.get('cursor', fg)

# Create the theme
theme = f'''
foreground = {fg}
background = {bg}
cursor-color = {cursor}

palette = 0={colors['colors']['color0']}
palette = 1={colors['colors']['color1']}
palette = 2={colors['colors']['color2']}
palette = 3={colors['colors']['color3']}
palette = 4={colors['colors']['color4']}
palette = 5={colors['colors']['color5']}
palette = 6={colors['colors']['color6']}
palette = 7={colors['colors']['color7']}
palette = 8={colors['colors']['color8']}
palette = 9={colors['colors']['color9']}
palette = 10={colors['colors']['color10']}
palette = 11={colors['colors']['color11']}
palette = 12={colors['colors']['color12']}
palette = 13={colors['colors']['color13']}
palette = 14={colors['colors']['color14']}
palette = 15={colors['colors']['color15']}
'''

# Write the theme to the Ghostty themes directory
theme_path = os.path.expanduser("~/.config/ghostty/themes/pywal_ghostty")
os.makedirs(os.path.dirname(theme_path), exist_ok=True)

with open(theme_path, "w") as f:
    f.write(theme)
EOF


# # Ensure Ghostty config directory exists
# GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
# mkdir -p "$GHOSTTY_CONFIG_DIR"
#
# # Ensure Ghostty config file exists
# GHOSTTY_CONFIG_FILE="$GHOSTTY_CONFIG_DIR/config"
# if [ ! -f "$GHOSTTY_CONFIG_FILE" ]; then
#   echo 'theme = "pywal_ghostty"' > "$GHOSTTY_CONFIG_FILE"
# else
#   # Append theme if not already set
#   if ! grep -q 'theme = "pywal_ghostty"' "$GHOSTTY_CONFIG_FILE"; then
#     echo 'theme = "pywal_ghostty"' >> "$GHOSTTY_CONFIG_FILE"
#   fi
# fi

echo "Theme applied. Please restart Ghostty to see the changes."

# clear the terminal
clear
