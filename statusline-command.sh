#!/usr/bin/env bash
# Claude Code statusline
# Reads the statusline JSON payload from stdin and prints one compact line.

export LC_ALL=C
input=$(cat)

# ---- ANSI colors (kept modest; terminal renders statusline dimmed) ----
RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'

# Pick a color for a percentage value (green < 50, yellow < 80, red >= 80)
color_for_pct() {
  local pct="$1"
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then
    echo ""
    return
  fi
  local bucket
  bucket=$(awk -v p="$pct" 'BEGIN{ if (p>=80) print "red"; else if (p>=50) print "yellow"; else print "green" }')
  case "$bucket" in
    red) echo "$RED" ;;
    yellow) echo "$YELLOW" ;;
    *) echo "$GREEN" ;;
  esac
}

# Format a raw token count as e.g. 12.3k / 1.2M, falling back to plain digits.
format_tokens() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" = "null" ]; then
    echo "0"
    return
  fi
  awk -v n="$n" 'BEGIN{
    if (n>=1000000) printf "%.1fM", n/1000000;
    else if (n>=1000) printf "%.1fk", n/1000;
    else printf "%d", n
  }'
}

# Format a unix epoch (seconds) as HH:MM local time, empty if unavailable.
format_reset() {
  local epoch="$1"
  if [ -z "$epoch" ] || [ "$epoch" = "null" ]; then
    echo ""
    return
  fi
  date -d "@$epoch" +"%a %H:%M" 2>/dev/null
}

# Draw a 10-cell progress bar for a percentage, colored by threshold.
# Optional second argument: the percentage to pick the color from
# (used by the cache bar, where a high value is good).
bar_for_pct() {
  local pct="$1" width=10
  local filled c
  filled=$(awk -v p="$pct" -v w="$width" 'BEGIN{f=int(p/100*w+0.5); if(f<0)f=0; if(f>w)f=w; print f}')
  c=$(color_for_pct "${2:-$pct}")
  local bar="" i
  for ((i=0;i<width;i++)); do
    if [ $i -lt $filled ]; then bar+="\xe2\x96\x88"; else bar+="\xe2\x96\x91"; fi
  done
  printf "%s%b%s" "$c" "$bar" "$RESET"
}

parts=()

# ---- 0. Project dir + git branch/worktree + PR ----
proj_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$proj_dir" ]; then
  parts+=("${DIM}$(basename "$proj_dir")${RESET}")
fi
branch=$(echo "$input" | jq -r '.worktree.branch // empty')
if [ -z "$branch" ] && [ -n "$proj_dir" ]; then
  branch=$(git -C "$proj_dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$proj_dir" rev-parse --short HEAD 2>/dev/null)
fi
wt_name=$(echo "$input" | jq -r '.worktree.name // empty')
if [ -n "$branch" ]; then
  seg="\xe2\x8e\x87 ${branch}"
  [ -n "$wt_name" ] && seg="${seg} [wt:${wt_name}]"
  parts+=("$(printf "$seg")")
fi
pr_num=$(echo "$input" | jq -r '.pr.number // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')
if [ -n "$pr_num" ]; then
  seg="PR#${pr_num}"
  case "$pr_state" in
    approved) seg="${seg} ${GREEN}${pr_state}${RESET}" ;;
    changes_requested) seg="${seg} ${RED}${pr_state}${RESET}" ;;
    "") ;;
    *) seg="${seg} ${YELLOW}${pr_state}${RESET}" ;;
  esac
  parts+=("$seg")
fi

# ---- 1. Model display name ----
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model_name" ]; then
  parts+=("${DIM}${model_name}${RESET}")
fi

# ---- 2. Reasoning effort level (only present for some models) ----
effort=$(echo "$input" | jq -r '.effort.level // empty')
if [ -n "$effort" ]; then
  parts+=("Effort:${effort}")
fi

# ---- 2b. Thinking ----
thinking=$(echo "$input" | jq -r '.thinking.enabled // empty')
case "$thinking" in
  true)  parts+=("Think:${GREEN}on${RESET}") ;;
  false) parts+=("Think:${DIM}off${RESET}") ;;
esac

