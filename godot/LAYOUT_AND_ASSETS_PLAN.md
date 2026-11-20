> **Update 2026-11-20 (decided with Alex):** The world look is now a sprite world (see `.ai/STYLE.md` section 15). Buildings are sprites rendered from Meshy models built from the Nano Banana sheets (`tools/render_iso.py`, `sprites/World/`). **Claude** produces ALL building sprites, including the new ones listed in section 2 (`house_town_2story`, `inn_2story`, `house_saxon_halfhip`, portal walls, church variants). **Antigravity does not generate house or building models and does not edit `scripts/world/world_builder.gd`, `mats.gd` or `model_kit.gd`**; it keeps the level scripts (Saschiz, Șapartoc, Biertan, Apold), combat, traversal and audio items from Track B. Roadside props such as benches, fences and the stork nest go to Claude as sprites as well.

# Village & City Layout Plan, Asset Gap List & Work Split (Claude vs. Antigravity)

**References:**
- Street View Inspiration: `reference_streets/` (`sighisoara/`, `crit/`, `saschiz/`, `biertan/`, `sapartoc/`, `apold/`, `viscri/`)
- Gameplay Feedback: [CHANGE_REQUESTS.md](file:///Users/alex/Biertan/godot/CHANGE_REQUESTS.md)
- Model Pipeline: `scripts/world/model_kit.gd` (`res://models/<name>.glb`) & `scripts/world/world_builder.gd`

---

## 1. Street View Layout & Art Direction by Settlement

| Settlement | Street Surface & Width | House Style & Palette | Yard Walls, Gates & Fences | Key Landmarks & Props |
|---|---|---|---|---|
| **Sighișoara** (`sighisoara.gd`) | Fan-patterned granite **cobblestone** square (`Piața Cetății`) + narrow curving cobblestone lanes (`Strada Turnului`, `Strada Zidul Cetății`). | Tightly joined **2-story Saxon townhouses** in sage green, salmon pink, olive, blue, and warm yellow; white casement frames; steep terracotta roofs with shed/eyebrow dormers. | Masonry retaining walls with wrought-iron railings; vaulted gatehouse passage beneath the Clock Tower. | Clock Tower (*Turnul cu Ceas*) gate clearly visible from the main square; guild towers; Vlad Dracul house; market stalls; cellar tower entrance cleanly separated from walls. |
| **Criț** (`crit.gd`) | Unpaved **gravel/dirt road** with wide grassy verges / shallow ditches (~8–10 m setback in central stretch; narrower cobblestone apron near houses). | Gable-end & eave-oriented **1-story Saxon houses** in dusty rose/pink, warm peach/ochre, cream, and pastel sky-blue — **all grounded with dark grey lower plinths** and green/brown louvered shutters. *(Fix squished houses & stark white/black contrast.)* | Continuous **tile-capped plastered masonry courtyard walls** with tall arched or flat-topped **wooden double carriage gates** and recessed pedestrian doors; climbing ivy. | Fortified church; wide roadside verges; replace bare ribbon-pole grass spot with orchard / forest edge; remove road-blocking wheel & apple trees. |
| **Saschiz** (`saschiz.gd`) | Wide **2-lane main street** (`DN13/E60`) with broad grassy verges, brick pedestrian path, and concrete drainage ditches. | Contiguous rows of cream, muted beige/rose, and ochre-yellow Saxon houses with white pilasters/trims; 2-story **Hanul Cetății** & pink stepped-gable Town Hall. | Mix of plastered masonry carriage-gate walls and **wooden picket/slat fences**; small tiled pedestrian gate covers. | **Saschiz Fortified Church** (`saschiz_church.glb`) across a wide green lawn with spruce/pine trees; hilltop peasant fortress ruins behind; open fortress entrance. |
| **Biertan** (`biertanfort.gd`, `hillchurch.gd`) | Broad **cobblestone central square** (`Piața 1 Decembrie 1918`) with stone-paver promenade; **2-lane paved street** (`DJ141B`) with narrow grassy verges north of square. | 2-story pale ochre civic Town Hall with white pilasters + rhythmic rows of crisp white, ochre, dusty-pink, and cream gable-end houses with **half-hipped (`Krüppelwalmdach`) roofs** and oval attic oculus vents. | Street-aligned facades linked by plastered courtyard portal walls with recessed arched wooden carriage gates. | **Biertan Fortified Church** (`biertan_church.glb`) elevated on wooded hill; dark-timber square kiosk; benches, boxwood hedges, whitewashed tree trunks. |
| **Șapartoc** (`sapartoc.gd`) | **Narrow single-lane unpaved ochre dirt/gravel road** with wide overgrown grassy verges & no curbs/sidewalks. | Smaller whitewashed, sky-blue, and muted olive-green plastered houses set behind grassy yards, with timber barns/outbuildings. | **Low wooden post-and-rail fences** (white-painted or weathered bare wood) & simple timber gate posts. | **Reformed Church** (`reformed.glb`) at the road fork with wooden roadside cross (*troiță*); enlarged **Radu's Inn** with outdoor garden seating; tall spruces & wildflowers. |
| **Apold** (`apold.gd`) | Wide **2-lane paved road** (`DJ106`) with gravel/grass verges, concrete drainage channels, and **concrete culvert bridges** into gates. | Compact linear Saxon rows in pastel pink, warm ochre, cream, grey, and mint green with white window trims and eyebrow dormers. | Tile-capped plastered masonry walls with **solid timber double driveway gates**, plus brick-pillared wrought-iron fences. | **Apold Fortified Church** perched on grassy embankment with whitewashed curtain wall, ochre gatehouse, and bell tower with **dark-timber overhanging gallery (*hourd*)**; autumn foliage (no spring flower fields). |
| **Viscri** (`viscri.gd`) | Wide **unpaved dirt/gravel road** (`104L`) with broad grassy verges, stone-and-timber drainage ditches, and small footbridges. | Warm ochre/butter-cream and **sky-blue/periwinkle** gable-front Saxon houses with dark grey plinths, relief stucco trims, and periwinkle louvered shutters. | Rounded-arch plastered courtyard gateways (either under continuous house roofline or tile-capped wall) with dark weathered wooden double doors. | **Viscri Fortified Church** (`viscri_church.glb`) with low **buttressed dry-stone outer wall** + tall whitewashed inner curtain wall & timber-gallery tower; wooden plank street benches; whitewashed tree trunks; utility pole with **stork nest**. |

---

## 2. Existing Assets vs. Buildings & Props to Generate

### Already in `models/`
- **Houses / Barns:** `house_saxon.glb`, `house_ro.glb`, `house_big.glb`, `barn.glb`
- **Churches:** `biertan_church.glb`, `saschiz_church.glb`, `viscri_church.glb`, `village_church.glb`, `hill_church.glb`, `basilica.glb`, `chapel.glb`, `orthodox.glb`, `reformed.glb`
- **Towers / Cellars:** `clocktower.glb`, `gate_tower.glb`, `guild_tower.glb`, `cellar_tower.glb`, `cellar_hatch.glb`

### New Models / Variants Needed (Meshy `.glb` or Procedural `world_builder.gd` / `ModelKit`)
1. **`house_town_2story.glb`** — Tightly joined 2-story Sighișoara/Biertan townhouse with eyebrow/shed roof dormers and casement shutters.
2. **`inn_2story.glb`** — 2-story Saxon inn/civic building (*Hanul Cetății* in Saschiz, Radu's Inn in Șapartoc with outdoor garden seating, Biertan Town Hall).
3. **`house_saxon_halfhip.glb`** — Classic `Krüppelwalmdach` (half-hipped) Saxon gable-front house with oval/twin attic vents and dark grey lower plinth (fixes squished Criț houses & adds Viscri/Biertan/Apold variety).
4. **`portal_wall_arched.glb` & `portal_wall_flat.glb`** — Tile-capped plastered masonry courtyard wall segments with arched or rectangular wooden double carriage gates (replaces loose stone yard walls and fixes Crit/Sighișoara/Apold/Viscri street fronts).
5. **`apold_church.glb`** (or `apold_bell_tower.glb` + curtain wall) — Fortified church with whitewashed curtain wall, ochre gatehouse, and defensive bell tower with dark-timber upper *hourd* gallery (fixes dark/bare Apold church).
6. **Roadside & Village Props (for `ModelKit` / `sprites/Props/`):**
   - `culvert_bridge.glb` — Stone/concrete footbridge over roadside drainage ditch (Apold, Viscri).
   - `street_bench_wood.glb` — Rustic wooden plank bench on posts (Viscri, Biertan).
   - `troita_cross.glb` — Traditional wooden roadside cross (Șapartoc, Sighișoara).
   - `fence_post_rail.glb` & `fence_picket_wood.glb` — Continuous wooden village fences (Șapartoc, Saschiz, Old Cemetery).
   - `stork_nest_pole.glb` — Whitewashed utility pole with stork nest (Viscri).
   - **2D/UI & Combat Props:** Real thrown boulder sprite for Uriași (replacing white circle), custom in-theme cellar jars/bookshelf (`cellar.gd`), realistic grass/flower sprites (replacing flat pixel squares).

---

## 3. Division of Work: Claude vs. Antigravity

> **Rule of thumb:** Keep edits cleanly separated by level script and shared systems so Claude and Antigravity can work in parallel without merge conflicts.

### Track A — Claude (Sighișoara, Cellar, Criț, Viscri + Story Cards)
1. **Sighișoara (`scripts/levels/sighisoara.gd` & `scripts/levels/cellar.gd`):**
   - Match Piața Cetății & Strada Turnului Street View layout (cobblestone square/lanes, denser city activities).
   - Fix Clock Tower / Village Gate visibility & road leading to it (`00:00–00:14`, `06:08–07:44`).
   - Fix cellar door/tower overlap (`00:24–00:40`) and church/Sexton wall-phasing collision (`06:44`, `07:55–08:02`).
   - Fix cellar iron gate size, entrance placement, and key-unlock progression (`10:15–10:33`); replace red/cracked cellar floor and clashing bright-green jars/bookshelf (`01:05–01:19`, `09:28–09:39`).
   - Remove floating props (`05:34`), clothesline (`04:56`), random stair (`08:16`), and fix Romanian house *prispă* orientation (`04:34–04:42`).
2. **Criț (`scripts/levels/crit.gd`):**
   - Restore gate/opening on south road where stone wall blocks path (`12:35–12:46`).
   - Fix squished house proportions (`15:16–15:27`) and harsh white/black contrast (`13:28–13:32`) using Criț Street View palette (warm peach/ochre/pink/sky-blue with dark grey plinths) and tile-capped courtyard walls.
   - Clear wheel (`13:43`) and apple trees (`14:40`) from road; replace bare ribbon-pole spot (`16:02–16:38`) with orchard/forest edge; close old cemetery fence gaps (`17:50`).
   - Clarify Criț quest flow (`13:50–14:08`).
3. **Viscri (`scripts/levels/viscri.gd`):**
   - Apply Viscri Street View layout: wide unpaved dirt/gravel main street, broad grassy verges, drainage ditch/footbridges, ochre & sky-blue gable houses with rounded-arch courtyard gates, wooden benches, whitewashed tree trunks, stork nest, and Viscri Fortified Church outer buttressed stone wall.
4. **Story Cards & Illustrations (`sprites/Story/`):**
   - Fix Butcher card (remove floating beam & meat hook, `03:01–03:26`), red tint/blood spots (`03:41–03:55`), and add beard to chariot character (`32:08–32:15`).

### Track B — Antigravity (Shared Design System, Asset Generation, Saschiz, Șapartoc, Biertan, Apold, Combat/Traversal)
1. **Shared Design System & Asset Generation (`scripts/world/mats.gd`, `scripts/world/world_builder.gd`, `scripts/world/model_kit.gd`, `models/*.glb` via Meshy):**
   - Implement cohesive Saxon color palette (dark grey plinths, warm plaster tones, weathered terracotta roofs) and realistic grass/flower sprites.
   - Generate & integrate new Meshy `.glb` buildings (`house_town_2story`, `inn_2story`, `house_saxon_halfhip`, `portal_wall_arched`, `apold_church`) and roadside props (`culvert_bridge`, `street_bench_wood`, `fence_post_rail`, `stork_nest_pole`).
2. **Saschiz (`scripts/levels/saschiz.gd`):**
   - Match E60 Street View layout (wide verges, *Hanul Cetății*, wooden/masonry fences, Fortified Church green).
   - Clear road trees (`22:41`), fix floating cart (`22:45+`), open Saschiz fortress entrance (`29:47–29:55`), replace untextured boxes/ducks/stone blocks (`24:32–25:14`), fix road quest pointer (`22:33–22:48`), Azorel kids dialogue (`30:39–31:07`), and Saschiz music (`30:33`).
3. **Șapartoc & Biertan (`scripts/levels/sapartoc.gd`, `scripts/levels/biertanfort.gd`, `scripts/levels/hillchurch.gd`):**
   - Match Șapartoc dirt road + wooden post-and-rail fences + Reformed Church fork; enlarge Radu's Inn with outdoor garden seating (`33:05–33:27`); remove Ana's hammock from road (`37:11`).
   - Fix priest/villager scale (`36:00–36:10`) & waking priest sprite mismatch (`36:10–36:28`); update Ana & Șapartoc church illustration (`38:06–38:27`).
   - Align Biertan central square & DJ141B streetscape with Street View.
4. **Apold (`scripts/levels/apold.gd`):**
   - Switch to autumn setting (remove spring flowers, `38:59–39:38`), upgrade Apold church (`apold_church.glb` with timber *hourd* gallery), fix floating steps near Old Dumitru (`39:28–39:35`) & random cellar door (`39:57`).
   - Fix cemetery wave combat (`42:17–44:57`): restore food-table % UI, pause ghosts during notifications, spawn ghosts from cemetery only, clarify nightfall objective.
5. **Cross-Cutting Traversal, Combat & Audio (`scripts/actors/player.gd`, `scripts/levels/uriasi.gd`, etc.):**
   - Add **Shift-to-run** with stamina bar (`40:58–41:11`), speed up Matei following (`11:48`), fix Uriași boulder sprite & reduce camera shake (`28:07–28:39`), fix night barn-watch geese SFX & hide player (`08:31–08:52`), and profile `"On the road..."` transition hang (`29:22`).
