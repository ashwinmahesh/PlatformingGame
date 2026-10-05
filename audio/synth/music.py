#!/usr/bin/env python3
"""Code-synthesised music cues (plan §12): scores are note lists rendered by small instruments.
Run: make music. Writes game/assets/audio/music/<cue>.wav as seamless loops.

These are the slice's music sample. Gate C decides whether music stays synthesised, is sourced,
or is composed by you.
"""
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from synth import *  # noqa: E402,F403

OUT = pathlib.Path(__file__).resolve().parents[2] / "game/assets/audio/music"

# Chords as (root midi, quality) per bar.
MAJOR = [0, 4, 7]
MINOR = [0, 3, 7]


def pluck(f, dur, bright=1.0):
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 6.0)
        v = math.sin(2 * math.pi * f * t) + 0.35 * bright * math.sin(4 * math.pi * f * t) * math.exp(-t * 14.0) + 0.15 * math.sin(6 * math.pi * f * t) * math.exp(-t * 20.0)
        out.append(v * e)
    return out


def flute(f, dur):
    n = int(dur * SR)
    env = env_adsr(n, 0.04, 0.08, 0.75, min(0.12, dur * 0.4))
    out, ph = [], 0.0
    for i in range(n):
        vib = 1.0 + 0.006 * math.sin(2 * math.pi * 5.5 * i / SR) * min(1.0, i / (0.2 * SR))
        ph += f * vib / SR
        out.append((math.sin(2 * math.pi * ph) + 0.18 * math.sin(4 * math.pi * ph)) * env[i])
    return out


def square_lead(f, dur):
    n = int(dur * SR)
    env = env_adsr(n, 0.005, 0.06, 0.5, min(0.08, dur * 0.4))
    out, ph = [], 0.0
    for i in range(n):
        ph += f / SR
        p = ph % 1.0
        out.append((0.6 if p < 0.25 else -0.6) * env[i])
    return lowpass(out, 3500)


def bass(f, dur):
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        out.append(osc(f * t, "tri") * math.exp(-t * 3.0) * min(1.0, i / 80.0))
    return out


def pad(freqs, dur):
    n = int(dur * SR)
    env = env_adsr(n, 0.25, 0.2, 0.7, 0.3)
    out = [0.0] * n
    for f in freqs:
        ph = 0.0
        for i in range(n):
            ph += f / SR
            out[i] += osc(ph, "saw") * 0.25
    return mul(lowpass(lowpass(out, 900), 1200), env)


def kick():
    t = sweep(0.22, 130, 42, "sine", curve=0.4)
    return mul(t, env_exp(len(t), 0.07))


def snare(seed):
    n = noise(0.16, seed)
    return mix(mul(bandpass_sweep(n, 3000, 1500), env_exp(len(n), 0.05)), gain(mul(sweep(0.08, 220, 160, "tri"), env_exp(int(0.08 * SR), 0.03)), 0.5))


def hat(seed):
    n = noise(0.05, seed)
    return mul(highpass(n, 6000), env_exp(len(n), 0.012))


