#!/usr/bin/env bash
# 3 Streetlight Halo — sodium-orange monochrome, dark vignette centred on the
# lamp, a soft halo glow that pulses with loudness, and one small dark moth
# speck drifting and fluttering around the halo.
source "$(dirname "$0")/common.sh"
NUM=03
GRAIN=16
HX=$((IW*60/100)); HY=$((IH*28/100))   # lamp / halo centre
PREP="$(cover_fit $IW $IH),gblur=sigma=1.5,format=gbrp,
  colorchannelmixer=rr=.32:rg=.6:rb=.12:gr=.2:gg=.38:gb=.07:br=.05:bg=.1:bb=.02,
  format=yuv420p,eq=contrast=0.9:brightness=-0.04,vignette=angle=PI/3:x0=$HX:y0=$HY"
HALO="st(0,hypot(X-$HX,Y-$HY));clip(255*(0.75*exp(-pow(ld(0)/(0.16*W),2))+0.35*exp(-ld(0)/(0.3*W))),0,255)"
GRAPH="
$(still halo "$(canvas $IW $IH),geq=lum='$HALO',$MASK");
$(still moth "color=black:s=16x12:r=$FPS:d=1,format=yuva420p,
  geq=lum=18:cb=128:cr=128:a='235*exp(-(pow((X-7.5)/4.2,2)+pow((Y-5.5)/3.2,2)))'");
[src][halo]blend@h=c0_mode=screen:c0_opacity=0.3:c1_mode=normal:c2_mode=normal,eq@L=brightness=0[lit];
[lit][moth]overlay@m=x=$HX:y=$HY:format=yuv420[core]"
CMDS=(
  'blend@h c0_opacity=clip(0.2+0.6*e,0,1)'
  'eq@L brightness=-0.03+0.05*e'
  # slow loops around the lamp + a little wing jitter
  "overlay@m x=int($HX-8+0.13*$IW*sin(0.37*t)+0.04*$IW*wob(5)+4*(rnd(6)-0.5))"
  "overlay@m y=int($HY-6+0.1*$IH*sin(0.53*t+1.3)+0.04*$IH*wob(7)+4*(rnd(8)-0.5))"
)
render "$@"
