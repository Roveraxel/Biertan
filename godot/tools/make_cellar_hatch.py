"""A cellar hatch: low stone cheeks and back wall around two sloped, iron-strapped plank doors, with a flagged apron.
python3 tools/make_cellar_hatch.py <outdir>.  wood_* objects become timber in the game. Front (camera side) is -y."""
import bpy, bmesh, sys
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
W, D = 2.8, 2.4; Hf, Hb = 0.35, 1.25; ck = 0.36
x0, x1, y0, y1 = -W / 2, W / 2, -D / 2, D / 2
def zs(y):   # the slope of the doors, front low to back high
    return Hf + (Hb - Hf) * (y - y0) / (y1 - y0)
st = new()
box(st, x0 - 0.1, x1 + 0.1, y1 - 0.45, y1 + 0.05, 0, Hb + 0.12)          # back wall, capped
for sx0, sx1 in ((x0, x0 + ck), (x1 - ck, x1)):                           # cheeks: wedges following the slope
    hull(st, [(sx0, y0, 0), (sx1, y0, 0), (sx0, y1, 0), (sx1, y1, 0), (sx0, y0, Hf + 0.08), (sx1, y0, Hf + 0.08), (sx0, y1, Hb + 0.08), (sx1, y1, Hb + 0.08)])
box(st, x0 - 0.1, x1 + 0.1, y0 - 0.55, y0, 0, 0.12)                       # flagged apron
box(st, x0 - 0.05, x1 + 0.05, y0 - 0.12, y0 + 0.02, 0, Hf + 0.1)         # front sill
obj(st, "cellar_hatch")
wd = new(); ya, yb = y0 + 0.02, y1 - 0.45; t = 0.1
for xa, xb in ((x0 + ck + 0.02, -0.02), (0.02, x1 - ck - 0.02)):
    hull(wd, [(xa, ya, zs(ya)), (xb, ya, zs(ya)), (xa, yb, zs(yb)), (xb, yb, zs(yb)),
              (xa, ya, zs(ya) + t), (xb, ya, zs(ya) + t), (xa, yb, zs(yb) + t), (xb, yb, zs(yb) + t)])
    for f in (0.18, 0.5, 0.82):                                          # iron straps across the planks
        yy = ya + (yb - ya) * f; yy2 = yy + 0.12
        hull(wd, [(xa, yy, zs(yy) + t), (xb, yy, zs(yy) + t), (xa, yy2, zs(yy2) + t), (xb, yy2, zs(yy2) + t),
                  (xa, yy, zs(yy) + t + 0.035), (xb, yy, zs(yy) + t + 0.035), (xa, yy2, zs(yy2) + t + 0.035), (xb, yy2, zs(yy2) + t + 0.035)])
    xc = (xa + xb) / 2; yy = ya + 0.22                                    # a ring handle
    hull(wd, [(xc - 0.1, yy, zs(yy) + t), (xc + 0.1, yy, zs(yy) + t), (xc - 0.1, yy + 0.05, zs(yy + 0.05) + t), (xc + 0.1, yy + 0.05, zs(yy + 0.05) + t),
              (xc - 0.1, yy, zs(yy) + t + 0.08), (xc + 0.1, yy, zs(yy) + t + 0.08), (xc - 0.1, yy + 0.05, zs(yy + 0.05) + t + 0.08), (xc + 0.1, yy + 0.05, zs(yy + 0.05) + t + 0.08)])
obj(wd, "wood_door")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=f"{OUT}/cellar_hatch.glb", export_format="GLB", use_selection=True, export_yup=True, export_apply=True, export_materials="NONE")
print("built cellar_hatch")
