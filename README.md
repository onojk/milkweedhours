# Milkweed Hours — music videos

Ten cheap, quiet, grainy music videos for *Milkweed Hours* (Jonathan Kendall):
one apartment building after dark, built only from the monarch-on-milkweed
cover painting and plain ffmpeg filtergraphs. Pipeline reused from
[everycastshell](https://github.com/onojk/everycastshell).

- `looks/NN_*.sh` — one look per song (`--test SECONDS [START|loud|quiet]` for a short clip)
- `looks/common.sh` — shared renderer: title card, loudness → `sendcmd`, grain, encode
- `tools/env.py` — per-frame loudness envelope (copied from everycastshell)
- `tools/breathe.py` — slows that envelope into a "breath" (0.8 s swell, 2.5 s settle)
- `tools/cmds.py` — turns the envelope into an ffmpeg `sendcmd` script (copied)
- `tools/section.py` — loudest/quietest stretch of a song (test clips)
- `tools/tempo.py` — rough bar length for the 6/8 and waltz sways
- `render_all.sh` — renders everything to `out/NN-title.mp4` (`JOBS=2` for parallel)

Inputs (not committed): song WAVs in `~/Downloads` (`SONGS_DIR`), cover PNG
(`COVER_SRC`). Output: 1920x1080, 30 fps, H.264 veryfast CRF 24, AAC 320k;
the dynamic chain runs at 1280x720, grain at 640x360, both upscaled.

    ./render_all.sh --test 20 loud 01      # 20 s from the loudest part of song 1
    ./render_all.sh --test 20 quiet 08     # 20 s from the quietest part of song 8
    JOBS=2 ./render_all.sh                 # everything (10 last: it samples 1-9)