def render(bpm, bars, chords, key_root, lead, seed, drums="light", pad_on=True, lead_gain=0.5, scale_minor=False):
    rng = random.Random(seed)
    beat = 60.0 / bpm
    total = bars * 4 * beat
    out = [0.0] * int(total * SR)
    pent = [0, 2, 4, 7, 9] if not scale_minor else [0, 3, 5, 7, 10]
    # A 2-bar motif repeated in an AABA shape gives the melody something to hum.
    motif_rhythm = [[0, 1], [1, 0.5], [1.5, 0.5], [2, 1], [3, 1], [4, 1.5], [5.5, 0.5], [6, 2]]
    motifs = []
    for _ in range(2):
        motifs.append([rng.choice([0, 1, 2, 3, 4, 2, 4]) for _ in motif_rhythm])
    for bar in range(bars):
        root, quality = chords[bar % len(chords)]
        t0 = bar * 4 * beat
        chord = [root + i for i in quality]
        if pad_on:
            add_at(out, pad([midi_hz(n) for n in chord], 4 * beat), t0, 0.22)
        for b in range(4):
            note = root - 12 if b % 2 == 0 else root - 5
            add_at(out, bass(midi_hz(note), beat * 0.95), t0 + b * beat, 0.55)
            if drums != "none":
                if b % 2 == 0:
                    add_at(out, kick(), t0 + b * beat, 0.7)
                if drums == "drive" and b % 2 == 1:
                    add_at(out, snare(bar * 4 + b), t0 + b * beat, 0.35)
                for h in range(2):
                    add_at(out, hat(bar * 8 + b * 2 + h), t0 + (b + h * 0.5) * beat, 0.18 if drums == "light" else 0.25)
        # Arpeggio plucks on 8ths.
        for e in range(8):
            n = chord[(e * 2 + bar) % 3] + 12
            add_at(out, pluck(midi_hz(n), beat * 0.9, 0.8), t0 + e * beat * 0.5, 0.16)
        # Melody: AABA over 8-bar phrases, 2 bars per motif.
        section = (bar // 2) % 4
        motif = motifs[1] if section == 2 else motifs[0]
        if bar % 2 == 0:
            for (start, length), deg in zip(motif_rhythm, motif):
                pc = pent[deg % len(pent)]
                m = key_root + 12 + pc
                # Nudge toward chord tones on strong beats.
                if start in (0, 2, 4, 6):
                    best = min(chord, key=lambda c: abs(((c - m) % 12)))
                    m += ((best - m) % 12) if ((best - m) % 12) <= 2 else 0
                add_at(out, lead(midi_hz(m), length * beat * 0.95), t0 + start * beat, lead_gain)
    return out


def loop_tail(x, total_len):
    """Fold the reverb tail back onto the start so the loop is seamless."""
    head, tail = x[:total_len], x[total_len:]
    for i, v in enumerate(tail):
        if i < len(head):
            head[i] += v
    return head


def make_cue(name, bpm, bars, **kw):
    raw = render(bpm, bars, **kw)
    total_len = len(raw)
    wet = reverb(raw, wet=0.22)
    write_wav(OUT / f"{name}.wav", loop_tail(wet, total_len), peak_db=-8.0)


def victory():
    out = []
    for i, m in enumerate([72, 76, 79, 84]):
        add_at(out, flute(midi_hz(m), 0.22), i * 0.16, 0.6)
    add_at(out, flute(midi_hz(88), 1.4), 0.7, 0.6)
    add_at(out, pad([midi_hz(n) for n in (60, 64, 67, 72)], 2.4), 0.6, 0.4)
    for i in range(6):
        add_at(out, pluck(midi_hz(84 + [0, 4, 7, 12, 16, 19][i]), 0.6), 0.8 + i * 0.08, 0.2)
    write_wav(OUT / "victory.wav", reverb(out, 0.3), peak_db=-8.0)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # C major: I  vi  IV  V
    make_cue("mossbrook", 92, 16, chords=[(60, MAJOR), (57, MINOR), (53, MAJOR), (55, MAJOR)], key_root=60, lead=flute, seed=7, drums="light", lead_gain=0.45)
    # G major, bouncy: I  V  vi  IV
    make_cue("glimmerbrook", 124, 16, chords=[(55, MAJOR), (62, MAJOR), (64, MINOR), (60, MAJOR)], key_root=67, lead=square_lead, seed=11, drums="light", lead_gain=0.32)
    # A minor, driving: i  VI  III  VII
    make_cue("boss", 140, 16, chords=[(57, MINOR), (53, MAJOR), (60, MAJOR), (55, MAJOR)], key_root=57, lead=square_lead, seed=23, drums="drive", lead_gain=0.3, scale_minor=True)
    world_cues()
    victory()
    print(f"music: wrote 8 cues to {OUT}")


def world_cues():
    # Build 4/5 worlds.
    # Cloudtop Steps, D major, airy: I  iii  IV  V
    make_cue("cloudtop", 108, 16, chords=[(62, MAJOR), (66, MINOR), (67, MAJOR), (69, MAJOR)], key_root=62, lead=flute, seed=31, drums="light", lead_gain=0.42)
    # Sunscorch Canyon, E minor, twangy: i  VII  VI  VII
    make_cue("canyon", 112, 16, chords=[(52, MINOR), (50, MAJOR), (48, MAJOR), (50, MAJOR)], key_root=64, lead=pluck, seed=37, drums="drive", lead_gain=0.55, scale_minor=True)
    # Bubbleton Reef, F major, bouncy island: I  IV  ii  V
    make_cue("reef", 118, 16, chords=[(53, MAJOR), (58, MAJOR), (55, MINOR), (60, MAJOR)], key_root=65, lead=pluck, seed=41, drums="light", lead_gain=0.6)
    # Frostfang Peak, A major, gentle and sparkly: I  V  vi  IV
    make_cue("frostfang", 96, 16, chords=[(57, MAJOR), (64, MAJOR), (66, MINOR), (62, MAJOR)], key_root=69, lead=flute, seed=43, drums="none", lead_gain=0.45)


if __name__ == "__main__":
    main()
