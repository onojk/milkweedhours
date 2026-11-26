#!/usr/bin/env bash
# Shared plumbing for every look (adapted from ~/everycastshell/looks/common.sh).
# A look script sets:
#   NUM    two-digit song number
#   PREP   static filter chain applied ONCE to the cover (before looping).
#          Do RGB colour work here and end in yuv420p: the dynamic chain
#          should stay YUV (eq/lagfun/blend/overlay) — auto RGB<->YUV
#          conversions per frame are the main speed killer.
#          $(cover_fit W H) scales/crops the landscape painting to WxH.
#   GRAPH  dynamic filtergraph: reads [src] (looped, sendcmd-driven cover) and
#          optionally [1:a]; must output [core] at IWxIH (upscaled to 1920x1080
#          after). If it consumes [1:a] it must also output [aout].
#          $(still LABEL CHAIN) makes a one-frame generated texture/mask, looped.
#   CMDS   array of 'filter@name cmd=EXPR' specs for tools/cmds.py (e, h, t, D).
#          e here is the slow "breath" from tools/breathe.py, not raw loudness.
#   GRAIN  (optional) film grain strength, default 14, 0 = off. Grain is
#          rendered at 640x360 and upscaled (chunky, filmic, cheap to encode)
#          and merged into luma after [core] — looks should NOT add noise.
#   EXTRA_INPUTS (optional array of extra ffmpeg input args, inputs 2..)
#   TITLE_END (optional, seconds) bring the title card back for the last N s.
# then calls `render "$@"`.
# Usage of any look:  looks/NN_x.sh                         full song
#                     looks/NN_x.sh --test 20 [start|loud|quiet]   short clip
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SONGS_DIR=${SONGS_DIR:-$HOME/Downloads}
COVER_SRC=${COVER_SRC:-$HOME/Downloads/of_the_soul_with_the_body_by_onojk123_dfan8ep.png}
FONT=${FONT:-/usr/share/fonts/opentype/urw-base35/NimbusMonoPS-Regular.otf}
COVER="$ROOT/assets/cover_2560.png"
W=1920; H=1080; FPS=30
# Internal working size for the dynamic chain (upscaled to WxH at the end:
# faster, and the soft upscale is part of the grit). Override with IW/IH env.
IW=${IW:-1280}; IH=${IH:-720}
CRF=${CRF:-24}
ARTIST_LINE="Milkweed Hours — Jonathan Kendall"
TITLE_LOWER=${TITLE_LOWER:-1}   # typewriter title card in lowercase
mkdir -p "$ROOT/work" "$ROOT/out" "$ROOT/assets"

