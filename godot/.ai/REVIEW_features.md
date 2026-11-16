# Code-Path Verification Review

Trace of code paths for the seven gameplay features specified in Task T13.

---

### 1. Act Cards
- **Code Path:** `scripts/core/level_loader.gd:132-136` in `_act_card(level_id)`:
  - `act_2`: `level_id == "biertanfort" and not G.side_has("bt_arrive") and not G.side_has("act_2")`. Triggered when the player travels from Richiș to Biertan for the first time before `bt_arrive` is set in `biertanfort.gd:120`. `G.side_add("act_2")` is marked and `G.show_story("act_2")` is displayed.
  - `act_3`: `level_id == "gorge" and G.side_has("bt_fled") and not G.side_has("act_3")`. Triggered when transitioning from Biertan to the Gorge after defeating the baron's strigoi form (`bt_fled` is set at `sacristy.gd:163`). `G.side_add("act_3")` is marked and `G.show_story("act_3")` is displayed.
  - `act_4`: `level_id == "viscri" and VisQuest.taken() and not G.side_has("act_4")`. In `vis_quest.gd:29`, `VisQuest.taken()` is defined as `G.side_has("tn_done") and not G.side_has("fin_lorena")`. Triggered upon exiting the tunnel into Viscri cellars (`tunnel.gd:303`). `G.side_add("act_4")` is marked and `G.show_story("act_4")` is displayed.
- **Verdict:** `reachable` (`scripts/core/level_loader.gd:132`).

---

### 2. Balaur Film & Animation
- **Code Path:**
  - `balaur_rise` film card: in `scripts/levels/gorge.gd:149`, `await G.show_story("balaur_rise")` is called following the dialogue with the Solomonar. The card is defined in `scripts/core/game_manager.gd:28-31` with panels referencing `balaur_1` and `balaur_2`. Assets `sprites/Story/balaur_1.png` and `sprites/Story/balaur_2.png` exist on disk.
  - Balaur shader animation: in `scripts/bosses/storm_balaur.gd:25-43`, shader code `SERPENT` applies a travelling sinusoidal wave distortion along the serpent's body mesh (`along * 11.0 - TIME * speed`). Dynamic wave parameters (`amp`, `speed`, `wave`) are updated in `step()` (lines 136-146) across diving, circling, and grounded states.
- **Verdict:** `reachable` (`scripts/levels/gorge.gd:149`, `scripts/bosses/storm_balaur.gd:25-43`).

---

### 3. Walking Animations Frame Audit
- **Code Path:** `scripts/actors/pixel_figure.gd:50-73` (`library()`) parses directory files as `<anim>_<dir>_<frame>.png` and sorts frame indices:
  - `earth_dog`: `sprites/Pixel/earth_dog/` has 48 walk frames (6 frames across all 8 directions: south, south-east, east, north-east, north, north-west, west, south-west).
  - `varcolac`: `sprites/Pixel/varcolac/` has 48 walk frames (6 frames across all 8 directions).
  - `Azorel`: uses `sprites/Pixel/npc_azorel/` (mapped via `Prop.FIGURES` in `prop.gd:13`), which has 48 walk frames (6 frames across all 8 directions).
  - `Matei`: uses `sprites/Pixel/npc_matei/`, which has 48 walk frames (6 frames across all 8 directions).
  - `The Sexton`: uses `sprites/Pixel/npc_sexton/` (mapped via `Prop.FIGURES["bsexton"]` in `prop.gd:10`), which has 48 walk frames (6 frames across all 8 directions). Note: the raw folder `sprites/Pixel/sexton` only has 30 frames, but `Prop.FIGURES` explicitly routes to `npc_sexton`, ensuring complete 8-direction coverage.
  - `Meister Thomas`: uses `sprites/Pixel/npc_butcher/`, which has 48 walk frames (6 frames across all 8 directions).
- **Verdict:** `reachable` (`scripts/actors/pixel_figure.gd:50`, all 6 characters possess 6-frame walk cycles in all 8 directions matching code expectations).

