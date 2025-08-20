#!/bin/bash

# a script for creating a new tmux session based on the basename of the directory.
if [[ -x $(command -v tmux) ]]; then
  thebasename=$(basename $(pwd))
  notify-send "created a tmux session"
  tmux new-session -d -s $thebasename

  if [ -z "$TMUX" ]; then
    tmux attach -t $thebasename
  else
    tmux switch-client -t $thebasename
  fi
else
  echo "You need to have tmux installed"
fi
