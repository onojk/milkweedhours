#!/usr/bin/env python3
"""Soften an env.py envelope into a slow "breath" for hushed songs.

usage: breathe.py RAW.env OUT.env [attack_s] [release_s]
env.py's e has a fast attack (built for explosive choruses) and a steep 1.8
curve that leaves quiet songs sitting near 0. Here e is un-curved, run through
a slow one-pole follower (default 0.8 s up, 2.5 s down) and re-curved more
gently, so loud parts swell and settle instead of flashing.
h (transients) passes through untouched for looks that want a flicker.
Output format is identical (t e h), so cmds.py reads it as-is.
"""
import sys
import numpy as np

src, out = sys.argv[1], sys.argv[2]
att = float(sys.argv[3]) if len(sys.argv) > 3 else 0.8
rel = float(sys.argv[4]) if len(sys.argv) > 4 else 2.5
d = np.loadtxt(src, ndmin=2)
t, e, h = d[:, 0], d[:, 1], d[:, 2]
fps = round(1 / (t[1] - t[0])) if len(t) > 1 else 30
lin = np.clip(e, 0, 1) ** (1 / 1.8)
ka, kr = 1 / (att * fps), 1 / (rel * fps)
b = np.zeros_like(lin)
acc = lin[0] if len(lin) else 0.0
for i, v in enumerate(lin):
    acc += (v - acc) * (ka if v > acc else kr)
    b[i] = acc
b = np.clip(b, 0, 1) ** 1.3
with open(out, "w") as f:
    for i in range(len(t)):
        f.write(f"{t[i]:.4f} {b[i]:.4f} {h[i]:.4f}\n")
