"""PaperKid's pedestrian: a person on the pavement, modelled, rigged and given a walk in Blender.

    blender --background --factory-startup --python pedestrian.py -- <out dir> [preview]

Writes <out dir>/PedestrianModel.glb (one skinned mesh, its armature, and the clip Walk) and, with
`preview`, PNG renders. The figure stands on the ground at its origin facing the engine's +Z (as the
cars do: Pedestrian.as turns the entity toward where it walks), about 1.6 m tall, the height of the
Pedestrian prefab's navigation agent.

Walk: one second, two steps of 0.65 m (1.3 m of pavement at speed 1: Pedestrian.as plays it at the
walking speed over that). The legs swing with the knee bending on the forward swing, the feet stay
level, the arms swing against the legs and the body bobs with each step. Every rotation is set from
the bone's own direction (a swing turns the bone toward or away from forward), not from guessed axis
signs.
"""
import bpy, math, os, sys
from mathutils import Vector, Quaternion

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "pedestrian-out")
PREVIEW = "preview" in ARGS
FPS, LOOP = 24, 24
STRIDE = 0.65  # metres a step

kit3d.PALETTE.update({
    "Skin": (0.72, 0.48, 0.34), "Top": (0.52, 0.28, 0.58), "TopDark": (0.40, 0.20, 0.45),
    "Trousers": (0.18, 0.20, 0.27), "Shoe": (0.24, 0.16, 0.12), "Hair": (0.20, 0.13, 0.08),
    "Eye": (0.08, 0.06, 0.06), "Bag": (0.78, 0.55, 0.30),
})

# The joints at rest (standing, arms a little out), side +1 the figure's left (+X; it faces -Y).
HIP_Y = 0.86
HIP = lambda side: P(side * 0.11, 0, HIP_Y)
KNEE = lambda side: P(side * 0.115, 0.02, 0.47)
ANKLE = lambda side: P(side * 0.12, 0, 0.08)
TOE = lambda side: P(side * 0.12, 0.17, 0.04)
SHOULDER = lambda side: P(side * 0.22, 0, 1.33)
ELBOW = lambda side: P(side * 0.27, -0.02, 1.06)
HAND = lambda side: P(side * 0.29, 0.03, 0.82)
NECK = P(0, 0, 1.40)
HEAD = P(0, 0.01, 1.58)


def build():
    box("Pelvis", (0.32, 0.22, 0.18), P(0, 0, 0.9), "Trousers", "hips", bevel=0.05)
    box("Torso", (0.40, 0.24, 0.48), P(0, 0, 1.15), "Top", "spine", bevel=0.07)
    box("Hem", (0.41, 0.25, 0.05), P(0, 0, 0.93), "TopDark", "spine", bevel=0.02)
    tube("Neck", NECK - Vector((0, 0, 0.03)), NECK + Vector((0, 0, 0.07)), 0.055, "Skin", "head")
    ball("Head", HEAD, 0.19, "Skin", "head", scale=(1.0, 0.95, 1.05), segments=(32, 18))
    ball("Hair", HEAD + P(0, -0.02, 0.05), 0.2, "Hair", "head", scale=(1.03, 1.0, 0.9), segments=(32, 18),
         cut_below=0.1)
    ball("Bun", HEAD + P(0, -0.17, 0.08), 0.08, "Hair", "head", segments=(16, 10))
    for side in (-1, 1):
        ball("Eye", HEAD + P(side * 0.065, 0.165, 0.01), 0.024, "Eye", "head", segments=(12, 8))
        ball("Ear", HEAD + P(side * 0.185, 0, -0.01), 0.045, "Skin", "head", scale=(0.5, 1, 1), segments=(14, 10))
    # A shoulder bag on the left, for character.
    box("Bag", (0.08, 0.26, 0.2), P(0.25, -0.02, 0.98), "Bag", "spine", bevel=0.03)
    tube("Strap", P(0.24, 0, 1.08), P(-0.16, 0, 1.36), 0.018, "Bag", "spine", 6)
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        sh, el, ha = SHOULDER(side), ELBOW(side), HAND(side)
        ball("Shoulder" + s, sh, 0.08, "Top", "upperarm_" + s, segments=(14, 10))
        tube("Sleeve" + s, sh, sh + (el - sh) * 0.6, 0.068, "Top", "upperarm_" + s, 10, 0.06)
        tube("UpperArm" + s, sh + (el - sh) * 0.5, el, 0.045, "Skin", "upperarm_" + s, 10)
        ball("Elbow" + s, el, 0.045, "Skin", "forearm_" + s, segments=(10, 8))
        tube("Forearm" + s, el, ha, 0.043, "Skin", "forearm_" + s, 10, 0.038)
        ball("Hand" + s, ha, 0.05, "Skin", "forearm_" + s, segments=(12, 8))
        hp, kn, an, toe = HIP(side), KNEE(side), ANKLE(side), TOE(side)
        tube("Thigh" + s, hp, kn, 0.08, "Trousers", "thigh_" + s, 10, 0.065)
        ball("Knee" + s, kn, 0.065, "Trousers", "shin_" + s, segments=(10, 8))
        tube("Shin" + s, kn, an, 0.062, "Trousers", "shin_" + s, 10, 0.05)
        box("Shoe" + s, (0.11, (toe - an).length + 0.1, 0.09), (an + toe) / 2 + Vector((0, 0, -0.005)), "Shoe",
            "foot_" + s, bevel=0.03)


