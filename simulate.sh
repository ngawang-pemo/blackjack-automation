#!/bin/sh
# Usage: ./simulate.sh <strategy> [games]
#   strategy = a name from the strategies/ folder (like stand-on-16) or a file path
#   games    = how many games to play, default 1000 (seeds 0, 1, 2, ...)
# Plays many games with the same strategy and prints ONE summary line.

DIR=$(dirname "$0")
name="$1"
games="${2:-1000}"

if [ -z "$name" ]; then
  echo "Usage: simulate.sh <strategy> [games]" >&2
  exit 1
fi

# Find the strategy file
if [ -f "$name" ]; then
  file="$name"
elif [ -f "$DIR/strategies/$name.sh" ]; then
  file="$DIR/strategies/$name.sh"
else
  echo "Error: strategy '$name' not found" >&2
  exit 1
fi

wins=0
draws=0
losses=0
seed=0

# The loop that replaces 1000 manual runs
while [ "$seed" -lt "$games" ]; do
  result=$(sh "$DIR/play.sh" "$file" "$seed") || exit 1
  case "$result" in
    *"You win!"*) wins=$((wins + 1)) ;;
    *"Draw."*)    draws=$((draws + 1)) ;;
    *)            losses=$((losses + 1)) ;;
  esac
  seed=$((seed + 1))
done

# Win rate with one decimal, using whole numbers only (44.3% = 443 tenths)
tenths=$((wins * 1000 / games))
echo "$(basename "$file" .sh): $games games | $wins wins | $draws draws | $losses losses | win rate $((tenths / 10)).$((tenths % 10))%"
