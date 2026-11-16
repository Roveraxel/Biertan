# HANDOFF (live log; update before finishing and before every push)

## READ THIS FIRST (self-contained rules for every AI; this file is enough)
Project: Godot 4.7.2 game "Biertan" (GDScript, web export). Project root `/Users/alex/Biertan/godot`. More detail, only if you can open them: `.ai/ARCHITECTURE.md`, `.ai/LESSONS.md`, `.ai/AUDIT_2026-11-16.md`.

**Who may edit code:** only Claude (it can compile and run the game). Every other AI writes proposals into `.ai/proposals/` and results into `.ai/`. Do not edit any `.gd`, scene or asset file.

**Proposal and review loop:** (1) You write `.ai/proposals/<name>.md`: goal, files and functions touched, exact code in fenced blocks, what you could not check, first line `Status: proposed`. (2) Claude compiles it and writes `<name>.review.md` with `Verdict: approved / changes needed / rejected` and numbered changes (`file:line: problem: what to change`). (3) You answer with `<name>.v2.md` (then `.v3.md`), changing only what the review lists and saying which point each change answers. Three rounds at most. (4) Claude applies, tests and sets `Status: applied`. Add one line to Recent Changes below at every step.

**Mistakes already made; do not repeat them:**
1. Code you could not compile broke the game (a rejected patch is in `.ai/proposals/`). Never edit code directly.
2. No `:=` on values whose type is not obvious (results of `Dictionary.get()`, `call()`, untyped arrays, properties of base classes such as `Material.albedo_color`). Cast first (`as StandardMaterial3D`) or declare the type.
3. Call helpers where they exist: search for the `func` line first (example: `Level.dist_to_segment`, not a bare `dist_to_segment` inside `WorldBuilder`).
4. No `randf()`, `randi()`, `shuffle()`. Use the level's `rng` (`rng.f()`, `rng.i(n)`) or a `NetRandom`. Do not change seeds that already work.
5. Web performance: no one mesh node per decoration. Collect into a few `Batch` objects per chunk or material and commit once.
6. Ground decals sit at fixed heights (roads 0.012 to 0.014, patches about 0.015 to 0.02); a new flat layer at a near height flickers.
7. Stay inside your task and its files. Do not start work from the Known Issues list on your own.
8. Do not change the signature of an existing function; add a new one.
9. Godot 4 syntax only: `@export`, `@onready`, `signal.connect(callable)`, `await`, `super()`. Every variable, parameter and return gets a type. Typed loops: `for x: float in [..]:`.
10. Report the exact files and lines, and say what you could not check.
12. Take line numbers from the numbered file you are given, never count yourself. 13. Check call sites (grep) before suggesting a type for a parameter (`names` takes a String or an Array).
11. Never use Write on a shared output file (it overwrites everything). Write one small file per item, or append with Edit after reading it.

**Canon:** game year 1521; the baron died unmarried in 1321 ("two hundred years"); sacristy door 1515. Romanian folklore only, from Pamfile, Coman and Cosma (not pop culture, not Adevărul). Tone: dry, warm; Lorena narrates and fondly mocks the hunter.

## Active Feature
Final wedding fight now runs inside the Church on the Hill (`scripts/levels/hillchurch.gd`). Task board is the last section of this file (T1, T2, T4 to T7 open for local Nemotron; T3 Claude).

(previous)
Narration and story polish for the web playtest; next big item is the final fight as a Meshy-generated level inside the Church on the Hill.

## Last Worked On By
Claude (Claude Code session), 2026-11-16 03:00.

