#!/usr/bin/env python3
"""Synthesised starter sound set (plan §12 recipes). Run: make sfx

Writes game/assets/audio/sfx/<name>.wav. Every sound gets the same normalisation.
"""
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from synth import *  # noqa: E402,F403

OUT = pathlib.Path(__file__).resolve().parents[2] / "game/assets/audio/sfx"


def boing(f0, f1, dur, shape="sine"):
    tone = sweep(dur, f0, f1, shape, curve=0.6)
    return mul(tone, env_exp(len(tone), dur * 0.45))


def thump(dur=0.12, cutoff=380, seed=3):
    n = noise(dur, seed)
    return mul(lowpass(n, cutoff), env_exp(len(n), dur * 0.25))


def chime(notes, step=0.07, dur=0.35, shape="sine"):
    out = []
    for i, m in enumerate(notes):
        t = sweep(dur, midi_hz(m), midi_hz(m), shape)
        t = mul(t, env_exp(len(t), dur * 0.35))
        add_at(out, t, i * step)
    return out


def slash(dur=0.16, f0=6000, f1=700, seed=5):
    n = noise(dur, seed)
    return mul(bandpass_sweep(n, f0, f1), env_adsr(len(n), 0.01, 0.04, 0.6, dur * 0.5))


SOUNDS = {}


def sound(fn):
    SOUNDS[fn.__name__] = fn
    return fn


@sound
def jump1():
    return boing(330, 560, 0.16)


@sound
def jump2():
    return mix(boing(392, 720, 0.17), gain(chime([88, 91], 0.04, 0.15), 0.25))


@sound
def jump3():
    return mix(boing(440, 980, 0.22), gain(chime([84, 88, 91, 96], 0.045, 0.22), 0.4))


@sound
def land():
    return thump(0.09, 300)


@sound
def slash_():
    return slash()


@sound
def spin():
    return concat(slash(0.14, 7000, 900, 6), slash(0.2, 6000, 600, 7))


@sound
def hit():
    click = mul(sweep(0.06, 900, 200, "square"), env_exp(int(0.06 * SR), 0.012))
    return mix(click, gain(thump(0.08, 2500, 9), 0.7))


@sound
def bounce():
    return boing(260, 620, 0.2, "tri")


@sound
def springcap():
    t = sweep(0.45, 220, 700, "sine", curve=0.5, vibrato=0.12, vib_rate=22)
    return mul(t, env_exp(len(t), 0.2))


@sound
def plunge():
    return mul(sweep(0.22, 900, 250, "tri"), env_adsr(int(0.22 * SR), 0.01, 0.05, 0.7, 0.08))


@sound
def plunge_land():
    return mix(thump(0.25, 220, 11), gain(boing(120, 60, 0.25), 0.8))


@sound
def hurt():
    return mix(boing(520, 220, 0.2, "square"), gain(thump(0.1, 1500), 0.5))


@sound
def splash():
    n = noise(0.5, 13)
    return mul(bandpass_sweep(n, 4000, 500), env_exp(len(n), 0.15))


@sound
def poof():
    n = noise(0.25, 17)
    return mul(lowpass(n, 1800), env_adsr(len(n), 0.02, 0.05, 0.5, 0.15))


@sound
def defeat():
    return concat(boing(440, 330, 0.18, "tri"), boing(330, 220, 0.2, "tri"), boing(220, 110, 0.35, "tri"))


@sound
def slime_hop():
    t = sweep(0.18, 200, 420, "sine", vibrato=0.08, vib_rate=30)
    return mul(t, env_exp(len(t), 0.07))


@sound
def slime_land():
    return mix(gain(boing(180, 90, 0.14), 0.8), thump(0.08, 500, 21))


@sound
def slime_hurt():
    return mul(sweep(0.16, 600, 300, "sine", vibrato=0.15, vib_rate=35), env_exp(int(0.16 * SR), 0.06))


@sound
def slime_pop():
    bloop = mul(sweep(0.25, 700, 150, "sine"), env_exp(int(0.25 * SR), 0.08))
    bubbles = []
    for i in range(6):
        add_at(bubbles, mul(sweep(0.04, 900 + i * 150, 1400 + i * 200), env_exp(int(0.04 * SR), 0.012)), 0.03 + i * 0.03, 0.4)
    return mix(bloop, bubbles)


@sound
def notice():
    return chime([81, 86], 0.06, 0.18, "square")


@sound
def heart():
    return chime([79, 83, 86], 0.06, 0.3)


