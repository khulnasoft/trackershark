#!/bin/zsh --login
exec python3 $(dirname "$0")/tracker-capture.py "$@"