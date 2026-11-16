# Hollow Hills — Environment Art Brief

## Existing layout

Source: `scripts/hills_level.gd`. World size 3200×1700; main path runs west-east through (60,850), (500,760), (950,900), (1450,780), (1900,880), (2400,760), (2800,820), (3060,800). Tree copses occupy the slopes around (400,300), (500,1350), (1300,250), (1250,1400), (2000,300), (2200,1350), (2800,300). The Bear's Garden is centred at (2700,1420), surrounded by a thicket with a north-west opening.

Three Iele mushroom rings are centred at (900,480), (1700,1180) and (2350,420). Preserve standing stones, wayside cross, cave sign, sack, cave mouth, enemy ring homes and all exits/triggers.

## Visual goals

- Open upland meadow with rolling grass, scrub, exposed earth and low wind-shaped vegetation.
- Gentle terrain bands and shadows should imply undulating slopes without reducing navigation clarity.
- Keep tree copses visually distinct from the open meadow and preserve the path as the main navigation spine.
- Mushroom rings should feel unnaturally deliberate: pale mushrooms, trampled circular grass and subtle fungal colour variation.
- Standing stones should be weathered, lichen-covered and grounded with dark contact shadows.
- Bear's Garden should have a denser thorny perimeter, richer soil and readable wild-lettuce rows; keep the north-west entrance obvious.
- Cave entrance needs strong dark silhouette, layered rock lip and warm torch contrast.

## Asset kit

Meadow grass variants, scrub clumps, thistle/flower accents, low shrubs, small rocks, standing-stone variants, mushroom clusters, trampled ring ground decals, thorn thicket, wild lettuce, cave rock modules and cave-mouth shadow.

## Technical constraints

Do not move ring centres or enemy orbit homes. Keep the garden trigger and thicket opening intact. Tree trunk collision and y-sort anchors must remain accurate. The cave mouth and exit trigger must remain aligned.

## Acceptance

Open meadow, clear path, readable ritual rings, convincing standing stones and a visually distinct hidden garden. Existing encounter and quest logic remains unchanged.
