#!/usr/bin/env python3
"""Turn an envelope file into an ffmpeg sendcmd script.

usage: cmds.py ENV.txt OUT.cmd 'target cmd=EXPR' ['target cmd=EXPR' ...]
EXPR is a Python expression over: e (loudness 0..1), h (hit 0..1), t (seconds),
n (frame index), D (song duration), E (cumulative loudness: integral of e dt,
seconds — use for spin/scroll that speeds up when loud), rnd(k) (deterministic
per-frame random 0..1, stream k), wob(k) (smooth wander -1..1, stream k),
clip(v,a,b), plus math/np helpers.
Example: cmds.py work/01.env work/01.cmd 'eq@L brightness=-0.15+0.25*e'
Env CMD_START=S drops frames before S and shifts times (expressions still see
absolute t). A command is only emitted when its (rounded) value changes.
"""
import math, os, sys
import numpy as np

env_path, out_path, specs = sys.argv[1], sys.argv[2], sys.argv[3:]
rows = [tuple(map(float, l.split())) for l in open(env_path) if l.strip()]
D = rows[-1][0] if rows else 0.0
parsed = []
for s in specs:
    lhs, expr = s.split("=", 1)
    target, cmd = lhs.split()
    parsed.append((target, cmd, compile(expr, s, "eval")))

fps = round(1 / (rows[1][0] - rows[0][0])) if len(rows) > 1 else 30
cumE, acc = [], 0.0
for _, e_, _ in rows:
    acc += e_ / fps
    cumE.append(acc)


def rnd(k=0):
    x = math.sin(ns["n"] * 12.9898 + k * 78.233) * 43758.5453
    return x - math.floor(x)


def wob(k=0):
    t_ = ns["t"]
    return (math.sin(t_ * 0.73 + k * 1.7) * 0.5 + math.sin(t_ * 1.91 + k * 4.1) * 0.3
            + math.sin(t_ * 4.37 + k * 2.3) * 0.2)


ns = {"rnd": rnd, "wob": wob, "math": math, "np": np, "D": D, "clip": lambda v, a, b: max(a, min(b, v)),
      "sin": math.sin, "cos": math.cos, "pi": math.pi}
last = [None] * len(parsed)
START = float(os.environ.get("CMD_START", "0"))  # test renders: shift timeline
with open(out_path, "w") as f:
    for n, (t, e, h) in enumerate(rows):
        if t < START:
            continue
        ns.update(t=t, e=e, h=h, n=n, E=cumE[n])
        parts = []
        for i, (target, cmd, code) in enumerate(parsed):
            v = eval(code, ns)
            v = int(v) if isinstance(v, (int, np.integer)) else round(float(v), 4)
            if v != last[i]:
                last[i] = v
                parts.append(f"{target} {cmd} {v}")
        if parts:
            f.write(f"{t - START:.4f} " + ", ".join(parts) + ";\n")