# ---- 3. Context window usage ----
cw_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
cw_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
cw_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$cw_size" ] && [ "$cw_size" != "null" ]; then
  used_fmt=$(format_tokens "$cw_used")
  size_fmt=$(format_tokens "$cw_size")
  if [ -n "$cw_pct" ] && [ "$cw_pct" != "null" ]; then
    c=$(color_for_pct "$cw_pct")
    pct_fmt=$(awk -v p="$cw_pct" 'BEGIN{printf "%.0f", p}')
    parts+=("Ctx:$(bar_for_pct "$cw_pct") ${c}${pct_fmt}%${RESET} ${DIM}${used_fmt}/${size_fmt}${RESET}")
  else
    parts+=("Ctx:${used_fmt}/${size_fmt}")
  fi
fi

# ---- 4. Rate limits: 5h and 7d used percentage + reset time ----
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# 5h and 7d are separate segments so they can wrap independently.
if [ -n "$five_pct" ] && [ "$five_pct" != "null" ]; then
  c=$(color_for_pct "$five_pct")
  pct_fmt=$(awk -v p="$five_pct" 'BEGIN{printf "%.0f", p}')
  reset_fmt=$(format_reset "$five_reset")
  seg="5h:${c}${pct_fmt}%${RESET}"
  [ -n "$reset_fmt" ] && seg="${seg}(${reset_fmt})"
  parts+=("$seg")
fi
if [ -n "$week_pct" ] && [ "$week_pct" != "null" ]; then
  c=$(color_for_pct "$week_pct")
  pct_fmt=$(awk -v p="$week_pct" 'BEGIN{printf "%.0f", p}')
  reset_fmt=$(format_reset "$week_reset")
  seg="7d:${c}${pct_fmt}%${RESET}"
  [ -n "$reset_fmt" ] && seg="${seg}(${reset_fmt})"
  parts+=("$seg")
fi

# ---- 5. Session cost in USD ----
# Note: not part of the documented statusline JSON schema, but some Claude Code
# builds add a top-level "cost.total_cost_usd" field; read it defensively.
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost_usd" ] && [ "$cost_usd" != "null" ]; then
  cost_fmt=$(awk -v c="$cost_usd" 'BEGIN{printf "%.2f", c}')
  parts+=("Cost:\$${cost_fmt}")
fi

# ---- 6. Cache hit rate (cache_read / total input of last API call) ----
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
in_tok=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
total_in=$((cache_read + cache_creation + in_tok))
if [ "$total_in" -gt 0 ]; then
  hit=$(awk -v r="$cache_read" -v t="$total_in" 'BEGIN{printf "%.0f", r/t*100}')
  # invert colors: high hit rate is good
  inv=$((100 - hit))
  c=$(color_for_pct "$inv")
  parts+=("Cache:$(bar_for_pct "$hit" "$inv") ${c}${hit}%${RESET} ${DIM}R:$(format_tokens "$cache_read") C:$(format_tokens "$cache_creation")${RESET}")
fi

# Visible width of a segment: drop ANSI color codes, then count UTF-8
# characters (bytes that are not continuation bytes 0x80-0xBF).
visible_len() {
  printf "%s" "$1" | sed $'s/\033\\[[0-9;]*m//g' | tr -d '\200-\277' | wc -c | tr -d ' '
}

# ---- Join and print, wrapping to the terminal width ----
# Claude Code sets COLUMNS to the terminal width (tput cannot read it here).
# Segments go on the same line while they fit; the next one starts a new line,
# so every indicator stays visible. Without COLUMNS, everything on one line.
max_width=0
if [[ "${COLUMNS:-}" =~ ^[0-9]+$ ]] && [ "$COLUMNS" -gt 4 ]; then
  max_width=$((COLUMNS - 2))
fi
sep=" ${DIM}|${RESET} "
out=""
line=""
line_len=0
for p in "${parts[@]}"; do
  p_len=$(visible_len "$p")
  if [ -z "$line" ]; then
    line="$p"
    line_len=$p_len
  elif [ "$max_width" -gt 0 ] && [ $((line_len + 3 + p_len)) -gt "$max_width" ]; then
    out="${out}${line}"$'\n'
    line="$p"
    line_len=$p_len
  else
    line="${line}${sep}${p}"
    line_len=$((line_len + 3 + p_len))
  fi
done
out="${out}${line}"

printf "%s" "$out"
