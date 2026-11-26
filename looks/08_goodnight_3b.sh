#!/usr/bin/env bash
# 8 Goodnight 3B — almost dark: the cover as a blurred black-blue wall, one lit
# window with the painting inside it (warm, with mullions and a frame).
# In the last minute the wall drifts from black-blue to pale dawn grey and the
# window dims. Breath: the window's glow and brightness swell with loudness.
source "$(dirname "$0")/common.sh"
NUM=08
GRAIN=12
# night wall: luminance tinted very dark blue
PREP="$(cover_fit $IW $IH),gblur=sigma=5,format=gbrp,
  colorchannelmixer=rr=.024:rg=.047:rb=.009:gr=.03:gg=.059:gb=.011:br=.06:bg=.118:bb=.022,
  format=yuv420p"
EXTRA_INPUTS=(-i "$COVER" -i "$COVER")   # 2 = dawn wall, 3 = window picture

# window rectangle (inside the frame) at ~58% across, ~24% down
WW=320; WH=232; FR=8
WX=$((IW*58/100)); WY=$((IH*24/100))
X0=$WX; Y0=$WY; X1=$((WX+WW+2*FR)); Y1=$((WY+WH+2*FR))
GLOW="st(0,max(max($X0-X,X-$X1),0));st(1,max(max($Y0-Y,Y-$Y1),0));st(2,hypot(ld(0),ld(1)));clip(110*exp(-pow(ld(2)/90,2))+45*exp(-ld(2)/260),0,255)"
GRAPH="
[2:v]$(cover_fit $IW $IH),gblur=sigma=5,format=gbrp,
  colorchannelmixer=rr=.186:rg=.366:rb=.068:gr=.192:gg=.378:gb=.07:br=.204:bg=.401:bb=.075,
  format=yuv420p,eq=brightness=0.2:contrast=0.6,$LOOP[dawn];
[3:v]scale=$WW:$WH:flags=lanczos,gblur=sigma=0.8,format=gbrp,
  colorchannelmixer=rr=1.05:gg=.86:bb=.6,format=yuv420p,
  drawbox=x=iw/2-2:y=0:w=4:h=ih:color=0x1a1410:t=fill,
  drawbox=x=0:y=ih*0.42:w=iw:h=4:color=0x1a1410:t=fill,
  pad=iw+$((2*FR)):ih+$((2*FR)):$FR:$FR:color=0x15110d,$LOOP,eq@w=brightness=0[win];
$(canvas $IW $IH),geq=lum='$GLOW',split[gm1][gm2];
color=0xffb46a:s=${IW}x${IH}:r=$FPS:d=1,format=yuva420p[gc];
[gc][gm1]alphamerge,trim=end_frame=1,$LOOP[gwarm];
[gm2]$MASK,trim=end_frame=1,$LOOP[gluma];
[dawn][src]blend@d=all_mode=normal:all_opacity=0[bg];
[bg][gwarm]overlay=eval=init:format=yuv420[b1];
[b1][gluma]blend@g=c0_mode=screen:c0_opacity=0.2:c1_mode=normal:c2_mode=normal[b2];
[b2][win]overlay=x=$WX:y=$WY:eval=init:format=yuv420,vignette=PI/4[core]"
DAWN='clip((t-(D-60))/60,0,1)'
CMDS=(
  "blend@d all_opacity=(lambda p: p*p*(3-2*p))($DAWN)"
  "blend@g c0_opacity=clip(0.12+0.4*e-0.1*$DAWN,0,1)"
  "eq@w brightness=0.012*wob(4)+0.05*e-0.12*$DAWN"
)
render "$@"
