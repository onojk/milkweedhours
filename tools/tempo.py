#!/usr/bin/env python3
"""Rough beat period from an envelope, for tempo-locked sways.

usage: tempo.py ENV TARGET_SECONDS
Estimates the beat period (40-160 bpm) by autocorrelating the onset curve
(h plus rises in e), then prints the whole number of beats closest to
TARGET_SECONDS, in seconds — e.g. one 6/8 bar or one waltz bar of sway.
Falls back to TARGET_SECONDS if there is no clear pulse.
"""
import sys
import numpy as np

d = np.loadtxt(sys.argv[1], ndmin=2)
target = float(sys.argv[2])
t, e, h = d[:, 0], d[:, 1], d[:, 2]
fps = round(1 / (t[1] - t[0]))
o = h + np.clip(np.diff(e, prepend=e[0]), 0, None) * 10
o = o - o.mean()
if not np.any(o):
    print(f"{target:.4f}"); sys.exit()
ac = np.correlate(o, o, "full")[len(o) - 1:]
lo, hi = int(fps * 60 / 160), int(fps * 60 / 40)
lags = np.arange(lo, hi + 1)
# mild preference for ~90 bpm so octave errors land somewhere musical
w = np.exp(-0.5 * (np.log2(lags / (fps * 60 / 90))) ** 2)
score = ac[lags] * w
if ac[0] <= 0 or score.max() <= 0.05 * ac[0]:
    print(f"{target:.4f}"); sys.exit()
beat = lags[int(np.argmax(score))] / fps
n = max(1, round(target / beat))
print(f"{n * beat:.4f}")
