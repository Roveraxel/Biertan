"""Builds the village house models (geometry only; the game textures them): python3 tools/make_houses.py <outdir>
Blender axes: x long side, y depth (front/camera side is -y), z up.  Exported glTF: +y up, front +z."""
import bpy, bmesh, sys, math
from mathutils import Vector

OUT = sys.argv[-1]

def new():
    bm = bmesh.new()
    return bm

def box(bm, x0, x1, y0, y1, z0, z1):
    r = bmesh.ops.create_cube(bm, size=1.0)
    for v in r["verts"]:
        v.co.x = x0 if v.co.x < 0 else x1
        v.co.y = y0 if v.co.y < 0 else y1
        v.co.z = z0 if v.co.z < 0 else z1

def hull(bm, pts):
    vs = [bm.verts.new(p) for p in pts]
    r = bmesh.ops.convex_hull(bm, input=vs)
    junk = [g for g in set(r["geom_interior"]) | set(r["geom_unused"]) if isinstance(g, bmesh.types.BMVert)]
    if junk: bmesh.ops.delete(bm, geom=junk, context="VERTS")

def gable(bm, x0, x1, y0, y1, ze, rise, ox=0.45, oy=0.55, t=0.18):
    """Gable roof along x: eaves at height ze over y0..y1, ridge `rise` above."""
    ym = (y0 + y1) / 2.0
    half = (y1 - y0) / 2.0
    s = rise / half
    pts = []
    for x in (x0 - ox, x1 + ox):
        pts += [(x, y0 - oy, ze - oy * s), (x, y0 - oy, ze - oy * s - t), (x, ym, ze + rise), (x, ym, ze + rise - t * 1.2),
                (x, y1 + oy, ze - oy * s), (x, y1 + oy, ze - oy * s - t)]
    hull(bm, pts)

def hip(bm, x0, x1, y0, y1, ze, rise, ridge_in, ov=0.7, t=0.2):
    """Hipped roof: ridge shortened by ridge_in at both ends."""
    ym = (y0 + y1) / 2.0
    s = rise / ((y1 - y0) / 2.0)
    ze2 = ze - ov * s
    pts = []
    for (x, y) in ((x0 - ov, y0 - ov), (x1 + ov, y0 - ov), (x1 + ov, y1 + ov), (x0 - ov, y1 + ov)):
        pts += [(x, y, ze2), (x, y, ze2 - t)]
    pts += [(x0 + ridge_in, ym, ze + rise), (x1 - ridge_in, ym, ze + rise)]
    hull(bm, pts)

def window(bm, cx, cz, w, h, yf, d=-1, bar=0.11, pro=0.1, sill=True, shutters=False):
    """A framed window on a wall at y=yf; d=-1 is the front (-y) face."""
    def b(x0, x1, z0, z1, p):
        y0, y1 = (yf - p, yf + 0.02) if d < 0 else (yf - 0.02, yf + p)
        box(bm, x0, x1, y0, y1, z0, z1)
    b(cx - w / 2 - bar, cx + w / 2 + bar, cz + h / 2, cz + h / 2 + bar, pro)       # head
    b(cx - w / 2 - bar, cx + w / 2 + bar, cz - h / 2 - bar, cz - h / 2, pro)       # sill bar
    b(cx - w / 2 - bar, cx - w / 2, cz - h / 2, cz + h / 2, pro)
    b(cx + w / 2, cx + w / 2 + bar, cz - h / 2, cz + h / 2, pro)
    b(cx - 0.03, cx + 0.03, cz - h / 2, cz + h / 2, pro * 0.7)                        # mullion
    b(cx - w / 2, cx + w / 2, cz - 0.03, cz + 0.03, pro * 0.7)                        # transom
    if sill: b(cx - w / 2 - bar * 1.6, cx + w / 2 + bar * 1.6, cz - h / 2 - bar * 1.7, cz - h / 2 - bar, pro * 2.1)
    if shutters:
        b(cx - w / 2 - bar - 0.5, cx - w / 2 - bar - 0.02, cz - h / 2 - bar, cz + h / 2 + bar, pro * 0.8)
        b(cx + w / 2 + bar + 0.02, cx + w / 2 + bar + 0.5, cz - h / 2 - bar, cz + h / 2 + bar, pro * 0.8)

