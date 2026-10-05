#!/usr/bin/env python3
"""Copy chosen CC0 Kenney sounds into the game under our sound names (plan §12: find it first,
synthesise the gaps). Synthesised .wav files with the same name are removed so the sourced .ogg
wins. Run after `make sfx`: `make source-audio`. Every entry is listed in docs/assets/LICENSES.md.
"""
import pathlib, shutil

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "art/sourced"
OUT = ROOT / "game/assets/audio/sfx"
MUSIC = ROOT / "game/assets/audio/music"

SFX = {
    "slash": "kenney_rpg_audio/Audio/knifeSlice.ogg",
    "spin": "kenney_rpg_audio/Audio/knifeSlice2.ogg",
    "hit": "kenney_impact_sounds/Audio/impactPunch_medium_000.ogg",
    "land": "kenney_impact_sounds/Audio/impactSoft_medium_001.ogg",
    "step": "kenney_rpg_audio/Audio/footstep01.ogg",
    "step2": "kenney_rpg_audio/Audio/footstep04.ogg",
    "gate": "kenney_impact_sounds/Audio/impactWood_heavy_000.ogg",
    "boss_bonk": "kenney_impact_sounds/Audio/impactWood_heavy_002.ogg",
    "coconut_break": "kenney_impact_sounds/Audio/impactWood_heavy_003.ogg",
    "ui_blip": "kenney_interface_sounds/Audio/click_001.ogg",
    "checkpoint": "kenney_interface_sounds/Audio/confirmation_002.ogg",
    "heart": "kenney_interface_sounds/Audio/maximize_006.ogg",
    "seed": "kenney_music_jingles/Audio/Pizzicato jingles/jingles_PIZZI10.ogg",
}
MUSIC_FILES = {
    "victory": "kenney_music_jingles/Audio/Pizzicato jingles/jingles_PIZZI07.ogg",
}


def main():
    for name, rel in SFX.items():
        src = SRC / rel
        assert src.exists(), src
        shutil.copyfile(src, OUT / f"{name}.ogg")
        wav = OUT / f"{name}.wav"
        if wav.exists():
            wav.unlink()
            imp = OUT / f"{name}.wav.import"
            if imp.exists():
                imp.unlink()
    for name, rel in MUSIC_FILES.items():
        shutil.copyfile(SRC / rel, MUSIC / f"{name}.ogg")
        for ext in (".wav", ".wav.import"):
            p = MUSIC / f"{name}{ext}"
            if p.exists():
                p.unlink()
    print(f"source-audio: {len(SFX)} sfx, {len(MUSIC_FILES)} music cues from Kenney (CC0)")


if __name__ == "__main__":
    main()
