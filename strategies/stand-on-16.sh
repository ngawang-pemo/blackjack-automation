#!/bin/sh
# Hit until you have 16 or more, then stand.
# $1 = your total, $2 = the dealer's visible card (A, 2-10, J, Q, K)
if [ "$1" -lt 16 ]; then echo h; else echo s; fi
