Status: proposed

# Proposal: Regional Villager Names for Unnamed NPCs

## 1. Goal
Provide gentle, historically and regionally authentic 16th-century Transylvanian Saxon and Romanian names for the NPCs who currently have generic titles ("A husband", "A wife", "The grandmother", "A farmer", "The baker", etc.) across `scripts/levels/*.gd` and their corresponding quest scripts.

## 2. Files and Functions Touched
- `scripts/levels/apold.gd`: `build()`, lines 44, 47 (`granny`, `baker`)
- `scripts/levels/biertanfort.gd`: `build()`, lines 124, 128, 150 (`spouse1`, `spouse2`, `servant`)
- `scripts/levels/cris.gd`: `build()`, lines 35, 39, 41, 45 (`oakman`, `goose1`, `goose2`, `farmer`, `towerkid`, `feaster`)
- `scripts/levels/crit.gd`: `_quest_things()`, line 30, line 78 (`mother`, `millwife`)
- `scripts/levels/malancrav.gd`: `build()`, lines 49, 52, 57 (`orchard`, `mbaker`, `mchild`, `mgranny`)

## 3. Name Allocations Grounded in 16th-Century Transylvanian Regional Canon
- **Apold:**
  - `granny`: "Frau Martha · Grandmother" (Saxon grandmother)
  - `baker`: "Lukas · Baker" (Saxon baker)
- **Biertan Fortified Church:**
  - `spouse1`: "Jürgen" (Saxon husband in marriage prison)
  - `spouse2`: "Liese" (Saxon wife in marriage prison)
  - `servant`: "Kaspar · House servant" (the baron's sleepwalking thrall servant)
- **Criș (Romanian village):**
  - `oakman`: "Nicu · Villager"
  - `goose1`: "Tanti Doina · Neighbour"
  - `goose2`: "Ioniță · Neighbour"
  - `farmer`: "Simion · Farmer"
  - `towerkid`: "Dorin"
  - `feaster`: "Costin · Villager"
- **Criț:**
  - `mother`: "Paraschiva · Floarea's mother"
  - `millwife`: "Katharina · Miller's wife"
- **Mălâncrav:**
  - `orchard`: "Jakob · Orchard keeper"
  - `mbaker`: "Frau Elsa · Baker"
  - `mchild`: "Stefan"
  - `mgranny`: "Bunica Anica"

## 4. Suggested Code Changes

### `scripts/levels/apold.gd`
```gdscript
// Replace line 44:
add_prop("npc", "granny", "Frau Martha · Grandmother", granny, "E   Speak with Frau Martha", Color("3a3430"))
// Replace line 47:
add_prop("npc", "baker", "Lukas · Baker", baker, "E   Speak with Lukas", Color("6a5a40"))
```

### `scripts/levels/biertanfort.gd`
```gdscript
// Replace lines 124-128:
spouse1 = add_prop("npc", "spouse1", "Jürgen", p1, "E   Speak with Jürgen", Color("4a5260"))
spouse2 = add_prop("npc", "spouse2", "Liese", p2, "E   Speak with Liese", Color("5a3240"))
// Replace line 150:
add_prop("npc", "servant", "Kaspar · Servant", tb + Vector2(200, 30), "E   Speak with Kaspar", Color("3a3a40"))
```

### `scripts/levels/cris.gd`
```gdscript
// In build():
add_prop("npc", "oakman", "Nicu", oak + Vector2(-60, 20), "E   Speak with Nicu", Color("5a4a35"))
add_prop("npc", "goose1", "Tanti Doina", gs + Vector2(-70, 20), "E   Speak with Doina", Color("4a5240"))
add_prop("npc", "farmer", "Simion", fm, "E   Speak with Simion", Color("5a5040"))
add_prop("npc", "towerkid", "Dorin", tw, "E   Speak with Dorin", Color("6a5540"))
```

### `scripts/levels/crit.gd`
```gdscript
// In _quest_things():
add_prop("npc", "mother", "Paraschiva · Floarea's mother", free_spot(house + Vector2(140, -60), 40.0), "E   Speak with Paraschiva", Color("5a3a30"))
```

### `scripts/levels/malancrav.gd`
```gdscript
// In build():
add_prop("npc", "orchard", "Jakob · Orchard keeper", orch, "E   Speak with Jakob", Color("504838"))
add_prop("npc", "mbaker", "Frau Elsa · Baker", mbake, "E   Speak with Frau Elsa", Color("6a5a40"))
add_prop("npc", "mchild", "Stefan", free_spot(orch + Vector2(180, 120), 30.0), "E   Speak with Stefan", Color("605040"))
add_prop("npc", "mgranny", "Bunica Anica", free_spot(Vector2(size.x * 0.45, size.y * 0.6), 40.0), "E   Speak with Bunica Anica", Color("3a3430"))
```

## 5. What Could Not Be Checked
- Dialogue greeting strings in matching quest files (`ap_quest.gd`, `bt_quest.gd`, `cs_quest.gd`, `crit_quest.gd`, `ml_quest.gd`) still use generic titles ("The grandmother", "Floarea's mother") in some `G.start_dialogue` headers; updating `display` on the prop does not break quest triggers (which key on `p.id`), but dialogue headers should also be harmonized when Claude reviews and applies.
