#!/usr/bin/env bash

# -------------------------
# Pomodoro Configuration
# -------------------------
declare -A pomo_options=(
  [work]=50
  [break]=15
)

# Temporary / state files
POMO_STATE="$HOME/.local/state/pomodoro/state"
mkdir -p "$(dirname "$POMO_STATE")"

# -------------------------
# State variables
# -------------------------
paused=0
current_session=""
remaining_sec=0

# -------------------------
# Cleanup function
# -------------------------
cleanup_pomodoro() {
  # Restore cursor and clear state
  printf "\033[?25h"
  echo '' > "$POMO_STATE"
  rm -f "$POMO_STATE"
  exit 0
}

# -------------------------
# Pause / Resume handlers
# -------------------------
pause_pomodoro() { paused=1; }
resume_pomodoro() { paused=0; }

# -------------------------
# Trap signals
# -------------------------
trap cleanup_pomodoro EXIT SIGINT SIGTERM
trap pause_pomodoro USR1
trap resume_pomodoro USR2

# -------------------------
# UI Renderer
# -------------------------
render_ui() {
    local session=$1
    local time=$2
    local is_paused=$3

    # Move cursor to top-left and clear from there
    printf "\033[H\033[J\033[?25l"
    
    echo -e "\n    🍅 \033[1;31mPomodoro\033[0m"
    echo -e "    ━━━━━━━━━━━━━━━━"
    
    if [[ "$session" == "work" ]]; then
        echo -e "    💪 \033[1;32mWork Session\033[0m"
    else
        echo -e "    ☕ \033[1;34mBreak Session\033[0m"
    fi
    
    echo -e "\n       \033[1;37m$time\033[0m"
    
    if [[ $is_paused -eq 1 ]]; then
        echo -e "\n    \033[1;33m   (PAUSED)\033[0m"
    else
        echo -e ""
    fi
    echo -e "    ━━━━━━━━━━━━━━━━"
    echo -e "    \033[0;90mq: quit | p: pause\033[0m"
}

# -------------------------
# Pomodoro function
# -------------------------
pomodoro() {
  local session="$1"
  local duration="${pomo_options[$session]}"
  [[ -z "$duration" ]] && return 1

  current_session="$session"
  remaining_sec=$((duration * 60))

  # Notify start
  command -v notify-send >/dev/null &&
    notify-send --app-name="Pomodoro🍅" \
      "Pomodoro started" \
      "$session session – $duration minutes"

  while (( remaining_sec > 0 )); do
    printf -v time "%02d:%02d" $((remaining_sec/60)) $((remaining_sec%60))

    # Render to terminal if in a TTY
    if [[ -t 1 ]]; then
      render_ui "$session" "$time" "$paused"
    fi

    if (( paused )); then
      echo "$session (paused)" > "$POMO_STATE"
    else
      echo "$session $time" > "$POMO_STATE"
      ((remaining_sec--))
    fi

    # Check for keyboard input (non-blocking)
    if [[ -t 0 ]]; then
        read -t 1 -n 1 key
        if [[ "$key" == "q" ]]; then exit 0; fi
        if [[ "$key" == "p" ]]; then 
            if (( paused )); then paused=0; else paused=1; fi
        fi
    else
        # If not in terminal, just sleep
        sleep 1
    fi
  done

  # Notify completion
  command -v notify-send >/dev/null &&
    notify-send --app-name="Pomodoro🍅" \
      "Pomodoro complete" \
      "$session session finished"

  command -v spd-say >/dev/null && spd-say "$session session complete"

  # Clear state after each session
  echo '' > "$POMO_STATE"
}

# -------------------------
# Start Pomodoro loop
# -------------------------
start_pomodoro() {
  local loops=10
  [[ "$1" =~ ^[0-9]+$ ]] && loops="$1"

  for ((i=1; i<=loops; i++)); do
    pomodoro "work"
    pomodoro "break"
  done
}

# -------------------------
# Hyprland Popup Logic
# -------------------------
launch_popup() {
    local term=""
    local cmd_flag="-e"
    
    # Detection order: ghostty -> kitty -> alacritty
    if command -v ghostty >/dev/null; then 
        term="ghostty"
    elif command -v kitty >/dev/null; then 
        term="kitty"
        cmd_flag="--"
    elif command -v alacritty >/dev/null; then 
        term="alacritty"
    else 
        term="xterm"
    fi

    local script_path
    script_path=$(realpath "$0")
    
    # Launch with Hyprland rules
    # We use 'hyprctl dispatch exec' and wrap the command carefully
    echo "Launching $term with $script_path..."
    hyprctl dispatch exec "[float;size 300 250;pin;move 70% 5%] $term $cmd_flag $script_path --start"
}

# -------------------------
# Script entry point
# -------------------------
case "$1" in
    --start)
        shift
        start_pomodoro "$@"
        ;;
    --popup)
        launch_popup
        ;;
    --pause)
        pkill -USR1 -f "$(basename "$0") --start"
        ;;
    --resume)
        pkill -USR2 -f "$(basename "$0") --start"
        ;;
    --stop)
        pkill -f "$(basename "$0") --start"
        echo '' > "$POMO_STATE"
        ;;
    *)
        echo "Usage: $0 {--start|--popup|--pause|--resume|--stop}"
        echo -e "\nHyprland Keybind Example:"
        echo "bind = SUPER, P, exec, $(realpath "$0") --popup"
        ;;
esac
