#!/bin/bash
# Claude Code tmux state hook
# Changes tmux window color based on Claude state
# Uses @claude-state window option to track state for focus-dismiss
#
# Spec: ~/dotfiles/.claude/tmux-notifications-spec.md
#
# State Machine:
#   IDLE (white) -> UserPromptSubmit -> RUNNING (blue)
#   RUNNING -> Stop/Notification -> WAITING (red)
#   WAITING -> PreToolUse -> RUNNING (blue)
#   WAITING -> pane-focus-in -> IDLE (white)
#
# Race Conditions:
#   If PreToolUse fires followed immediately by Stop (fast operation),
#   the window will flash blue->red quickly. This is correct behavior
#   and indicates Claude briefly ran then finished.

# Debug logging (enable with: export CLAUDE_TMUX_DEBUG=1)
DEBUG_LOG="/tmp/claude-tmux.log"
debug() {
  if [ "$CLAUDE_TMUX_DEBUG" = "1" ]; then
    echo "[$(date '+%H:%M:%S.%3N')] [$$] $*" >> "$DEBUG_LOG"
  fi
}

# Exit early if not in tmux
[ -z "$TMUX" ] && exit 0

# Read hook input from stdin
input=$(cat)
debug "Received hook input"

# Use TMUX_PANE to get the window where Claude is running (not the focused window)
WINDOW=$(tmux display-message -p -t "$TMUX_PANE" '#I')
debug "Claude running in window $WINDOW"

# Get currently focused window to avoid notifying if already there
FOCUSED=$(tmux display-message -p '#I')
debug "Currently focused window: $FOCUSED"

# Get current state for idempotency check
CURRENT_STATE=$(tmux show-window-option -v -t ":$WINDOW" @claude-state 2>/dev/null)
debug "Current state: ${CURRENT_STATE:-<unset>}"

# Helper function to set state with idempotency
set_state() {
  local new_state=$1
  local color=$2
  local state_name=$3

  debug "Event: $state_name, Target state: $new_state"

  # Idempotency: Skip if already in this state
  if [ "$CURRENT_STATE" = "$new_state" ]; then
    debug "Already in $new_state state, skipping color change"
    return 0
  fi

  debug "Transitioning from ${CURRENT_STATE:-<unset>} to $new_state"

  # Set window colors
  tmux set-window-option -t ":$WINDOW" window-status-style "fg=$color" 2>/dev/null
  tmux set-window-option -t ":$WINDOW" window-status-current-style "fg=$color,bg=#4F5B66" 2>/dev/null
  tmux set-window-option -t ":$WINDOW" @claude-state "$new_state" 2>/dev/null

  debug "State changed to $new_state successfully"
}

# Parse event type from JSON (simple grep, no jq dependency)
if echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  # Blue - User submitted a prompt, Claude is starting work
  set_state "running" "#6699cc" "UserPromptSubmit"

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"PreToolUse"'; then
  # Blue - Claude resumed after permission approval, about to execute tool
  # Note: Multiple PreToolUse events may fire (one per tool), but idempotency
  # check prevents unnecessary color changes
  set_state "running" "#6699cc" "PreToolUse"

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Notification"'; then
  # Red - Claude needs permission to proceed
  set_state "waiting" "#EC5f67" "Notification"

  # Show tmux popup notification if user is in a different window
  if [ "$WINDOW" != "$FOCUSED" ]; then
    debug "Showing notification (user in window $FOCUSED)"
    tmux display-message -d 2500 "Claude needs input in window ($WINDOW)" 2>/dev/null
  else
    debug "Skipping notification (user already in Claude window)"
  fi

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Stop"'; then
  # Red - Claude finished response, waiting for user input
  set_state "waiting" "#EC5f67" "Stop"

  # Show tmux popup notification if user is in a different window
  if [ "$WINDOW" != "$FOCUSED" ]; then
    debug "Showing notification (user in window $FOCUSED)"
    tmux display-message -d 2500 "Claude needs input in window ($WINDOW)" 2>/dev/null
  else
    debug "Skipping notification (user already in Claude window)"
  fi

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"SessionEnd"'; then
  # White - Claude session ended, restore default colors
  set_state "idle" "#cdd3de" "SessionEnd"

else
  debug "Unknown hook event, no action taken"
fi

exit 0
