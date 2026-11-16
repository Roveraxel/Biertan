"""Render a GLB (Meshy model) to 8 pixel-art direction sprites for Biertan.

Run on the Mac, in Blender's background mode (Blender 3.6 or newer):

    blender --background --python tools/render_sprite.py -- \
        --glb models/hill_church.glb --name church_bell --out tools/render_out

Output: <out>/<name>/rotation_<dir>.png for the 8 directions
south, south-west, west, north-west, north, north-east, east, south-east.
Same file names as sprites/Pixel/<name>/. Transparent background,
fixed camera, fixed lights, same framing for all 8 views.

Options (after the lone "--"):
    --glb PATH      input model (required)
    --name NAME     output folder name (default: file name of the GLB)
    --out DIR       output root (default: tools/render_out next to this script's repo)
    --size N        final square size in px (default 128)
    --pixel N       one art pixel is N x N output pixels (default 2; 1 = no chunky pixels)
    --colors N      palette size after reduction (default 24)
    --elev DEG      camera elevation above the ground (default 50; 90 = straight down)
    --prefix TEXT   file name prefix (default "rotation_"; the task board says rot_)
    --front DIR     direction the model's front faces after import (default south)

Notes:
  * No 3D model is added to the game: only the PNG files leave this script.
  * Not tested in Blender by the author (Blender is not installed on the
    machine where this was written). See .ai/proposals/blender_sprite_render.md.
"""
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

# direction -> yaw in degrees (rotation about +Z). With glTF import the model's
# front looks to -Y, which is "south" (north = +Y, east = +X).
DIRS = {
    "south": 0.0,
    "south-east": 45.0,
    "east": 90.0,
    "north-east": 135.0,
    "north": 180.0,
    "north-west": 225.0,
    "west": 270.0,
    "south-west": 315.0,
}


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    opts = {
        "glb": None, "name": None, "out": None, "size": 128, "pixel": 2,
        "colors": 24, "elev": 50.0, "prefix": "rotation_", "front": "south",
        "tint": None,
    }
    i = 0
    while i < len(argv):
        key = argv[i].lstrip("-")
        if key not in opts or i + 1 >= len(argv):
            raise SystemExit("unknown or incomplete option: " + argv[i])
        val = argv[i + 1]
        if key in ("size", "pixel", "colors"):
            val = int(val)
        elif key == "elev":
            val = float(val)
        opts[key] = val
        i += 2
    if not opts["glb"]:
        raise SystemExit("--glb PATH is required")
    if opts["front"] not in DIRS:
        raise SystemExit("--front must be one of " + ", ".join(DIRS))
    if opts["size"] % opts["pixel"] != 0:
        raise SystemExit("--size must be a multiple of --pixel")
    return opts


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_model(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.data.objects if o not in before]


def mesh_bounds(objs):
    """World-space bounding box of all mesh objects."""
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    found = False
    for o in objs:
        if o.type != "MESH":
            continue
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
            found = True
    if not found:
        raise SystemExit("no mesh found in the GLB")
    return lo, hi


def build_pivot(objs, front):
    """Put the model on a pivot at the origin: feet on z=0, centred in x/y,
    rotated so its front faces `front` for yaw 0."""
    bpy.context.view_layer.update()
    lo, hi = mesh_bounds(objs)
    centre = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    pivot = bpy.data.objects.new("pivot", None)
    bpy.context.scene.collection.objects.link(pivot)
    roots = [o for o in objs if o.parent is None]
    for o in roots:
        o.parent = pivot
        o.location = o.location - centre
    # --front tells where the model looks after import; undo that offset
    pivot.rotation_euler = (0, 0, math.radians(-DIRS[front]))
    bpy.context.view_layer.update()
    lo, hi = mesh_bounds(objs)
    size = hi - lo
    # radius of the bounding sphere around the vertical axis and the height
    radius = math.sqrt((size.x / 2) ** 2 + (size.y / 2) ** 2)
    return pivot, radius, size.z


def setup_camera(radius, height, elev_deg):
    """Orthographic camera, same distance and scale for every direction."""
    elev = math.radians(elev_deg)
    target = Vector((0, 0, height / 2))
    dist = 10.0 * max(radius, height, 0.01)
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    # fit the bounding sphere of the whole model in the frame, with 6% margin
    reach = math.sqrt(radius ** 2 + (height / 2) ** 2)
    cam_data.ortho_scale = 2.0 * reach * 1.06
    cam_data.clip_start = 0.01
    cam_data.clip_end = dist * 4
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    # camera sits to the south (-Y) and above, looking at the model
    cam.location = target + Vector((0, -math.cos(elev), math.sin(elev))) * dist
    look = (target - cam.location).to_track_quat("-Z", "Y")
    cam.rotation_euler = look.to_euler()
    bpy.context.scene.camera = cam
    return cam


