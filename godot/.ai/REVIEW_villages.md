# Village Ground and Tree Code Review

Review of all nine village levels (`Mats.is_village`) for ground materials, tint clashing with the new green meadow texture (`textures/px_meadow_diff_1k.png`), road/cobble tints, and decor/tree validity against `scripts/actors/decor.gd`.

---

## 1. Ground Material & Texture Summary

In `scripts/world/mats.gd`:
- `Mats.is_village(id)` returns `true` for all nine canonical villages (`VILLAGES = ["sighisoara", "viscri", "crit", "saschiz", "sapartoc", "apold", "cris", "malancrav", "richisvillage"]`).
- `Mats.ground_for(id, level)` returns `Mats.ground()`.
- Because `Mats.px()` is `true` for all villages in `VILLAGES`, `Mats.ground()` returns:
  `mat("px_meadow", 2.6, Color(1.0, 0.97, 0.88), 0.1)`
  This maps to `textures/px_meadow_diff_1k.png` tiled at 2.6 m per repeat with a warm cream-green albedo tint `Color(1.0, 0.97, 0.88)`.

---

## 2. Per-Village Level Audit

### Sighișoara (`scripts/levels/sighisoara.gd`)
- **Ground Material:** `px_meadow` via `Mats.ground()`.
- **Ground Tint:** `ground = Color("2c3326")` (line 36).
  - *Clash Risk:* Dark murky olive-brown tint (`#2c3326`) used for unmeshed background / fog / ambient bounce; contrasts heavily with the bright green meadow.
- **Roads / Cobbles:**
  - Line 44: `add_path(roads[i], m.road_width[i], Color.WHITE, -990, "Cobbles")`.
  - All roads are set to `"Cobbles"`, using `px_cobble` (`Color(1.0, 0.94, 0.84)`). This warm sandstone cobble looks harmonious on green.
- **Patches / Blots:** No `add_patch` calls.
- **Decor & Trees:**
  - `add_tree(p, rng.f() < 0.2)` (line 223) generates procedural crowns.
  - Decor used: `well`, `stall`, `notice_board`, `horse_cart`, `troita`, `portrait`, `hearth`, `grating`, `crate`, `cellar_door`, `guild_sign`, `hams_rack`, `garlic_braid`, `bell_rope`, `haycart`, `joimarita`, `lamp_lit`.
  - *Validation:* All decor names are fully registered in `scripts/actors/decor.gd`.

### Viscri (`scripts/levels/viscri.gd`)
- **Ground Material:** `px_meadow` via `Mats.ground()`.
- **Ground Tint:** `ground = Color("2a3224")` (line 19).
  - *Clash Risk:* Dark desaturated olive-grey tint (`#2a3224`).
- **Roads / Cobbles:**
  - Line 31: `add_path(roads[i], w, Color.WHITE, -990, "Cobbles" if w >= 140.0 else "Path")`.
  - Cobbles use `px_cobble`; dirt paths use `forest_leaves_02` (`Color(0.7, 0.62, 0.52)`).
- **Patches / Blots:** No `add_patch` calls.
- **Decor & Trees:**
  - `add_tree(p, wood and rng.f() < 0.3)` (line 86).
  - Decor used: `chair`, `potlid`, `chopping_block`, `hams_rack`, `goose_pen`, `goose`, `goose_honk`, `dog_bark`, `dog_sleep`, `kennel`, `scraps`, `bone`, `hay`, `haycart`, `cellar_door`, `lantern_iron`, `troita`, `laundry`, `ladder`, `salt_barrel`, `sacks`, `barrels`, `handcart`, `oven`, `firewood`.
  - *Validation:* All decor names are registered in `scripts/actors/decor.gd`.

### Criț (`scripts/levels/crit.gd`)
- **Ground Material:** `px_meadow` via `Village.standard()`.
- **Ground Tint:** Inherited `ground = Color("2a3224")` from `village.gd:24`.
- **Roads / Cobbles:** Cobbles on roads $\ge 140$ m, dirt paths elsewhere (`village.gd:53`). Forest path connector added in line 56.
- **Patches / Blots:**
  - Inherits `scatter(..., 360, [Color("363e2a"), Color("2a2e22"), Color("444230")])` from `village.gd:31`.
  - *Clash Risk:* 360 dark brown/blackish decal blots scattered over the map create mud-stain contrasts against the bright pixel meadow.
- **Decor & Trees:**
  - `plant_trees(400.0, 280.0, ...)` (line 18).
  - Decor used: `bench`, `laundry`, `linen`, `well`, `lye`, `washtub`, `apples`, `plums`, `ribbons`, `stubs`, `logs`, `troita`, `haycart`, `corn_shock`.
  - *Validation:* All decor names exist in `decor.gd`. (Note: `"corn_shock"` is anachronistic per folklore review, but valid in decor dict).

