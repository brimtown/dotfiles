# Claude Code tmux Notification System - Specification

**Version:** 1.0
**Date:** 2026-01-09
**Status:** Draft for Review

---

## 1. Overview

Visual notification system for Claude Code integrated with tmux that provides clear, reliable feedback about Claude's execution state through window tab colors and notifications.

### Design Principles
1. **Clarity**: Always know Claude's state at a glance
2. **Reliability**: Consistent behavior across all scenarios
3. **Minimal distraction**: Notifications only when needed
4. **Debuggability**: Easy to troubleshoot when issues arise

---

## 2. End-User Experience

### Visual States

| State | Tab Color | Meaning | User Action |
|-------|-----------|---------|-------------|
| **Idle** | White (#cdd3de) | Claude session ended or notification dismissed | None needed |
| **Running** | Blue (#6699cc) | Claude is actively working (thinking, tool calls, responding) | Wait for completion |
| **Waiting** | Red (#EC5f67) | Claude needs input (permission request or finished response) | Switch to window and respond |

### Behavior Scenarios

#### Scenario A: Normal Workflow
1. User submits prompt → **Blue** (Claude starts)
2. Claude makes tool calls → **Stays blue** throughout
3. Claude finishes response → **Red** (needs input)
4. User switches to window → **White** (dismissed)
5. User responds → **Blue** (Claude starts again)

#### Scenario B: Permission Request
1. Claude requests permission → **Red** (needs input)
2. Optional: tmux popup notification if user is in different window
3. User switches to window → **White** (dismissed)
4. User approves → **Blue** (Claude resumes)
5. Claude finishes → **Red** (needs input)

#### Scenario C: Multiple Sessions
- Each tmux window with Claude maintains independent state
- Window 1 can be blue while Window 2 is red
- Dismissing one window doesn't affect others

#### Scenario D: Focus Behavior
- **Clicking within current Claude window**: No change (doesn't dismiss)
- **Switching from another tmux window**: Dismisses red, turns white
- **Returning from another app**: Doesn't dismiss (tmux sees no window change)

---

## 3. State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│   [IDLE/WHITE]                                               │
│        │                                                      │
│        │ UserPromptSubmit                                    │
│        ▼                                                      │
│   [RUNNING/BLUE] ◄──────────────────────┐                   │
│        │                                  │                   │
│        │ Notification (permission_prompt) │ PreToolUse       │
│        │ OR Stop                          │                   │
│        ▼                                  │                   │
│   [WAITING/RED]  ────────────────────────┘                   │
│        │                                                      │
│        │ pane-focus-in (window switch)                       │
│        ▼                                                      │
│   [IDLE/WHITE]                                               │
│        │                                                      │
│        │ SessionEnd                                          │
│        ▼                                                      │
│   [IDLE/WHITE]                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### State Transitions

| From State | Event | To State | Trigger |
|------------|-------|----------|---------|
| IDLE | UserPromptSubmit | RUNNING | User sends message |
| RUNNING | Notification (permission_prompt) | WAITING | Claude requests permission |
| RUNNING | Stop | WAITING | Claude finishes response |
| WAITING | PreToolUse | RUNNING | User approves permission |
| WAITING | pane-focus-in | IDLE | User switches to window |
| ANY | SessionEnd | IDLE | Claude session exits |

**Note**: PostToolUse is NOT used - we stay RUNNING throughout all tool executions until Stop fires.

---

## 4. Technical Implementation

### 4.1 Hook Configuration

**File**: `~/.claude/settings.json`

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/tmux-state.sh" }]
    }],
    "PreToolUse": [{
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/tmux-state.sh" }]
    }],
    "Notification": [{
      "matcher": "permission_prompt",
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/tmux-state.sh" }]
    }],
    "Stop": [{
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/tmux-state.sh" }]
    }],
    "SessionEnd": [{
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/tmux-state.sh" }]
    }]
  }
}
```

### 4.2 tmux Configuration

**File**: `~/.tmux.conf`

```bash
# Enable focus events (required for pane-focus-in hook)
set-option -g focus-events on

# Dismiss notification on window focus
set-hook -g pane-focus-in 'run-shell ~/.claude/hooks/tmux-dismiss.sh'
```

### 4.3 State Management

**Window Options** (per tmux window):
- `@claude-state`: Current state (`idle`, `running`, `waiting`)
- `@last-focused-window`: Last focused window index (for dismiss script)

**Global Options**:
- `@last-focused-window`: Tracks which window was last focused (dismiss detection)

---

## 5. Script Specifications

### 5.1 tmux-state.sh

**Purpose**: Changes tmux window color based on Claude Code hook events

**Input**: JSON via stdin from Claude Code hooks
**Output**: None (sets tmux window options)
**Exit Code**: Always 0

**Logic**:
```bash
1. Check if running in tmux ($TMUX set), exit if not
2. Read JSON input from stdin
3. Determine Claude window index from $TMUX_PANE
4. Determine currently focused window index
5. Parse hook_event_name from JSON
6. Based on event:
   - UserPromptSubmit → Set RUNNING/BLUE
   - PreToolUse → Set RUNNING/BLUE
   - Notification (permission_prompt) → Set WAITING/RED + notify if not focused
   - Stop → Set WAITING/RED + notify if not focused
   - SessionEnd → Set IDLE/WHITE
