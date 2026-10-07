#!/bin/bash
bar=2.4   # seconds per chord
declare -A C=(
  [A]="110 220 277.18 329.63"
  [E]="82.41 164.81 246.94 329.63 415.30"
  [Bm]="123.47 185 246.94 293.66 369.99"
  [D]="146.83 220 293.66 369.99"
)
L="A E Bm"; LD="A E Bm D"
V1="$L $L $L $L $L $L $L $L"; V2="$L $L $L $L"
CH="$L $L $LD $L"
song="$L $L $V1 $CH $CH $V2 $CH $CH $L $L"

for ch in $song; do
  args=()
  for f in ${C[$ch]}; do args+=(sine mix "$f"); done
  play -nq synth "$bar" "${args[@]}" vol 0.25 fade h 0.01 "$bar" 0.4
done
