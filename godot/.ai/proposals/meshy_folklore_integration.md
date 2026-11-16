Status: applied (sprites + Decor.SIZES + forest placements compiled & checked with Godot 4.7.2 headless; staged GLBs kept in assets/meshy/staging/ with .gdignore)

# Meshy Folklore & Environment Integration (Mix: Sprites + Staged GLBs)

**Goal:** Integrate the 4 Blender-rendered folklore prop sprites into `sprites/Props/` + `Decor.SIZES`, and document the big 3D GLBs staged in `assets/meshy/staging/` for `ModelKit` / Godot validation.
- **Not compiled/run:** Godot is not installed on this machine, so Claude must apply, compile, and visually check the `.gd` edits in Godot.

## 1. Small Props Rendered to PNG Sprites (`sprites/Props/`, <10 KB total)
Rendered from textured Meshy GLBs in Blender 5.3.0 (`tools/render_sprite.py`, 64×64, 24 colors, elev 40°):
- `sprites/Props/hanging_charms.png` (2.0 KB, from `hanging_protective_charms.glb`)
- `sprites/Props/witch_effigy.png` (2.2 KB, from `witchcraft_effigy.glb`)
- `sprites/Props/bone_totem.png` (1.9 KB, from `bone_totem.glb`)
- `sprites/Props/forest_offerings.png` (2.8 KB, from `abandoned_forest_offerings.glb`)

### Code Additions (`scripts/actors/decor.gd` + forest levels)
Add to `Decor.SIZES` (`scripts/actors/decor.gd:41`):
```gdscript
	"hanging_charms": 0.95, "witch_effigy": 1.0, "bone_totem": 1.15, "forest_offerings": 0.75,
	"pig": 0.75, "anvil": 0.8, "donkey": 1.15, "goat": 0.85, "watermill": 2.1, "footbridge": 1.6,
	"milestone": 0.9, "grindstone": 0.95, "plough": 1.1, "dead_tree": 2.0, "tree_stump": 0.85, "stepping_stones": 1.2,
```

Place deterministically off-trail (no collision/trigger/NPC changes):
- `scripts/levels/forest.gd` (Wolf Forest):
  - `add_decor(TRAIL[2] + Vector2(-140, -130), "bone_totem", 0.3)`
  - `add_decor(TRAIL[4] + Vector2(150, 120), "bone_totem", 0.3)`
  - `add_decor(GLADE + Vector2(-210, 140), "witch_effigy", 0.25)`
  - `add_decor(TRAIL[0] + Vector2(220, -110), "hanging_charms", 0.2)`
- `scripts/levels/crisforest.gd` (Forest of Criș):
  - `add_decor(OAK + Vector2(-220, 160), "forest_offerings", 0.2)`
  - `add_decor(OAK + Vector2(210, -150), "witch_effigy", 0.25)`
- `scripts/levels/critforest.gd` (Sfânta Vineri's wood / shrine):
  - `add_decor` `forest_offerings` and `hanging_charms` near the shrine clearing.

## 2. Big Elements Staged in `assets/meshy/staging/` (for Godot / `ModelKit` Validation)
Downloaded to `godot/assets/meshy/staging/`:
- **Textured (Meshy refine):**
  - `cursed_hollow_oak.glb` (5.62 MB + PBR textures) — Wolf Forest / Muma's Hollow landmark
  - `stone_ritual_altar.glb` (5.66 MB + PBR textures) — Forest clearings / folklore encounter focal point
  - `stana_shepherd_hut.glb` (3.96 MB + base_color) — Stână shepherd hut (`stana.gd`)
- **Free geometry previews (0 credits — `ModelKit` applies the game's own pixel textures):**
  - `sighisoara_clock_tower.glb` (0.07 MB)
  - `guild_tower_family.glb` (0.07 MB)
  - `saxon_townhouse.glb` (0.06 MB)
  - `romanian_farmhouse.glb` (0.05 MB)
  - `rural_watermill.glb` (0.07 MB)
  - `fortified_saxon_church.glb` (0.07 MB)
  - `drowned_quarry_rock.glb` (0.07 MB)
  - `mine_tunnel_timber.glb` (0.07 MB)

### Note for Claude
- `ModelKit.shape()` (`scripts/world/model_kit.gd:48-75`) strips GLB materials and sorts triangles into building `roof` / `wall` surfaces. That works directly for the 8 architectural previews + `stana_shepherd_hut.glb`.
- For `cursed_hollow_oak.glb` and `stone_ritual_altar.glb`, keep their native Meshy materials (with texture max size capped at 512 px in Godot import settings to protect the ~80 MB Web export) OR render them via `tools/render_sprite.py` (previews already generated in `tools/render_out/`).
