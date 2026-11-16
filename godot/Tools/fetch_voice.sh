#!/bin/bash
# fetch_voice.sh <out_dir>: download Lorena's narration from Fish Audio (needs *.fish.audio allowed)
out=${1:-/home/claude/bg/audio/voice}; mkdir -p "$out"
while read k id; do curl -sf -o "$out/$k.mp3" "https://platform.r2.fish.audio/tasks/2026-11-15/$id.mp3" && echo "ok $k" || echo "FAIL $k"; done < /home/claude/tools/voice_urls.txt
