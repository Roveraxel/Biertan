#!/bin/bash
# Run the HANDOFF tasks one by one, each in a NEW headless Claude Code process (fresh context),
# using a local Ollama model. Skips tasks already marked done. Never edits .gd files (they are read-only).
# Usage: tools/run_all.sh            (all tasks)      tools/run_all.sh T9 T1   (only these)
# Stop with Ctrl+C. Logs: .ai/run_logs/<task>.log
MODEL="${MODEL:-nemotron-3.5-bolt:e4b-nvfp4}"
cd "$(dirname "$0")/.." || exit 1
TASKS=("$@"); [ ${#TASKS[@]} -eq 0 ] && TASKS=(T9 T1 T6 T11 T13 T2 T5 T8 T7 T14 T10)
for T in "${TASKS[@]}"; do
  if grep -E "^### $T:.*status: done" .ai/HANDOFF.md >/dev/null; then echo "== $T already done, skipping"; continue; fi
  echo "== $T started $(date '+%H:%M:%S')"
  PROMPT="Read .ai/HANDOFF.md and .ai/LESSONS.md and follow their rules exactly. All .gd files are read-only; do not edit .gd, scene or asset files. Write only into .ai/ and .ai/proposals/. Do task $T exactly as its Task Board section in .ai/HANDOFF.md says. Read one file at a time and keep notes short. Append results to the output file the task names as you go. When finished, change the status of $T to done in .ai/HANDOFF.md, add one line to Recent Changes, and reply with one sentence. If the task cannot be done, write one line why in .ai/BLOCKED.md."
  ollama launch claude --model "$MODEL" -- -p "$PROMPT" --permission-mode acceptEdits --allowedTools "Read,Write,Edit,Glob,Grep" > ".ai/run_logs/$T.log" 2>&1
  echo "== $T finished (exit $?) $(date '+%H:%M:%S'); log: .ai/run_logs/$T.log"
done
echo "ALL DONE" >> .ai/BLOCKED.md
