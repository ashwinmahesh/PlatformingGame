# Board

## Done (2026-10-05)
- Builds 1–3: movement, combat, World 1 slice, Mother Gloop, hub, swimming, camera zoom, sourced
  CC0 art and sound (see docs/assets/LICENSES.md).
- Build 4: five open worlds with Star Shards (Glimmerbrook, Cloudtop Steps, Sunscorch Canyon,
  Bubbleton Reef, Frostfang Peak); Rumble Golem and Avalanche Ape on BossBase/BossWorld; Build 4
  monsters (Batling, Hoppy, Shroomlet, Mimic, Armorling, Jellyfloat, Pricklepot, Snapper Crab).
- Build 5: vibrant storybook look (8x6 palette, sky ambient, Whimsy set pieces), busier Mossbrook,
  magic abilities (Fireball, Glide, Thunderclap, Air Dash) learned per world clear.
- Build 6: CC0 asset swap (Quaternius, KayKit) under the toon shader; controls swap; bigger
  platforms and buildings; open, less linear worlds; puzzles, secret rooms and villagers with
  errands in every world; deeper water with sword swimming; the new enemy roster (docs/bestiary.md);
  an upper tier in every world and Mossbrook (HighTier kit); World 6, Lanternwick, a dense
  old-English town built from the Medieval Village kit (TownHouse + ModuleBatch).
- 86 automated tests green (`make test`, which fails on any FAIL line).

## Needs a human
- Play each world end to end and say what feels off (platform sizes, jump distances, boss pace),
  especially the new upper tiers and Lanternwick's rooftops.
- Install gdtoolkit; install export templates for `make export-mac`.

## Backlog (next)
- Gamepad/keyboard remapping UI; a world map; music beyond the synthesised cues.
- More ability gates in Worlds 1–2 for revisits (brambles, ice, far ledges).