## Recent Changes
- 2026-11-16 07:00 review: T4 code map 74 of 83 files mapped (9 empty: tunnel, sx_quest, interact, hillchurch, mats, varcolac, vineyard, swinging_hook, rc_quest), lines checked and accurate. T1 typing review rejected, see `.ai/REVIEW_typing.review.md` (wrong line numbers, one harmful suggestion). No .gd file was changed by Nemotron (checksums equal). Runner now strips thinking text and numbers lines.
- Ground: village ground is now a seamless pixel-art meadow (`textures/px_meadow_diff_1k.png`), macro veil on villages; cobbles warmer. Trees: each crown one colour family (mostly green, a few ochre/rust). Sexton-defeat film: `sprites/Story/sexton_1.png`, STORIES `sexton_end`, shown before the judgement; narration line `sexton_end` not recorded yet.
- AUDIT: another AI edited `world_builder.gd`, `trees.gd`, `mats.gd` on the Mac and broke compilation; rejected and saved to `.ai/proposals/`. Details in `.ai/AUDIT_2026-11-16.md`. New rule 0 in ARCHITECTURE.md.
- Web build republished (5 data parts; PARTS list in index.html updated).
- Church on the Hill is now a church interior (nave, pillars, pews, altar, crypt slabs): walking up the aisle starts the wedding, the dead rise from the slabs, wolves come in at the door, the sexton enters by the door. New bell rope by the tower door stuns the dead for 4 s (8 s cooldown) and restores guest courage. Texts changed from graveyard to church. Not yet playtested end to end. No Meshy model used for the interior (procedural level plus existing textures).
- Narration: 11 of 28 lines recorded in the Romania voice (drama-3) into `audio/voice/`: prologue, descent, recap_sighisoara 0-2, act_2, flash_cup, flash_twig, flash_stones, flash_stones2, recap_cris_0. `Narration.VOICE` updated. Web build republished.
- Sighișoara: postern gate cut into the town wall by the Butchers' Tower, guild sign moved beside the outside cellar door.
- Meister Thomas (`npc_butcher`): 6-frame walk cycle in 8 directions.
- Added `PROJECT_CONTEXT.md` (repo root, also on GitHub `Roveraxel/Biertan` main) and this `.ai/` folder.
- Earlier this week: act cards, balaur film and ripple animation, Casa Vlad Dracul interior, compact villages, Biertan gates, walking Azorel / earth dog / vârcolac, Lorena narration hooks (`scripts/core/narration.gd`).

## Known Issues
- Ground/trees changed but only checked in Viscri and Mălâncrav screenshots; other villages unchecked. Forest and wilds trees still use the old palette.
- Sprite style differences between NPCs (cast consistency) are unresolved; scales are already uniform.
- 17 narration lines still unrecorded (Fish free-plan credits ran out; they refill on the next cycle): recap_cris_1-2, supper_biertan 0-1, act_3, balaur_rise 0-1, act_4, and the 9 `lvl_*` lines. Missing lines are skipped silently. Voice: "Romania" `6d76b9c0a0c54f6a97a1c1748270cee1`, model drama-3 with [bracket] directions.
- Final fight in the church: bell placement and fight start are poor; no film after the sexton is defeated.
- Character sizes and styles are inconsistent across the cast.
- Some Thomas walk frames show a grey shirt without the apron.
- Unverified in game: postern gate leaves, act cards, balaur film, compact villages in all quests, Biertan gates.
- Pushing from the Mac shell is blocked in the Claude desktop sandbox; push from a normal terminal.

## Next Steps
1. Record the remaining 17 narration lines when Fish credits refill (about 2,000 credits needed), add to `audio/voice/`, rebuild.
2. Playtest the new church fight and the sexton film card.
3. Check haystacks and remaining tree variety in the forests; cast sprite style consistency (needs PixelLab regeneration, not done).
4. Cast consistency pass.
5. Playtest and verify the unverified items above.

## Task Board
Code changes go through the proposal and review loop described in `.ai/ARCHITECTURE.md` (Proposal and review loop). Rules: first read `.ai/LESSONS.md` (mistakes not to repeat). One owner per task. Only edit the files named in your task. Write results to the named output file under `.ai/`. When done, change the status here to `done` and add one line to Recent Changes.


### Model routing (who runs which task; Claude reviews every result)
Model: Nemotron, local (Ollama name `nemotron-3.5-bolt:e4b-nvfp4`, 7.2 GB). Start an agent session with `ollama launch claude --model nemotron-3.5-bolt:e4b-nvfp4`, or run a single-file task with `tools/run_task.sh <task> nemotron-3.5-bolt:e4b-nvfp4`. Qwen 3.8 is 18 GB and too big for the 16 GB laptop; use it only if a smaller Qwen is installed. Kimi and OpenRouter are not used.
| Task | How |
|---|---|
| T1, T2, T4, T6 (one file at a time) | `tools/run_task.sh T4 nemotron-3.5-bolt:e4b-nvfp4` |
| T5, T7, T8, T9, T10, T11, T13, T14, T15 | agent session, one task per session |
| Anything that edits `.gd` | Claude only (compiles, tests, publishes) |
Agent session prompt: "Read .ai/HANDOFF.md and follow its rules. No edits to .gd, scene or asset files. Task: <id>."
Local models have about 16k context on a 16 GB laptop: one file or one function per request. Suggested order: T4, T9, T1, T6, then the rest.