def build_armature():
    arm = bpy.data.armatures.new("PedestrianRig")
    rig = bpy.data.objects.new("PedestrianRig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones

    def bone(name, head, tail, parent=None, connect=False):
        b = eb.new(name)
        b.head, b.tail, b.roll = head, tail, 0.0
        if parent:
            b.parent = eb[parent]
            b.use_connect = connect
        return b

    bone("root", Vector((0, 0, 0)), Vector((0, 0, 0.2)))
    bone("hips", P(0, 0, HIP_Y - 0.05), P(0, 0, HIP_Y + 0.08), "root")
    bone("spine", P(0, 0, HIP_Y + 0.08), NECK, "hips")
    bone("head", NECK, NECK + Vector((0, 0, 0.32)), "spine")
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        bone("upperarm_" + s, SHOULDER(side), ELBOW(side), "spine")
        bone("forearm_" + s, ELBOW(side), HAND(side), "upperarm_" + s, True)
        bone("thigh_" + s, HIP(side), KNEE(side), "hips")
        bone("shin_" + s, KNEE(side), ANKLE(side), "thigh_" + s, True)
        bone("foot_" + s, ANKLE(side), TOE(side), "shin_" + s, True)
    bpy.ops.object.mode_set(mode="OBJECT")
    for b in rig.pose.bones:
        b.rotation_mode = "QUATERNION"
    return rig


def swing_quat(rig, bone_name, degrees):
    """A turn of the bone in the figure's forward plane: positive turns the bone toward forward
    (Blender's -Y), about the axis across the figure; given in the bone's own frame."""
    bone = rig.data.bones[bone_name]
    rest = bone.matrix_local.to_3x3()
    direction = rest.col[1].normalized()            # a bone's Y runs head to tail
    forward = Vector((0, -1, 0))
    axis = direction.cross(forward)
    if axis.length < 1e-6:  # a bone already pointing forward (the foot): turn about X
        axis = Vector((1, 0, 0)) if direction.y < 0 else Vector((-1, 0, 0))
    axis_local = rest.inverted() @ axis.normalized()
    return Quaternion(axis_local, math.radians(degrees))


def walk(rig):
    rig.animation_data_create()
    action = bpy.data.actions.new("Walk")
    rig.animation_data.action = action
    pb = rig.pose.bones
    for f in range(1, LOOP + 2):
        t = (f - 1) / LOOP
        phase = 2 * math.pi * t
        for side, offset in ((1, 0.0), (-1, math.pi)):
            s = "L" if side > 0 else "R"
            p = phase + offset
            thigh = 26 * math.sin(p)                      # forward of the hip at +26
            knee = 42 * max(0.0, math.cos(p)) + 6         # bent on the forward swing
            pb["thigh_" + s].rotation_quaternion = swing_quat(rig, "thigh_" + s, thigh)
            pb["shin_" + s].rotation_quaternion = swing_quat(rig, "shin_" + s, -knee)
            # The foot level: undo what the thigh and shin did to it (they turn about the axis across
            # the body one way; the foot, pointing forward, turns about it the other, so the same
            # sum levels it), and toe down a little at the back of the stride.
            toe_off = 18 * (-math.sin(p) - 0.6) / 0.4 if -math.sin(p) > 0.6 else 0.0
            pb["foot_" + s].rotation_quaternion = swing_quat(rig, "foot_" + s, (thigh - knee) + toe_off)
            arm = -20 * math.sin(p)                       # against the same side's leg
            pb["upperarm_" + s].rotation_quaternion = swing_quat(rig, "upperarm_" + s, arm)
            pb["forearm_" + s].rotation_quaternion = swing_quat(rig, "forearm_" + s, 12 + 8 * max(0.0, math.sin(-p)))
            for name in ("thigh_", "shin_", "foot_", "upperarm_", "forearm_"):
                pb[name + s].keyframe_insert("rotation_quaternion", frame=f)
        # The body rises over each planted leg (twice a cycle) and leans a touch forward.
        pb["hips"].location = Vector((0, 0.02 * (1 - math.cos(2 * phase)) / 2, 0))  # hips' Y is up
        pb["hips"].keyframe_insert("location", frame=f)
        pb["spine"].rotation_quaternion = swing_quat(rig, "spine", 4)
        pb["spine"].keyframe_insert("rotation_quaternion", frame=f)
    action.use_fake_user = True
    return action


def main():
    kit3d.reset()
    bpy.context.scene.render.fps = FPS
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = 1, LOOP + 1
    os.makedirs(OUT, exist_ok=True)
    build()
    rig = build_armature()
    body = kit3d.skin(rig, "PedestrianModel")
    action = walk(rig)
    if PREVIEW:
        cam = kit3d.studio()
        target = Vector((0, 0, 0.9))
        rig.animation_data.action = None
        kit3d.shoot(cam, os.path.join(OUT, "preview-front34.png"), P(-2.0, 2.6, 1.5), target)
        rig.animation_data.action = action
        for f in (1, 7, 13, 19):
            bpy.context.scene.frame_set(f)
            kit3d.shoot(cam, os.path.join(OUT, "preview-walk-%02d.png" % f), P(-3.4, 0.0, 1.0), target)
    kit3d.export_rigged(os.path.join(OUT, "PedestrianModel.glb"), rig, body)
    print("PedestrianModel written to", OUT)


main()
