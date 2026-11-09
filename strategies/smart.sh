#!/bin/sh
# Looks at the dealer's visible card too.
# A dealer showing 2 to 6 is likely to bust, so we can stand early.
# Otherwise we play safe-but-brave and hit until 17.
# $1 = your total, $2 = the dealer's visible card (A, 2-10, J, Q, K)
case "$2" in
  2|3|4|5|6) limit=12 ;;
  *)         limit=17 ;;
esac
if [ "$1" -lt "$limit" ]; then echo h; else echo s; fi
