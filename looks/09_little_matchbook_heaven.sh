#!/usr/bin/env bash
# 9 Little Matchbook Heaven — the brightest look: warm diner duotone (deep
# red shadows, cream highlights, a little original colour kept), a slow pan,
# and a match-flare glow by the milkweed flowers that flickers up on the
# louder beats (transients, decayed by lagfun so it flares, not strobes).
source "$(dirname "$0")/common.sh"
NUM=09
GRAIN=14
SW=$((IW*108/100/2*2)); SH=$((IH*108/100/2*2))
PREP="$(cover_fit $SW $SH),gblur=sigma=1,format=gbrp,
  colorchannelmixer=rr=.51:rg=.413:rb=.077:gr=.21:gg=.713:gb=.077:br=.21:bg=.413:bb=.377,
  lutrgb=r='120+0.53*val':g='28+0.84*val':b='30+0.70*val',format=yuv420p,eq=brightness=0.04:saturation=1.1"
FX=$((IW*22/100)); FY=$((IH*72/100))
GRAPH="
[src]crop@p=$IW:$IH:0:0,eq@L=brightness=0:saturation=1[img];
$(still fm "$(canvas $IW $IH),geq=lum='st(0,hypot(X-$FX,Y-$FY));clip(255*(0.7*exp(-pow(ld(0)/(0.16*W),2))+0.5*exp(-pow(ld(0)/(0.04*W),2))),0,255)',$MASK");
color=black:s=${IW}x${IH}:r=$FPS,format=yuv420p,lutyuv=y=0:u=128:v=128[blk];
[fm][blk]blend@f=all_mode=normal:all_opacity=0,lagfun=decay=0.9[flare];
[img][flare]blend=c0_mode=screen:c0_opacity=0.85:c1_mode=normal:c2_mode=normal,vignette=PI/5[core]"
CMDS=(
  "crop@p x=int(($SW-$IW)*(0.2+0.6*t/D))"
  "crop@p y=int(($SH-$IH)*(0.5+0.3*wob(2)))"
  'blend@f all_opacity=clip(1.8*h*(0.3+0.7*e)+0.05*rnd(5)*e,0,1)'
  'eq@L brightness=0.06*e'
  'eq@L saturation=1+0.2*e'
)
render "$@"
