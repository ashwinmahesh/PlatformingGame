# Board

## Done (2026-10-05)
- Builds 1–3: movement, combat, World 1 slice, Mother Gloop, hub, swimming, camera zoom, sourced
  CC0 art and sound (see docs/assets/LICENSES.md).
- Build 4: five open worlds with Star Shards (Glimmerbrook, Cloudtop Steps, Sunscorch Canyon,
  Bubbleton Reef, Frostfang Peak); Rumble Golem and Avalanche Ape on BossBase/BossWorld; Build 4
  monsters (Batling, Hoppy, Shroomlet, Mimic, Armorling, Jellyfloat, Pricklepot, Snapper Crab).
- Build 5: vibrant storybook look (8x6 palette, sky ambient, Whimsy set pieces), busier Mossbrook,
  magic abilities (Fireball, Glide, Thunderclap, Air Dash) learned per world clear.
- 70 automated tests green (`make test`, which now fails on any FAIL line).

## Needs a human
- Play each world end to end and say what feels off (platform sizes, jump distances, boss pace).
- Install gdtoolkit; install export templates for `make export-mac`.

## Backlog (next)
- Gamepad/keyboard remapping UI; a world map; music beyond the synthesised cues.
- More ability gates in Worlds 1–2 for revisits (brambles, ice, far ledges).
