Status: proposed

# Fix Biertan / Sacristy Softlock (T6 Finding)

**Goal:** Prevent a permanent softlock in Biertan when a player reaches the sacristy door without all 9 village tokens.
- **Not compiled/run:** Godot is not installed on this machine, so Claude must apply, compile, and test this change.

## The Softlock (`bt_quest.gd:264-268` + `sacristy.gd:88-95`)
1. `bt_quest.gd:266-267` blocks the road back down (`"down"`) as soon as `bt_invited` or `bt_night` is set:
   - `elif night(): G.start_dialogue("The road down", ["Not while he is still up there."])`
   - `elif has("bt_arrive") and not has("bt_night") and has("bt_invited"): G.start_dialogue("The road down", ["You have been asked to supper. It would be rude."])`
2. At the top of Biertan, `sacristy.gd:88-95` refuses to open the sacristy door if `BtQuest.tokens_have() < BtQuest.TOKENS.size()` (9 tokens).
3. If the player skipped any earlier village token (or jumped via `?level=biertanfort`), they cannot open the sacristy door AND cannot go back down the hill to collect the missing tokens.

## Proposed Fix (Two Parts)
1. **Allow returning down the road before `bt_night` (or warn at supper/confrontation):**
   In `bt_quest.gd:264-268`, allow `"down"` to return to Richiș whenever `not night()` (or warn if tokens are missing before starting `bt_night`). Even better: allow `"down"` during `night()` *if* `tokens_have() < TOKENS.size()` so a trapped player can always go back to fetch missing tokens.
2. **Warn before locking into `bt_night`:**
   In `bt_quest.gd`, when confronting the baron (`proofs() == PROOFS.size()`) or before opening `sacristy.gd`, if `tokens_have() < TOKENS.size()`, tell the player which tokens are still missing and let them go back down the hill.

```gdscript
# scripts/quests/bt_quest.gd:264-268
		"down":
			if has("bt_fled"): Loader.goto_level("gorge")
			elif night() and tokens_have() >= TOKENS.size(): G.start_dialogue("The road down", ["Not while he is still up there."])
			else: Loader.goto_level("richisvillage", RcQuest.ridge_gate + Vector2(0, 200) if RcQuest.ridge_gate != Vector2.ZERO else null)
```
