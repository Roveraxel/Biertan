# Muma Pădurii's Hollow — Environment Art Brief

## Existing layout

Source: `scripts/hollow_level.gd`. Compact boss arena, 1500×1400, centre around (750,680), spawn near (750,1130). Existing oak ring, hollow tree-house, boss, sisters and ritual positions must remain exactly aligned with gameplay code. Inspect the full script and related `hollow_tree.gd` before changing any art.

## Visual goals

- Ancient, enclosed forest clearing with oppressive old-growth oaks.
- Strong silhouette for the central hollow tree-house; roots should anchor into the earth and form a readable architectural mass.
- Ground should be darker and more organic toward the centre, with moss, roots and leaf litter.
- Distinct ritual/encounter locations should have subtle ground markings and restrained supernatural light.
- Tree canopy frames the arena; avoid hiding player, boss, projectiles or sisters.
- Preserve readable open combat space and dodge routes.

## Asset kit

Ancient oak trunks, exposed roots, hollow-tree façade/door, canopy masses, twisted branches, moss, roots, dead leaves, fungal clusters, ritual ground marks and subtle green/amber light accents.

## Technical constraints

This is a boss arena. Prioritise combat readability and projectile visibility. Decorative roots must not introduce unplanned collision. Keep the central arena footprint and all spawn/trigger positions unchanged.

## Acceptance

The arena feels claustrophobic and ancient while preserving clear boss combat readability and the current encounter layout.
