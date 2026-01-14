#!/bin/bash
input=$(cat)
JQ=$(command -v jq)

# Parse fields
cwd=$(echo "$input" | $JQ -r '.workspace.project_dir')
project_path=$(echo "$cwd" | sed "s|^$HOME|~|")
model=$(echo "$input" | $JQ -r '.model.id' | sed 's/claude-//;s/-[0-9]*$//')
ctx_pct=$(echo "$input" | $JQ -r '.context_window.used_percentage')
ctx_size=$(echo "$input" | $JQ -r '.context_window.context_window_size')
ctx_used=$((ctx_size * ctx_pct / 100 / 1000))
ctx_total=$((ctx_size / 1000))
duration_ms=$(echo "$input" | $JQ -r '.cost.total_duration_ms')
duration_min=$((duration_ms / 60000))
version=$(echo "$input" | $JQ -r '.version')

# Context bar (10 fillable chars + marker at 80%)
bar_width=10
threshold_pos=8
filled_exact=$((ctx_pct * bar_width))
bar_filled=$((filled_exact / 100))
remainder=$((filled_exact % 100))

# Partial block based on remainder
if [ $remainder -ge 75 ]; then
  partial="▓"
elif [ $remainder -ge 50 ]; then
  partial="▒"
elif [ $remainder -ge 25 ]; then
  partial="░"
else
  partial=""
fi

# Build bar chars
bar_chars=""
for ((i=0; i<bar_width; i++)); do
  if [ $i -lt $bar_filled ]; then
    bar_chars+="█"
  elif [ $i -eq $bar_filled ] && [ -n "$partial" ]; then
    bar_chars+="$partial"
  else
    bar_chars+="░"
  fi
done

# Insert threshold marker at 80%
bar="${bar_chars:0:threshold_pos}│${bar_chars:threshold_pos}"

# Bar color based on usage
if [ $ctx_pct -ge 80 ]; then
  bar_color="\033[31m"  # red
else
  bar_color="\033[35m"  # magenta
fi

# Git branch
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_info="  $(printf '\033[34m')⎇$(printf '\033[0m') $(printf '\033[31m')$branch$(printf '\033[0m')"
  fi
fi

# Output
printf '\033[36m%s\033[0m%s  \033[33m⬡\033[0m %s  %s%% %b%s\033[0m (%sk/%sk)  \033[32m⏱\033[0m %sm  \033[90mv%s\033[0m' \
  "$project_path" "$git_info" "$model" "$ctx_pct" "$bar_color" "$bar" "$ctx_used" "$ctx_total" "$duration_min" "$version"
