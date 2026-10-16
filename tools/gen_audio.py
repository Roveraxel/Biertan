#!/usr/bin/env python3
"""Synthesizes all Biertan sound effects, ambience and music loops (no external assets)."""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1521)


def t_(d):
    return np.linspace(0, d, int(SR * d), endpoint=False)


def noise(d):
    return rng.standard_normal(int(SR * d))


def lp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, "low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return signal.sosfilt(signal.butter(order, [lo, hi], "band", fs=SR, output="sos"), x)


def env(n, a=0.01, r=0.1, curve=2.0):
    e = np.ones(n)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] = np.linspace(1, 0, nr) ** curve
    return e


def decay(t, k):
    return np.exp(-k * t)


def norm(x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def save(name, x, peak=0.85):
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (np.clip(norm(x, peak), -1, 1) * 32767).astype(np.int16))


def sweep(t, f0, f1, shape="sin"):
    f = f0 + (f1 - f0) * (t / t[-1])
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "saw":
        return signal.sawtooth(ph)
    if shape == "sq":
        return signal.square(ph)
    return np.sin(ph)


def loopify(x, fade):
    f = int(fade * SR)
    out = x[:-f].copy()
    w = np.linspace(0, 1, f)
    out[:f] = out[:f] * w + x[-f:] * (1 - w)
    return out


def note(freq, d, kind="bell", vel=1.0):
    t = t_(d)
    if kind == "bell":
        s = sum(a * np.sin(2 * np.pi * freq * m * t) * np.exp(-k * t) for m, a, k in [(1, 1, 1.6), (2.76, 0.4, 3.2), (5.4, 0.2, 5.0)])
    elif kind == "pluck":
        s = signal.sawtooth(2 * np.pi * freq * t) * np.exp(-5 * t)
        s = lp(s, 1800)
    else:  # pad
        s = (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 2.003 * t) + 0.3 * np.sin(2 * np.pi * freq * 0.5 * t))
        s *= np.sin(np.pi * t / d) ** 1.5
    return s * vel


def place(buf, s, at):
    i = int(at * SR)
    n = min(len(s), len(buf) - i)
    if n > 0:
        buf[i:i + n] += s[:n]


# ------------------------------------------------------------ sound effects
t = t_(0.18)
save("swing", lp(hp(noise(0.18), 500), 3500) * env(len(t), 0.02, 0.12) + 0.2 * sweep(t, 700, 200) * decay(t, 12))
t = t_(0.22)
save("hit", sweep(t, 150, 48) * decay(t, 16) + 0.7 * lp(noise(0.22), 1500) * decay(t, 60))
t = t_(0.32)
x = lp(sweep(t, 200, 105, "saw"), 900) * (1 + 0.3 * np.sin(2 * np.pi * 28 * t)) + 0.3 * lp(noise(0.32), 700)
save("hurt", x * env(len(t), 0.01, 0.2))
t = t_(0.26)
save("dodge", hp(lp(noise(0.26), 4000), 800) * np.sin(np.pi * t / 0.26) ** 1.5, 0.6)
t = t_(0.09)
a = np.sin(2 * np.pi * 988 * t) * decay(t, 18)
t2 = t_(0.22)
b = np.sin(2 * np.pi * 1319 * t2) * decay(t2, 12) + 0.3 * np.sin(2 * np.pi * 2638 * t2) * decay(t2, 20)
c = np.zeros(int(SR * 0.3)); place(c, a, 0); place(c, b, 0.07)
save("coin", c, 0.6)
t = t_(0.42)
x = np.sin(2 * np.pi * np.cumsum(220 + 300 * (t / 0.42) ** 1.5 + 18 * np.sin(2 * np.pi * 14 * t)) / SR) * env(len(t), 0.02, 0.15)
for at in (0.05, 0.16, 0.27):
    tb = t_(0.05); place(x, np.sin(2 * np.pi * np.cumsum(500 + 1500 * tb / 0.05) / SR) * decay(tb, 30) * 0.5, at)
save("potion", x, 0.6)
t = t_(0.05)
save("blip", np.sin(2 * np.pi * 520 * t) * env(len(t), 0.005, 0.04), 0.35)
t = t_(0.7)
ramp = t / 0.7
n1 = noise(0.7)
x = (lp(n1, 700) * (1 - ramp) + hp(lp(n1, 4500), 900) * ramp) * env(len(t), 0.1, 0.35) + 0.15 * sweep(t, 120, 380) * env(len(t), 0.1, 0.4)
for at in rng.uniform(0.05, 0.6, 14):
    tc = t_(0.01); place(x, hp(noise(0.01), 2500) * decay(tc, 300) * 0.8, at)
save("ignite", x, 0.7)


