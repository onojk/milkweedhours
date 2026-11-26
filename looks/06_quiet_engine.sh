#!/usr/bin/env bash
# 6 Quiet Engine — night through a fogged windshield: a pre-blurred milky
# copy of the cover is crossfaded over the sharp one and clears a little on
# louder parts; faint green dashboard glow along the bottom edge; a slow
# idle drift of a couple of pixels.
source "$(dirname "$0")/common.sh"
NUM=06
GRAIN=14
SW=$((IW*104/100/2*2)); SH=$((IH*104/100/2*2)); CX=$(((SW-IW)/2)); CY=$(((SH-IH)/2))
NIGHT="colorchannelmixer=rr=.06:rg=.118:rb=.022:gr=.075:gg=.148:gb=.027:br=.096:bg=.189:bb=.035"
PREP="$(cover_fit $SW $SH),gblur=sigma=1,format=gbrp,$NIGHT,format=yuv420p,eq=contrast=1.05"
EXTRA_INPUTS=(-i "$COVER")   # 2 = fog
GRAPH="
[2:v]$(cover_fit $SW $SH),format=gbrp,$NIGHT,format=yuv420p,gblur=sigma=26,
  eq=brightness=0.16:contrast=0.45:saturation=0.5,$LOOP[fog];
[fog][src]blend@f=all_mode=normal:all_opacity=0.8,crop@v=$IW:$IH:$CX:$CY,eq@L=brightness=0[ws];
$(canvas $IW $IH),geq=lum='140*pow(clip((Y/H-0.78)/0.22,0,1),1.6)*(0.55+0.45*sin(PI*X/W))',gblur=sigma=12,split[gm1][gm2];
color=0x33c27a:s=${IW}x${IH}:r=$FPS:d=1,format=yuva420p[gc];
[gc][gm1]alphamerge,trim=end_frame=1,$LOOP[gcol];
[gm2]$MASK,trim=end_frame=1,$LOOP[gl];
[ws][gcol]overlay=eval=init:format=yuv420[w1];
[w1][gl]blend@g=c0_mode=screen:c0_opacity=0.1:c1_mode=normal:c2_mode=normal,vignette=PI/4.5[core]"
CMDS=(
  'blend@f all_opacity=clip(0.85-0.45*e,0,1)'
  "crop@v x=int($CX+3*wob(3))"
  "crop@v y=int($CY+2*wob(4))"
  'blend@g c0_opacity=clip(0.05+0.25*e,0,1)'
  'eq@L brightness=-0.02+0.04*e'
)
render "$@"
