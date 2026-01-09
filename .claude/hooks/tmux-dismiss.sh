#!/bin/bash
# Dismiss Claude notification when focusing a window
# Only resets to white if @claude-state is "waiting"
#
# Spec: ~/dotfiles/.claude/tmux-notifications-spec.md
#
# Behavior:
#   - Triggered by tmux pane-focus-in hook
#   - Only dismisses on actual window switches (not clicks within same window)
#   - Preserves RUNNING (blue) state - only dismisses WAITING (red) state
#   - Uses tmux window index (not pane) so split panes share state correctly
#
# Window vs Pane:
#   - tmux window = tab in status bar (numbered 0, 1, 2, etc.)
#   - tmux pane = split within a window (can have multiple per window)
#   - This script uses window index so all panes in a window share notification state

# Debug logging (disable with: export CLAUDE_TMUX_DEBUG=0)
DEBUG_LOG="/tmp/claude-tmux.log"
debug() {
  if [ "$CLAUDE_TMUX_DEBUG" != "0" ]; then
    echo "[$(date '+%H:%M:%S.%3N')] [dismiss] $*" >> "$DEBUG_LOG"
  fi
}

# Exit early if not in tmux
[ -z "$TMUX" ] && exit 0

# Get current window index
WINDOW=$(tmux display-message -p '#I')
debug "pane-focus-in fired for window $WINDOW"

# Check if this is an actual window switch (not a click within same window)
LAST_FOCUSED=$(tmux show-option -gv @last-focused-window 2>/dev/null)
debug "Last focused window: ${LAST_FOCUSED:-<unset>}"

if [ "$LAST_FOCUSED" = "$WINDOW" ]; then
  debug "Not a window switch (already in window $WINDOW), skipping dismiss"
  exit 0
fi

# Update tracking for next invocation
tmux set-option -g @last-focused-window "$WINDOW" 2>/dev/null
debug "Updated last-focused-window to $WINDOW"

# Check if this window has a Claude state
STATE=$(tmux show-window-option -v -t ":$WINDOW" @claude-state 2>/dev/null)
debug "Window $WINDOW state: ${STATE:-<unset>}"

# Only dismiss if state is "waiting" (red)
# Preserve "running" (blue) and "idle" (white) states
if [ "$STATE" = "waiting" ]; then
  debug "Dismissing notification (waiting -> idle)"

  # Reset to white (idle state)
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=#cdd3de" 2>/dev/null
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=#d8dee9,bg=#4F5B66" 2>/dev/null
  tmux set-window-option -t ":$WINDOW" @claude-state "idle" 2>/dev/null

  debug "Dismissed successfully"
else
  debug "State is not 'waiting', preserving current state"
fi

exit 0
