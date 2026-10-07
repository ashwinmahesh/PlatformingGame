#!/usr/bin/env bash
# Frame-time benchmark for every world and the hub (Build 7: dense worlds must hold 60 fps on the
# Mac Mini). Needs a window (not headless). Fails if any spot averages under MIN_FPS.
set -uo pipefail
cd "$(dirname "$0")/../game"
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
MIN_FPS=${MIN_FPS:-55}
status=0
for spec in "hub/mossbrook.tscn hub_arrival" "levels/w1/glimmerbrook.tscn w1_entrance" "levels/w1/glimmerbrook.tscn w1_cp_canopy" \
	"levels/w2/cloudtop.tscn w2_entrance" "levels/w2/cloudtop.tscn w2_cp_kingdom" "levels/w3/sunscorch.tscn w3_entrance" \
	"levels/w3/sunscorch.tscn w3_cp_town" "levels/w4/bubbleton.tscn w4_entrance" "levels/w4/bubbleton.tscn w4_cp_heights" \
	"levels/w5/frostfang.tscn w5_entrance" "levels/w5/frostfang.tscn w5_cp_rim" "levels/w6/lanternwick.tscn w6_cp_square" \
	"levels/w6/lanternwick.tscn w6_cp_rooftops" "levels/w7/glorbo.tscn w7_entrance" "levels/w7/glorbo.tscn w7_cp_orbit" \
	"levels/w7/glorbo.tscn w7_cp_village" $EXTRA; do
	set -- $spec
	line=$("$GODOT" --path . --resolution 1920x1080 --quit-after 3000 res://tools/dev/bench.tscn -- --scene=res://scenes/$1 --spawn=$2 --seconds=4 2>&1 | grep "^bench")
	fps=$(echo "$line" | sed -E 's/.*: ([0-9.]+) fps.*/\1/')
	echo "$2: $line"
	if [ -z "$fps" ] || [ "$(echo "$fps < $MIN_FPS" | bc)" = 1 ]; then echo "  SLOW"; status=1; fi
done
exit $status
