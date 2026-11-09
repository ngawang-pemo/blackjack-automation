#!/bin/sh
# Usage: ./test.sh [image]      (default image: blackjack-bot:1.0)
# Checks that the robot gives the exact same results as always.
# Same seeds + same rules = same numbers, so any change in the numbers means
# somebody changed the game (or the robot). This is the safety net of the pipeline.

IMAGE="${1:-blackjack-bot:1.0}"
FAILED=0

# check "<arguments>" "<expected output>"
check() {
  out=$(docker run --rm "$IMAGE" $1 2>/dev/null)
  if [ "$out" = "$2" ]; then
    echo "PASS: $1 -> $out"
  else
    echo "FAIL: $1 -> got '$out', expected '$2'"
    FAILED=1
  fi
}

# check_fails "<arguments>"   (the robot must exit with an error)
check_fails() {
  if docker run --rm "$IMAGE" $1 >/dev/null 2>&1; then
    echo "FAIL: '$1' should have failed but succeeded"
    FAILED=1
  else
    echo "PASS: '$1' failed as expected"
  fi
}

# The robot plays 200 games and always gets the same numbers
check "always-stand 200" "always-stand: 200 games | 85 wins | 11 draws | 104 losses | win rate 42.5%"
check "stand-on-16 200"  "stand-on-16: 200 games | 87 wins | 20 draws | 93 losses | win rate 43.5%"
check "smart 200"        "smart: 200 games | 84 wins | 21 draws | 95 losses | win rate 42.0%"

# The robot must refuse a strategy that does not exist
check_fails "no-such-strategy 10"

if [ "$FAILED" -eq 0 ]; then
  echo "All tests passed"
else
  echo "Some tests failed"
fi
exit $FAILED
