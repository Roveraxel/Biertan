"""The cellar tower: a stout stone tower-house with the cellar's arched doorway and plank doors built in.
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
# arched doorway surround on the front: heavy stone jambs and a voussoir ring
dw, dh, pro, bar = 1.7, 2.25, 0.3, 0.38
box(st, -dw / 2 - bar, -dw / 2, y0 - pro, y0 + 0.02, 0, dh)
box(st, dw / 2, dw / 2 + bar, y0 - pro, y0 + 0.02, 0, dh)
n = 9; r = dw / 2
for i in range(n):
    a0 = math.pi * i / n; a1 = math.pi * (i + 1) / n; pts = []
    for rad in (r, r + bar):
        for a in (a0, a1):
            for y in (y0 - pro, y0 + 0.02): pts.append((-math.cos(a) * rad, y, dh + math.sin(a) * rad))
    hull(st, pts)
# a stone hood over it, and arrow slits
box(st, -dw / 2 - bar - 0.25, dw / 2 + bar + 0.25, y0 - pro - 0.12, y0 + 0.02, dh + r + bar + 0.02, dh + r + bar + 0.26)
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
# the doors, in timber: two plank leaves under an arched head, iron-strapped, set a hand proud of the wall
wd = new()
y_in, y_out = y0 - 0.08, y0 + 0.01
for sgn in (-1, 1):
    xa = 0.02 if sgn > 0 else -dw / 2
    xb = dw / 2 if sgn > 0 else -0.02
    box(wd, xa, xb, y_in, y_out, 0.0, dh)
n = 14
for i in range(n):          # the arched head of the leaves
    a0 = math.pi * i / n; a1 = math.pi * (i + 1) / n
    hull(wd, [(-math.cos(a0) * r, y_in, dh + math.sin(a0) * r), (-math.cos(a1) * r, y_in, dh + math.sin(a1) * r),
              (-math.cos(a0) * r, y_out, dh + math.sin(a0) * r), (-math.cos(a1) * r, y_out, dh + math.sin(a1) * r),
              (-math.cos(a0) * r * 0.0, y_in, dh), (0.0, y_out, dh)])
for z in (0.5, 1.15, 1.8):  # iron straps (proud of the planks)
    box(wd, -dw / 2 + 0.03, dw / 2 - 0.03, y_in - 0.035, y_in, z, z + 0.11)
box(wd, -0.07, 0.07, y_in - 0.05, y_in, 0.0, dh + 0.1)                   # the meeting stile
for sx in (-0.3, 0.3): box(wd, sx - 0.05, sx + 0.05, y_in - 0.07, y_in, 0.95, 1.2)   # ring handles
box(wd, -dw / 2 - bar, dw / 2 + bar, y0 - pro - 0.06, y0 - pro + 0.0, 0.0, 0.0001) if False else None
obj(wd, "wood_door")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=f"{OUT}/cellar_tower.glb", export_format="GLB", use_selection=True, export_yup=True, export_apply=True, export_materials="NONE")
print("built cellar_tower")
