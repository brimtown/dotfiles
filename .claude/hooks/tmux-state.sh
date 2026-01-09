#!/bin/bash
# Claude Code tmux state hook
# Changes tmux window color based on Claude state
# Uses @claude-state window option to track state for focus-dismiss

[ -z "$TMUX" ] && exit 0  # Not in tmux, nothing to do

input=$(cat)
# Use TMUX_PANE to get the window where Claude is running, not the focused window
WINDOW=$(tmux display-message -p -t "$TMUX_PANE" '#I')

# Parse event type from JSON (simple grep, no jq needed)
if echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  # Blue - Claude is running
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=#6699cc"
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=#6699cc,bg=#4F5B66"
  tmux set-window-option -t ":$WINDOW" @claude-state "running"

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Notification"'; then
  # Red - Claude needs permission
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=#EC5f67"
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=#EC5f67,bg=#4F5B66"
  tmux set-window-option -t ":$WINDOW" @claude-state "waiting"
  tmux display-message -d 2000 "Claude needs input in window ($WINDOW)"

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Stop"'; then
  # Red - Claude finished, waiting for you (like unread notification)
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=#EC5f67"
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=#EC5f67,bg=#4F5B66"
  tmux set-window-option -t ":$WINDOW" @claude-state "waiting"
  tmux display-message -d 2000 "Claude needs input in window ($WINDOW)"

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"SessionEnd"'; then
  # White - Session ended (restore defaults)
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=#cdd3de"
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=#d8dee9,bg=#4F5B66"
  tmux set-window-option -t ":$WINDOW" @claude-state "idle"
fi

exit 0
