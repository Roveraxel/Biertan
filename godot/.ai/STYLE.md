# STYLE: the Biertan design system

One look for the whole game. Read this with ARCHITECTURE.md before adding or changing any art, model, light, texture or UI. Values below are taken from the code as of 2026-11-20; when you change a value in code, change it here too.

## 1. The look in one paragraph
A dark, gritty, damp Transylvanian autumn (1521). Pixel-art characters stand in a 3D world seen from a fixed top-down camera (Graveyard Keeper feel, Yaga mood). Villages are colourful Saxon plaster houses under dark tile roofs; the wilds and underground are muted and low in saturation. Story cards use Romanian folk ink art. Everything draws from Romanian folklore, never pop-culture versions.

## 2. Camera and scale
- Fixed camera, FOV 34, distance 26 m. No rotation keys (tried and rejected).
- One level pixel = 0.02 m (Fx.S), so 1 m = 50 level px.
- Hunter stands 1.25 m tall (PixelFigure.height). Houses 3-4 m to the eave, roof rise = min(width, depth) x 0.95, max 3.8 m. Towers 7 m or more. Doors about 2 m, hatches 1.2-1.7 m.
- Things the player walks behind fade (cutaways); every model registers with `level.cutaways`.

## 3. Characters (pixel art)
- Pixel art from PixelLab, 8 directions (south, south-west, west, north-west, north, north-east, east, south-east) as `sprites/Pixel/<name>/rotation_<dir>.png` plus `walk_<dir>_<n>.png`.
- Canvas sizes: humans and most creatures 64x64 (55 of 80 sprites). Small animals 48-56, large 80-128 (bear, boss, balaur). Pick the size class, do not invent new ones.
- Dark, gritty, readable at 1.25 m on screen. No realistic or painted cut-outs, no stylised low-poly, no voxels, no realistic Mixamo figures (all rejected).
- Outlines dark, 1 px, no anti-aliasing; limited palette per character (about 12-16 colours); skin and cloth colours from sections 5.
- After any edit check for transparent holes (the dog turned red from gaps) and for the sprite's foot gap (PixelFigure measures it).
- Folk costume cues for Saxons and Romanians: embroidered white shirts, red and black accents.

## 4. Models (Blender, GLB via ModelKit)
- Author in Blender axes: x long, y depth with front = -y, z up. Export glTF +Y up, no materials.
- ModelKit sorts faces into surfaces by slope: 0 roof, 1 wall, 2 timber (objects named `wood_*`). Textures are applied in metres, so never bake textures into models. Winding must be consistent; the kit emits clockwise triangles for Godot.
- Nominal texture size by name: tower 7 m, house 11 m, barn 13 m, hatch 3 m; church 26, basilica 28, chapel 12, orthodox 14, reformed 16.
- Minimum detail for a building: plinth or battered base, string course, real roof with ridge and eaves, chimney, door with frame, windows with frames or shutters, one prop (flower box, bench, woodpile). Houses must not look like boxes.
- Meshy realistic outputs look wrong next to the houses (rejected). Models are built in Blender to match the existing houses.
- Models cast no shadow themselves; a plain box casts the shadow (avoids flicker). Keep triangle counts web-safe.
- House families: house_saxon, house_big, house_ro (with prispa), barn, cellar_tower + cellar_hatch (cellar door is a separate hatch, not built into a wall), church models, gate_tower, guild_tower, clocktower.

