#!/bin/sh
# Usage: ./leaderboard.sh [games]
# Runs EVERY strategy in the strategies/ folder and prints them best first.
# Files starting with _ (like _template.sh) are skipped.

DIR=$(dirname "$0")
games="${1:-1000}"
tmp=$(mktemp)

for file in "$DIR"/strategies/*.sh; do
  case "$(basename "$file")" in
    _*) continue ;;
  esac
  line=$(sh "$DIR/simulate.sh" "$file" "$games") || exit 1
  # Turn "win rate 44.3%" into the sortable number 443
  rate=${line##*win rate }
  rate=${rate%\%}
  key="${rate%.*}${rate#*.}"
  echo "$key $line" >> "$tmp"
done

echo "Leaderboard ($games games each, same seeds for everyone)"
sort -rn "$tmp" | {
  rank=1
  while read -r key line; do
    echo "$rank. $line"
    rank=$((rank + 1))
  done
}
rm -f "$tmp"