@sound
def seed():
    return chime([72, 76, 79, 84, 88], 0.07, 0.45)


@sound
def checkpoint():
    return chime([67, 74, 79], 0.1, 0.5, "tri")


@sound
def warp():
    rise = sweep(0.7, 200, 1400, "sine", curve=2.0)
    shimmer = gain(chime([84, 88, 91, 96, 100], 0.09, 0.3), 0.4)
    return mix(mul(rise, env_adsr(len(rise), 0.05, 0.1, 0.7, 0.3)), shimmer)


@sound
def gate():
    n = noise(0.5, 23)
    return mix(mul(lowpass(n, 600), env_adsr(len(n), 0.02, 0.1, 0.6, 0.25)), gain(boing(110, 80, 0.4), 0.6))


@sound
def boss_roar():
    t = sweep(1.1, 90, 70, "saw", vibrato=0.06, vib_rate=7)
    t = [math.tanh(v * 2.5) for v in t]
    n = gain(lowpass(noise(1.1, 29), 900), 0.5)
    return mul(mix(t, n), env_adsr(len(t), 0.08, 0.2, 0.7, 0.4))


@sound
def boss_roll():
    t = sweep(0.8, 60, 120, "saw")
    return mul(lowpass(t, 500), env_adsr(len(t), 0.1, 0.1, 0.8, 0.3))


@sound
def boss_bonk():
    knock = mul(sweep(0.3, 300, 140, "tri"), env_exp(int(0.3 * SR), 0.06))
    return mix(knock, thump(0.3, 800, 31))


@sound
def boss_slam():
    return mix(gain(boing(90, 40, 0.5), 1.0), thump(0.4, 260, 37))


@sound
def boss_hurt():
    return mul(sweep(0.4, 500, 200, "sine", vibrato=0.2, vib_rate=18), env_exp(int(0.4 * SR), 0.15))


@sound
def boss_pop():
    return mix(thump(0.4, 1200, 41), slime_pop(), gain(chime([72, 76, 79, 84, 88, 91], 0.06, 0.5), 0.5))


@sound
def ui_blip():
    return chime([84], 0.0, 0.07, "square")


# --- Build 5 magic ----------------------------------------------------------------------------

@sound
def fireball():
    n = noise(0.32, 51)
    whoosh = mul(bandpass_sweep(n, 600, 3200), env_adsr(len(n), 0.01, 0.05, 0.7, 0.15))
    body = mul(sweep(0.32, 180, 420, "saw", curve=0.7), env_exp(int(0.32 * SR), 0.12))
    return mix(whoosh, gain(lowpass(body, 900), 0.6))


@sound
def fire_pop():
    crack = mul(highpass(noise(0.18, 53), 1500), env_exp(int(0.18 * SR), 0.03))
    return mix(thump(0.25, 700, 55), gain(crack, 0.7))


@sound
def thunder():
    crack = mul(highpass(noise(0.12, 57), 2000), env_exp(int(0.12 * SR), 0.02))
    rumble = mul(lowpass(noise(1.1, 59), 220), env_adsr(int(1.1 * SR), 0.02, 0.2, 0.6, 0.6))
    zap = mul(sweep(0.35, 1800, 120, "square", curve=0.4), env_exp(int(0.35 * SR), 0.08))
    return mix(gain(crack, 0.9), gain(rumble, 1.2), gain(zap, 0.35))


@sound
def dash():
    n = noise(0.22, 61)
    return mix(mul(bandpass_sweep(n, 4000, 900), env_adsr(len(n), 0.005, 0.03, 0.6, 0.1)), gain(boing(500, 900, 0.12), 0.3))


@sound
def glide():
    n = noise(0.5, 63)
    air = mul(lowpass(n, 1800), env_adsr(len(n), 0.08, 0.1, 0.5, 0.25))
    return mix(gain(air, 0.5), gain(chime([79, 84, 88], 0.06, 0.3), 0.5))


@sound
def ability():
    fanfare = chime([67, 72, 76, 79, 84, 88, 91, 96], 0.075, 0.7)
    shimmer = gain(chime([96, 100, 103, 108], 0.05, 0.5), 0.35)
    return reverb(mix(fanfare, shimmer), wet=0.25)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in SOUNDS.items():
        name = name.rstrip("_")
        write_wav(OUT / f"{name}.wav", fn(), peak_db=-6.0)
    print(f"sfx: wrote {len(SOUNDS)} sounds to {OUT}")


if __name__ == "__main__":
    main()
