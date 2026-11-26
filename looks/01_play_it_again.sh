#!/usr/bin/env bash
# 1 Play It Again — warm sepia, faint vertical plaster-wall texture over the
# cover, soft light bars like piano keys (three interleaved groups).
# Breath: the key bars brighten with loudness (each group sways a little
# differently), tiny brightness swell and a very slow push-in.
source "$(dirname "$0")/common.sh"
NUM=01
GRAIN=14
PREP="$(cover_fit $IW $IH),gblur=sigma=1.3,format=gbrp,
  colorchannelmixer=rr=.393:rg=.769:rb=.189:gr=.349:gg=.686:gb=.168:br=.272:bg=.534:bb=.131,
  format=yuv420p,eq=contrast=0.8:brightness=-0.07:gamma=1.04"

# 14 soft vertical bars across the frame, brighter toward the bottom; group $2
# takes every third bar
key_mask() {  # $1=label $2=group 0..2
  still "$1" "$(canvas $IW $IH),geq=lum='st(0,X*14/W);if(eq(mod(floor(ld(0)),3),$2),255*exp(-pow((ld(0)-floor(ld(0))-0.5)/0.15,2))*(0.25+0.75*pow(Y/H,1.2)),0)',gblur=sigma=6,$MASK"
}
GRAPH="
$(still wall "color=0x808080:s=${IW}x10:r=$FPS:d=1,format=gray,noise=c0s=50:c0f=u:all_seed=3,
  scale=$IW:$IH:flags=bicubic,gblur=sigma=0.7,format=yuv420p,lutyuv=u=128:v=128");
$(key_mask k0 0);
$(key_mask k1 1);
$(key_mask k2 2);
[src]scale@z=w=$IW:h=$IH:flags=bilinear,crop=$IW:$IH,eq@L=brightness=0[img];
[img][wall]blend=c0_mode=overlay:c0_opacity=0.35:c1_mode=normal:c2_mode=normal[w];
[w][k0]blend@k0=c0_mode=screen:c0_opacity=0:c1_mode=normal:c2_mode=normal[a];
[a][k1]blend@k1=c0_mode=screen:c0_opacity=0:c1_mode=normal:c2_mode=normal[b];
[b][k2]blend@k2=c0_mode=screen:c0_opacity=0:c1_mode=normal:c2_mode=normal,
  vignette=PI/4.5[core]"
CMDS=(
  "scale@z w=2*int($IW*(1+0.05*t/D+0.012*e)/2)"
  "scale@z h=2*int($IH*(1+0.05*t/D+0.012*e)/2)"
  'eq@L brightness=-0.03+0.06*e'
  'blend@k0 c0_opacity=clip(0.08+0.8*e*(0.8+0.3*wob(1)),0,1)'
  'blend@k1 c0_opacity=clip(0.08+0.8*e*(0.8+0.3*wob(2)),0,1)'
  'blend@k2 c0_opacity=clip(0.08+0.8*e*(0.8+0.3*wob(3)),0,1)'
)
render "$@"
