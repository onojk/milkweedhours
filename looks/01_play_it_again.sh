#!/usr/bin/env bash
# 1 Play It Again — warm sepia, faint vertical plaster-wall texture over the
# cover, and one soft searchlight: a wide feathered beam (like a passing car
# or a lighthouse through the wall) with a glowing pool where it lands,
# sweeping slowly back and forth (one pass every ~9 s).
# Breath: the beam's brightness and width (a narrow core always on, a wide
# halo that fades in on louder parts), tiny brightness swell, slow push-in.
source "$(dirname "$0")/common.sh"
NUM=01
GRAIN=14
PREP="$(cover_fit $IW $IH),gblur=sigma=1.3,format=gbrp,
  colorchannelmixer=rr=.393:rg=.769:rb=.189:gr=.349:gg=.686:gb=.168:br=.272:bg=.534:bb=.131,
  format=yuv420p,eq=contrast=0.8:brightness=-0.07:gamma=1.04"

# Beam masks on a 2*IW-wide canvas, beam centred at x=IW; cropping an IW
# window at x puts the beam at screen x = IW - x. $2 = beam half-width at the
# top (it widens toward the floor), pool at ~86% down.
beam_mask() {  # $1=label $2=half-width px $3=peak 0..255
  still "$1" "$(canvas $((2*IW)) $IH),geq=lum='st(0,$2*(0.6+0.8*Y/H));st(1,X-W/2);clip($3*(exp(-pow(ld(1)/ld(0),2))*(0.45+0.35*Y/H)+0.7*exp(-pow(ld(1)/(1.7*$2),2)-pow((Y-0.86*H)/(0.1*H),2))),0,255)',gblur=sigma=8,$MASK"
}
GRAPH="
$(still wall "color=0x808080:s=${IW}x10:r=$FPS:d=1,format=gray,noise=c0s=50:c0f=u:all_seed=3,
  scale=$IW:$IH:flags=bicubic,gblur=sigma=0.7,format=yuv420p,lutyuv=u=128:v=128");
$(beam_mask bn $((IW*7/100)) 255);
$(beam_mask bw $((IW*16/100)) 230);
[bn]crop@cn=$IW:$IH:$((IW/2)):0[bnc];
[bw]crop@cw=$IW:$IH:$((IW/2)):0[bwc];
[src]scale@z=w=$IW:h=$IH:flags=bilinear,crop=$IW:$IH,eq@L=brightness=0[img];
[img][wall]blend=c0_mode=overlay:c0_opacity=0.35:c1_mode=normal:c2_mode=normal[w];
[w][bwc]blend@bw=c0_mode=screen:c0_opacity=0:c1_mode=normal:c2_mode=normal[a];
[a][bnc]blend@bn=c0_mode=screen:c0_opacity=0.2:c1_mode=normal:c2_mode=normal,
  vignette=PI/4.5[core]"
CMDS=(
  "scale@z w=2*int($IW*(1+0.05*t/D+0.012*e)/2)"
  "scale@z h=2*int($IH*(1+0.05*t/D+0.012*e)/2)"
  'eq@L brightness=-0.03+0.06*e'
  # sweep: beam centre between 12% and 88% of the frame, 18 s round trip
  "crop@cn x=int($IW/2-0.38*$IW*sin(2*pi*t/18))"
  "crop@cw x=int($IW/2-0.38*$IW*sin(2*pi*t/18))"
  'blend@bn c0_opacity=clip(0.22+0.5*e,0,1)'
  'blend@bw c0_opacity=clip(0.75*e**1.3,0,1)'
)
render "$@"
