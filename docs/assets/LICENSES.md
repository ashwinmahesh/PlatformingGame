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
| Ultimate Monsters | Quaternius (quaternius.com) | CC0 | https://quaternius.com/packs/ultimatemonsters.html | 2026-10-05 | Slimes (Green/Pink Blob), Mushnub, Bunny (Hoppy), Squidle (Jellyfloat), Orc (Armorling), Cactoro (Pricklepot), Yeti (Avalanche Ape); Build 7: Ghost (Wispghost), Dragon (Wyrmling), Armabee (Buzzbee), Hywirl (Whirlwisp), Frog (Hopfrog), Wizard (Hexwizard) | Toon shader with outline; tinted per world; behaviour unchanged |
| Stylized Nature MegaKit (Standard) | Quaternius | CC0 | https://quaternius.itch.io/stylized-nature-megakit | 2026-10-05 | Green trees and pines, flowers, ferns, mushrooms, rocks, pebbles | Toon/foliage shader; vertex colours kept; leaves drawn outside the ink outline |
| Medieval Village MegaKit (Standard) | Quaternius | CC0 | https://quaternius.itch.io/medieval-village-megakit | 2026-10-05 | Imported for the town buildings (World 6 and Mossbrook) | Toon shader |
| Fantasy Props MegaKit (Standard) | Quaternius | CC0 | https://quaternius.itch.io/fantasy-props-megakit | 2026-10-05 | Barrels, crates, carts, stalls, benches, banners, chests | Toon shader |
| Universal Base Characters (Standard) | Quaternius | CC0 | https://quaternius.itch.io/universal-base-characters | 2026-10-05 | Not used yet: the free tier has no animations or fantasy outfits, so the KayKit hero stays | — |
| Platformer Pack 1.0 (Free) | Kay Lousberg | CC0 | https://kaylousberg.itch.io/kaykit-platformer | 2026-10-05 | Jump platforms and moving platforms in per-world colours | Stretched to each platform's collision box; toon shader |
| Watercolor Terrain Textures | Jonas Voland / Voxel Core Lab | CC0 | https://voxelcorelab.itch.io/watercolor-terrain-textures | 2026-10-05 | Painted brush texture on all terrain tops and sides | Used as brightness only, so palette colours stay in charge |
| Space Kit 2.0 | Kenney | CC0 | https://kenney.nl/assets/space-kit | 2026-10-06 | World 7 (Planet Glorbo): the saucer hangars, satellite dishes, meteor, crystal rocks, generator | Scaled; toon shader |
| Ultimate Space Kit | Quaternius | CC0 | https://poly.pizza/bundle/Ultimate-Space-Kit-YWh743lqGX | 2026-10-06 | World 7 (Planet Glorbo): alien trees and bushes, domes and pod houses, solar panels, antennas, rocks, the planets in the sky | Toon shader; texture atlas kept |

Synthesised in-house (`audio/synth/`): jumps, bounce, Springcap, Plunge, slime and boss sounds,
splash, warp, and the three music loops. Built in-house: slimes, Mother Gloop, Bonk monkey,
coconuts, Springcap, portals, checkpoints and level geometry.
