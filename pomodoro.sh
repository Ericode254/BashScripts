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
TMP_FILES=("$POMO_STATE")  # add more files here if needed
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
  for f in "${TMP_FILES[@]}"; do
    if [[ -f "$f" ]]; then
      echo '' > "$f"  # clear content first for Waybar
      rm -f "$f"
      echo "Cleaned up: $f"
    fi
  done
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
# EXIT: normal exit
# SIGINT: Ctrl+C
# SIGTERM: kill
# USR1 / USR2: pause/resume signals
trap cleanup_pomodoro EXIT SIGINT SIGTERM
trap pause_pomodoro USR1
trap resume_pomodoro USR2

# -------------------------
# Pomodoro function
# -------------------------

pomodoro() (
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
    if (( paused )); then
      echo "$session (paused)" > "$POMO_STATE"
      sleep 1
      continue
    fi

    printf -v time "%02d:%02d" $((remaining_sec/60)) $((remaining_sec%60))
    echo "$session $time" > "$POMO_STATE"

    sleep 1
    ((remaining_sec--))
  done  # <-- closes the while loop

  # Notify completion
  command -v notify-send >/dev/null &&
    notify-send --app-name="Pomodoro🍅" \
      "Pomodoro complete" \
      "$session session finished"

  command -v spd-say >/dev/null && spd-say "$session session complete"

  # Clear Waybar state after each session
  echo '' > "$POMO_STATE"
  rm -f "$POMO_STATE"
)  # <-- closes the pomodoro function

# -------------------------
# Start Pomodoro loop
# -------------------------
start_pomodoro() {
  local loops=2
  [[ "$1" =~ ^[0-9]+$ ]] && loops="$1"

  for ((i=1; i<=loops; i++)); do
    pomodoro "work"
    pomodoro "break"
  done
}

# -------------------------
# Change durations
# -------------------------
change_pomo() {
  local session="$1"
  local minutes="$2"
  if [[ -n "$session" && "$minutes" =~ ^[0-9]+$ ]]; then
    pomo_options[$session]="$minutes"
    echo "The $session time has been changed to $minutes minutes"
  else
    echo "Usage: change_pomo [work|break] [time_in_minutes]"
  fi
}

# -------------------------
# Script entry point
# -------------------------
# Example usage: start_pomodoro 3
# You can also call change_pomo "work" 50 before starting
