# Environment Visual Upgrade — Master Plan

This document coordinates the environment-art pass across the current Godot source branch. It is a Claude implementation handoff. Do not modify production files as part of this documentation commit.

## Source inspection baseline

Inspected branch: `godot-level1-slice`. The source currently contains these environment classes: `HubLevel`, `ForestLevel`, `HillsLevel`, `HollowLevel`, `CavesLevel`, `GorgeLevel`, `VineyardLevel`, `MosnaLevel`, `RichisLevel`, `BiertanLevel`, `WallsLevel`, `ChurchLevel`, and `ArenaLevel`. Shared rendering and environment primitives live in `scripts/level.gd`, `scripts/tree2d.gd`, `scripts/block.gd`, `scripts/prop.gd`, `scripts/g.gd`; tile sources currently include `assets/tiles/grass.svg` and `assets/tiles/cobble.svg`.

The currently inspected source branch does not expose the Stână scene described in the Pages build and conversation. Claude must reconcile the source commit with the deployed Pages build before implementation and locate the Stână source. Do not infer that an exported Pages tree is the editable Godot project.

## Shared art direction

- Maintain the existing top-down/3/4 presentation, world scale, pixel-art cluster language and established character sprite style.
- Environment art should have controlled texture density, strong silhouettes, consistent light direction, grounded contact shadows and clear walkable corridors.
- Use region-specific palettes and materials; reuse shape language and modular construction.
- Retain existing player, dog, NPC, enemy and boss sprites unchanged.
- Keep procedural placement seeded and deterministic where current code uses seeded RNG.
- Avoid large monolithic background images. Build reusable tiles, modular props, foliage clusters, wall/fence segments and overlays.
- Preserve collision footprints, y-sort conventions, interactable positions, trigger areas, enemy spawn points, exits, quest landmarks and camera framing.

## Implementation order

1. **Stână** — first visual benchmark; use the original screenshot and references in `README.md`.
2. **Shared environment kit** — grass/soil/cobble variation, path edges, stones, ground clutter, shadows, fences, walls, trees, shrubs, debris, timber and lighting props.
3. **Wolf Forest** — tree canopy/understory and path readability.
4. **Hollow Hills** — meadow variation, standing stones, mushroom rings and bear garden.
5. **Village hubs** — Saschiz, Richiș and Moșna; shared Saxon vernacular with local distinctions.
6. **Burnt Vineyards and Gorge** — dry vines, quarry stone, water/rock transitions.
7. **Salt Caves and Muma's Hollow** — distinct subterranean palettes, rock formations, crystals and old-oak architecture.
8. **Biertan, Three Walls and Church** — fortified stonework, siege damage, blood wards and ecclesiastical interior.
9. **Arena / boss spaces** — readability-first set dressing and controlled VFX contrast.

## Required technical audit before asset production

- Identify exact Pages deployment commit and the source commit that generated it.
- Inspect `project.godot`, all level scripts, shared draw methods and asset loading/cache conventions.
- Inspect `Tree2D`, `Block`, `Prop`, `Brazier`, `Gate`, and relevant collision code.
- Record world-units-per-pixel, sprite dimensions, tile scale, y-sort anchors and occlusion order.
- Record all collision rectangles and triggers before moving or resizing any environment object.
- Check desktop and web export texture limits, memory and draw-call impact.
- Keep changes on a dedicated feature branch and preserve a clean rollback point.

## Shared asset families

- Ground: grass base, grass colour variants, worn dirt, packed earth, mud, gravel, cobble, flagstone, cave floor, ash, scorched earth, blood-stained stone, moss and snowless highland scrub.
- Transitions: path edge, grass-to-dirt, dirt-to-stone, wet-to-dry, ash-to-grass, cave-to-outdoor and wall-footing transitions.
- Natural: deciduous trees, pines, stumps, roots, shrubs, bracken, fern, tall grass, mushrooms, reeds, dead vines, rocks, boulders and fallen branches.
- Built: wattle fences, timber fences, stone walls, Saxon house modules, roof modules, ruined walls, gates, towers, church details, pews, altar and mine supports.
- Props: barrels, sacks, baskets, troughs, hay, firewood, tools, carts, wells, crosses, signposts, braziers, torches, candles, gravestones, salt crystals and ore.
- Rendering support: contact-shadow decals, canopy overlays, ambient occlusion accents, wetness/ash overlays and region-specific light masks.

## Quality gates

- No character sprite redesign or replacement.
- No quest, dialogue, combat, enemy, progression, camera or HUD changes.
- No object moved without checking gameplay coordinates and collision.
- New environment elements must have documented source/licence and editable source files.
- Every new asset must have a clear intended scale, anchor, collision policy and reuse category.
- Headless test: `godot --headless --path . -- --autotest`.
- Provide before/after screenshots from identical camera positions and a complete changed-file list.
- Verify web export after Godot validation.

## Claude deliverables

1. Source/deployment branch mapping and current Stână source location.
2. Existing asset inventory with reuse/replace/add recommendations.
3. Stână prototype using modular production assets.
4. Per-level environment pass following the level briefs in this folder.
5. Test results, screenshots, asset provenance and rollback instructions.