### Saschiz (`scripts/levels/saschiz.gd`)
- **Ground Material:** `px_meadow` via `Village.standard()`.
- **Ground Tint:** Inherited `Color("2a3224")`.
- **Roads / Cobbles:** Standard village roads (`village.gd:53`).
- **Patches / Blots:** Inherited `scatter()` dark blots (360 count).
- **Decor & Trees:**
  - Inherits standard tree planting.
  - Decor used: `crate`, `lantern`, `haycart`, `handcart`.
  - *Validation:* All decor names are registered in `decor.gd`.

### Șapartoc (`scripts/levels/sapartoc.gd`)
- **Ground Material:** `px_meadow` via `Village.standard()`.
- **Ground Tint:** Inherited `Color("2a3224")`.
- **Roads / Cobbles:** Standard village roads (`village.gd:53`).
- **Patches / Blots:** Inherited `scatter()` dark blots.
- **Decor & Trees:**
  - `add_tree(p, rng.f() < 0.25)` (line 60).
  - Decor used: `hay`, `trough`, `geraniums`, `logs`, `letters`, `lamp_lit`, `lamp_post`, `hammock`, `book`, `planks`, `priest_sleep`, `wine_jug`, `table`, `pot_fire`, `music_stand`.
  - *Validation:* All decor names are registered in `decor.gd`.

### Apold (`scripts/levels/apold.gd`)
- **Ground Material:** `px_meadow` via `Village.standard()`.
- **Ground Tint:** Inherited `Color("2a3224")`.
- **Roads / Cobbles:** Standard village roads (`village.gd:53`).
- **Patches / Blots:** Inherited `scatter()` dark blots.
- **Decor & Trees:**
  - Inherits standard tree planting.
  - Decor used: `pot_steam`, `oven`, `cellar_door`, `feast_table`, `chair`, `wet_steps`, `grave_mound`, `candles2`, `stubs`, `bonfire`, `woodpile`, `coliva`, `colac`, `wine`, `tuica`, `bench2`.
  - *Validation:* All decor names are registered in `decor.gd`.

### Criș (`scripts/levels/cris.gd`)
- **Ground Material:** `px_meadow` via `Village.standard()`.
- **Ground Tint:** Inherited `Color("2a3224")`.
- **Roads / Cobbles:** Standard village roads (`village.gd:53`).
- **Patches / Blots:** Inherited `scatter()` dark blots.
- **Decor & Trees:**
  - `add_tree(oak + Vector2(0, -70))` (line 32).
  - Decor used: `herb_string`, `hat_egg`, `goose_honk`, `scarecrow`, `rye_sheaf`, `rye_fire`, `long_feast`, `wine_mug`, `hay`, `troita`.
  - *Validation:* All decor names are registered in `decor.gd`.

### Mălâncrav (`scripts/levels/malancrav.gd`)
- **Ground Material:** `px_meadow` via `Village.standard()`.
- **Ground Tint:** Inherited `Color("2a3224")`.
- **Roads / Cobbles:** Standard village roads (`village.gd:53`).
- **Patches / Blots:** Inherited `scatter()` dark blots.
- **Decor & Trees:**
  - `plum_tree` decor placed 6 times in orchard (line 50); standard village trees.
  - Decor used: `haystack`, `plum_tree`, `dog_bark`, `empty_cup`, `wilted_twig`, `plum_stones`, `trousers_flag`, `crypt_stairs`, `sheep_lie`.
  - *Validation:* All decor names are registered in `decor.gd`.

### Richiș (`scripts/levels/richisvillage.gd`)
- **Ground Material:** `px_meadow` via `Mats.ground()`.
- **Ground Tint:** `ground = Color("2c342a")` (line 20).
  - *Clash Risk:* Dark grey-green base `#2c342a`.
- **Roads / Cobbles:** Standard village roads (`village.gd:53`).
- **Patches / Blots:** Inherited `scatter()` dark blots.
- **Decor & Trees:**
  - Standard village trees.
  - Decor used: `bench`, `nai`, `basil`, `decoction`, `trapdoor`, `garlic_braid`, `iele_circle`, `ridge_barrier`, `troita`.
  - *Validation:* All decor names are registered in `decor.gd`.

---

## 3. Flagged Villages for Claude Screenshot Audit

1. **Sighișoara (`sighisoara.gd`):** Check the transition between the bright pixel meadow and dark `Color("2c3326")` map edges and tower walls.
2. **Viscri (`viscri.gd`):** Check contrast between the meadow and `Color("2a3224")` ground tint, especially along church hill.
3. **Criț & Apold:** Check whether the 360 scatter blots (`Color("363e2a")`, `Color("2a2e22")`, `Color("444230")`) look like natural soil variations or jarring dark splotches on `textures/px_meadow_diff_1k.png`.
