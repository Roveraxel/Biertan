# Wolf Forest — Environment Art Brief

## Existing layout and gameplay anchors

Source: `scripts/forest_level.gd`. World size 3400×1800; spawn near (160,900). A winding dirt path runs through points (80,900), (600,950), (1000,820), (1400,760), (1800,900), (2300,960), (2700,840), (3300,880). Keep a readable corridor around it; current tree placement avoids points within 175 units of the path and avoids glades.

Important glades: around (1150,480), (1550,480), (2000,700), (1300,1040), (2700,1080), plus hidden quest clearings at (560,260), (2950,260), (2200,1560), (420,1520), (1300,180), (2550,1380), (3200,1600). Preserve the shepherd hut at roughly (1480,420), hermit's spring near (470,1560), sign near (3150,840), torches/braziers and all enemy/event positions.

## Visual goals

- Build a layered old Transylvanian mixed forest: dark spruce/pine masses, broadleaf trunks, tangled roots, bracken, fern, fallen limbs and leaf litter.
- Establish depth through canopy silhouettes and ground shadows; retain visible ground around player/enemies.
- The path should feel worn, irregular and continuous, with soft earth shoulders, exposed roots and occasional embedded stones.
- Make each glade legible as a deliberate pocket of open ground, with distinct grass/soil texture and a sparse ring of plants.
- Add subtle forest-floor variety: moss patches, dead leaves, mushrooms, small rocks and damp soil.
- Keep quest clearings visually discoverable without adding new markers or changing quest logic.
- The hermit's spring should read as a cold, clear water source with wet stones, moss and restrained blue-green light.

## Asset kit

- Pine/spruce: at least 3 canopy silhouettes and 2 trunk/branch variants.
- Broadleaf: oak/beech canopy clusters, exposed-root trunk base and stump.
- Understory: fern, bracken, low shrub, thorn bush, tall grass and mushroom clusters.
- Ground: forest grass, dark moss, leaf litter, packed dirt, path edge and damp earth.
- Set dressing: fallen log, broken branch, stones, roots, old shepherd fence fragment, torn fleece/basket props.
- Spring kit: shallow water surface, rounded wet stones, moss and a subtle reflection/ripple overlay.

## Composition and rendering

- Preserve the current procedural tree distribution and deterministic seed initially; swap in improved visual assets before changing density.
- Avoid placing dense foliage over path points, glades, combat arenas or interaction targets.
- Use canopy overlays carefully; player/enemy silhouettes must remain readable under trees.
- Tree collision should correspond to trunk, not full canopy. Y-sort anchor belongs at trunk base.
- Vary scale/rotation modestly within a coherent perspective. Avoid obvious repeated identical clusters.
- Keep the path broad enough for combat movement and retain the existing event trigger corridors.

## Acceptance

Forest reads as a layered, old-growth woodland with a clear navigable trail and recognisable glades. Existing quests, enemies, lurker spawning, voice trap, exits and all object positions remain unchanged.
