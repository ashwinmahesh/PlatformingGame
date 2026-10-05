"""Tiny code synthesiser shared by sfx.py and music.py (plan §12). Standard library only.

Every sound goes through the same normalisation so synthesised sounds sit together.
"""
import math
import random
import struct
import wave

SR = 32000


def silence(seconds):
    return [0.0] * int(seconds * SR)


def env_adsr(n, a=0.005, d=0.05, s=0.6, r=0.1):
    out = []
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(n - a_n - d_n - r_n, 0)
    for i in range(n):
        if i < a_n:
            v = i / max(a_n, 1)
        elif i < a_n + d_n:
            v = 1.0 - (1.0 - s) * (i - a_n) / max(d_n, 1)
        elif i < a_n + d_n + s_n:
            v = s
        else:
            v = s * max(0.0, 1.0 - (i - a_n - d_n - s_n) / max(r_n, 1))
        out.append(v)
    return out


def env_exp(n, decay):
    return [math.exp(-i / (decay * SR)) for i in range(n)]


def sweep(seconds, f0, f1, shape="sine", curve=1.0, vibrato=0.0, vib_rate=6.0):
    n = int(seconds * SR)
    out, phase = [], 0.0
    for i in range(n):
        t = i / max(n - 1, 1)
        f = f0 + (f1 - f0) * (t ** curve)
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * vib_rate * i / SR)
        phase += f / SR
        out.append(osc(phase, shape))
    return out


def osc(phase, shape):
    p = phase % 1.0
    if shape == "sine":
        return math.sin(2 * math.pi * p)
    if shape == "square":
        return 1.0 if p < 0.5 else -1.0
    if shape == "saw":
        return 2.0 * p - 1.0
    if shape == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    raise ValueError(shape)


def noise(seconds, seed=1):
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(int(seconds * SR))]


def lowpass(x, cutoff):
    out, y = [], 0.0
    k = 1.0 - math.exp(-2 * math.pi * cutoff / SR)
    for v in x:
        y += k * (v - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [a - b for a, b in zip(x, lp)]


def bandpass_sweep(x, f0, f1):
    """Crude moving band: high-pass then low-pass with cutoffs that sweep."""
    out, y_lp, y_lp2 = [], 0.0, 0.0
    n = len(x)
    for i, v in enumerate(x):
        f = f0 + (f1 - f0) * i / max(n - 1, 1)
        k_hi = 1.0 - math.exp(-2 * math.pi * f * 1.6 / SR)
        k_lo = 1.0 - math.exp(-2 * math.pi * f * 0.6 / SR)
        y_lp += k_hi * (v - y_lp)
        y_lp2 += k_lo * (y_lp - y_lp2)
        out.append(y_lp - y_lp2)
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def gain(a, g):
    return [x * g for x in a]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def add_at(dst, src, start_s, g=1.0):
    start = int(start_s * SR)
    need = start + len(src)
    if need > len(dst):
        dst.extend([0.0] * (need - len(dst)))
    for i, v in enumerate(src):
        dst[start + i] += v * g


def reverb(x, wet=0.18, delays=(0.031, 0.047, 0.073, 0.097), fb=0.45):
    out = list(x) + [0.0] * int(0.4 * SR)
    for d in delays:
        dn = int(d * SR)
        buf = [0.0] * len(out)
        for i in range(len(out)):
            prev = buf[i - dn] if i >= dn else 0.0
            src = x[i] if i < len(x) else 0.0
            buf[i] = src + prev * fb
        for i in range(len(out)):
            out[i] += buf[i] * wet / len(delays)
    return out


def normalize(x, peak_db=-6.0):
    peak = max((abs(v) for v in x), default=0.0)
    if peak <= 0:
        return x
    target = 10 ** (peak_db / 20.0)
    return [v * target / peak for v in x]


def fade_out(x, seconds=0.01):
    n = min(int(seconds * SR), len(x))
    for i in range(n):
        x[len(x) - n + i] *= 1.0 - i / n
    return x


def write_wav(path, x, peak_db=-6.0):
    x = fade_out(normalize(x, peak_db))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in x))


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)