7. Set window-status-style, window-status-current-style, @claude-state
```

**Critical Requirements**:
- Must handle race conditions (multiple hooks firing rapidly)
- Must use `$TMUX_PANE` to get correct window (not currently focused window)
- Must suppress tmux popup if Claude window is already focused
- Must be fast (< 100ms execution time)

### 5.2 tmux-dismiss.sh

**Purpose**: Dismisses red notification when user switches to Claude window

**Input**: None (triggered by tmux pane-focus-in hook)
**Output**: None (sets tmux window options)
**Exit Code**: Always 0

**Logic**:
```bash
1. Check if running in tmux ($TMUX set), exit if not
2. Get current window index
3. Get last focused window from global option @last-focused-window
4. If current == last focused → EXIT (not a window switch)
5. Update @last-focused-window to current window
6. Get @claude-state for current window
7. If state == "waiting" → Set IDLE/WHITE
8. Otherwise → Do nothing (preserve running/idle state)
```

**Critical Requirements**:
- Must only dismiss on actual window switches (not clicks within window)
- Must preserve RUNNING state (don't turn blue to white)
- Must be fast (< 50ms execution time)
- Must handle multiple Claude sessions independently

---

## 6. Edge Cases & Solutions

### Issue 1: Race Condition - Rapid Hook Firing
**Scenario**: User approves permission, PreToolUse fires, Stop fires 10ms later
**Problem**: Window flashes blue then immediately red
**Solution**: Accept this behavior - it's technically correct. PreToolUse means "about to run tool", Stop means "done running". If operation is instant, both states happen quickly.
**Alternative**: Add 200ms debouncing in tmux-state.sh (store last event time)

### Issue 2: Focus Event Spam
**Scenario**: User clicks within Claude window repeatedly
**Problem**: dismiss script runs unnecessarily
**Solution**: Track @last-focused-window, only dismiss on actual window switches

### Issue 3: Multiple PreToolUse Events
**Scenario**: Claude makes 10 tool calls, PreToolUse fires 10 times
**Problem**: Unnecessary overhead setting blue 10 times
**Solution**: Add idempotency - check current state, skip if already RUNNING/BLUE
**Impact**: Reduces tmux command spam by ~90%

### Issue 4: Split Panes in Same Window
**Scenario**: Claude in left pane, editor in right pane, same window
**Problem**: Switching panes triggers pane-focus-in
**Solution**: tmux-dismiss.sh uses window index (not pane), so split panes in same window share state correctly

### Issue 5: Session Restart
**Scenario**: tmux server restarts, all window options lost
**Problem**: Claude windows lose state tracking
**Solution**: Accept this - state will reset on next Claude event. Document as known limitation.

### Issue 6: Remote Sessions
**Scenario**: Claude Code running on remote machine via SSH
**Problem**: Local tmux can't control remote machine's tmux
**Solution**: Scripts must run on same machine as tmux. Document SSH workflow (run Claude Code in remote tmux session, not local).

---

## 7. Known Issues with Current Implementation

### Critical Issues
1. **No idempotency**: Sets colors even if already set (wasteful)
2. **No debouncing**: Rapid events cause color flashing
3. **No logging**: Impossible to debug when things go wrong
4. **PostToolUse not ignored**: Not in config, but could be added accidentally

### Minor Issues
1. **Hardcoded colors**: Not customizable per theme
2. **No error handling**: Silently fails if tmux commands error
3. **No metrics**: Can't track how often notifications occur

---

## 8. Testing & Verification

### Unit Tests
- [ ] tmux-state.sh handles each hook event correctly
- [ ] tmux-dismiss.sh only dismisses on window switch
- [ ] State persistence across multiple tool calls
- [ ] Multiple sessions don't interfere

### Integration Tests
1. **Single tool call**: Send prompt → Blue → Red → Dismiss → White
2. **Multiple tool calls**: Send prompt → Blue (stays blue) → Red after all tools
3. **Permission request**: Request → Red → Approve → Blue → Red
4. **Multiple sessions**: Start Claude in 2 windows, verify independent colors
5. **Window switching**: Red in Window 1 → Switch to 1 → White
6. **Pane switching**: Split window, switch panes → Colors unchanged
7. **Session end**: Exit Claude → White

### Manual Verification Commands
```bash
# Check current state
tmux show-window-option @claude-state

