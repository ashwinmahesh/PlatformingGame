# Sproutblade — agent rules
Godot 4.7.2 (typed GDScript) · macOS, Apple Silicon · Plan: ~/Documents/Obsidian Vault/Zelda-like game/game_plan_opus.md
Source of truth: docs/contracts/*.md · Board: docs/board.md · Decisions: docs/decisions/
Build notes for the human live in the vault: Zelda-like game/OpusPlatformer/

## Commands (use these; add new ones to the Makefile, don't improvise)
make play | run | test | loop | import | capture SCENE=… | clip NAME=… | palette | sfx | music | source-audio | assets | fetch-assets
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

## Design principles (Ashwin's standing rules; apply to every world, the hub and every gameplay
## change; where they differ from game_plan_opus.md, these win)

### Art and tone
- Vibrant, whimsical and magical, in the spirit of Dragon Quest. Realism is not required; give each
  world signature unreal set pieces (giant mushroom forests, cloud palaces, coral towers).
- Monsters take inspiration from Dragon Quest, as our own designs.
- Every sourced pack goes under the one toon shader (Toon.apply) with the world's colour tint, so
  mixed packs read as one game.
- Buildings are generous in size (Props.BUILDING_SCALE); townhouses use TownHouse + ModuleBatch.

### Level design
- Every world is a small open world: non-linear, never a corridor, about 10-15 minutes to clear.
  Several routes, loops and side spots; shards in any order.
- Never reuse a layout between worlds. Each world gets its own shape (meadow ring, sky islands,
  winding gorge, town grid, valley, walled town...).
- Dense, lively sandbox, never sparse: talkable villagers in every level (some with errands that
  reward a seed), interaction puzzles (bells, crates and plates, switches, breakable or bramble
  doors), and expansive secret rooms that each have platforming inside.
- Vertical accessibility is a core focus:
  - every level has a full upper world (decks, rooftops, ledges) with its own paths, villagers,
    secrets, seeds and enemies, not just a few platforms;
  - several ways up everywhere (spiral ramps, ladders, stepped ledges, crates, wall-jump walls,
    lifts, bounce pads, wind) and easy ways down;
  - no low area traps the player: every alley, gorge, courtyard or pit has a visible way up close
    by, and something to do in it;
  - every ladder must stand on ground and lead onto something solid (tests/sim/test_worlds.gd).
- Platforms are generous for the hero's mobility (OpenWorld.grown); individual jumps are low and
  forgiving (rises of about 3 m or less); slopes you walk stay under about 22 degrees (HighTier).
- Water is deep (8-12 m) in a walled basin with a bed, with things to find underwater; the sword
  works while swimming.

### Combat and movement
- Never shorten the sword's reach or width; the slash swings toward the camera's facing.
- Hitboxes match visuals, especially bosses. Every enemy shows a tell before it attacks.
- Each magic ability counters at least two enemy types (docs/bestiary.md). One ability is learned
  per world cleared, alternating combat and movement.
- The Plunge is a visible straight-down sword thrust; the landing shadow shows where you'll land.
- Wall jumps: a kick neither uses nor refills air jumps; bouncing between different walls is
  unlimited; never off the same wall twice in a row.
- Ladders: walk in to grab, forward/back to climb, jump to let go, step off at the top.
- Pickups have a generous radius and drift toward the hero when close.

### Assets
- Free packs with no licence restrictions only (CC0); record each in docs/assets/LICENSES.md.
- Raw download archives stay git-ignored in art/sourced/_dl/; `make fetch-assets` re-downloads them.

### How to work with Ashwin
- Ashwin plays real saves. Back up the save before anything that touches it, get Ashwin's yes
  before writing to it, and keep tools off it: only the title screen uses user://save_0.json; dev
  tools and captures write user://dev_saves/, tests user://test_saves/.
- Ashwin plays from `make play` (a snapshot in builds/play/). Never restart the game while Ashwin
  is mid-game (check the newest telemetry session); offer `make play` instead.
- Crashes and bugs Ashwin reports jump the queue.
- Ashwin pushes git themselves; commit locally only. No model identifiers in commits or files.
- Markdown notes go in the Obsidian vault (Zelda-like game/OpusPlatformer/); README.md is the one
  exception in the repo.
- Use they/them for Ashwin.

## Done means
Evidence: `make test` green with a clean log, plus captures/clips for anything visual.
Never weaken or delete tests to pass. Never claim feel or visual quality you didn't capture.
Never mark a human gate as passed.