### T1: GDScript static-typing audit (owner: Nemotron local (Ollama + Claude Code), status: open)
Scope: read-only review of `scripts/ui/`, `scripts/quests/` and `scripts/actors/`.
Output: `.ai/REVIEW_typing.md` containing, per file, a list of `line: problem: suggested fix` for
- variables, parameters or returns without a declared type where the type cannot be inferred,
- `:=` on Variant results (dictionary `.get()`, `call()`, untyped array elements),
- loops without a typed iterator over typed data,
- signals declared without parameter types.
Do NOT modify any `.gd` file. Claude applies the fixes afterwards.

### T2: Narration copy review (owner: Nemotron local (Ollama + Claude Code), status: open)
Scope: read `scripts/core/narration.gd` (the LINES dictionary).
Output: `.ai/REVIEW_narration.md` with suggested rewrites that sound more spoken and more Transylvanian-storyteller (short sentences, dry humour, Lorena fondly mocking the hunter, English with a light Romanian flavour). Keep each line under the original byte length so recording credits are not exceeded. Do NOT edit the .gd file.

### T3: Final fight in the Church on the Hill (owner: Claude, status: interior done; sexton-defeat film pending)
Files: `scripts/levels/hillchurch.gd`, sexton boss, a new church interior level, story card after the sexton falls. Other AIs: do not edit these.


### T4: Code map (owner: Nemotron local, status: open; 9 files still missing, rerun)
Read every `.gd` file under `scripts/`, one at a time. For each file write ONE small file `.ai/codemap/<path with / replaced by _>.md`, for example `.ai/codemap/scripts_world_trees.gd.md`, containing exactly one line: `path: what it is, key public functions, which levels or quests use it`. Never write to `.ai/CODEMAP.md` yourself (Write overwrites the file and loses earlier lines); Claude merges the small files. Skip files that already have a file in `.ai/codemap/`. Do NOT modify any `.gd` file. When every `.gd` file has a codemap file, set T4 to done.

### T5: Consistency and anachronism review (owner: Nemotron, status: open)
Read `STORY.md`, `scripts/quests/*.gd`, `scripts/levels/*.gd` dialogue strings and `scripts/core/game_manager.gd` (STORIES). Output `.ai/REVIEW_consistency.md` listing contradictions as `file:line: problem: suggested fix`. Canon: game year 1521; the baron died unmarried in 1321 ("two hundred years"); sacristy door 1515; Biertan; character names and roles must match across files. Also flag any dialogue that sounds modern. Do NOT edit the files.

### T6: QA checklist (owner: Nemotron, status: open)
From the quest scripts, write `.ai/QA_CHECKLIST.md`: per level, the steps a playtester should do in order, the flags set (`G.side_add(...)`), and what must visibly happen. Mark steps that look impossible to complete from the code. Read-only.

### T7: Story drafts for the backlog (owner: Nemotron, status: open)
Write drafts (not code) to `.ai/DRAFT_quests.md`, grounded in `STORY.md`, in Romanian folklore (use Tudor Pamfile, Mihai Coman, Aurel Cosma Jr.; no pop-culture versions), and in the game's tone (dry, warm, Lorena mocking the hunter):
1. The Criț subquests (two short ones).
2. A scene where village children sing.
3. Sfânta Vineri: a clear in-story explanation of who she is and what she wants.
4. The mushroom and Turks side story.
5. The Saschiz market.
Each draft: location, NPCs, steps (what the player sees and does), reward, 6 to 10 lines of key dialogue. Keep drafts short. Claude implements the chosen ones.

### Who does what
- Claude: all code changes, builds, publishing, Meshy and PixelLab art, narration audio, the sexton-defeat film, natural ground/grass/haystacks/trees, character consistency.
- Nemotron (local Ollama): read-only reviews, code map, QA checklist and story drafts, written to `.ai/` only.
- ChatGPT: reserve only, because the monthly quota is almost used. Use it for a second opinion on a hard design question, nothing routine.
- After a Nemotron task: change its status to `done` here and add one line to Recent Changes in HANDOFF.md.

### T8: Folklore fact-check (owner: Nemotron, status: open)
Read all dialogue, STORIES and `scripts/bosses/*.gd` text. Output `.ai/REVIEW_folklore.md`: every place where a creature, rite or custom differs from the Romanian sources (Tudor Pamfile "Mitologia poporului român", Mihai Coman "Mitologie populară românească", Aurel Cosma Jr. "Cosmogonia poporului român", the Solomonar and Cățelul pământului references in memory), as `file:line: what the game says: what the source says: suggested fix`. Also list anything that comes from pop culture and not from folklore. Do not use Adevărul as a source. Read-only.