def arch_gate(bm, cx, w, h, yf, pro=0.22, bar=0.3, d=-1):
    """Round-arched gateway surround (the big Saxon courtyard gate): posts plus an arch ring of wedge blocks."""
    y0, y1 = (yf - pro, yf + 0.02) if d < 0 else (yf - 0.02, yf + pro)
    box(bm, cx - w / 2 - bar, cx - w / 2, y0, y1, 0.0, h)
    box(bm, cx + w / 2, cx + w / 2 + bar, y0, y1, 0.0, h)
    r = w / 2.0
    n = 9
    for i in range(n):
        a0 = math.pi * i / n; a1 = math.pi * (i + 1) / n
        pts = []
        for rad in (r, r + bar):
            for a in (a0, a1):
                for y in (y0, y1):
                    pts.append((cx - math.cos(a) * rad, y, h + math.sin(a) * rad))
        hull(bm, pts)
    # a plank door set in it
    yy = (yf + 0.03, yf + 0.0) if d < 0 else (yf, yf)
    return

def door(bm, cx, w, h, yf, pro=0.14, bar=0.14, d=-1):
    y0, y1 = (yf - pro, yf + 0.02) if d < 0 else (yf - 0.02, yf + pro)
    box(bm, cx - w / 2 - bar, cx - w / 2, y0, y1, 0.0, h + bar)
    box(bm, cx + w / 2, cx + w / 2 + bar, y0, y1, 0.0, h + bar)
    box(bm, cx - w / 2 - bar, cx + w / 2 + bar, y0, y1, h, h + bar)
    box(bm, cx - w / 2 - bar * 1.6, cx + w / 2 + bar * 1.6, yf - pro * 2.2 if d < 0 else yf - 0.02, yf + 0.02 if d < 0 else yf + pro * 2.2, 0.0, 0.18)   # threshold step
    box(bm, cx - w / 2, cx + w / 2, yf - pro * 0.45 if d < 0 else yf, yf + 0.02 if d < 0 else yf + pro * 0.45, 0.0, h)  # the leaf, a touch proud

def chimney(bm, x, y, z0, z1, w=0.75, d=0.75):
    box(bm, x - w / 2, x + w / 2, y - d / 2, y + d / 2, z0, z1)
    box(bm, x - w / 2 - 0.12, x + w / 2 + 0.12, y - d / 2 - 0.12, y + d / 2 + 0.12, z1, z1 + 0.18)
    box(bm, x - w / 2 + 0.1, x + w / 2 - 0.1, y - d / 2 + 0.1, y + d / 2 - 0.1, z1 + 0.18, z1 + 0.5)

def gable_wall(bm, x, y0, y1, z0, rise, thick=0.3):
    """The plastered triangle of a gable end at x (a wall-coloured wedge)."""
    ym = (y0 + y1) / 2.0
    hull(bm, [(x, y0, z0), (x, y1, z0), (x, ym, z0 + rise), (x + thick, y0, z0), (x + thick, y1, z0), (x + thick, ym, z0 + rise)])

def band(bm, x0, x1, y0, y1, z, hgt=0.2, pro=0.1):
    box(bm, x0 - pro, x1 + pro, y0 - pro, y1 + pro, z, z + hgt)

def ridge_cap(bm, x0, x1, y, z, w=0.22, h=0.2):
    box(bm, x0, x1, y - w / 2, y + w / 2, z - 0.02, z + h)

