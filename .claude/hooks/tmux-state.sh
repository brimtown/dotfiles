#!/bin/bash
# Claude Code tmux state hook
# Changes tmux window color based on Claude state
# Uses @claude-state window option to track state for focus-dismiss
#
# Spec: ~/dotfiles/.claude/tmux-notifications-spec.md
#
# State Machine:
#   IDLE (white) -> UserPromptSubmit -> RUNNING (blue)
#   RUNNING -> Stop/Notification/PermissionRequest -> WAITING (red)
#   WAITING -> PreToolUse -> RUNNING (blue)
#   WAITING -> pane-focus-in -> IDLE (white)
#
# Race Conditions:
#   If PreToolUse fires followed immediately by Stop (fast operation),
#   the window will flash blue->red quickly. This is correct behavior
#   and indicates Claude briefly ran then finished.

# Debug logging (disable with: export CLAUDE_TMUX_DEBUG=0)
DEBUG_LOG="/tmp/claude-tmux.log"
debug() {
  if [ "$CLAUDE_TMUX_DEBUG" != "0" ]; then
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

# Bubble window toward front when it needs attention
# Swaps with first non-red window, only auto-focuses if user was in idle window
bubble_up() {
  # Capture state BEFORE any swaps
  local original_window=$WINDOW
  local user_was_in_state=$(tmux show-window-option -v -t ":$FOCUSED" @claude-state 2>/dev/null)
  debug "User currently in window $FOCUSED (state: ${user_was_in_state:-idle})"

  # Find first non-red window to swap with (maintains red-first ordering)
  local swap_target=""
  for i in $(tmux list-windows -F '#{window_index}' | sort -n); do
    [ "$i" -ge "$WINDOW" ] && break  # Don't swap with self or higher
    local state=$(tmux show-window-option -v -t ":$i" @claude-state 2>/dev/null)
    if [ "$state" != "waiting" ]; then
      swap_target=$i
      break
    fi
  done

  if [ -n "$swap_target" ]; then
    debug "Bubbling window $WINDOW to position $swap_target"
    tmux swap-window -s ":$WINDOW" -t ":$swap_target" 2>/dev/null
    WINDOW=$swap_target
    debug "Window swapped to position $swap_target"
  else
    debug "No non-red window to swap with, staying at $WINDOW"
  fi

  # Auto-focus if:
  # 1. User was in THIS window (so they follow the swap), or
  # 2. User was in an idle window (steal their attention)
  # Skip if user is in a DIFFERENT running/waiting window (don't interrupt)
  if [ "$FOCUSED" = "$original_window" ]; then
    tmux select-window -t ":$WINDOW" 2>/dev/null
    debug "Focused window $WINDOW (user was in this window, following swap)"
  elif [ -z "$user_was_in_state" ] || [ "$user_was_in_state" = "idle" ]; then
    tmux select-window -t ":$WINDOW" 2>/dev/null
    debug "Focused window $WINDOW (user was in idle window)"
  else
    debug "Skipping focus (user in different $user_was_in_state window)"
  fi
}

# Parse event type from JSON (simple grep, no jq dependency)
if echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  # Blue - User submitted a prompt, Claude is starting work
  set_state "running" "#6699cc" "UserPromptSubmit"

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"PreToolUse"'; then
  # Blue - Claude resumed after permission approval, about to execute tool
  # Only transition if waiting (user approved permission)
  # Ignore PreToolUse when idle (startup tool calls before user prompt)
  if [ "$CURRENT_STATE" = "waiting" ]; then
    set_state "running" "#6699cc" "PreToolUse"
  else
    debug "Ignoring PreToolUse in state: ${CURRENT_STATE:-<unset>}"
  fi

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Notification"'; then
  # Red - Claude needs permission to proceed
  bubble_up
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
  bubble_up
  set_state "waiting" "#EC5f67" "Stop"

  # Show tmux popup notification if user is in a different window
  if [ "$WINDOW" != "$FOCUSED" ]; then
    debug "Showing notification (user in window $FOCUSED)"
    tmux display-message -d 2500 "Claude needs input in window ($WINDOW)" 2>/dev/null
  else
    debug "Skipping notification (user already in Claude window)"
  fi

elif echo "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"PermissionRequest"'; then
  # Red - Claude needs permission to run a tool
  bubble_up
  set_state "waiting" "#EC5f67" "PermissionRequest"

  # Show tmux popup notification if user is in a different window
  if [ "$WINDOW" != "$FOCUSED" ]; then
    debug "Showing notification (user in window $FOCUSED)"
    tmux display-message -d 2500 "Claude needs permission in window ($WINDOW)" 2>/dev/null
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
