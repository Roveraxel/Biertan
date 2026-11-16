# HANDOFF (live log; update before finishing and before every push)

## Active Feature
Final wedding fight now runs inside the Church on the Hill (`scripts/levels/hillchurch.gd`). Task board is the last section of this file (T1, T2, T4 to T7 open for Nemotron in Cherry Studio; T3 Claude).

(previous)
Narration and story polish for the web playtest; next big item is the final fight as a Meshy-generated level inside the Church on the Hill.

## Last Worked On By
Claude (Claude Code session), 2026-11-16 02:30.

## Recent Changes
- Church on the Hill is now a church interior (nave, pillars, pews, altar, crypt slabs): walking up the aisle starts the wedding, the dead rise from the slabs, wolves come in at the door, the sexton enters by the door. New bell rope by the tower door stuns the dead for 4 s (8 s cooldown) and restores guest courage. Texts changed from graveyard to church. Not yet playtested end to end. No Meshy model used for the interior (procedural level plus existing textures).
- Narration: 11 of 28 lines recorded in the Romania voice (drama-3) into `audio/voice/`: prologue, descent, recap_sighisoara 0-2, act_2, flash_cup, flash_twig, flash_stones, flash_stones2, recap_cris_0. `Narration.VOICE` updated. Web build republished.
- Sighișoara: postern gate cut into the town wall by the Butchers' Tower, guild sign moved beside the outside cellar door.
- Meister Thomas (`npc_butcher`): 6-frame walk cycle in 8 directions.
- Added `PROJECT_CONTEXT.md` (repo root, also on GitHub `Roveraxel/Biertan` main) and this `.ai/` folder.
- Earlier this week: act cards, balaur film and ripple animation, Casa Vlad Dracul interior, compact villages, Biertan gates, walking Azorel / earth dog / vârcolac, Lorena narration hooks (`scripts/core/narration.gd`).

## Known Issues
- 17 narration lines still unrecorded (Fish free-plan credits ran out; they refill on the next cycle): recap_cris_1-2, supper_biertan 0-1, act_3, balaur_rise 0-1, act_4, and the 9 `lvl_*` lines. Missing lines are skipped silently. Voice: "Romania" `6d76b9c0a0c54f6a97a1c1748270cee1`, model drama-3 with [bracket] directions.
- Final fight in the church: bell placement and fight start are poor; no film after the sexton is defeated.
- Ground, grass, haystacks and trees in villages look unnatural.
- Character sizes and styles are inconsistent across the cast.
- Some Thomas walk frames show a grey shirt without the apron.
- Unverified in game: postern gate leaves, act cards, balaur film, compact villages in all quests, Biertan gates.
- Pushing from the Mac shell is blocked in the Claude desktop sandbox; push from a normal terminal.

## Next Steps
1. Record the remaining 17 narration lines when Fish credits refill (about 2,000 credits needed), add to `audio/voice/`, rebuild.
2. Playtest the new church fight; add the sexton-defeat film (Meshy folk-illustration picture, story card).
3. Natural-looking ground, grass, haystacks and trees.
4. Cast consistency pass.
5. Playtest and verify the unverified items above.

## Task Board
Rules: one owner per task. Only edit the files named in your task. Write results to the named output file under `.ai/`. When done, change the status here to `done` and add one line to Recent Changes.


### T1: GDScript static-typing audit (owner: Nemotron via Cherry Studio, status: open)
Scope: read-only review of `scripts/ui/`, `scripts/quests/` and `scripts/actors/`.
Output: `.ai/REVIEW_typing.md` containing, per file, a list of `line: problem: suggested fix` for
- variables, parameters or returns without a declared type where the type cannot be inferred,
- `:=` on Variant results (dictionary `.get()`, `call()`, untyped array elements),
- loops without a typed iterator over typed data,
- signals declared without parameter types.
Do NOT modify any `.gd` file. Claude applies the fixes afterwards.

### T2: Narration copy review (owner: Nemotron via Cherry Studio, status: open)
Scope: read `scripts/core/narration.gd` (the LINES dictionary).
Output: `.ai/REVIEW_narration.md` with suggested rewrites that sound more spoken and more Transylvanian-storyteller (short sentences, dry humour, Lorena fondly mocking the hunter, English with a light Romanian flavour). Keep each line under the original byte length so recording credits are not exceeded. Do NOT edit the .gd file.

### T3: Final fight in the Church on the Hill (owner: Claude, status: interior done; sexton-defeat film pending)
Files: `scripts/levels/hillchurch.gd`, sexton boss, a new church interior level, story card after the sexton falls. Other AIs: do not edit these.


### T4: Code map (owner: Nemotron, status: open, do this first)
Read every `.gd` file under `scripts/`. Output `.ai/CODEMAP.md`: one line per file (`path: what it is, key public functions, which levels or quests use it`). Do NOT modify any `.gd` file.

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
- Nemotron (Cherry Studio): read-only reviews, code map, QA checklist and story drafts, written to `.ai/` only.
- ChatGPT: reserve only, because the monthly quota is almost used. Use it for a second opinion on a hard design question, nothing routine.
- After a Nemotron task: change its status to `done` here and add one line to Recent Changes in HANDOFF.md.
