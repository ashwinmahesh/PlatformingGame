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
# Quaternius Animated Dinosaur Bundle (CC0) from Poly Pizza: one .glb per dinosaur (World 9).
for pair in Parasaurolophus:47b9d0bd-cddb-49be-b072-12201def24a9 TRex:34eed102-48f0-43dd-bc6f-ef7a6dfddfbb \
            Velociraptor:c1f0c4cb-c84f-415c-8323-d8cb871a2126 Triceratops:6aa1f3ff-b9b3-4bb5-9d85-b2ffa514f0cc \
            Stegosaurus:6f8f4ac6-f9e8-488d-97a8-220b9b2fd02a Apatosaurus:7b873860-f23f-4266-b341-5c5e6770cfa0; do
  mkdir -p "$DL/quaternius_dinosaurs"; echo "== ${pair%%:*}"
  curl -fsSL -A "Mozilla/5.0" -o "$DL/quaternius_dinosaurs/${pair%%:*}.glb" "https://static.poly.pizza/${pair#*:}.glb"
done
echo "Done. Unzip a pack over art/sourced/<pack>/ to refresh it, then re-copy what the game uses into game/assets/."
