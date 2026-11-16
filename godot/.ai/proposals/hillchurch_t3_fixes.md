Status: applied (compiled & checked with Godot 4.7.2 headless; Web export templates missing on Mac)

# T3: Church on the Hill — Bell Placement, Stun Radius & Fight Start

**Goal:** Fix the two remaining gameplay issues noted in `.ai/HANDOFF.md` Known Issues ("bell placement and fight start are poor") in `scripts/levels/hillchurch.gd`.
- **Not compiled/run:** Godot is not installed on this machine, so Claude must apply, compile, and playtest these edits.

## Problems Found in `scripts/levels/hillchurch.gd`
1. **Bell placement & stun radius (`hillchurch.gd:8, 308`):**
   - `BELL_AT` is `Vector2(300, 1150)` (far west aisle, outside the pillar row at `x=560`), and `_ring()` skips enemies with `e.pos.distance_to(BELL_AT) > 800.0`.
   - `ALTAR` is at `Vector2(1200, 560)` (`ALTAR + Vector2(0, 120)` is the wedding table at `(1200, 680)`). Distance from `BELL_AT` `(300, 1150)` to `(1200, 680)` is $\approx 1016\text{ px} > 800\text{ px}$.
   - **Result:** Ringing the bell fails to stun the dead attacking the wedding table.
2. **Fight start trigger (`hillchurch.gd:76`):**
   - `add_trigger(Rect2(900, 1130, 600, 40), _cold_feet)` fires in the middle of the nave (`y=1130`), long before the player reaches the guests or altar (`y=560..760`).
   - **Result:** The wedding cutscene interrupts the player halfway up the aisle before they can see the scene or talk to guests.

## Proposed Changes (`scripts/levels/hillchurch.gd`)

1. Move `BELL_AT` inside the nave by the southwest tower bay (`Vector2(760, 1460)` — clear of the pews at `y=1400, 1500` which span `x=550..810`? Wait: check pew X range at line 52: `1200.0 - 520.0 - 130.0 = 550.0` to `550 + 260 = 810.0`, and `y=1400, 1500`). So `Vector2(760, 1320)` sits cleanly in the open bay between the south-west pillar (`x=560, y=1210..1290`) and the pews (`y=1400`), or `Vector2(420, 1320)` in the tower alcove.
   - More importantly, raise the bell stun radius in `_ring()` from `800.0` to `1500.0` (or remove the distance cap since a church bell rings across the whole nave of a `2400x1800` interior).
2. Move the `_cold_feet` trigger forward to `Rect2(950, 740, 500, 40)` (just south of the wedding guests at `ALTAR + Vector2(0, 190..210)` = `y=750..770`, wait: `ALTAR + (0, 210)` is `y=770`, so `y=800` lets the player see the whole wedding party and optionally talk to them before stepping up to the altar).

```gdscript
# hillchurch.gd:8
const BELL_AT := Vector2(760, 1320)
```

```gdscript
# hillchurch.gd:76
	add_trigger(Rect2(950, 820, 500, 40), _cold_feet)   # reaching the wedding party starts the ceremony
```

```gdscript
# hillchurch.gd:308 (whole-church bell stun so enemies at the altar are always hit)
	for e in Enemy.all:
		if not is_instance_valid(e) or e.hp <= 0.0: continue
		if e.kind.begins_with("dead"): e.stun_t = 4.0
		elif e == sexton: e.stun_t = 1.5
```

## Pending Non-Code Item for T3
- Record `audio/voice/sexton_end_0.mp3` (listed in `HANDOFF.md:59` as awaiting Fish Audio credits).
