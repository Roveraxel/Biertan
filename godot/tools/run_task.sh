#!/bin/bash
# Run a read-only HANDOFF task on a local Ollama model, one file per call (keeps the context small).
# Usage: tools/run_task.sh T4 qwen3.8        (run from the godot folder)
# Output is appended to the .ai/ file named below. Never edits any .gd file.
set -u
TASK="${1:?task id, e.g. T4}"; MODEL="${2:-qwen3.8}"
cd "$(dirname "$0")/.." || exit 1
H=.ai/HANDOFF.md
case "$TASK" in
  T1) OUT=.ai/REVIEW_typing.md;    FILES=$(ls scripts/ui/*.gd scripts/quests/*.gd scripts/actors/*.gd) ;;
  T2) OUT=.ai/REVIEW_narration.md; FILES="scripts/core/narration.gd" ;;
  T4) OUT=.ai/CODEMAP.md;          FILES=$(find scripts -name '*.gd' | sort) ;;
  T6) OUT=.ai/QA_CHECKLIST.md;     FILES=$(ls scripts/quests/*.gd) ;;
  *) echo "Task $TASK needs whole-project reading. Use: ollama launch claude --model $MODEL with the prompt in HANDOFF.md"; exit 2 ;;
esac
RULES=$(awk '/^## READ THIS FIRST/{f=1;next} /^## Active Feature/{f=0} f' "$H")
TEXT=$(awk -v t="### $TASK:" 'index($0,t)==1{f=1;print;next} /^### /{f=0} f' "$H")
echo "# $TASK by $MODEL, $(date '+%F %H:%M')" >> "$OUT"
for F in $FILES; do
  echo "== $F"
  P="You are a read-only reviewer on a Godot GDScript project. Rules:
$RULES

Task:
$TEXT

Answer only for this one file, in the output format the task describes, short. Do not write code unless the task asks for it.
File: $F
\`\`\`gdscript
$(cat "$F")
\`\`\`"
  { echo; echo "## $F"; printf '%s' "$P" | ollama run "$MODEL" 2>/dev/null; } >> "$OUT"
done
echo "Done. Output: $OUT. Now set $TASK to done in $H and add a line to Recent Changes."
