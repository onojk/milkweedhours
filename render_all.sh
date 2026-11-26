#!/usr/bin/env bash
# Render every look (10 last: it samples the finished videos 1-9).
#   ./render_all.sh                 all songs, full length
#   ./render_all.sh 03 07           just those songs
#   JOBS=2 ./render_all.sh          render looks 1-9 two at a time
#   ./render_all.sh --test 20 [start] [NN...]   short test clips
set -euo pipefail
cd "$(dirname "$0")"
args=()
if [[ ${1:-} == --test ]]; then args=(--test "${2:-20}" "${3:-0}"); shift $(( $# >= 3 ? 3 : $# )); fi
nums=("$@"); [[ ${#nums[@]} -gt 0 ]] || nums=(01 02 03 04 05 06 07 08 09 10)
mkdir -p work
run_one() {
  local script; script=$(ls looks/"$1"_*.sh 2>/dev/null | head -1 || true)
  [[ -n $script ]] || { echo "!! no look for $1, skipping"; return 0; }
  "$script" "${@:2}" > "work/log-$1.txt" 2>&1 && echo "ok   $1  $(tail -1 "work/log-$1.txt")" \
    || { echo "FAIL $1 (see work/log-$1.txt)"; return 1; }
}
export -f run_one
first=(); last=()
for n in "${nums[@]}"; do [[ $n == 10 ]] && last+=("$n") || first+=("$n"); done
if (( ${#first[@]} )); then
  printf '%s\n' "${first[@]}" | xargs -P "${JOBS:-1}" -I{} bash -c 'run_one "$@"' _ {} "${args[@]}"
fi
for n in "${last[@]}"; do run_one "$n" "${args[@]}"; done
