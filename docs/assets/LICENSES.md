# Sourced assets (manifest)

Every sourced file is kept untouched in `art/sourced/<pack>/` with its licence file. All of these
are **CC0 1.0** (public domain). Credit is optional; we credit anyway.

| Pack | Author | Licence | Source | Downloaded | Used for | Changes |
|---|---|---|---|---|---|---|
| Nature Kit 2.1 | Kenney (kenney.nl) | CC0 | https://kenney.nl/assets/nature-kit | 2026-10-05 | Trees, rocks, bushes, flowers, grass, mushrooms, logs, stumps, lilies, fences, signs; Build 4: cacti, palms, statues and ruin blocks, tents, campfire stones, pumpkins, pines (trees now drawn as Whimsy puffball trees) | Scaled; materials replaced with the toon shader; colours mapped to our palette by material name (`Toon.KENNEY_PALETTE_MAP`) |
| Character Pack: Adventurers 1.0 | Kay Lousberg (kaylousberg.com) | CC0 | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | 2026-10-05 | Hero (Rogue), villagers (Mage, Knight, Barbarian), sword, 76 animations | Toon shader + ink outline; weapons hidden; hero gets a sprout and a 1.45x longer sword |
| Medieval Hexagon Pack 1.0 | Kay Lousberg | CC0 | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | 2026-10-05 | Village houses, market, windmill, well, tower, crates, barrels, props, forest clusters, mountains, clouds, water lilies | Toon shader (texture atlas kept) |
| RPG Audio | Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-05 | Slash, spin, footsteps | Renamed into `game/assets/audio/sfx/` by `tools/source_audio.py` |
| Impact Sounds | Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-05 | Hit, land, gate, boss bonk, coconut break | Same |
| Interface Sounds | Kenney | CC0 | https://kenney.nl/assets/interface-sounds | 2026-10-05 | UI blip, checkpoint, heart | Same |
| Music Jingles | Kenney | CC0 | https://kenney.nl/assets/music-jingles | 2026-10-05 | Seed pickup, victory sting | Same |

Synthesised in-house (`audio/synth/`): jumps, bounce, Springcap, Plunge, slime and boss sounds,
splash, warp, and the three music loops. Built in-house: slimes, Mother Gloop, Bonk monkey,
coconuts, Springcap, portals, checkpoints and level geometry.
