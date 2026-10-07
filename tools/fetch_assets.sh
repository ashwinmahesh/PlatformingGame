#!/usr/bin/env bash
# Re-download the original archives of the itch.io packs into art/sourced/_dl/ (git-ignored:
# several are over GitHub's 100 MB limit). Not needed to build or play: the unpacked packs in
# art/sourced/<pack>/ and the copies in game/assets/ are committed. Use this only to re-extract
# or update a pack. Usage: make fetch-assets
set -euo pipefail
cd "$(dirname "$0")/.."
DL=art/sourced/_dl
fetch() { mkdir -p "$DL/$1"; echo "== $2"; python3 tools/itch_fetch.py "$2" "$DL/$1" "${3:-}"; }
fetch nature   https://quaternius.itch.io/stylized-nature-megakit Standard
fetch village  https://quaternius.itch.io/medieval-village-megakit Standard
fetch props    https://quaternius.itch.io/fantasy-props-megakit Standard
fetch ubc      https://quaternius.itch.io/universal-base-characters Standard
fetch kaykit_platformer https://kaylousberg.itch.io/kaykit-platformer
fetch watercolor https://voxelcorelab.itch.io/watercolor-terrain-textures
# Direct downloads (not itch.io).
fetch_url() { mkdir -p "$DL/$1"; echo "== $2"; curl -fL --retry 3 -o "$DL/$1/$(basename "$2")" "$2"; }
fetch_url kenney_space https://kenney.nl/media/pages/assets/space-kit/20874c75ac-1677698978/kenney_space-kit.zip
# Music (CC0; the game uses renamed copies in game/assets/audio/music/).
OF=https://opengameart.org/sites/default/files; AR=https://archive.org/download
song() { mkdir -p "$DL/music"; echo "== $1"; curl -fL --retry 3 -A "Mozilla/5.0" -o "$DL/music/$1" "$2"; }
song mossbrook.mp3 "$OF/Komiku_-_02_-_Le_Grand_Village_0.mp3"
song glimmerbrook.mp3 "$OF/Komiku_-_03_-_Champ_de_tournesol_0.mp3"
song cloudtop.mp3 "$OF/Komiku_-_06_-_La_ville_aux_ponts_suspendus_0.mp3"
song canyon.mp3 "$OF/Komiku_-_08_-_Un_dsert_0.mp3"
song reef.mp3 "$OF/Komiku%20-%20Poupi%27s%20incredible%20adventures%20%21%20-%2039%20Swimming%20with%20the%20fish_0.mp3"
song frostfang.mp3 "$OF/Komiku%20-%20It%27s%20time%20for%20adventure%20vol%202%20-%2007%20Frozen%20Jungle_0.mp3"
song lanternwick.mp3 "$OF/Komiku%20-%20Poupi%27s%20incredible%20adventures%20%21%20-%2004%20The%20weekly%20fair_1.mp3"
song world_07.mp3 "$AR/Komiku-Its_Time_For_Adventure_Vol5/Komiku%20-%20It%27s%20time%20for%20adventure%20vol%205%20-%2005%20Xenobiological%20Forest.mp3"
song world_09.mp3 "$AR/Komiku01ChildhoodScene/Komiku_-_03_-_Big_person_tiny_cities_world_maps_theme.mp3"
song shop.mp3 "$AR/Komiku-Its_Time_For_Adventure_Vol4/Komiku_-_04_-_I_got_99_broadswords_but_this_one_isnt_one_stores_theme.mp3"
song title.mp3 "$OF/Komiku%20-%20Tale%20on%20the%20Late%20-%2001%20Tale%20on%20the%20Late%20%28Main%20Theme%29.mp3"
song boss.wav "$OF/Juhani%20Junkala%20-%20Epic%20Boss%20Battle%20%5BSeamlessly%20Looping%5D.wav"
song chiptune_adventures_ogg.zip "$OF/Juhani%20Junkala%20%5BChiptune%20Adventures%5D%20OGG.zip"
echo "Done. Unzip a pack over art/sourced/<pack>/ to refresh it, then re-copy what the game uses into game/assets/."
