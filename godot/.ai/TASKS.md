# TASKS (shared task board for all AIs; read ARCHITECTURE.md and HANDOFF.md first)

Rules: one owner per task. Only edit files named in your task. Write results to the named output file. Do not touch anything else.
When done, change the status to `done` and add one line to the Recent Changes section of HANDOFF.md.

## T1: GDScript static-typing audit (owner: Gemini via Cherry Studio, status: open)
Scope: read-only review of `scripts/ui/`, `scripts/quests/` and `scripts/actors/`.
Output: `.ai/REVIEW_typing.md` containing, per file, a list of `line: problem: suggested fix` for
- variables, parameters or returns without a declared type where the type cannot be inferred,
- `:=` on Variant results (dictionary `.get()`, `call()`, untyped array elements),
- loops without a typed iterator over typed data,
- signals declared without parameter types.
Do NOT modify any `.gd` file. Claude applies the fixes afterwards.

## T2: Narration copy review (owner: Gemini via Cherry Studio, status: open)
Scope: read `scripts/core/narration.gd` (the LINES dictionary).
Output: `.ai/REVIEW_narration.md` with suggested rewrites that sound more spoken and more Transylvanian-storyteller (short sentences, dry humour, Lorena fondly mocking the hunter, English with a light Romanian flavour). Keep each line under the original byte length so recording credits are not exceeded. Do NOT edit the .gd file.

## T3: Final fight in the Church on the Hill (owner: Claude, status: in progress)
Files: `scripts/levels/hillchurch.gd`, sexton boss, a new church interior level, story card after the sexton falls. Other AIs: do not edit these.