title_of() {
  case $1 in
    01) echo "Play It Again";;              02) echo "Coffee Gone Cold";;
    03) echo "Streetlight Halo";;           04) echo "Saint of the Bus Stop";;
    05) echo "A Note in a Second-Hand Coat";; 06) echo "Quiet Engine";;
    07) echo "Parking Lot Moon";;           08) echo "Goodnight 3B";;
    09) echo "Little Matchbook Heaven";;    10) echo "Thin-Walled Song";;
  esac
}
slug_of() { title_of "$1" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'; }
wav_of() { echo "$SONGS_DIR/$(title_of "$1").wav"; }

ensure_cover() {
  [[ -f $COVER ]] || ffmpeg -v error -y -i "$COVER_SRC" \
    -vf "scale=2560:-2:flags=lanczos,format=rgb24" "$COVER"
}
ensure_env() {  # $1=NUM — raw loudness (env.py) -> slow breath (breathe.py)
  local wav raw="$ROOT/work/$1.raw.env" env="$ROOT/work/$1.env"
  wav=$(wav_of "$1")
  [[ -f $raw && $raw -nt $wav ]] || python3 "$ROOT/tools/env.py" "$wav" "$raw" "$FPS"
  [[ -f $env && $env -nt $raw ]] || python3 "$ROOT/tools/breathe.py" "$raw" "$env"
}
song_dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$(wav_of "$1")"; }

# Loop filter: decode/prepare the still once, repeat it forever at FPS.
LOOP="loop=loop=-1:size=1:start=0,setpts=N/$FPS/TB"
# Landscape painting (1.37:1) -> exactly WxH, centred.
cover_fit() { echo "scale=$1:-2:flags=lanczos,crop=$1:$2"; }
# One generated frame (texture/mask), looped forever:  $(still label "chain")
still() { echo "$2,trim=end_frame=1,$LOOP[$1]"; }
# A black gray canvas of WxH for geq masks: $(canvas W H)
canvas() { echo "color=black:s=$1x$2:r=$FPS:d=1,format=gray"; }
# gray mask -> yuv420p with luma stretched back to 0..255 (so black stays 0
# for screen/multiply blends against the yuv picture)
MASK="format=yuv420p,lutyuv=y='clip((val-16)*255/219,0,255)':u=128:v=128"

render() {
  local dur="" start=0 tag=""
  if [[ ${1:-} == --test ]]; then dur=${2:-20}; start=${3:-0}; tag="test-"; fi
  ensure_cover; ensure_env "$NUM"
  local title wav out cmdf graphf
  title=$(title_of "$NUM"); wav=$(wav_of "$NUM")
  case $start in
    loud|quiet) start=$(python3 "$ROOT/tools/section.py" "$ROOT/work/$NUM.env" "$start" "$dur");;
  esac
  [[ -n $dur ]] || dur=$(song_dur "$NUM")
  out="$ROOT/out/${tag}${NUM}-$(slug_of "$NUM").mp4"
  cmdf="$ROOT/work/$NUM.cmd"; graphf="$ROOT/work/$NUM.graph"
  if (( TITLE_LOWER )); then
    printf '%s' "$title" | tr 'A-Z' 'a-z' > "$ROOT/work/$NUM.title.txt"
    printf '%s' "$ARTIST_LINE" | tr 'A-Z' 'a-z' > "$ROOT/work/artist.txt"
  else
    printf '%s' "$title" > "$ROOT/work/$NUM.title.txt"
    printf '%s' "$ARTIST_LINE" > "$ROOT/work/artist.txt"
  fi

  CMD_START=$start python3 "$ROOT/tools/cmds.py" "$ROOT/work/$NUM.env" "$cmdf" "${CMDS[@]}"

  # title card: first 4 s, fade out over the 4th; optionally back at the end
  local fade="alpha='if(lt(t,3),1,max(0,4-t))':enable='lt(t,4)'"
  if [[ -n ${TITLE_END:-} ]]; then
    local te; te=$(python3 -c "print(round($dur-$TITLE_END,2))")
    fade="alpha='if(lt(t,4),if(lt(t,3),1,4-t),min(1,(t-$te)/2))':enable='lt(t,4)+gte(t,$te)'"
  fi
  {
    printf '[0:v]%s%s,sendcmd=f=%s[src];\n' "${PREP:+$PREP,}" "$LOOP" "$cmdf"
    printf '%s;\n' "$GRAPH"
    if (( ${GRAIN:-14} > 0 )); then
      printf 'nullsrc=s=640x360:r=%s,format=yuv420p,lutyuv=y=128:u=128:v=128,noise=c0s=%s:c0f=t+u,scale=%s:%s:flags=bicubic[grain];\n' \
        "$FPS" "${GRAIN:-14}" "$IW" "$IH"
      printf '[core]format=yuv420p[cg];[cg][grain]blend=c0_mode=grainmerge:c1_mode=normal:c2_mode=normal[core2];\n'
    else
      printf '[core]format=yuv420p[core2];\n'
    fi
    printf "[core2]scale=%s:%s:flags=bicubic," "$W" "$H"
    printf "drawtext=fontfile=%s:textfile=%s:fontsize=48:fontcolor=0xF3ECDD:box=1:boxcolor=black@0.3:boxborderw=14|22:shadowcolor=black@0.75:shadowx=2:shadowy=2:x=(w-tw)/2:y=h/2-46:%s," \
      "$FONT" "$ROOT/work/$NUM.title.txt" "$fade"
    printf "drawtext=fontfile=%s:textfile=%s:fontsize=28:fontcolor=0xF3ECDD@0.85:box=1:boxcolor=black@0.3:boxborderw=8|22:shadowcolor=black@0.75:shadowx=2:shadowy=2:x=(w-tw)/2:y=h/2+22:%s," \
      "$FONT" "$ROOT/work/artist.txt" "$fade"
    printf 'fps=%s[vout]\n' "$FPS"
  } > "$graphf"

  local amap=(-map 1:a)
  grep -q '\[aout\]' <<<"$GRAPH" && amap=(-map '[aout]')
  echo ">> $out  (${dur}s from ${start}s)"
  local t0=$SECONDS
  ffmpeg -hide_banner -v error -stats_period 10 -stats -y \
    -i "$COVER" -ss "$start" -i "$wav" "${EXTRA_INPUTS[@]}" \
    -filter_threads "$(nproc)" -/filter_complex "$graphf" -map '[vout]' "${amap[@]}" \
    -t "$dur" -r "$FPS" -c:v libx264 -preset veryfast -crf "$CRF" -pix_fmt yuv420p \
    -c:a aac -b:a 320k -movflags +faststart "$out"
  echo ">> done in $((SECONDS - t0))s  $(du -h "$out" | cut -f1)"
}
EXTRA_INPUTS=()
