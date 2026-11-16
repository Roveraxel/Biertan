#!/bin/bash
# Merge .ai/codemap/*.md (one line each) into .ai/CODEMAP.md, sorted.
cd "$(dirname "$0")/.." || exit 1
cat .ai/codemap/*.md | sed '/^$/d' | sort > .ai/CODEMAP.md
echo "$(wc -l < .ai/CODEMAP.md) of $(find scripts -name '*.gd' | wc -l) files mapped"