def flowerbox(bm, cx, w, zc, yf, d=-1):
    y0, y1 = (yf - 0.3, yf) if d < 0 else (yf, yf + 0.3)
    box(bm, cx - w / 2, cx + w / 2, y0, y1, zc, zc + 0.26)

def bench(bm, cx, yf, d=-1, w=1.4):
    s = -1 if d < 0 else 1
    box(bm, cx - w / 2, cx + w / 2, yf + s * 0.1, yf + s * 0.5, 0.42, 0.5)
    for x in (cx - w / 2 + 0.1, cx + w / 2 - 0.1):
        box(bm, x - 0.05, x + 0.05, yf + s * 0.15, yf + s * 0.45, 0.0, 0.42)

def woodpile(bm, x0, x1, yf, d=-1, rows=4):
    s = -1 if d < 0 else 1
    for r in range(rows):
        box(bm, x0 + r * 0.05, x1 - r * 0.05, yf + s * 0.05, yf + s * 0.75, r * 0.2 + 0.0, r * 0.2 + 0.19)

def export(bm, name):
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=f"{OUT}/{name}.glb", export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_materials="NONE")
    bpy.data.objects.remove(ob)
    print("built", name, len(me.polygons), "faces")

bpy.ops.wm.read_factory_settings(use_empty=True)

# ---------------------------------------------------------------- Saxon street house (small)
# long body with the courtyard gate and a framed door on the street front, steep plastered gables, chimney, lean-to
bm = new()
X0, X1, Y0, Y1, WH = -5.0, 5.0, -2.9, 2.9, 3.3
box(bm, X0, X1, Y0, Y1, 0.0, WH)
box(bm, X0 - 0.08, X1 + 0.08, Y0 - 0.08, Y1 + 0.08, 0.0, 0.55)                    # rubble plinth, a touch proud
gable(bm, X0, X1, Y0, Y1, WH, 2.0, oy=0.35)
gable_wall(bm, X0 - 0.01, Y0, Y1, WH, 2.7, 0.0) if False else None
arch_gate(bm, -2.6, 2.3, 2.4, Y0)
door(bm, 1.0, 0.95, 2.2, Y0)
window(bm, 2.9, 1.7, 0.85, 1.05, Y0, shutters=True)
window(bm, -0.3, 1.6, 0.8, 1.0, Y0, shutters=True)
window(bm, 4.0, 1.55, 0.0001 + 0.7, 1.0, Y0, shutters=False) if False else None
window(bm, -2.0, 1.5, 0.7, 0.9, Y1, d=1)
window(bm, 2.0, 1.5, 0.7, 0.9, Y1, d=1)
window(bm, X0, 3.1, 0.6, 0.7, 0)  if False else None
chimney(bm, 1.6, 0.4, 3.2, 5.0)
# lean-to shed against the back, half the length
box(bm, 0.5, 5.0, Y1, Y1 + 2.2, 0.0, 2.1)
hull(bm, [(0.3, Y1 - 0.1, 3.0), (5.3, Y1 - 0.1, 3.0), (0.3, Y1 + 2.6, 2.2), (5.3, Y1 + 2.6, 2.2),
          (0.3, Y1 - 0.1, 2.8), (5.3, Y1 - 0.1, 2.8), (0.3, Y1 + 2.6, 2.0), (5.3, Y1 + 2.6, 2.0)])
ridge_cap(bm, X0 - 0.3, X1 + 0.3, 0.0, WH + 2.0)
flowerbox(bm, 2.9, 1.3, 1.1, Y0)
flowerbox(bm, -0.3, 1.2, 1.0, Y0)
bench(bm, 1.0, Y0 - 0.05, w=1.3) if False else None
woodpile(bm, -4.6, -3.0, Y0 - 0.05)
window(bm, -4.0, 1.6, 0.6, 0.8, Y1, d=1)
export(bm, "house_saxon")

