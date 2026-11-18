# Builds the hunter as a low-poly rigged 3D model with idle/walk/attack/hurt animations and exports models/figures/hunter.glb
# usage: python3 tools/make_hunter.py   (needs the bpy module)
import bpy, bmesh, math, sys
from mathutils import Vector, Euler

bpy.ops.wm.read_factory_settings(use_empty=True)
mats = {}
def mat(name, rgb):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = (*rgb, 1); b.inputs["Roughness"].default_value = 0.9
    mats[name] = m; return m
SKIN = mat("skin", (0.80, 0.60, 0.46)); SHIRT = mat("shirt", (0.86, 0.82, 0.70)); VEST = mat("vest", (0.36, 0.22, 0.12))
PANTS = mat("pants", (0.25, 0.22, 0.20)); BOOT = mat("boot", (0.15, 0.10, 0.07)); HAT = mat("hat", (0.10, 0.09, 0.09)); HAIR = mat("hair", (0.12, 0.08, 0.05)); STEEL = mat("steel", (0.65, 0.66, 0.70)); LEATHER = mat("leather", (0.45, 0.30, 0.16))

# the rig: name -> (head, tail, parent)  (metres, Z up in Blender, character faces -Y)
BONES = {
 "hips": ((0,0,0.92),(0,0,1.05),None), "spine": ((0,0,1.05),(0,0,1.40),"hips"), "head": ((0,0,1.40),(0,0,1.68),"spine"),
 "uarm.L": ((0.22,0,1.38),(0.22,0,1.12),"spine"), "farm.L": ((0.22,0,1.12),(0.22,0,0.88),"uarm.L"),
 "uarm.R": ((-0.22,0,1.38),(-0.22,0,1.12),"spine"), "farm.R": ((-0.22,0,1.12),(-0.22,0,0.88),"uarm.R"),
 "thigh.L": ((0.10,0,0.92),(0.10,0,0.48),"hips"), "shin.L": ((0.10,0,0.48),(0.10,0,0.08),"thigh.L"),
 "thigh.R": ((-0.10,0,0.92),(-0.10,0,0.48),"hips"), "shin.R": ((-0.10,0,0.48),(-0.10,0,0.08),"thigh.R"),
}
parts = []   # (object, bone)
def box(name, bone, centre, size, material, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(location=centre); o = bpy.context.object; o.name = name
    o.scale = (size[0]/2, size[1]/2, size[2]/2); o.rotation_euler = Euler(rot); bpy.ops.object.transform_apply(scale=True, rotation=True)
    o.data.materials.append(material); parts.append((o, bone)); return o
def cyl(name, bone, centre, r, h, material, verts=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=centre); o = bpy.context.object; o.name = name
    o.data.materials.append(material); parts.append((o, bone)); return o
def sph(name, bone, centre, r, material, sq=(1,1,1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=7, radius=r, location=centre); o = bpy.context.object; o.name = name
    o.scale = sq; bpy.ops.object.transform_apply(scale=True); o.data.materials.append(material); parts.append((o, bone)); return o

# torso, vest, belt, satchel
box("torso", "spine", (0,0,1.22), (0.40,0.24,0.40), SHIRT)
box("vest", "spine", (0,0,1.22), (0.43,0.27,0.30), VEST)
box("pelvis", "hips", (0,0,0.98), (0.38,0.23,0.16), PANTS)
box("belt", "hips", (0,0,1.06), (0.42,0.26,0.05), LEATHER)
box("satchel", "hips", (-0.27,0.0,0.95), (0.08,0.22,0.22), LEATHER)
# head, hair, hat
sph("head", "head", (0,0,1.55), 0.13, SKIN, (1,0.95,1.1))
box("nose", "head", (0,-0.12,1.54), (0.04,0.05,0.05), SKIN)
sph("hair", "head", (0,0.03,1.58), 0.135, HAIR, (1,0.95,0.95))
cyl("hat_brim", "head", (0,0,1.66), 0.24, 0.02, HAT, 12)
cyl("hat_crown", "head", (0,0,1.72), 0.13, 0.12, HAT, 10)
# arms (sleeves cream, hands skin)
for s, x in (("L", 0.22), ("R", -0.22)):
    box("uarm."+s, "uarm."+s, (x,0,1.25), (0.11,0.11,0.28), SHIRT)
    box("farm."+s, "farm."+s, (x,0,1.00), (0.09,0.09,0.26), SHIRT)
    sph("hand."+s, "farm."+s, (x,0,0.86), 0.055, SKIN)
    box("thigh."+s, "thigh."+s, (0.10 if s=="L" else -0.10,0,0.70), (0.15,0.15,0.46), PANTS)
    box("shin."+s, "shin."+s, (0.10 if s=="L" else -0.10,0,0.28), (0.13,0.13,0.40), BOOT)
    box("foot."+s, "shin."+s, (0.10 if s=="L" else -0.10,-0.05,0.04), (0.13,0.26,0.08), BOOT)
# sabre in the right hand
box("sabre", "farm.R", (-0.22,-0.10,0.86), (0.03,0.62,0.04), STEEL)
box("hilt", "farm.R", (-0.22,0.18,0.86), (0.04,0.12,0.04), LEATHER)

# armature
arm_d = bpy.data.armatures.new("rig"); rig = bpy.data.objects.new("hunter_rig", arm_d); bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig; bpy.ops.object.mode_set(mode="EDIT")
for n, (h, t, p) in BONES.items():
    b = arm_d.edit_bones.new(n); b.head = h; b.tail = t
    if p: b.parent = arm_d.edit_bones[p]
bpy.ops.object.mode_set(mode="OBJECT")
# one skinned mesh
for o, bone in parts:
    vg = o.vertex_groups.new(name=bone); vg.add([v.index for v in o.data.vertices], 1.0, "REPLACE")
bpy.ops.object.select_all(action="DESELECT")
for o, _ in parts: o.select_set(True)
bpy.context.view_layer.objects.active = parts[0][0]; bpy.ops.object.join()
body = bpy.context.object; body.name = "hunter_body"; body.parent = rig
mod = body.modifiers.new("arm", "ARMATURE"); mod.object = rig
bpy.ops.object.shade_flat()

# animations
rig.animation_data_create()
def pose(name, frames, fps=24):
    act = bpy.data.actions.new(name); rig.animation_data.action = act
    bpy.context.view_layer.objects.active = rig; bpy.ops.object.mode_set(mode="POSE")
    for f, bones in frames:
        for pb in rig.pose.bones: pb.rotation_mode = "XYZ"; pb.rotation_euler = (0,0,0); pb.location = (0,0,0)
        for bn, v in bones.items():
            if bn == "hips_loc": rig.pose.bones["hips"].location = v
            else: rig.pose.bones[bn].rotation_euler = tuple(math.radians(a) for a in v)
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_euler", frame=f)
            if pb.name == "hips": pb.keyframe_insert("location", frame=f)
    bpy.ops.object.mode_set(mode="OBJECT")
    t = rig.animation_data.nla_tracks.new(); t.name = name; t.strips.new(name, int(act.frame_range[0]), act); rig.animation_data.action = None
S = 28
pose("idle", [(1, {"spine": (0,0,0), "uarm.L": (2,0,0), "uarm.R": (2,0,0)}), (30, {"spine": (-2,0,0), "hips_loc": (0,0,-0.01), "uarm.L": (4,0,0), "uarm.R": (4,0,0)}), (60, {"spine": (0,0,0), "uarm.L": (2,0,0), "uarm.R": (2,0,0)})])
def step(a, b): return {"thigh.L": (-S*a,0,0), "thigh.R": (S*a,0,0), "shin.L": (max(0,S*a)*1.3,0,0), "shin.R": (max(0,-S*a)*1.3,0,0), "uarm.L": (S*a*0.8,0,0), "uarm.R": (-S*a*0.8,0,0), "hips_loc": (0,0,-0.03*b), "spine": (4,0,0)}
pose("walk", [(1, step(1,1)), (7, step(0,0)), (13, step(-1,1)), (19, step(0,0)), (25, step(1,1))])
pose("attack", [(1, {"uarm.R": (-20,0,0), "spine": (0,-10,0)}), (6, {"uarm.R": (-150,0,10), "farm.R": (-30,0,0), "spine": (0,-25,0)}), (12, {"uarm.R": (-40,0,-20), "farm.R": (0,0,0), "spine": (0,35,0)}), (20, {"uarm.R": (-10,0,0), "spine": (0,0,0)})])
pose("hurt", [(1, {}), (4, {"spine": (-25,0,0), "head": (-15,0,0), "uarm.L": (-40,0,0), "uarm.R": (-40,0,0), "hips_loc": (0,0.1,0)}), (14, {})])
pose("die", [(1, {}), (14, {"hips_loc": (0,0,-0.78), "spine": (-80,0,0), "thigh.L": (-60,0,0), "thigh.R": (-30,0,0), "shin.L": (70,0,0), "shin.R": (40,0,0)}), (22, {"hips_loc": (0,0,-0.78), "spine": (-80,0,0), "thigh.L": (-60,0,0), "thigh.R": (-30,0,0), "shin.L": (70,0,0), "shin.R": (40,0,0)})])
out = sys.argv[-1] if sys.argv[-1].endswith(".glb") else "/home/claude/bg/models/figures/hunter.glb"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_animations=True, export_animation_mode="NLA_TRACKS", export_apply=False, export_yup=True)
print("exported", out)
