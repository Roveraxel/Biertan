Status: proposed

# T15: Blender sprite render script

**Deliverable:** `tools/render_sprite.py` (Blender Python). No `.gd`, scene or asset file is touched, and no 3D model goes into the game build. Only PNG files come out.

## Not tested
Blender is not installed on the machine where this was written (`/Applications` has no Blender). The file passes a Python syntax check (`py_compile`), but it has **never run inside Blender**. Treat the first run as the test. Expected trouble spots, most likely first:
1. The render engine name. It tries `BLENDER_EEVEE_NEXT` (Blender 4.2+), then `BLENDER_EEVEE`, then `BLENDER_WORKBENCH`.
2. `bpy.ops.import_scene.gltf` and the model's facing. glTF front is +Z, which becomes -Y in Blender, so I assume the front looks south. If a Meshy model comes out facing another way, pass `--front east` (or whichever) instead of editing the code.
3. The sun-light energies (3.2 and 1.0) may look too bright or too flat.

## Run it
```
blender --background --python tools/render_sprite.py -- \
    --glb models/hill_church.glb --name church_bell --out tools/render_out
```
Output goes to `tools/render_out/church_bell/rotation_<dir>.png` for the 8 directions (south, south-west, west, north-west, north, north-east, east, south-east). It never writes into `sprites/Pixel/` by itself; Claude copies the files after checking them.

## What it does
- Imports the GLB, puts the model's feet on z=0, centres it, and uses one pivot that is rotated 0/45/.../315 degrees for the 8 views. The camera and lights never move, so shading is the same for every direction.
- Orthographic camera at 50 degrees elevation (`--elev`, 90 is straight down). The frame is sized once from the bounding sphere, so all 8 views have the same scale and nothing is cropped.
- Fixed lights: warm sun key, cool sun fill, grey ambient. The same for every prop.
- Transparent background, no anti-aliasing (`filter_size 0`), alpha cut at 50%.
- Pixel look: renders at `size / pixel` (default 64), reduces to `--colors` (default 24) with a deterministic k-means (fixed seed), then enlarges with nearest-neighbour to 128x128.

## Decisions for Claude
- **File names.** The task board says `rot_<dir>.png`, but the files in `sprites/Pixel/<name>/` are named `rotation_<dir>.png` (e.g. `sprites/Pixel/earth_dog/rotation_south.png`). The default is `rotation_`. `--prefix rot_` changes it.
- **Sprite size.** The task says 128x128, but existing sprites are small: `earth_dog` rotation is 56x56 and `wheat_shock.png` is 50x62. Props at 128 px will look bigger or sharper than the rest unless the level scales them down. `--size 56 --pixel 1` gives the existing size. Check the scale in a level screenshot first.
- **Palette.** `--colors` reduces per sprite. It does not use one shared palette for the whole game. A shared palette needs a palette image from Alex or Claude (future `--palette` option).
- **Church bell.** There is no bell model. `models/hill_church.glb` is the whole church. A bell needs its own Meshy GLB first. Until then, test with a single pew or the small `models/chapel.glb`.
- **Cast consistency (open item 4).** Not started. Once one prop works, running the script over characters with the same `--elev`, `--size` and lights would give consistent size and shading.
