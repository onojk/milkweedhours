#!/usr/bin/env python3
"""Per-frame loudness envelope for a song.

usage: env.py SONG.wav OUT.txt [fps]
Writes one line per video frame:  t  e  h
  e = loudness 0..1 (percentile-normalised per song, curved so quiet verses ~0
      and explosive choruses ~1; fast attack, slower release)
  h = transient/hit 0..1 (how far the instant level jumps above the recent average)
"""
import subprocess, sys
import numpy as np

wav, out = sys.argv[1], sys.argv[2]
fps = int(sys.argv[3]) if len(sys.argv) > 3 else 30
SR = 48000
hop = SR // fps

raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", wav, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
    check=True, stdout=subprocess.PIPE).stdout
x = np.frombuffer(raw, dtype=np.float32)
n = int(np.ceil(len(x) / hop))
x = np.pad(x, (0, n * hop - len(x)))
rms = np.sqrt(np.mean(x.reshape(n, hop) ** 2, axis=1) + 1e-12)
db = 20 * np.log10(rms)

voiced = db[db > -60]
lo = np.percentile(voiced, 20) if len(voiced) else -40
hi = np.percentile(voiced, 99.5) if len(voiced) else 0
lin = np.clip((db - lo) / max(hi - lo, 1e-6), 0, 1)

# fast attack / slow release follower
e = np.zeros(n)
acc = 0.0
for i, v in enumerate(lin):
    acc += (v - acc) * (0.6 if v > acc else 0.08)
    e[i] = acc
e = e ** 1.8  # push quiet verses toward stillness, keep choruses hot

# transients: instant level minus ~0.5 s running mean
k = max(1, fps // 2)
slow = np.convolve(lin, np.ones(k) / k, mode="full")[:n]
h = np.clip((lin - slow) * 4.0, 0, 1) * np.clip(lin * 1.5, 0, 1)

with open(out, "w") as f:
    for i in range(n):
        f.write(f"{i / fps:.4f} {e[i]:.4f} {h[i]:.4f}\n")
