#!/bin/bash
# Dismiss Claude notification when focusing a window
# Only resets to white if @claude-state is "waiting"

[ -z "$TMUX" ] && exit 0

# Get current window
WINDOW=$(tmux display-message -p '#I')

# Check if this window has a waiting Claude state
STATE=$(tmux show-window-option -v -t ":$WINDOW" @claude-state 2>/dev/null)

if [ "$STATE" = "waiting" ]; then
  # Reset to white (dismiss notification)
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=#cdd3de"
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=#d8dee9,bg=#4F5B66"
  tmux set-window-option -t ":$WINDOW" @claude-state "idle"
fi

exit 0
