# HANDOFF (live log; update before finishing and before every push)

## Active Feature
Final wedding fight now runs inside the Church on the Hill (`scripts/levels/hillchurch.gd`). Task board: `.ai/TASKS.md` (T1, T2 open for Gemini in Cherry Studio; T3 Claude).

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