### T9: Missing asset scan (owner: Nemotron, status: open)
Find every `res://` path and every sprite or sound name used in `scripts/` (`add_decor("name")`, `Audio.sfx("name")`, `FIGURES`, texture names in `Mats`). Output `.ai/REVIEW_assets.md`: names that have no matching file under `sprites/`, `audio/` or `textures/`, with the file and line that uses each. Read-only.

### T10: Proposals for the open issues (owner: Nemotron, status: open)
Write proposals only, into `.ai/proposals/` as `NAME.md` (plan in plain words and the exact code you suggest in a fenced block, nothing applied): (a) a gentle regional name list for the villagers who currently have none (check `scripts/levels/*.gd`); (b) a small, cheap way to make the forest edge trees (`_wilds()` in `world_builder.gd`) follow the new one-colour-family palette in `Trees.leaf_color` without extra nodes. Claude reviews, compiles and applies.

### T11: Village ground and tree check by code (owner: Nemotron, status: open)
Nemotron cannot see the game, so this is a code review. For every village level (`Mats.is_village`), list in `.ai/REVIEW_villages.md`: which ground material is used (`Mats.ground()` now uses `textures/px_meadow_diff_1k.png`), any `add_patch` or ground colour set in the level that would clash with a green meadow (dark tints, `ground = Color(...)`), roads or cobbles with tints that look wrong on green, and any tree or decor placed through `add_tree` / `add_decor` with a name that is not in `scripts/actors/decor.gd`. Read-only. Claude then screenshots the flagged villages.

### T12: Forest tree palette (owner: Nemotron, status: open; same file as T10b)
Combined with T10(b). Output only the proposal file; do not edit `.gd`.

### T13: Verify by reading (owner: Nemotron, status: open)
For each feature below, trace the code path and write `.ai/REVIEW_features.md` saying "reachable" or "broken: <why>" with `file:line`:
1. Act cards: `_act_card()` in `level_loader.gd` (act_2, act_3, act_4 conditions).
2. Balaur film `balaur_rise` and the balaur animation in `storm_balaur.gd`.
3. Walking animations: files named `walk_<dir>_<n>.png` exist for every `npc_*` and creature that uses `PixelFigure` with walking (earth dog, vârcolac, Azorel, Matei, the sexton, Meister Thomas); check the frame counts match the code.
4. Compact villages: `Village.compact()` and `_trim_edges()` do not remove or move anything a quest needs (props listed in the quests' `target`, `spots` and `add_prop` ids).
5. Biertan gates: the night gates open only after that ring's guards are beaten (`biertanfort.gd`, `wood_gate.gd`).
6. The Sighișoara postern gate in `sighisoara.gd` (`WoodGate.make` after `_wall_point`) and the cellar door `cellar_door` position: is the door reachable from the town side?
7. The new church fight in `hillchurch.gd`: every phase (0 to 4) can be reached, `_cold_feet()` fires once, the bell cooldown works, `_judgement()` always runs after the sexton's death (check `died` is connected once).
Read-only.

### T14: Backlog designs (owner: Nemotron, status: open)
Write one short design per item into `.ai/DRAFT_backlog.md` (location, what the player sees and does, what Claude must build, in a few lines each): other village recaps (the `recap_*` story cards for villages that have none, in Lorena's voice), shades at lamps (what is meant and a cheap way to do it), Limousin cow jokes (10 short lines), footprints in the snow or mud (a cheap approach for the web build), the stână hay ground texture (describe the texture), more music and boss music (list which levels need which mood, folk, no medieval sound, in the style of Surorile Osoianu), analytics (what to measure for a 2-hour playtest and a privacy-safe way to log it). Keep it short; no code.


### T15: Blender sprite render test (owner: Nemotron local, status: open)
Write a Blender script. Test before wider use:
- Deliver `tools/render_sprite.py` (Blender Python, run by Alex on the Mac). Input: a GLB path (Meshy model). Output: 8 directions as PNG, 128x128, transparent background, fixed top-down camera, same lighting for every prop, named `rot_<dir>.png` like sprites/Pixel/<name>/.
- Test prop: the church bell (or one pew) for `scripts/levels/hillchurch.gd`.
- Output files only as PNG. No 3D model goes into the game build (web export is about 80 MB).
- Reduce colors to match the pixel-art palette. Claude checks the result in a level screenshot before it ships.
- If it works, extend to the other props and to cast-size consistency (open item 4).
- Nemotron writes the script and notes to `.ai/proposals/`; Claude reviews at the next check.