---

### 4. Compact Villages
- **Code Path:** `scripts/core/village.gd:61-125` (`compact()` and `_trim_edges()`):
  - In `_trim_edges()`, only blocks with `b.style == "house"` are candidates for trimming. Before any house is removed, `village.gd:109-114` checks `p.pos.distance_to(b.c) < 320.0` for all props in `props`. If any prop is within 320 m, `used = true` and the house is retained.
  - In `compact()`, coordinates for blocks, decals, trees, roads, cobbles, and `spots` are uniformly multiplied by `compact_k = 0.8`. Nodes and child props are scaled via `_scale_node(n, f)`.
  - No quest prop, clue, or task spot is deleted or dissociated from its interactive location.
- **Verdict:** `reachable` (`scripts/core/village.gd:61`, safe and non-destructive).

---

### 5. Biertan Night Gates
- **Code Path:** `scripts/levels/biertanfort.gd:100-108`, `191-230` and `scripts/actors/wood_gate.gd`:
  - Three concentric wall gates are created at lines 101-103 using `WoodGate.make(...)`.
  - If night has fallen and the gate's bolt flag is not set (`not has.call("bt_bolt%d" % i)`), the gate remains shut.
  - `_guard_down(ring)` (line 211) iterates through `guard[ring]`. Only when every guard in that ring is dead, fleeing, or fainted does it call `G.side_add("bt_bolt%d" % ring)` and `gates[ring].open()`.
  - The gates open sequentially as the player defeats each ring's defending guards.
- **Verdict:** `reachable` (`scripts/levels/biertanfort.gd:211`).

---

### 6. Sighișoara Postern Gate & Outside Cellar Door
- **Code Path:** `scripts/levels/sighisoara.gd:49-59` and lines 336-344:
  - In line 50-55, `door_ref := m.at(-116, -99)` defines the reference position. `_wall_point(door_ref)` calculates the nearest wall point `pw`. The postern rect `postern` is appended to `cut`, and `_cut_at_gates(w, cut)` cuts the curtain wall around the postern gate.
  - `WoodGate.make(self, pw, GAP, rad_to_deg(-pdir.angle()), "Postern gate")` (line 59) instantiates an interactive wooden postern gate through the wall.
  - The cellar door is placed outside the wall at line 339 (`cellar_door = cw + Vector2(0, 16)`). The player can walk through the postern gate from the town interior to reach the exterior cellar door and guild sign.
- **Verdict:** `reachable` (`scripts/levels/sighisoara.gd:49-59`).

---

### 7. Church on the Hill Fight Progression
- **Code Path:** `scripts/levels/hillchurch.gd:80-186`, `236-270`:
  - Phase 0: Player enters church; aisle trigger invokes `_cold_feet()`.
  - `_cold_feet()` (line 118): checks `if phase != 0 ...: return` and immediately assigns `phase = -1`, ensuring it fires exactly once. At dialogue conclusion, it invokes `_wave(1)`.
  - Phase 1 & 2: `_wave(w)` runs for `WAVE_TIME[w]` (20s and 24s respectively), tracking guest courage. `_wave(1)` transitions to `_wave(2)`, which transitions to `_sexton()` (Phase 3).
  - Phase 3: `_sexton()` spawns `sexton` boss. Line 185 connects `sexton.died.connect(func(_e): _judgement())` exactly once.
  - Bell cooldown: in `_process(dt)` line 95, `bell_cd = maxf(0.0, bell_cd - dt)`. In `ring_bell()` (line 267), `if bell_cd > 0.0: Hud.toast(...); return` enforces an 8.0s cooldown (`bell_cd = 8.0`).
  - Phase 4: When `sexton` dies, `_judgement()` is called, setting `phase = 4`, clearing foes, showing story card `sexton_end`, executing the trial dialogue, and concluding with `fin_done`.
- **Verdict:** `reachable` (`scripts/levels/hillchurch.gd:118`, `157`, `171`, `185`, `236`).
