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
echo "Done. Unzip a pack over art/sourced/<pack>/ to refresh it, then re-copy what the game uses into game/assets/."