# ---------------------------------------------------------------- Saxon merchant house (large, two storeys)
# a front gabled wing with a stepped gable, string course, two rows of windows, a tall gate
bm = new()
X0, X1, Y0, Y1, WH = -4.6, 4.6, -3.2, 3.2, 5.6
box(bm, X0, X1, Y0, Y1, 0.0, WH)
box(bm, X0 - 0.1, X1 + 0.1, Y0 - 0.1, Y1 + 0.1, 0.0, 0.6)
band(bm, X0, X1, Y0, Y1, 2.75, 0.22, 0.12)                                           # string course between the storeys
gable(bm, X0, X1, Y0, Y1, WH, 2.4, oy=0.4)
# front wing, a deeper gabled bay breaking forward with its own steep gable across the main ridge
WX0, WX1, WY0 = 0.6, 4.2, Y0 - 1.1
box(bm, WX0, WX1, WY0, Y0 + 0.2, 0.0, WH)
band(bm, WX0, WX1, WY0, Y0, 2.75, 0.22, 0.1)
hull(bm, [(WX0 - 0.5, WY0 - 0.6, WH - 0.4), (WX0 - 0.5, WY0 - 0.6, WH - 0.62), (WX1 + 0.5, WY0 - 0.6, WH - 0.4), (WX1 + 0.5, WY0 - 0.6, WH - 0.62),
          ((WX0 + WX1) / 2 - 0.0, WY0 - 0.6, WH + 2.1), ((WX0 + WX1) / 2, WY0 - 0.6, WH + 1.9),
          (WX0 - 0.5, Y0 + 2.0, WH - 0.4), (WX1 + 0.5, Y0 + 2.0, WH - 0.4), ((WX0 + WX1) / 2, Y0 + 2.0, WH + 2.1),
          (WX0 - 0.5, Y0 + 2.0, WH - 0.62), (WX1 + 0.5, Y0 + 2.0, WH - 0.62), ((WX0 + WX1) / 2, Y0 + 2.0, WH + 1.9)])
# wing windows
for z in (1.5, 4.0):
    window(bm, 1.7, z, 0.8, 1.0, WY0, shutters=(z < 3))
    window(bm, 3.1, z, 0.8, 1.0, WY0, shutters=(z < 3))
window(bm, 2.4, WH + 1.3, 0.7, 0.85, WY0 - 0.0)                                      # attic light in the gable
# main front, left of the wing: tall courtyard gate and windows
arch_gate(bm, -2.5, 2.6, 2.5, Y0)
window(bm, -2.5, 4.0, 0.9, 1.1, Y0, shutters=True)
window(bm, -0.3, 1.5, 0.8, 1.0, Y0)
window(bm, -0.3, 4.0, 0.8, 1.0, Y0)
for x in (-3.0, 0.0, 3.0):
    window(bm, x, 1.6, 0.8, 1.0, Y1, d=1); window(bm, x, 4.0, 0.8, 1.0, Y1, d=1)
chimney(bm, -1.2, 0.0, 6.0, 8.6, 0.9, 0.9)
chimney(bm, 3.6, 1.5, 6.0, 8.3, 0.8, 0.8)
ridge_cap(bm, X0 - 0.3, X1 + 0.3, 0.0, WH + 2.4)
flowerbox(bm, -0.3, 1.2, 1.0, Y0)
flowerbox(bm, 1.7, 1.2, 1.0, WY0); flowerbox(bm, 3.1, 1.2, 1.0, WY0)
bench(bm, -2.5 + 2.6, Y0 - 0.05, w=1.3) if False else None
woodpile(bm, -4.3, -3.4, Y0 - 0.05, rows=5)
export(bm, "house_big")

