#!/bin/sh
# Usage: ./play.sh <strategy-file> <seed>
# Plays ONE whole game of blackjack by itself and prints the final line.
# A "strategy" is a tiny script that looks at the game and answers h or s.
# This script is the robot player: it asks the strategy what to do, again and again,
# until the game is over.

# Where the blackjack program is (the Docker image sets BLACKJACK for us)
BJ="${BLACKJACK:-./blackjack}"
strategy="$1"
seed="$2"
moves=""

while :; do
  # The program has no memory: we give it the seed and ALL moves so far
  out=$("$BJ" "$seed" "$moves") || exit 1

  # Game over? Then print the last line and stop.
  case "$out" in
    *"Hit or stand?") ;;
    *) echo "$out"; exit 0 ;;
  esac

  # Read the game state out of the line:
  #   You: J 8 (18) | Dealer: 4 ? | Hit or stand?
  # total  = the number in brackets (18), dealer = the visible dealer card (4)
  total=${out#*\(}
  total=${total%%\)*}
  dealer=${out#*Dealer: }
  dealer=${dealer%% *}

  # Ask the strategy what to do
  move=$(sh "$strategy" "$total" "$dealer")
  case "$move" in
    h|s) ;;
    *) echo "Error: $strategy must print h or s, it printed '$move'" >&2; exit 1 ;;
  esac
  moves="$moves$move"
done
