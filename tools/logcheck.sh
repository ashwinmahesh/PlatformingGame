#!/usr/bin/env bash
# Log watchdog (plan §7.3): pass Godot output through; fail on errors hiding behind a green run.
set -o pipefail
status=0
while IFS= read -r line; do
  printf '%s\n' "$line"
  case "$line" in
    *"SCRIPT ERROR"*|*"ERROR:"*|*"Parse Error"*|*"Failed loading"*) status=1 ;;
  esac
done
exit $status
