#!/usr/bin/env bash
# 2 Coffee Gone Cold — rising steam wisps (blurred noise drifting up, fading
# toward the top) over the cover; the whole grade slowly cools from warm brown
# to grey-blue across the song (crossfade of two stills graded once).
# Breath: steam opacity and a small brightness swell; the wisps wander sideways.
source "$(dirname "$0")/common.sh"
NUM=02
GRAIN=14
WARM="colorchannelmixer=rr=.45:rg=.45:rb=.12:gr=.32:gg=.42:gb=.1:br=.2:bg=.28:bb=.08"
COOL="colorchannelmixer=rr=.25:rg=.4:rb=.1:gr=.28:gg=.45:gb=.12:br=.33:bg=.5:bb=.17"
PREP="$(cover_fit $IW $IH),gblur=sigma=1.5,format=gbrp,$WARM,format=yuv420p,eq=contrast=0.85"
EXTRA_INPUTS=(-i "$COVER")   # 2 = cool grade
SW=$((IW+96))
GRAPH="
[2:v]$(cover_fit $IW $IH),gblur=sigma=1.5,format=gbrp,$COOL,format=yuv420p,eq=contrast=0.85,$LOOP[cool];
color=0x808080:s=$((SW/8))x$((IH/8)):r=$FPS:d=1,format=gray,noise=c0s=100:c0f=u:all_seed=5,
  lut=c0='clip((val-150)*6,0,255)',scale=$SW:$IH:flags=bicubic,gblur=sigma=6:sigmaV=30,lut=c0='clip(val*3.5,0,255)',
  trim=end_frame=1,split[s1][s2];[s1][s2]vstack,$LOOP,crop@s=$IW:$IH:48:'mod(n,$IH)'[steam0];
$(still fadeup "$(canvas $IW $IH),geq=lum='255*pow(Y/H,1.3)*(0.4+0.6*exp(-pow((X-0.45*W)/(0.35*W),2)))'");
[steam0][fadeup]blend=all_mode=multiply,$MASK[steam];
[cool][src]blend@x=all_mode=normal:all_opacity=0[g];
[g][steam]blend@st=c0_mode=screen:c0_opacity=0.2:c1_mode=normal:c2_mode=normal,
  eq@L=brightness=0,vignette=PI/4.2[core]"
CMDS=(
  # 0 = warm brown at the start, 1 = grey-blue at the end (smoothstep)
  "blend@x all_opacity=(lambda p: p*p*(3-2*p))(clip(t/D,0,1))"
  "crop@s x=int(48+40*wob(1))"
  'blend@st c0_opacity=clip(0.3+0.4*e,0,1)'
  'eq@L brightness=-0.02+0.05*e'
)
render "$@"
