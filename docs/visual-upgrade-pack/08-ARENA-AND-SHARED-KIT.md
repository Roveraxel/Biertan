# Arena and Shared Environment Asset Kit

## Arena

Inspect `scripts/arena_level.gd` and any boss-specific arena dependencies. Keep the arena composition, boss spawn, attack lanes, boundary collision and exit trigger intact. Use minimal, high-contrast set dressing: worn earth/stone, perimeter landmarks, broken stakes, sparse debris and controlled light pools. Avoid visual clutter behind boss telegraphs and projectiles.

## Shared modular production kit

Create reusable source assets with documented pixel dimensions, intended in-game world dimensions, anchor point, collision policy and palette:

- Ground tile families: grass, forest floor, meadow, packed dirt, path, cobble, flagstone, ash, scorched soil, cave floor, wet stone and quarry gravel.
- Edge/transition pieces: straight, inner/outer corner, T-junction, cross-junction, end-cap and irregular transition.
- Natural props: trees, stumps, roots, rocks, shrubs, ferns, bracken, mushrooms, flowers, fallen logs and reeds.
- Built props: wattle fence straight/corner/gate/broken; timber fence; stone wall; house wall/roof modules; tower; church; mine supports.
- Small props: haystack, trough, firewood, barrel, basket, sack, cart, well, signpost, cross, gravestone, brazier, torch, candle, crystal and ore.
- Shadow/lighting: soft contact shadows, tree canopy shadows, ambient occlusion accents, puddle reflections and region-specific overlays.

## Asset integration standards

- Follow the existing project import and texture-cache conventions.
- Prefer atlases or reusable small textures where practical.
- Keep original editable source (SVG or other chosen source format) alongside imported output.
- Establish a common palette sheet and scale reference before bulk asset generation.
- Use texture filtering and pixel snapping consistently with the existing project settings.
- Avoid per-instance unique textures where a shared atlas/material can be used.
- Decorative assets must not silently change collision. Define collision explicitly.
- Test all assets in the actual game camera, at native resolution and in motion.

## Performance and QA

Measure draw calls, texture memory, frame time and web export size before/after. Use batching/reuse and limit transparent overdraw from large foliage layers. Test low-end integrated graphics and browser build. Run headless autotest and manually verify every level entrance/exit and combat space.