## 5. Colour
- Saxon plaster (Mats.SAXON): ochre (0.97,0.70,0.32), blue (0.42,0.62,0.90), sage (0.52,0.74,0.42), rose (0.90,0.50,0.48), yellow (1.00,0.86,0.36), teal (0.40,0.78,0.74), lilac (0.74,0.60,0.86), cream (0.96,0.93,0.85). Each house keeps its colour by position.
- Shutters (Mats.SHUTTERS): blue (0.16,0.36,0.62), red (0.55,0.14,0.12), green (0.20,0.42,0.24), teal (0.12,0.45,0.48), brown (0.36,0.24,0.14).
- Romanian houses: mostly lime-wash white, some old blue, a few bare timber; roofs silvered shingle or red tile.
- Casa Vlad Dracul: ochre, painted as now.
- Roofs: dark red-brown tile (px_roof, px_roof2). Roofs must never go black; check lighting after any model change.
- Stone: grey (px_stone); tower and hatch stone tinted lighter (about 1.3) to match the garden walls.
- Underground and caves: desaturated grey-brown. No saturated orange or red floors or walls (it strains the eyes). Torch colour is mixed 60% toward soft warm white (0.96,0.90,0.82) in underground levels.

## 6. Light
- Village dusk (px): cold grey light, moon (0.66,0.70,0.78) energy 1.9, shadow 0.45, sky (0.50,0.53,0.60), haze density 0.026, fog (0.16,0.18,0.20).
- Night: thin blue moon (0.42,0.52,0.95), black haze (0.035,0.045,0.08), energy up so shapes still read.
- Day: low warm sun (1.0,0.9,0.72), long soft shadows, haze burnt off.
- Sacristy/hall church: candlelight (0.80,0.66,0.52), energy 0.8.
- Underground (cellar, crypt, caves): moon (0.82,0.76,0.68) energy 0.7, sky (0.36,0.33,0.30), fog density 0.035; pools of lamp light, black beyond the map; wall tops black.
- Torches: default (1,0.86,0.68), energy 0.95; fire (orange) only for open flames, kept small.

## 7. Materials and textures
- Pixel textures `px_*` (brick, cobble, flag, grass, gravel, meadow, mud, planks, plaster0-6, roof, roof2, salt, shingle, stone) with NEAREST filtering. Tile sizes in metres via Mats.mat(name, tile, tint, smooth).
- Ground in villages is meadow with grass tufts and wildflowers; roads cobble; yards fenced with stone walls capped with tile, which run on to meet the house or tower.
- Underground textures from tools/make_under_tex.py (neutral greys, light mortar).

## 8. Props and decor
- Sizes are in metres in `scripts/actors/decor.gd` SIZES (pumpkins 0.85, cabbages 0.85, wattle fence 0.95, apple tree 1.9, shed 1.45, barrel about 0.9 ...). Add the new prop to SIZES in the same change.
- Props that mark quests (notice board, guild sign, hay_eyes, jar shelf, pallet table, iron grate) keep to the same pixel-art sprite style as decor.
- Trees are 3D clumps in muted greens with a few autumn reds; more variation and branches wanted, within web budget.

## 9. UI
- Background panels near black (0.02,0.02,0.03) at 0.6-0.9 alpha; dialogue boxes (0.03,0.03,0.05); text warm amber (0.85,0.74,0.50); health bar red; hurt flash red (0.7,0.05,0.05); poison/dread purple (0.3,0.1,0.4).
- Prompts like "E  Speak to Azorel" bottom centre in amber, quest line top left, hints bottom left.
- Keep text readable at 720p.

## 10. Story art
- Romanian folk ink illustration: black, red and cream, folk costume, embroidery motifs (reference: xantipaillustration). The hunter is drawn the same way on every card. Hand-painted Meshy art is only used if it matches this.
- Narration: Lorena as the warm storyteller (voice "Romania"), fondly mocking the hunter. The hunter has short spoken reactions only, no voiced dialogue.

## 11. Audio
- Romanian folk music in the vein of Surorile Osoianu, not generic medieval. Short grunts and combat reactions for the hunter.

## 12. Before you add anything (checklist)
1. Does it fit sections 2-9 (scale, palette, texture, light)? Name the nearest existing asset and match it.
2. Does it still look right at night, in dusk and in the day lighting?
3. Does it read next to the neighbouring houses and sprites (not too realistic, not too flat)?
4. Add it to this file if it creates a new rule, and note it in HANDOFF.md.
5. Check for black or transparent faces, bad winding, floating props and doors that cannot be reached.
