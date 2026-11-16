# TASKS (shared task board for all AIs; read ARCHITECTURE.md and HANDOFF.md first)

Rules: one owner per task. Only edit files named in your task. Write results to the named output file. Do not touch anything else.
When done, change the status to `done` and add one line to the Recent Changes section of HANDOFF.md.

## T1: GDScript static-typing audit (owner: Nemotron via Cherry Studio, status: open)
Scope: read-only review of `scripts/ui/`, `scripts/quests/` and `scripts/actors/`.
Output: `.ai/REVIEW_typing.md` containing, per file, a list of `line: problem: suggested fix` for
- variables, parameters or returns without a declared type where the type cannot be inferred,
- `:=` on Variant results (dictionary `.get()`, `call()`, untyped array elements),
- loops without a typed iterator over typed data,
- signals declared without parameter types.
Do NOT modify any `.gd` file. Claude applies the fixes afterwards.

## T2: Narration copy review (owner: Nemotron via Cherry Studio, status: open)
Scope: read `scripts/core/narration.gd` (the LINES dictionary).
Output: `.ai/REVIEW_narration.md` with suggested rewrites that sound more spoken and more Transylvanian-storyteller (short sentences, dry humour, Lorena fondly mocking the hunter, English with a light Romanian flavour). Keep each line under the original byte length so recording credits are not exceeded. Do NOT edit the .gd file.

## T3: Final fight in the Church on the Hill (owner: Claude, status: in progress)
Files: `scripts/levels/hillchurch.gd`, sexton boss, a new church interior level, story card after the sexton falls. Other AIs: do not edit these.


## T4: Code map (owner: Nemotron, status: open, do this first)
Read every `.gd` file under `scripts/`. Output `.ai/CODEMAP.md`: one line per file (`path: what it is, key public functions, which levels or quests use it`). Do NOT modify any `.gd` file.

## T5: Consistency and anachronism review (owner: Nemotron, status: open)
Read `STORY.md`, `scripts/quests/*.gd`, `scripts/levels/*.gd` dialogue strings and `scripts/core/game_manager.gd` (STORIES). Output `.ai/REVIEW_consistency.md` listing contradictions as `file:line: problem: suggested fix`. Canon: game year 1521; the baron died unmarried in 1321 ("two hundred years"); sacristy door 1515; Biertan; character names and roles must match across files. Also flag any dialogue that sounds modern. Do NOT edit the files.

## T6: QA checklist (owner: Nemotron, status: open)
From the quest scripts, write `.ai/QA_CHECKLIST.md`: per level, the steps a playtester should do in order, the flags set (`G.side_add(...)`), and what must visibly happen. Mark steps that look impossible to complete from the code. Read-only.

## T7: Story drafts for the backlog (owner: Nemotron, status: open)
Write drafts (not code) to `.ai/DRAFT_quests.md`, grounded in `STORY.md`, in Romanian folklore (use Tudor Pamfile, Mihai Coman, Aurel Cosma Jr.; no pop-culture versions), and in the game's tone (dry, warm, Lorena mocking the hunter):
1. The Criț subquests (two short ones).
2. A scene where village children sing.
3. Sfânta Vineri: a clear in-story explanation of who she is and what she wants.
4. The mushroom and Turks side story.
5. The Saschiz market.
Each draft: location, NPCs, steps (what the player sees and does), reward, 6 to 10 lines of key dialogue. Keep drafts short. Claude implements the chosen ones.

## Who does what
- Claude: all code changes, builds, publishing, Meshy and PixelLab art, narration audio, the sexton-defeat film, natural ground/grass/haystacks/trees, character consistency.
- Nemotron (Cherry Studio): read-only reviews, code map, QA checklist and story drafts, written to `.ai/` only.
- ChatGPT: reserve only, because the monthly quota is almost used. Use it for a second opinion on a hard design question, nothing routine.
- After a Nemotron task: change its status to `done` here and add one line to Recent Changes in HANDOFF.md.
