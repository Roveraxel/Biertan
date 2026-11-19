"""The cellar tower: a stout stone tower-house (the cellar's hatch is a separate model, cellar_hatch).
python3 tools/make_cellar_tower.py <outdir>.  Objects named wood_* become the timber surface in the game."""
import bpy, bmesh, sys, math
OUT = sys.argv[-1]
def new(): return bmesh.new()
def box(bm, x0, x1, y0, y1, z0, z1):
    r = bmesh.ops.create_cube(bm, size=1.0)
    for v in r["verts"]:
        v.co.x = x0 if v.co.x < 0 else x1; v.co.y = y0 if v.co.y < 0 else y1; v.co.z = z0 if v.co.z < 0 else z1
def hull(bm, pts):
    vs = [bm.verts.new(p) for p in pts]
    r = bmesh.ops.convex_hull(bm, input=vs)
    junk = [g for g in set(r["geom_interior"]) | set(r["geom_unused"]) if isinstance(g, bmesh.types.BMVert)]
    if junk: bmesh.ops.delete(bm, geom=junk, context="VERTS")
def obj(bm, name):
    me = bpy.data.meshes.new(name); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob); return ob

bpy.ops.wm.read_factory_settings(use_empty=True)
W, D, H = 5.2, 5.2, 4.6
x0, x1, y0, y1 = -W / 2, W / 2, -D / 2, D / 2     # front (camera side) is y0
st = new()
box(st, x0, x1, y0, y1, 0, H)                                           # the shaft
box(st, x0 - 0.12, x1 + 0.12, y0 - 0.12, y1 + 0.12, 0, 0.7)             # battered plinth
for z in (2.6,):                                                         # string course
    box(st, x0 - 0.1, x1 + 0.1, y0 - 0.1, y1 + 0.1, z, z + 0.18)
box(st, x0 - 0.22, x1 + 0.22, y0 - 0.22, y1 + 0.22, H - 0.3, H)         # corbelled top
box(st, x0 - 0.1, x1 + 0.1, y0 - 0.1, y1 + 0.1, H - 0.55, H - 0.3)
# hipped roof, steep, with a little ridge
ov = 0.55; rise = 3.0; ze = H
hull(st, [(x0 - ov, y0 - ov, ze - 0.25), (x1 + ov, y0 - ov, ze - 0.25), (x1 + ov, y1 + ov, ze - 0.25), (x0 - ov, y1 + ov, ze - 0.25),
          (x0 - ov, y0 - ov, ze - 0.45), (x1 + ov, y0 - ov, ze - 0.45), (x1 + ov, y1 + ov, ze - 0.45), (x0 - ov, y1 + ov, ze - 0.45),
          (-0.15, -0.15, ze + rise), (0.15, 0.15, ze + rise), (-0.15, 0.15, ze + rise), (0.15, -0.15, ze + rise)])
# arrow slits
for (cx, cz) in ((-1.7, 3.6), (1.7, 3.6), (0.0, 3.6)):
    box(st, cx - 0.09, cx + 0.09, y0 - 0.1, y0 + 0.02, cz - 0.4, cz + 0.4)
    box(st, cx - 0.2, cx + 0.2, y0 - 0.06, y0 + 0.02, cz + 0.4, cz + 0.5)
for sx in (x0, x1):                                                      # slits in the sides too
    for cy in (-1.0, 1.0):
        d = -1 if sx < 0 else 1
        box(st, sx + (-0.1 if d < 0 else -0.02), sx + (0.02 if d < 0 else 0.1), cy - 0.09, cy + 0.09, 3.2, 4.0)
# buttresses at the front corners
for sx in (x0, x1 - 0.4):
    box(st, sx - 0.1, sx + 0.5, y0 - 0.28, y0 + 0.02, 0, 1.7)
obj(st, "cellar_tower")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=f"{OUT}/cellar_tower.glb", export_format="GLB", use_selection=True, export_yup=True, export_apply=True, export_materials="NONE")
print("built cellar_tower")
