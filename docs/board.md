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
- Build 7 (2026-10-06): Glide replaced by Vinelash; world abilities stored in the save and taught
  once a world is finished with all six stars; abilities 1-9 and a gamepad picker; the Glimmer
  Seed shop (Clover); six stars per world (errand, hidden, puzzle stars) with puzzle variety; six
  more monsters; performance pass (StaticMerge, chunked ModuleBatch, Kit.lighten), every world at
  60 fps; the golem gem and Ape head hit zones; lifts now rise all the way; CC0 music for every
  world, the bosses, the title and the shop; three new worlds: Planet Glorbo (W7, Queen
  Bloomzilla, Gravity Orb), Brickbloom Heights (W8, Grand Star, Star Rush) and Dinodew Jungle
  (W9, rideable dinosaurs, Chomposaurus Rex, Mighty Roar).
- 156 automated tests green (`make test`, which fails on any FAIL line).

## Needs a human
- Play each world end to end and say what feels off (platform sizes, jump distances, boss pace),
  especially the new upper tiers, Lanternwick's rooftops and Worlds 7-9 (Hopscotch Court and the
  Sky Rows jump distances, riding the dinosaurs).
- Install gdtoolkit; install export templates for `make export-mac`.

## Backlog (next)
- Gamepad/keyboard remapping UI; a world map.
- More ability gates in Worlds 1–2 for revisits (brambles, ice, far ledges).
