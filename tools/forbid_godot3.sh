#!/usr/bin/env bash
# Guardrail (plan §7.6): reject Godot 3 API in GDScript.
if grep -rnE '\bKinematicBody\b|\bSpatial\b|\byield\(|^\s*export var|^\s*onready var|\.instance\(\)|\bsetget\b|move_and_slide\([^)]' game --include='*.gd'; then
  echo "Godot 3 API found (see above)"; exit 1
fi
echo "forbid_godot3: clean"
