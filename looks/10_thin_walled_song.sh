#!/usr/bin/env bash
# 10 Thin-Walled Song — the neighbours: slow 4 s crossfades through excerpts
# of looks 1-9 in order (each the loudest stretch of that video, past its
# title card), slightly muffled (desaturated, softened) as if heard through
# the wall; fades to black at the end and the title card returns.
# Needs the full renders out/01..09 (render_all.sh renders 10 last).
# Breath: a small brightness swell.
source "$(dirname "$0")/common.sh"
NUM=10
GRAIN=8          # the excerpts already carry their own grain
TITLE_END=7
X=4              # crossfade length
ensure_env $NUM
D=$(song_dur $NUM)
L=$(python3 -c "print(round(($D-$X)/9,3))")   # 9 segments + one tail fade = D
C=$(python3 -c "print(round($L+$X,3))")        # excerpt length
EXTRA_INPUTS=()
for i in 1 2 3 4 5 6 7 8 9; do
  n=0$i; src=$(ls "$ROOT"/out/$n-*.mp4 2>/dev/null | head -1 || true)
  [[ -n $src ]] || { echo "!! need out/$n-*.mp4 (render looks 1-9 first)"; exit 1; }
  ensure_env $n
  nb="$ROOT/work/nbr$n.mp4"
  if [[ ! -f $nb || $nb -ot $src ]]; then
    st=$(python3 "$ROOT/tools/section.py" "$ROOT/work/$n.env" loud "$C" 8)
    ffmpeg -v error -y -ss "$st" -t "$C" -i "$src" -an -vf "scale=$IW:$IH,fps=$FPS" \
      -c:v libx264 -preset veryfast -crf 16 "$nb"
  fi
  EXTRA_INPUTS+=(-i "$nb")
done
PREP="scale=16:16"
GRAPH="[src]nullsink;"
for i in 1 2 3 4 5 6 7 8 9; do GRAPH+="[$((i+1)):v]settb=AVTB,setpts=PTS-STARTPTS,format=yuv420p[v$i];"; done
prev=v1
for i in 2 3 4 5 6 7 8 9; do
  off=$(python3 -c "print(round($L*($i-1),3))")
  GRAPH+="[$prev][v$i]xfade=transition=fade:duration=$X:offset=$off[x$i];"; prev=x$i
done
FO=$(python3 -c "print(round($D-8,2))")
GRAPH+="[$prev]sendcmd=f=$ROOT/work/$NUM.cmd,hue=s=0.85,gblur=sigma=1.1,eq@L=brightness=0,
  fade=t=out:st=$FO:d=6,vignette=PI/4.5[core]"
CMDS=('eq@L brightness=-0.02+0.05*e')
render "$@"
