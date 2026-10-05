# Sproutblade — agent rules
Godot 4.7.2 (typed GDScript) · macOS, Apple Silicon · Plan: ~/Documents/Obsidian Vault/Zelda-like game/game_plan_opus.md
Source of truth: docs/contracts/*.md · Board: docs/board.md · Decisions: docs/decisions/
Build notes for the human live in the vault: Zelda-like game/OpusPlatformer/

## Commands (use these; add new ones to the Makefile, don't improvise)
make run | test | loop | import | capture SCENE=… | clip NAME=… | palette | sfx | music | source-audio | assets | fetch-assets
make lint needs gdtoolkit (`pipx install "gdtoolkit==4.*"`), not installed yet.

## Godot
- Godot 4 API only (tools/forbid_godot3.sh). Static types everywhere: `untyped_declaration` is an
  error, including for-loop variables over untyped arrays.
- Gameplay numbers live in data/*.tres (MovementSettings, AttackDef, EnemyDef, WorldDef).
- Physics ticks (60 Hz) are the only gameplay clock. Never time damage or cancels from animation.
- Damage only flows through CombatResolver; hit/hurt areas only report overlaps (meta "actor").
- Collision layers only via Layers constants (docs/contracts/collision.md).
- Scenes are built in code from Kit helpers (scripts/world/kit.gd); .tscn files are thin roots.
- Tests drive the real movement loop in physics scenes; never mock is_on_floor().
- After adding a class_name, run `make import` so the class cache knows it before `make test`.

## Assets
- Colours come only from art/palette/palette.json via Palette (generated) and the toon shader.
- Ashwin approved sourcing CC0 packs end to end (2026-10-05). Downloads stay untouched in
  art/sourced/<pack>/ with their licence; every one is listed in docs/assets/LICENSES.md.
- Sourced models are wrapped, never edited: Props (scripts/world/props.gd) for scenery,
  CharacterModel for rigged KayKit characters; Toon.apply gives them the one toon look.
- Sounds: synthesised by audio/synth/*.py, then tools/source_audio.py overrides some with Kenney.

## Done means
Evidence: `make test` green with a clean log, plus captures/clips for anything visual.
Never weaken or delete tests to pass. Never claim feel or visual quality you didn't capture.
Never mark a human gate as passed.
