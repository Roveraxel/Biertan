# Salt Caves — Environment Art Brief

## Existing layout

Source: `scripts/caves_level.gd`. Inspect the complete current script and record its exact world bounds, cave chambers, connecting passages, crystals, water, enemies, boss and exit triggers before editing. Preserve all gameplay coordinates and collision geometry.

## Visual goals

- Strong underground identity with layered limestone, damp rock, salt deposits and deep shadow.
- Use distinct floor materials for dry cave floor, wet patches, shallow water, loose scree and salt-encrusted ground.
- Salt crystals should have readable faceted silhouettes and restrained cool emission; avoid washing out the player or enemy silhouettes.
- Cave walls should show depth through layered rock ledges, stalactites/stalagmites and occasional timber supports where structurally plausible.
- Create clear visual routes through chambers and tunnels; use lighting pools to guide the eye.

## Asset kit

Limestone wall segments, irregular rock clusters, stalactite/stalagmite modules, salt crystal clusters in multiple sizes, mineral seams, damp floor decals, puddle/water overlays, timber mine supports, broken cart/ore props, cave debris and cool light masks.

## Rendering and gameplay

- Keep wall collision shapes authoritative; decorative rock silhouettes must not create invisible blockers.
- Preserve crystal interaction points and respawn/regrow behaviour.
- Use low-frequency texture variation to avoid noisy floors.
- Keep web export texture sizes modest and reuse atlas/tiles where practical.

## Acceptance

The cave reads as a coherent underground space with strong depth, distinct salt formations and clear combat lanes. Existing boss, loot, crystal and exit behaviour remains identical.
