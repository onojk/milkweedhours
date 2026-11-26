#!/usr/bin/env bash
# 7 Parking Lot Moon — deep night blue, a bright moon disc with glow, a dark
# puddle below holding the moon's reflection, rippled by a scrolling
# displacement map; the whole frame sways slowly in waltz time.
# Breath: ripple depth, reflection and moon brightness, sway depth.
source "$(dirname "$0")/common.sh"
NUM=07
GRAIN=14
SW=$((IW*106/100/2*2)); SH=$((IH*106/100/2*2))
ensure_env $NUM
P=$(python3 "$ROOT/tools/tempo.py" "$ROOT/work/$NUM.env" 4.0)
echo ">> sway period ${P}s"
PREP="$(cover_fit $SW $SH),gblur=sigma=1.2,format=gbrp,
  colorchannelmixer=rr=.024:rg=.047:rb=.009:gr=.042:gg=.083:gb=.015:br=.114:bg=.224:bb=.042,
  format=yuv420p"
MX=$((SW*72/100)); MY=$((SH*20/100)); R=$((SW*5/100))
PX=$((SW*70/100)); PY=$((SH*86/100)); RX=$((SW*20/100)); RY=$((SH*7/100))
PUD="hypot((X-$PX)/$RX,(Y-$PY)/$RY)"
GRAPH="
$(still moon "$(canvas $SW $SH),geq=lum='st(0,hypot(X-$MX,Y-$MY));clip(242*clip(($R-ld(0))/2.5,0,1)+120*exp(-pow(ld(0)/(3*$R),2)),0,255)',$MASK");
$(still pud "$(canvas $SW $SH),geq=lum='255-110*clip(1.3-$PUD,0,1)',gblur=sigma=6,$MASK");
$(still refl "$(canvas $SW $SH),geq=lum='230*exp(-(pow((X-$MX)/(0.045*W),2)+pow((Y-$PY)/(0.03*H),2)))*clip((1-$PUD)*4,0,1)'");
$(canvas 8 $((2*SH))),geq=lum='128+10*sin(2*PI*Y*74/H)+6*sin(2*PI*Y*106/H)',scale=$SW:$((2*SH)):flags=neighbor,
  trim=end_frame=1,$LOOP,crop=$SW:$SH:0:'mod(n*2,$SH)'[xm0];
color=0x808080:s=${SW}x${SH}:r=$FPS,format=gray[flat];
color=0x808080:s=${SW}x${SH}:r=$FPS,format=gray[ym];
[xm0][flat]blend@a=all_mode=normal:all_opacity=0.5[xm];
[refl][xm][ym]displace=edge=smear,$MASK[rf];
[src][pud]blend=c0_mode=multiply:c1_mode=normal:c2_mode=normal[p];
[p][moon]blend@mo=c0_mode=screen:c0_opacity=0.9:c1_mode=normal:c2_mode=normal[m];
[m][rf]blend@rf=c0_mode=screen:c0_opacity=0.5:c1_mode=normal:c2_mode=normal,
  rotate@r=a=0:ow=$IW:oh=$IH:c=black,vignette=PI/4.2[core]"
CMDS=(
  "rotate@r a=(0.005+0.006*e)*sin(2*pi*t/$P)"
  'blend@a all_opacity=clip(0.35+0.65*e,0,1)'
  'blend@rf c0_opacity=clip(0.35+0.4*e,0,1)'
  'blend@mo c0_opacity=clip(0.8+0.2*e,0,1)'
)
render "$@"