def setup_lights():
    """Same lights for every prop: a warm key, a cool fill, soft ambient."""
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.55, 0.58, 0.65, 1.0)
    bg.inputs[1].default_value = 0.6
    bpy.context.scene.world = world

    def sun(name, energy, color, rot):
        d = bpy.data.lights.new(name, "SUN")
        d.energy = energy
        d.color = color
        o = bpy.data.objects.new(name, d)
        o.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.context.scene.collection.objects.link(o)

    sun("key", 3.2, (1.0, 0.92, 0.80), (50, 0, -35))
    sun("fill", 1.0, (0.70, 0.80, 1.0), (60, 0, 145))


def setup_render(px):
    sc = bpy.context.scene
    engines = [e.identifier for e in
               bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    for pick in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        if pick in engines:
            sc.render.engine = pick
            break
    sc.render.resolution_x = px
    sc.render.resolution_y = px
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.filter_size = 0.0          # no soft edges: pixel art
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    if sc.render.engine == "BLENDER_WORKBENCH":
        sc.display.shading.light = "STUDIO"
        sc.display.shading.color_type = "TEXTURE"


def kmeans_palette(rgb, k, iters=10):
    """Deterministic k-means. rgb is an (n, 3) float array."""
    rng = np.random.default_rng(1)
    n = len(rgb)
    k = max(1, min(k, n))
    sample = rgb if n <= 20000 else rgb[rng.choice(n, 20000, replace=False)]
    centres = sample[rng.choice(len(sample), k, replace=False)].copy()
    for _ in range(iters):
        d = ((sample[:, None, :] - centres[None, :, :]) ** 2).sum(axis=2)
        lab = d.argmin(axis=1)
        for c in range(k):
            m = sample[lab == c]
            if len(m):
                centres[c] = m.mean(axis=0)
    return centres


def process(path_in, path_out, small, final, colors, name):
    """Quantize to a small palette, hard alpha, nearest-neighbour upscale."""
    img = bpy.data.images.load(path_in)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    alpha = px[:, :, 3] >= 0.5
    rgb = px[:, :, :3].copy()
    opaque = rgb[alpha]
    if len(opaque):
        pal = kmeans_palette(opaque, colors)
        flat = rgb.reshape(-1, 3)
        d = ((flat[:, None, :] - pal[None, :, :]) ** 2).sum(axis=2)
        rgb = pal[d.argmin(axis=1)].reshape(h, w, 3)
    out = np.zeros((h, w, 4), dtype=np.float32)
    out[:, :, :3] = rgb
    out[:, :, 3] = alpha.astype(np.float32)
    out[~alpha] = 0.0
    scale = final // w
    if scale > 1:
        out = np.repeat(np.repeat(out, scale, axis=0), scale, axis=1)
    fh, fw = out.shape[:2]
    res = bpy.data.images.new(name, fw, fh, alpha=True)
    res.pixels.foreach_set(out.ravel())
    res.filepath_raw = path_out
    res.file_format = "PNG"
    res.save()
    bpy.data.images.remove(res)


def apply_procedural_tint(objs, tint_str):
    """Apply a procedural noise-varied matte material to untextured preview meshes."""
    r, g, b = (float(x) for x in tint_str.split(","))
    mat = bpy.data.materials.new("proc_tint")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.88
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 14.0
    noise.inputs["Detail"].default_value = 4.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.25
    ramp.color_ramp.elements[0].color = (r * 0.65, g * 0.65, b * 0.65, 1.0)
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = (min(1.0, r * 1.15), min(1.0, g * 1.15), min(1.0, b * 1.15), 1.0)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    for o in objs:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(mat)


def main():
    o = parse_args()
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    name = o["name"] or os.path.splitext(os.path.basename(o["glb"]))[0]
    out_root = o["out"] or os.path.join(repo, "tools", "render_out")
    glb = o["glb"] if os.path.isabs(o["glb"]) else os.path.join(repo, o["glb"])
    out_dir = os.path.join(out_root, name)
    os.makedirs(out_dir, exist_ok=True)
    tmp_dir = os.path.join(out_dir, "_tmp")
    os.makedirs(tmp_dir, exist_ok=True)

    reset_scene()
    objs = import_model(glb)
    if o["tint"]:
        apply_procedural_tint(objs, o["tint"])
    pivot, radius, height = build_pivot(objs, o["front"])
    setup_camera(radius, height, o["elev"])
    setup_lights()
    small = o["size"] // o["pixel"]
    setup_render(small)

    for dname, yaw in DIRS.items():
        pivot.rotation_euler = (0, 0, math.radians(yaw - DIRS[o["front"]]))
        bpy.context.view_layer.update()
        tmp = os.path.join(tmp_dir, dname + ".png")
        bpy.context.scene.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        final = os.path.join(out_dir, o["prefix"] + dname + ".png")
        process(tmp, final, small, o["size"], o["colors"], name + "_" + dname)
        os.remove(tmp)
        print("wrote", final)
    os.rmdir(tmp_dir)


if __name__ == "__main__":
    main()
