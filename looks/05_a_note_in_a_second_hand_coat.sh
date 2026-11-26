#!/usr/bin/env bash
# 5 A Note in a Second-Hand Coat — faded colour, wool-fabric weave texture,
# a faded ruled-paper overlay (blue lines, red margin), the whole page
# swaying gently in 6/8 (one rock per bar, bar length from tools/tempo.py).
# Breath: sway depth and a small brightness swell.
source "$(dirname "$0")/common.sh"
NUM=05
GRAIN=12
SW=$((IW*106/100/2*2)); SH=$((IH*106/100/2*2))   # headroom for the rotation
ensure_env $NUM
P=$(python3 "$ROOT/tools/tempo.py" "$ROOT/work/$NUM.env" 3.0)
echo ">> sway period ${P}s"
PREP="$(cover_fit $SW $SH),gblur=sigma=1.2,format=yuv420p,hue=s=0.45,eq=contrast=0.8:brightness=0.02:gamma=1.05"
GRAPH="
color=0x808080:s=${SW}x${SH}:r=$FPS:d=1,format=gray,noise=c0s=60:c0f=u:all_seed=9,split[n1][n2];
[n1]gblur=sigma=3:sigmaV=0.4[wh];[n2]gblur=sigma=0.4:sigmaV=3[wv];
[wh][wv]blend=all_mode=average,lut=c0='clip(128+(val-128)*3,0,255)',format=yuv420p,
  lutyuv=u=128:v=128,trim=end_frame=1,$LOOP[wool];
$(still paper "color=0xEDE4CE:s=${SW}x${SH}:r=$FPS:d=1,format=yuv420p,
  drawgrid=x=-10:y=14:w=iw*2:h=30:t=2:color=0x4f78b0@0.9,
  drawbox=x=150:y=0:w=3:h=ih:color=0xb84a4a@0.8:t=fill,gblur=sigma=0.8");
[src][wool]blend=c0_mode=softlight:c0_opacity=0.6:c1_mode=normal:c2_mode=normal[a];
[a][paper]blend=c0_mode=multiply:c0_opacity=0.55:c1_mode=normal:c1_opacity=0.8:c2_mode=normal:c2_opacity=0.8,
  rotate@r=a=0:ow=$IW:oh=$IH:c=black,eq@L=brightness=0,vignette=PI/4.5[core]"
CMDS=(
  "rotate@r a=(0.006+0.008*e)*sin(2*pi*t/$P)"
  'eq@L brightness=-0.02+0.05*e'
)
render "$@"
