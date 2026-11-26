#!/usr/bin/env bash
# 4 Saint of the Bus Stop — rainy night teal, faint two-depth rain (smeared
# a little by lagfun), and slow headlight sweeps crossing the frame every
# 26 s, alternating direction. Breath: rain, headlight strength, brightness.
source "$(dirname "$0")/common.sh"
NUM=04
GRAIN=12
PREP="$(cover_fit $IW $IH),gblur=sigma=1.4,format=gbrp,
  colorchannelmixer=rr=.04:rg=.08:rb=.02:gr=.126:gg=.248:gb=.046:br=.138:bg=.271:bb=.051,
  format=yuv420p,eq=contrast=0.9:brightness=-0.05"
# sparse noise dots stretched into streaks, stacked so a scrolling crop wraps
# (from everycastshell look 01; noise on mid-grey spans ~79..177)
rain_layer() {  # $1=label $2=rows $3=threshold $4=px/frame $5=seed
  echo "color=0x808080:s=$((IW/2))x$2:r=$FPS:d=1,format=gray,noise=c0s=100:c0f=u:all_seed=$5,
  lut=c0='if(gt(val,$3),255,0)',trim=end_frame=1,scale=$IW:$IH:flags=neighbor,
  avgblur=sizeX=1:sizeY=3,split[$1a][$1b];[$1a][$1b]vstack,$LOOP,
  crop=$IW:$IH:0:'$IH-mod(n*$4,$IH)'[$1]"
}
SIG=$((IW*12/100))
GRAPH="
$(rain_layer rn 50 175 26 7);
$(rain_layer rf 30 176 40 11);
[rn][rf]blend=all_mode=lighten,$MASK[rain];
$(still hl "$(canvas $((3*IW)) $IH),geq=lum='235*exp(-pow((X-W/2)/$SIG,2))*(0.3+0.7*pow(Y/H,1.4))',gblur=sigma=4,$MASK");
[hl]crop@hl=$IW:$IH:0:0[hlc];
[src]eq@L=brightness=0[img];
[img][rain]blend@r=c0_mode=screen:c0_opacity=0.15:c1_mode=normal:c2_mode=normal[wet];
[wet][hlc]blend@h=c0_mode=screen:c0_opacity=0.5:c1_mode=normal:c2_mode=normal,
  lagfun=decay=0.8,vignette=PI/4[core]"
CMDS=(
  # headlight band sits at canvas x=1.5*IW: crop x=0 or 2*IW hides it.
  # every 26 s (from 9 s in) a 5 s sweep, alternating direction.
  "crop@hl x=(lambda c,u: int(2*$IW*(u if c%2==0 else 1-u)) if 0<=u<=1 else 0)(int(t//26),(t%26-9)/5)"
  'blend@h c0_opacity=clip(0.4+0.35*e,0,1)'
  'blend@r c0_opacity=clip(0.12+0.18*e,0,1)'
  'eq@L brightness=-0.03+0.05*e'
)
render "$@"