# Check current color
tmux show-window-option window-status-style

# Manually trigger dismiss
~/.claude/hooks/tmux-dismiss.sh

# Watch events in real-time
tail -f /tmp/tmux-hooks-debug.log  # (requires adding logging)
```

---

## 9. Future Enhancements

### Phase 2 (Optional)
- [ ] Configurable colors via settings.json
- [ ] Logging to /tmp/claude-tmux.log for debugging
- [ ] Metrics: track notification frequency, average response time
- [ ] Sound alerts (optional, off by default)
- [ ] Desktop notifications via OSC escape sequences (cross-platform)

### Phase 3 (Advanced)
- [ ] Session persistence via tmux-resurrect integration
- [ ] Custom notification templates
- [ ] Integration with terminal-notifier for macOS native notifications
- [ ] Web dashboard showing all active Claude sessions

---

## 10. References

### Research Sources
1. **Claude Code Hook Documentation**
   `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/hook-development/`

2. **Open Source Implementations**
   - Alexandre Quemy's n8n + Gotify system: https://quemy.info/2025-08-04-notification-system-tmux-claude.html
   - pchalasani/claude-code-tools: https://github.com/pchalasani/claude-code-tools
   - OSC notifications: https://kane.mx/posts/2025/claude-code-notification-hooks/

3. **tmux Documentation**
   - Focus events: `man tmux` → search "focus-events"
   - Hooks: `man tmux` → search "set-hook"
   - Window options: `man tmux` → search "set-window-option"

### Related Commits
- `6d8d25d`: Initial Claude Code tmux integration (2026-01-09)
- `3eb9a5f`: Add dismiss-on-focus functionality
- `3bfd9a6`: Skip notification when already focused

---

## 11. Implementation Changes Required

Based on this spec, here are the changes needed to fix current issues:

### File: `~/.claude/hooks/tmux-state.sh`
**Changes** (AGREED):
1. ✅ Add idempotency check - check current @claude-state, skip if already in target state
2. ✅ Add optional debug logging - enable via CLAUDE_TMUX_DEBUG=1 env var → /tmp/claude-tmux.log
3. Add error handling for tmux commands (wrap in conditionals)
4. Document race condition behavior in comments
5. Add timestamp to debug logs for sequence analysis

**Implementation**:
```bash
# At top of script
DEBUG_LOG="/tmp/claude-tmux.log"
debug() {
  [ "$CLAUDE_TMUX_DEBUG" = "1" ] && echo "[$(date '+%H:%M:%S.%3N')] $*" >> "$DEBUG_LOG"
}

# Before setting state
CURRENT_STATE=$(tmux show-window-option -v -t ":$WINDOW" @claude-state 2>/dev/null)
if [ "$CURRENT_STATE" = "running" ]; then
  debug "Already RUNNING, skipping color change"
  exit 0
fi
```

### File: `~/.claude/hooks/tmux-dismiss.sh`
**Changes** (AGREED):
1. ✅ Add global option tracking for last-focused-window
2. ✅ Add early exit if not a window switch (current == last focused)
3. ✅ Add optional debug logging - same CLAUDE_TMUX_DEBUG mechanism
4. Add comment explaining pane vs window behavior
5. Add error handling for missing @claude-state

**Implementation**:
```bash
# Early exit for non-switches
LAST_FOCUSED=$(tmux show-option -gv @last-focused-window 2>/dev/null)
if [ "$LAST_FOCUSED" = "$WINDOW" ]; then
  debug "Not a window switch, skipping dismiss"
  exit 0
fi

# Update tracking
tmux set-option -g @last-focused-window "$WINDOW"
```

### File: `~/.tmux.conf`
**Changes**:
- None needed (already correct)

### File: `~/.claude/settings.json`
**Changes**:
- None needed (already correct)

---

## 12. Success Criteria

Implementation is successful when:
1. ✅ All 7 integration tests pass
2. ✅ No color flickering during normal multi-tool workflows
3. ✅ Dismiss only triggers on window switches, not pane switches
4. ✅ Multiple sessions work independently without interference
5. ✅ System is debuggable (logs available when needed)
6. ✅ Behavior matches state machine diagram exactly

---

**Document Status**: Approved and ready for implementation

**Storage**: This spec will be stored at `~/dotfiles/.claude/tmux-notifications-spec.md` for future reference

**Next Steps**:
1. Implement idempotency and window-switch detection in both scripts
2. Add optional debug logging (CLAUDE_TMUX_DEBUG=1)
3. Test all 7 integration scenarios
4. Commit spec and updated scripts to dotfiles repo
