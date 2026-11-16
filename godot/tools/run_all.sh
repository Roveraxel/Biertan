#!/bin/bash
# Run the HANDOFF tasks one after another; every task starts with a fresh context.
# Single-file tasks (T4, T1, T6, T2) go through tools/run_task.sh (one model call per file);
# the others run in a new headless Claude Code process each. Tasks already marked done are skipped.
# Usage: tools/run_all.sh            (all)      tools/run_all.sh T9 T1   (only these)
# Stop with Ctrl+C; run again to resume. Logs: .ai/run_logs/<task>.log
MODEL="${MODEL:-nemotron-3.5-bolt:e4b-nvfp4}"
cd "$(dirname "$0")/.." || exit 1
mkdir -p .ai/run_logs .ai/codemap
TASKS=("$@"); [ ${#TASKS[@]} -eq 0 ] && TASKS=(T4 T2 T7 T14)
mark_done() { perl -pi -e "s/^(### $1:.*status: )[a-z][^)]*\)/\$1done)/" .ai/HANDOFF.md; echo "- $1 done by local $MODEL ($(date '+%F %H:%M'))" >> .ai/run_logs/done.txt; }
for T in "${TASKS[@]}"; do
  if grep -E "^### $T:.*status: done" .ai/HANDOFF.md >/dev/null; then echo "== $T already done, skipping"; continue; fi
  echo "== $T started $(date '+%H:%M:%S')"
  case "$T" in
    T4|T1|T6|T2)
      bash tools/run_task.sh "$T" "$MODEL" > ".ai/run_logs/$T.log" 2>&1
      if [ "$T" = "T4" ]; then
        bash tools/merge_codemap.sh >> ".ai/run_logs/$T.log" 2>&1
        [ "$(ls .ai/codemap/*.md 2>/dev/null | wc -l)" -ge "$(find scripts -name '*.gd' | wc -l)" ] && mark_done "$T" || echo "   T4 incomplete, left open"
      elif grep -q "^== " ".ai/run_logs/$T.log" && ! grep -q "Permission denied\|command not found" ".ai/run_logs/$T.log"; then mark_done "$T"; else echo "   $T failed, see log; left open"; fi ;;
    *)
      PROMPT="Read .ai/HANDOFF.md and .ai/LESSONS.md and follow their rules exactly. All .gd files are read-only; do not edit .gd, scene or asset files. Write only into .ai/ and .ai/proposals/, and never use Write on a file that already has content (read it and append with Edit, or write a new file). Do task $T exactly as its Task Board section in .ai/HANDOFF.md says. Read one file at a time and keep notes short. When finished, reply with one sentence. If the task cannot be done, write one line why in .ai/BLOCKED.md."
      ollama launch claude --model "$MODEL" -- -p "$PROMPT" --permission-mode acceptEdits --allowedTools "Read,Write,Edit,Glob,Grep" > ".ai/run_logs/$T.log" 2>&1
      if [ -s ".ai/run_logs/$T.log" ] && ! grep -qi "error\|Permission denied\|command not found" ".ai/run_logs/$T.log"; then mark_done "$T"; else echo "   $T failed, see log; left open"; fi ;;
  esac
  echo "== $T finished $(date '+%H:%M:%S'); log: .ai/run_logs/$T.log"
done
echo "ALL DONE $(date '+%F %H:%M')" >> .ai/BLOCKED.md