# ---------------------------------------------------------------- Romanian porch house
# a low timber house under a deep hipped roof, the prispa (porch) along the front on posts, a stone chimney
bm = new()
X0, X1, Y0, Y1, WH = -4.6, 4.6, -2.3, 2.3, 2.9
box(bm, X0, X1, Y0, Y1, 0.0, WH)
box(bm, X0 - 0.07, X1 + 0.07, Y0 - 0.07, Y1 + 0.07, 0.0, 0.45)
hip(bm, X0, X1, Y0, Y1, WH, 2.0, 1.5, ov=0.45)                                       # the main roof
PY = Y0 - 1.5
# the prispa: a raised timber platform, a lean-to roof of its own on carved posts, rail with balusters, steps
box(bm, X0 + 0.1, X1 - 0.1, PY, Y0, 0.0, 0.5)
hull(bm, [(X0 - 0.2, Y0 + 0.05, WH - 0.2), (X1 + 0.2, Y0 + 0.05, WH - 0.2), (X0 - 0.2, PY - 0.3, WH - 0.95), (X1 + 0.2, PY - 0.3, WH - 0.95),
          (X0 - 0.2, Y0 + 0.05, WH - 0.4), (X1 + 0.2, Y0 + 0.05, WH - 0.4), (X0 - 0.2, PY - 0.3, WH - 1.15), (X1 + 0.2, PY - 0.3, WH - 1.15)])
box(bm, X0 + 0.15, X1 - 0.15, PY + 0.06, PY + 0.28, WH - 1.45, WH - 1.05)             # the beam the roof rests on
for i in range(6):
    x = X0 + 0.45 + i * (X1 - X0 - 0.9) / 5.0
    box(bm, x - 0.1, x + 0.1, PY + 0.05, PY + 0.25, 0.5, WH - 1.45)
    box(bm, x - 0.17, x + 0.17, PY + 0.0, PY + 0.3, WH - 1.75, WH - 1.45)             # carved capital
    hull(bm, [(x - 0.1, PY + 0.05, WH - 1.75), (x + 0.1, PY + 0.05, WH - 1.75), (x - 0.5, PY + 0.05, WH - 1.45), (x + 0.5, PY + 0.05, WH - 1.45),
              (x - 0.1, PY + 0.25, WH - 1.75), (x + 0.1, PY + 0.25, WH - 1.75), (x - 0.5, PY + 0.25, WH - 1.45), (x + 0.5, PY + 0.25, WH - 1.45)])  # bracket
step = (X1 - X0 - 0.9) / 5.0
for i in range(5):                                                                      # rail with balusters between the posts, a gap at the door
    xa = X0 + 0.45 + i * step
    if i == 2: continue
    box(bm, xa + 0.1, xa + step - 0.1, PY + 0.09, PY + 0.21, 1.35, 1.47)
    for k in range(1, 6):
        bx = xa + 0.1 + k * (step - 0.2) / 6.0
        box(bm, bx - 0.035, bx + 0.035, PY + 0.11, PY + 0.19, 0.5, 1.35)
for k in range(3):                                                                      # steps up to the door
    box(bm, -0.8, 0.8, PY - 0.35 - k * 0.3, PY + 0.02, 0.0, 0.34 - k * 0.15 if k < 2 else 0.1)
door(bm, 0.0, 1.0, 2.25, Y0, pro=0.12)
window(bm, -2.9, 1.7, 0.7, 0.9, Y0, pro=0.09, shutters=True)
window(bm, 2.9, 1.7, 0.7, 0.9, Y0, pro=0.09, shutters=True)
window(bm, -1.6, 1.7, 0.5, 0.6, Y0, pro=0.09) if False else None
window(bm, -2.0, 1.6, 0.6, 0.75, Y1, d=1)
window(bm, 2.0, 1.6, 0.6, 0.75, Y1, d=1)
chimney(bm, -2.8, 0.3, 3.4, 5.1, 0.7, 0.7)
ridge_cap(bm, X0 + 1.4, X1 - 1.4, 0.0, WH + 2.0, 0.26, 0.2)
woodpile(bm, 3.0, 4.3, Y1, d=1, rows=5)
export(bm, "house_ro")
