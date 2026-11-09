#!/bin/sh
# YOUR STRATEGY: copy this file to strategies/<your-name>.sh and change the rule.
# (Files starting with _ are ignored by the leaderboard.)
#
# The robot calls your script like this:   sh strategies/<your-name>.sh <total> <dealer-card>
#   $1 = your total right now          (a number, like 14)
#   $2 = the dealer's visible card     (A, 2, 3, ... 10, J, Q or K)
#
# Your script must print exactly one letter:
#   h = hit (take a card)
#   s = stand (stop)
#
# Example rule: hit while the total is below 15.
if [ "$1" -lt 15 ]; then echo h; else echo s; fi
