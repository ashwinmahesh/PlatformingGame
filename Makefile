# Sproutblade: the one set of commands (plan Appendix E). Godot 4.7.2 on macOS.
SHELL       := /bin/bash
.SHELLFLAGS := -o pipefail -c
GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
G       := $(GODOT) --path game
LOGCHK  := tools/logcheck.sh

.PHONY: run import test loop lint check capture clip palette sfx music source-audio assets export-mac

run:
	$(G)

import:
	$(G) --headless --import 2>&1 | $(LOGCHK) > /dev/null

test: import
	$(G) --headless --fixed-fps 60 --quit-after 120000 res://tests/test_runner.tscn 2>&1 | $(LOGCHK)

loop: import
	$(G) --headless --fixed-fps 60 --quit-after 120000 res://tests/test_runner.tscn -- --only=test_slice_loop 2>&1 | $(LOGCHK)

lint:
	@command -v gdlint >/dev/null || { echo 'gdlint missing: pipx install "gdtoolkit==4.*"'; exit 1; }
	gdlint game/scripts game/tools game/tests && tools/forbid_godot3.sh

check: lint test

# Window flashes on screen for a few seconds (rendering needs a real window).
capture:
	$(G) --resolution 1600x900 res://tools/capture/capture.tscn -- --scene=$(SCENE) --out=$(CURDIR)/captures/$(notdir $(basename $(SCENE)))

palette:
	python3 tools/gen_palette.py

sfx:
	python3 audio/synth/sfx.py

music:
	python3 audio/synth/music.py

source-audio:
	python3 tools/source_audio.py

assets: palette sfx music source-audio import

# Needs export templates (Editor > Manage Export Templates) and an export_presets.cfg.
export-mac:
	mkdir -p builds/mac
	$(G) --headless --export-release "macOS" $(CURDIR)/builds/mac/Sproutblade.zip

# Scripted clip recorded with Movie Maker (window flashes). NAME=triple_jump|plunge_springcap|slash_combo|hub_portal
clip:
	rm -rf captures/clips/$(NAME) && mkdir -p captures/clips/$(NAME)
	$(G) --resolution 1280x720 --write-movie $(CURDIR)/captures/clips/$(NAME)/frame.png --fixed-fps 30 res://tools/clip/clip_runner.tscn -- --scenario=$(NAME)

check-scripts: import
	$(G) --headless res://tools/check_scripts.tscn 2>&1 | $(LOGCHK)
