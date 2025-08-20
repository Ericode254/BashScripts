#!/bin/bash

# Function to check and install a dependency if it's missing
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 not found. Installing..."
        sudo pacman -Sy "$2" --noconfirm
    else
        echo "$1 is already installed."
    fi
}

# Check dependencies
check_dependency yt-dlp yt-dlp
check_dependency mpv mpv
check_dependency fzf fzf
check_dependency notify-send libnotify
check_dependency pv pv

# Check if a query was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <Search Query>"
    exit 1
fi

# Optimized Search: Only fetch video titles and IDs, limit to 10 results
echo "Searching YouTube for: $1"
VIDEOS=$(yt-dlp "ytsearch10:$1" --quiet --no-warnings --print "%(id)s - %(title)s" --compat-options youtube-dl)

# Use fzf to select a video
SELECTED=$(echo "$VIDEOS" | fzf --prompt="Select a video to play/download: " --height=15 --border)

# Extract the video ID and title from the selection
VIDEO_ID=$(echo "$SELECTED" | cut -d ' ' -f 1)
VIDEO_TITLE=$(echo "$SELECTED" | cut -d '-' -f 2- | xargs)
VIDEO_URL="https://www.youtube.com/watch?v=$VIDEO_ID"

if [ -z "$VIDEO_ID" ]; then
    echo "No video selected. Exiting..."
    exit 1
fi

# Prompt the user to choose an action: Play or Download
ACTION=$(echo -e "Play\nDownload" | fzf --prompt="Choose an action for '$VIDEO_TITLE': " --height=5 --border)

if [ "$ACTION" == "Play" ]; then
    echo "Playing video: $VIDEO_TITLE"
    notify-send "Playing video" "$VIDEO_TITLE"
    mpv "$VIDEO_URL"
elif [ "$ACTION" == "Download" ]; then
    # Ask the user to choose video or audio format
    FORMAT=$(echo -e "Video\nAudio" | fzf --prompt="Choose a format to download: " --height=5 --border)

    if [ "$FORMAT" == "Audio" ]; then
        YTDLP_FORMAT="bestaudio"
        FILE_TYPE="Audio"
    elif [ "$FORMAT" == "Video" ]; then
        YTDLP_FORMAT="bestvideo+bestaudio"
        FILE_TYPE="Video"
    else
        echo "Invalid format selected. Exiting..."
        exit 1
    fi

    echo "$FILE_TYPE download started for: $VIDEO_TITLE"
    NOTIFY_ID=9999
    notify-send -u low -r "$NOTIFY_ID" "$FILE_TYPE Download Started" "Downloading $VIDEO_TITLE"

    # Start download with yt-dlp
    yt-dlp -f "$YTDLP_FORMAT" --downloader aria2c --downloader-args '-c -j 8 -x 16 -s 16 -k 1M' "$VIDEO_URL" \
    | pv --line-mode --rate \
    | while read -r line; do
        notify-send -u low -r "$NOTIFY_ID" "Download in progress" "$line"
    done

    notify-send -u low -r "$NOTIFY_ID" "$FILE_TYPE Download Complete" "$FILE_TYPE downloaded for $VIDEO_TITLE"
else
    echo "Invalid action selected. Exiting..."
    exit 1
fi

