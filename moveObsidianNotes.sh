#!/bin/bash

# Define the source and destination directories
SOURCE_DIR="$HOME/vaults/personal/Notes/"      # Change this to your Notes directory
DEST_DIR="$HOME/vaults/personal/CodesNotes"   # Change this to your CodesNotes directory

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Loop through each file in the source directory
for file in "$SOURCE_DIR"/*; do
    # Check if it is a file
    if [ -f "$file" ]; then
        # Prompt the user for confirmation
        read -p "Do you want to move the file $(basename "$file") to CodesNotes? (y/n): " choice
        case "$choice" in
            [Yy]* )
                mv "$file" "$DEST_DIR"
                echo "Moved $(basename "$file") to CodesNotes."
                ;;
            [Nn]* )
                echo "Skipped $(basename "$file")."
                ;;
            * )
                echo "Invalid choice. Please enter y or n."
                ;;
        esac
    fi
done

echo "Operation completed."
