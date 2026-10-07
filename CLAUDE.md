# Sproutblade — agent rules
Godot 4.7.2 (typed GDScript) · macOS, Apple Silicon · Plan: ~/Documents/Obsidian Vault/Zelda-like game/game_plan_opus.md
Source of truth: docs/contracts/*.md · Board: docs/board.md · Decisions: docs/decisions/
Build notes for the human live in the vault: Zelda-like game/OpusPlatformer/

## Commands (use these; add new ones to the Makefile, don't improvise)
make play | run | test | bench | loop | import | capture SCENE=… | clip NAME=… | palette | sfx | music | source-audio | assets | fetch-assets
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
- Music: one CC0 recording per cue in game/assets/audio/music/<cue>.(ogg|mp3|wav) (a world's cue
  is its `music` id, e.g. world_07), levelled with an entry in AudioDirector.MUSIC_GAIN, logged in
  docs/assets/LICENSES.md and re-fetchable through tools/fetch_assets.sh.

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
  Several routes, loops and side spots; stars in any order.
- Never reuse a layout between worlds. Each world gets its own shape (meadow ring, sky islands,
  winding gorge, town grid, valley, walled town...).
- Dense, lively sandbox, never sparse: talkable villagers in every level (some with errands that
  reward a seed), interaction puzzles, and expansive secret rooms that each have platforming inside.
- Puzzles have real variety: every world has at least two different puzzle types, and no puzzle
  type appears in more than two worlds (crate-on-plate and bells-in-order are already used up).
  Draw on mirrors and light beams, water levels, rotating bridges or rooms, ability puzzles
  (Fireball torches, Thunderclap machines, Vinelash routes...), notes played by ear, weight
  scales, gears, following a critter, a villager's riddle, timed switch runs, colour mixing,
  platforms set in sequence, creatures that react to the hero. Each is readable without a wall
  of text and has a small hint from a villager or a visual cue.
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
- Dense worlds must still hold 60 fps on the Mac Mini at 1920x1080: `make bench` checks every
  world and the hub. Build scenery through Kit (primitive meshes get sensible segment counts),
  let StaticMerge combine static scenery, chunk repeated kit pieces (ModuleBatch) with distance
  fades, and keep lights unshadowed with distance fade.
- Water is deep (8-12 m) in a walled basin with a bed, with things to find underwater; the sword
  works while swimming.

### Combat and movement
- Never shorten the sword's reach or width; the slash swings toward the camera's facing.
- Hitboxes match visuals, especially bosses. Every enemy shows a tell before it attacks.
- Every world has 6 Star Shards ("stars"). The boss gate or finale still opens at 3. Each world's
  six mix: at least one from a villager errand (return a lost item hidden somewhere you have to
  explore for), at least one in a hidden area, at least one behind a puzzle; the rest from the
  goal, upper-world platforming and ability routes. No two stars in a world feel alike.
- Every world teaches one magic ability once it is finished AND all 6 stars are in (stored in
  the save; saves from before keep what they earned), alternating combat and movement. Each
  ability counters at least two enemy types (docs/bestiary.md) and has routes in the worlds that use it. Keyboard casts abilities with
  number keys 1-9 (plus R, G, C, V shortcuts); gamepad picks one with D-pad left/right and casts
  with RT (LB/RB stay Thunderclap/Air Dash).
- The Glimmer Seed shop in Mossbrook sells upgrades (never a downgrade) and at most one bonus
  ability; world abilities are never sold.
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
- Commit to main as work lands and push when it works (Ashwin may push too). No model
  identifiers in commits or files.
- Markdown notes go in the Obsidian vault (Zelda-like game/OpusPlatformer/); README.md is the one
  exception in the repo.
- Use they/them for Ashwin.

## Done means
Evidence: `make test` green with a clean log, plus captures/clips for anything visual.
Never weaken or delete tests to pass. Never claim feel or visual quality you didn't capture.
Never mark a human gate as passed.