def howl(d, f_lo, f_hi, harm, vib=5.5, cut=2200):
    t = t_(d)
    f = f_lo + (f_hi - f_lo) * np.sin(np.pi * np.clip(t / d, 0, 1)) ** 0.7
    f = f * (1 + 0.012 * np.sin(2 * np.pi * vib * t) * np.minimum(1, t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = sum(a * np.sin(ph * (i + 1)) for i, a in enumerate(harm))
    x = lp(x, cut) * env(len(t), 0.25, 0.6, 1.5)
    d1 = np.zeros_like(x); d1[int(0.18 * SR):] = x[:-int(0.18 * SR)] * 0.35
    return x + d1


save("howl", howl(1.9, 300, 560, [1, 0.45, 0.2, 0.1]), 0.7)
x = howl(2.4, 80, 190, [1, 0.8, 0.6, 0.4, 0.25], 4.0, 1400) + 0.35 * lp(noise(2.4), 500) * env(int(2.4 * SR), 0.3, 1.0)
save("boss_howl", x, 0.85)
t = t_(1.7)
x = lp(sweep(t, 260, 40, "saw"), 700) + 0.6 * lp(noise(1.7), 900) * decay(t, 2.0)
save("boss_roar", x * env(len(t), 0.02, 0.9, 1.5), 0.9)
t = t_(1.3)
x = bp(noise(1.3), 1300, 3200) * (0.5 + 0.5 * np.sin(2 * np.pi * 5 * t)) * np.sin(np.pi * t / 1.3) ** 2
x += 0.4 * bp(noise(1.3), 400, 900) * np.sin(np.pi * t / 1.3) ** 2
save("whisper", x, 0.5)
t = t_(0.6)
save("flee", sweep(t, 600, 140, "saw") * 0.0 + hp(lp(noise(0.6), 2500), 300) * decay(t, 6), 0.4)

# ------------------------------------------------------------ ambience loops
d = 10.0
t = t_(d)
w1 = lp(noise(d), 380) * (0.55 + 0.45 * np.sin(2 * np.pi * t / 10 + 1))
w2 = bp(noise(d), 600, 1400) * (0.25 + 0.25 * np.sin(2 * np.pi * t * 0.3)) * 0.35
save("amb_wind", loopify(w1 + w2, 1.5), 0.55)
d = 8.0
x = lp(np.cumsum(noise(d)) / SR * 60, 250) * 0.5
x = x - np.mean(x)
for at in rng.uniform(0, d, 70):
    n = int(rng.uniform(0.004, 0.02) * SR)
    tc = np.arange(n) / SR
    place(x, bp(rng.standard_normal(n), 1200, 5000) * decay(tc, 250) * rng.uniform(0.2, 1.0), at)
save("amb_fire", loopify(x, 1.0), 0.5)

# ------------------------------------------------------------ music loops
def scale_notes(root, steps, octaves=(1, 2, 4)):
    return [root * (2 ** ((s + 12 * o) / 12)) for o in octaves for s in steps]


# hub: warm D-minor pentatonic over a soft drone
d = 24.0
m = np.zeros(int(d * SR))
for fr, vel in ((73.42, 0.9), (110.0, 0.6), (146.83, 0.35)):
    tt = t_(d)
    m += vel * (np.sin(2 * np.pi * fr * tt) + 0.4 * np.sin(2 * np.pi * fr * 2 * tt)) * (0.75 + 0.25 * np.sin(2 * np.pi * tt / 12 + fr))
pent = scale_notes(293.66, [0, 3, 5, 7, 10], (0, 1))
for at in np.arange(1.0, d - 3, 1.9):
    if rng.random() < 0.75:
        place(m, note(float(rng.choice(pent)), 3.2, "bell", 0.22), at + rng.uniform(0, 0.4))
for at in (0.0, 8.0, 16.0):
    for fr in (146.83, 174.61, 220.0):
        place(m, note(fr, 9.0, "pad", 0.12), at)
save("music_hub", loopify(lp(m, 4000), 1.5), 0.6)

# forest: dissonant low drone, sparse plucks, slow heartbeat
d = 28.0
m = np.zeros(int(d * SR))
tt = t_(d)
for fr, vel in ((55.0, 1.0), (58.27, 0.55), (82.41, 0.4)):
    m += vel * np.sin(2 * np.pi * fr * tt + 0.8 * np.sin(2 * np.pi * 0.11 * tt)) * (0.7 + 0.3 * np.sin(2 * np.pi * tt / 14 + fr))
m += 0.12 * lp(noise(d), 300)
dark = scale_notes(220.0, [0, 1, 6, 7, 10], (0, 1))
for at in np.arange(2.0, d - 4, 3.3):
    if rng.random() < 0.7:
        place(m, note(float(rng.choice(dark)), 2.5, "bell", 0.16), at + rng.uniform(0, 1.0))
for at in np.arange(0.0, d - 2, 2.0):
    tb = t_(0.25)
    beat = np.sin(2 * np.pi * 52 * tb) * decay(tb, 14)
    place(m, beat * 0.5, at)
    place(m, beat * 0.32, at + 0.28)
save("music_forest", loopify(lp(m, 3500), 1.5), 0.6)

# boss: pulsing war drum, low E drone, tense stabs. 100 bpm, 8 bars
bpm = 100
beat = 60.0 / bpm
d = beat * 32
m = np.zeros(int(d * SR))
tt = t_(d)
for fr, vel in ((41.2, 1.0), (61.74, 0.55), (82.41, 0.35)):
    m += vel * signal.sawtooth(2 * np.pi * fr * tt) * 0.25 * (0.6 + 0.4 * np.sin(2 * np.pi * tt / (beat * 8)))
m = lp(m, 500) * 1.5
for i in range(32):
    at = i * beat
    tb = t_(0.3)
    kick = (np.sin(2 * np.pi * np.cumsum(110 * np.exp(-8 * tb) + 42) / SR) * decay(tb, 10)) * (1.0 if i % 4 == 0 else 0.6)
    place(m, kick * 0.9, at)
    if i % 2 == 1:
        place(m, hp(noise(0.15), 800) * decay(t_(0.15), 28) * 0.25, at + beat / 2)
for bar in range(0, 8, 2):
    at = bar * 4 * beat
    for fr in (329.63, 349.23, 493.88):
        place(m, note(fr, 1.6, "pluck", 0.14), at + 2 * beat)
save("music_boss", loopify(lp(m, 4500), 1.0), 0.65)
print("audio written:", sorted(os.listdir(OUT)))
