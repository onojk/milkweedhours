#!/usr/bin/env python3
"""Find the loudest or quietest stretch of a song (for test clips/excerpts).

usage: section.py ENV loud|quiet SECONDS [margin_s]
Prints the start time (s) of the SECONDS-long window with the highest/lowest
mean e, ignoring `margin_s` (default 8) at either end of the song.
"""
import sys
import numpy as np

d = np.loadtxt(sys.argv[1], ndmin=2)
mode, L = sys.argv[2], float(sys.argv[3])
margin = float(sys.argv[4]) if len(sys.argv) > 4 else 8.0
t, e = d[:, 0], d[:, 1]
fps = round(1 / (t[1] - t[0]))
k = max(1, int(L * fps))
m = np.convolve(e, np.ones(k) / k, "valid")  # m[i] = mean of window starting at frame i
idx = np.arange(len(m))
ok = (t[idx] >= margin) & (t[idx] + L <= t[-1] - margin)
if not ok.any():
    ok[:] = True
m = np.where(ok, m, np.nan)
i = int(np.nanargmax(m) if mode == "loud" else np.nanargmin(m))
print(f"{t[i]:.2f}")
