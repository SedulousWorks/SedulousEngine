"""PaperKid's player: the kid on his bike, modelled, rigged and animated in Blender from this script.

    blender --background --factory-startup --python kid_bike.py -- <out dir> [preview]

Writes <out dir>/KidBike.glb (one skinned mesh, its armature, and the clips Ride, ThrowLeft and
ThrowRight) and,
with `preview`, PNG renders to check by eye. Nothing here is hand-placed: rerun after a change.

The model sits where the old primitives did: its origin is the ground under the middle of the bike,
the bike's front is +Z in the engine (Blender's -Y), the wheels are 0.35 m in radius and 1.1 m
apart, and the kid's head is about 1.55 m up, so the Bike entity's capsule (its centre 0.9 m above
the ground) still fits it.

The rig: the bike's parts are rigid on their bones (the frame, both wheels, the crank and pedals);
the kid's legs follow the pedals and his hands the grips through IK, baked to plain keyframes, so
the engine plays ordinary bone tracks.

- Ride: one second, the crank once round and the wheels twice (4.4 m of road at speed 1: Bike.as
  scales the clip by the bike's speed), the legs pedalling and a slight bob.
- ThrowLeft, ThrowRight: the same second, that arm winding back over the shoulder and flinging
  forward and out to its own side in its first half, back on the grip by the end, so Ride picks up
  where it ends. Bike.as throws with the hand on the side the paper goes.
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit3d import *  # P, the primitives, the materials and parts, two_bone
import kit3d

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "kidbike-out")
PREVIEW = "preview" in ARGS
FPS = 24
LOOP = 24  # frames in one second


# ---------------------------------------------------------------- the kid's colours
kit3d.PALETTE.update({
    "Frame": (0.86, 0.16, 0.14), "Tyre": (0.06, 0.06, 0.07), "Metal": (0.62, 0.64, 0.68),
    "Dark": (0.16, 0.16, 0.18), "Bag": (0.80, 0.66, 0.42), "BagDark": (0.58, 0.45, 0.27),
    "Paper": (0.93, 0.92, 0.86), "Skin": (0.82, 0.55, 0.38), "Shirt": (0.20, 0.45, 0.85),
    "Shorts": (0.22, 0.27, 0.40), "Cap": (0.95, 0.35, 0.15), "Shoe": (0.94, 0.94, 0.94),
    "Sole": (0.85, 0.20, 0.16), "Eye": (0.08, 0.06, 0.06), "Hair": (0.30, 0.18, 0.10),
})


# ---------------------------------------------------------------- the layout
R_WHEEL = 0.35
FRONT_AXLE = P(0, 0.55, R_WHEEL)
REAR_AXLE = P(0, -0.55, R_WHEEL)
CRANK = P(0, 0.02, 0.32)
CRANK_ARM = 0.16
PEDAL_X = 0.15
SEAT = P(0, -0.20, 0.86)
HEAD_TOP = P(0, 0.40, 0.80)
HEAD_BOTTOM = P(0, 0.45, 0.62)
STEM_TOP = P(0, 0.38, 0.93)
GRIP_X = 0.29
GRIP = lambda side: P(side * GRIP_X, 0.34, 0.95)
HIP = lambda side: P(side * 0.10, -0.15, 0.93)
# The upper body leans forward over the bars, as a kid on a small bike rides: about 30 degrees
# from upright, hips to neck.
SHOULDER = lambda side: P(side * 0.21, 0.09, 1.31)
NECK = P(0, 0.11, 1.37)
HEAD = P(0, 0.16, 1.54)
THIGH, SHIN = 0.40, 0.42      # hip to knee, knee to ankle
UPPER_ARM, FOREARM = 0.245, 0.245  # a little longer than the reach to the grips: a slight bend
ANKLE_LIFT = 0.06             # the ankle above the pedal's axle


def pedal_point(side, angle):
    """Where a pedal is with the crank at `angle` (radians; 0 = the right pedal forward)."""
    a = angle + (0 if side > 0 else math.pi)
    return CRANK + Vector((side * PEDAL_X, -CRANK_ARM * math.cos(a), CRANK_ARM * math.sin(a)))


def build_bike():
    for name, axle, bone in (("Front", FRONT_AXLE, "wheel_front"), ("Rear", REAR_AXLE, "wheel_rear")):
        ring(name + "Tyre", axle, R_WHEEL - 0.045, 0.045, "Tyre", bone)
        ring(name + "Rim", axle, R_WHEEL - 0.085, 0.018, "Metal", bone, minor_segments=4)
        disc(name + "Hub", axle, 0.045, 0.11, "Metal", bone, 10)
        for k in range(3):  # three spokes across: the wheel visibly turns
            a = math.pi * k / 3
            d = Vector((0, math.cos(a), math.sin(a))) * (R_WHEEL - 0.09)
            tube(name + "Spoke%d" % k, axle - d, axle + d, 0.008, "Metal", bone, 4)
    # The frame: a red BMX.
    for x in (-0.05, 0.05):
        tube("ChainStay", REAR_AXLE + Vector((x, 0, 0)), CRANK + Vector((x * 0.6, 0, 0)), 0.018, "Frame", "bike")
        tube("SeatStay", REAR_AXLE + Vector((x, 0, 0)), SEAT + Vector((x * 0.4, 0, -0.08)), 0.016, "Frame", "bike")
        tube("Fork", HEAD_BOTTOM + Vector((x, 0, 0)), FRONT_AXLE + Vector((x, 0, 0)), 0.02, "Frame", "bike")
    tube("SeatTube", CRANK, SEAT - Vector((0, 0, 0.06)), 0.026, "Frame", "bike")
    tube("TopTube", SEAT - Vector((0, 0, 0.08)), HEAD_TOP, 0.026, "Frame", "bike")
    tube("DownTube", CRANK, HEAD_BOTTOM, 0.03, "Frame", "bike")
    tube("HeadTube", HEAD_BOTTOM - Vector((0, 0, 0.03)), HEAD_TOP + Vector((0, 0, 0.03)), 0.035, "Frame", "bike")
    tube("Stem", HEAD_TOP, STEM_TOP, 0.022, "Dark", "bike")
    tube("Bar", GRIP(-1) + Vector((-0.04, 0, 0)), GRIP(1) + Vector((0.04, 0, 0)), 0.016, "Dark", "bike")
    for side in (-1, 1):
        tube("BarRise", STEM_TOP + Vector((side * 0.06, 0, 0)), GRIP(side) + Vector((-side * 0.12, 0, 0)), 0.016,
             "Dark", "bike")
        tube("Grip", GRIP(side) - Vector((side * 0.05, 0, 0)), GRIP(side) + Vector((side * 0.05, 0, 0)), 0.024,
             "Tyre", "bike")
    tube("SeatPost", SEAT - Vector((0, 0, 0.08)), SEAT, 0.018, "Metal", "bike")
    box("Saddle", (0.12, 0.26, 0.05), SEAT + Vector((0, -0.02, 0.03)), "Dark", "bike", bevel=0.015)
    # The rack and the paper bag over the back wheel, rolled papers poking out.
    box("Rack", (0.20, 0.30, 0.02), P(0, -0.55, 0.72), "Metal", "bike")
    tube("RackStay", P(0.08, -0.55, 0.72), REAR_AXLE + Vector((0.08, 0, 0)), 0.01, "Metal", "bike", 4)
    tube("RackStay", P(-0.08, -0.55, 0.72), REAR_AXLE + Vector((-0.08, 0, 0)), 0.01, "Metal", "bike", 4)
    box("Bag", (0.34, 0.34, 0.24), P(0, -0.56, 0.85), "Bag", "bike", bevel=0.03)
    box("BagFlap", (0.35, 0.12, 0.03), P(0, -0.43, 0.975), "BagDark", "bike", bevel=0.01, tilt=-30)
    for i, x in enumerate((-0.09, 0.0, 0.09)):
        tube("Paper%d" % i, P(x, -0.62, 0.92), P(x, -0.62 + 0.02 * i, 1.04), 0.035, "Paper", "bike", 10)
    # The drive: the chainring on the crank's bone, the arms and pedals on theirs.
    disc("Chainring", CRANK + Vector((0.07, 0, 0)), 0.085, 0.015, "Metal", "crank", 14)
    for side in (-1, 1):
        bone = "pedal_" + ("L" if side > 0 else "R")
        pedal = pedal_point(side, 0.0)
        tube("CrankArm" + bone, CRANK + Vector((side * 0.06, 0, 0)), pedal - Vector((side * 0.02, 0, 0)), 0.014,
             "Metal", "crank", 6)
        box("Pedal" + bone, (0.09, 0.07, 0.02), pedal + Vector((side * 0.03, 0, 0)), "Dark", bone)


def limb(name, a, b, radius, mat, bone, radius2=None):
    tube(name, a, b, radius, mat, bone, 8, radius2)
    ball(name + "Joint", b, radius2 if radius2 else radius, mat, bone, segments=(10, 8))


def build_kid(pose):
    """The kid at the rest pose: each part on its bone, placed by the joint positions in `pose`."""
    box("Pelvis", (0.30, 0.22, 0.16), P(0, -0.13, 0.95), "Shorts", "hips", bevel=0.04)
    # The torso leans forward to the bars: a chunky shirt block along hips -> neck.
    chest = (P(0, -0.11, 1.0) + NECK) / 2
    # Tipped forward along the spine: a positive turn about X takes the top toward -Y, forward.
    spine = NECK - P(0, -0.11, 1.0)
    lean = math.degrees(math.atan2(-spine.y, spine.z))
    box("Shirt", (0.36, 0.22, 0.42), chest, "Shirt", "spine", bevel=0.06, tilt=lean)
    tube("Neck", NECK - Vector((0, 0, 0.03)), NECK + Vector((0, 0, 0.06)), 0.055, "Skin", "head")
    # A big head (the kit's chibi proportion), eyes, the cap with its bill forward.
    ball("Head", HEAD, 0.20, "Skin", "head", scale=(1.0, 0.95, 1.0), segments=(32, 18))
    for side in (-1, 1):
        ball("Eye", HEAD + P(side * 0.07, 0.175, 0.01), 0.026, "Eye", "head", segments=(12, 8))
        ball("Ear", HEAD + P(side * 0.195, 0.0, -0.01), 0.05, "Skin", "head", scale=(0.5, 1, 1), segments=(14, 10))
    ball("Cap", HEAD + Vector((0, 0, 0.03)), 0.212, "Cap", "head", scale=(1.0, 1.0, 0.85), segments=(32, 18),
         cut_below=0.15)
    box("CapBill", (0.24, 0.17, 0.025), HEAD + P(0, 0.19, 0.075), "Cap", "head", bevel=0.01, tilt=-8)
    ball("Hair", HEAD + P(0, -0.12, -0.02), 0.13, "Hair", "head", scale=(1.2, 0.6, 0.9), segments=(24, 12))
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        sh, el, ha = pose["shoulder" + s], pose["elbow" + s], pose["hand" + s]
        ball("Shoulder" + s, sh, 0.075, "Shirt", "upperarm_" + s, segments=(14, 10))
        sleeve_end = sh + (el - sh) * 0.45
        tube("Sleeve" + s, sh, sleeve_end, 0.07, "Shirt", "upperarm_" + s, 8, 0.065)
        limb("UpperArm" + s, sleeve_end, el, 0.045, "Skin", "upperarm_" + s)
        limb("Forearm" + s, el, ha, 0.042, "Skin", "forearm_" + s, 0.038)
        ball("Hand" + s, ha, 0.05, "Skin", "forearm_" + s, segments=(12, 8))
        hp, kn, an, toe = pose["hip" + s], pose["knee" + s], pose["ankle" + s], pose["toe" + s]
        tube("ShortsLeg" + s, hp, hp + (kn - hp) * 0.55, 0.085, "Shorts", "thigh_" + s, 8, 0.075)
        limb("Thigh" + s, hp + (kn - hp) * 0.5, kn, 0.062, "Skin", "thigh_" + s)
        limb("Shin" + s, kn, an, 0.055, "Skin", "shin_" + s, 0.045)
        tube("Sock" + s, an - (an - kn).normalized() * 0.05, an, 0.05, "Shoe", "shin_" + s)
        mid = (an + toe) / 2
        shoe = box("Shoe" + s, (0.10, (toe - an).length + 0.08, 0.08), mid, "Shoe", "foot_" + s, bevel=0.025)
        box("Sole" + s, (0.105, (toe - an).length + 0.09, 0.025), mid - Vector((0, 0, 0.04)), "Sole", "foot_" + s)


# ---------------------------------------------------------------- solving the rest pose
def rest_pose():
    pose = {}
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        pedal = pedal_point(side, 0.0)  # cranks level at rest, the right pedal forward
        ankle = pedal + Vector((0, 0, ANKLE_LIFT))
        hip = HIP(side)
        pose["hip" + s], pose["ankle" + s] = hip, ankle
        pose["knee" + s] = two_bone(hip, ankle, THIGH, SHIN, P(0, 1, 0.3))
        pose["toe" + s] = ankle + P(0, 0.14, -0.04)
        sh, grip = SHOULDER(side), GRIP(side) + Vector((side * 0.0, 0, 0.0))
        pose["shoulder" + s], pose["hand" + s] = sh, grip
        pose["elbow" + s] = two_bone(sh, grip, UPPER_ARM, FOREARM, P(side * 0.8, -0.2, -0.4))
    return pose


# ---------------------------------------------------------------- the armature
def build_armature(pose):
    arm = bpy.data.armatures.new("KidBikeRig")
    rig = bpy.data.objects.new("KidBikeRig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones

    def bone(name, head, tail, parent=None, deform=True):
        b = eb.new(name)
        b.head, b.tail = head, tail
        b.roll = 0.0
        b.use_deform = deform
        if parent:
            b.parent = eb[parent]
        return b

    up = Vector((0, 0, 0.12))
    bone("root", Vector((0, 0, 0)), Vector((0, 0, 0.2)))
    bone("bike", P(0, 0, 0.3), P(0, 0, 0.5), "root")
    bone("wheel_front", FRONT_AXLE, FRONT_AXLE + up, "bike")
    bone("wheel_rear", REAR_AXLE, REAR_AXLE + up, "bike")
    bone("crank", CRANK, CRANK + up, "bike")
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        p = pedal_point(side, 0.0)
        bone("pedal_" + s, p, p + up, "crank")
        # Not deforming: where the foot goes (on its pedal) and where the hand goes (the grip).
        bone("ik_foot_" + s, p + Vector((0, 0, ANKLE_LIFT)), p + Vector((0, 0, ANKLE_LIFT)) + up, "pedal_" + s, False)
        # Laid along the foot (ankle to toe) and riding on the pedal: the foot copies its turn, so
        # it stays flat on the pedal and points forward all the way round the crank.
        bone("foot_aim_" + s, pose["ankle" + s], pose["toe" + s], "pedal_" + s, False)
        bone("ik_hand_" + s, GRIP(side), GRIP(side) + up, "bike", False)
        bone("pole_knee_" + s, HIP(side) + P(0, 0.8, 0.0), HIP(side) + P(0, 0.8, 0.0) + up, "bike", False)
        bone("pole_elbow_" + s, SHOULDER(side) + P(side * 0.6, -0.1, -0.4),
             SHOULDER(side) + P(side * 0.6, -0.1, -0.4) + up, "bike", False)
    bone("hips", P(0, -0.15, 0.90), P(0, -0.12, 1.02), "bike")
    bone("spine", P(0, -0.11, 1.0), NECK, "hips")
    bone("head", NECK, NECK + Vector((0, 0, 0.3)), "spine")
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        bone("upperarm_" + s, pose["shoulder" + s], pose["elbow" + s], "spine")
        bone("forearm_" + s, pose["elbow" + s], pose["hand" + s], "upperarm_" + s).use_connect = True
        bone("thigh_" + s, pose["hip" + s], pose["knee" + s], "hips")
        bone("shin_" + s, pose["knee" + s], pose["ankle" + s], "thigh_" + s).use_connect = True
        bone("foot_" + s, pose["ankle" + s], pose["toe" + s], "shin_" + s).use_connect = True
    bpy.ops.object.mode_set(mode="POSE")
    pb = rig.pose.bones
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        ik = pb["shin_" + s].constraints.new("IK")
        ik.target, ik.subtarget = rig, "ik_foot_" + s
        ik.pole_target, ik.pole_subtarget = rig, "pole_knee_" + s
        ik.pole_angle = math.radians(-90)
        ik.chain_count = 2
        # The foot stays flat on its pedal whatever the leg does.
        cr = pb["foot_" + s].constraints.new("COPY_ROTATION")
        cr.target, cr.subtarget = rig, "foot_aim_" + s
        cr.mix_mode = "REPLACE"
        ik = pb["forearm_" + s].constraints.new("IK")
        ik.target, ik.subtarget = rig, "ik_hand_" + s
        ik.pole_target, ik.pole_subtarget = rig, "pole_elbow_" + s
        # +90 here (the knees' -90 would bend the elbows in toward the chest): the elbows point
        # out, back and down, toward their poles.
        ik.pole_angle = math.radians(90)
        ik.chain_count = 2
    for b in pb:
        b.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


# ---------------------------------------------------------------- the clips
def bone_space(offset):
    """A rest-space offset in the local axes of a bone pointing up (+Z, no roll), which is how the
    helper and hip bones are laid out: its Y is up and its Z is forward-back (Blender's -Y)."""
    return Vector((offset.x, offset.z, -offset.y))


def key_drive(rig, throw_side):
    """Keys on the driving bones only (crank, wheels, pedals, and for a throw the throwing hand's
    target); IK does the rest, and baking turns the result into plain keys on every bone."""
    pb = rig.pose.bones
    for f in range(1, LOOP + 2):
        t = (f - 1) / LOOP
        crank = 2 * math.pi * t
        pb["crank"].rotation_euler = (crank, 0, 0)
        pb["crank"].keyframe_insert("rotation_euler", frame=f)
        for s in ("L", "R"):
            pb["pedal_" + s].rotation_euler = (-crank, 0, 0)  # pedals stay level as the crank turns
            pb["pedal_" + s].keyframe_insert("rotation_euler", frame=f)
        for w in ("wheel_front", "wheel_rear"):
            pb[w].rotation_euler = (2 * crank, 0, 0)
            pb[w].keyframe_insert("rotation_euler", frame=f)
        # A slight bob of the body with each push (twice a turn).
        pb["hips"].location = bone_space(P(0, 0, 0.012 * math.sin(2 * crank)))
        pb["hips"].keyframe_insert("location", frame=f)
    if throw_side:
        hand = pb["ik_hand_" + throw_side]
        out = 1.0 if throw_side == "L" else -1.0  # his left is +X
        # Where the throwing hand goes, from its grip: up behind the shoulder, cocked, flung forward
        # and out to its own side past the bars (the paper leaves here), following through, back on
        # the grip. Written for the left hand; the right is its mirror image.
        frames = {1: P(0, 0, 0), 4: P(0.01, -0.39, 0.60), 7: P(0.05, -0.46, 0.66), 9: P(0.26, 0.11, 0.50),
                  11: P(0.16, 0.06, 0.15), 14: P(0, 0, 0), 25: P(0, 0, 0)}
        for f, off in frames.items():
            hand.location = bone_space(Vector((off.x * out, off.y, off.z)))
            hand.keyframe_insert("location", frame=f)
    for fc in rig.animation_data.action.fcurves if hasattr(rig.animation_data.action, "fcurves") else []:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"


def bake(rig, name, throw_side=None):
    rig.animation_data_create()
    drive = bpy.data.actions.new(name + "Drive")
    rig.animation_data.action = drive
    key_drive(rig, throw_side)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.nla.bake(frame_start=1, frame_end=LOOP + 1, only_selected=False, visual_keying=True,
                     clear_constraints=False, use_current_action=False, bake_types={"POSE"})
    baked = rig.animation_data.action
    baked.name = name
    baked.use_fake_user = True
    bpy.ops.object.mode_set(mode="OBJECT")
    # Back to rest for the next bake.
    rig.animation_data.action = None
    for b in rig.pose.bones:
        b.location = (0, 0, 0)
        b.rotation_euler = (0, 0, 0)
        b.rotation_quaternion = (1, 0, 0, 0)
    bpy.data.actions.remove(drive)
    return baked


def strip_helpers(rig, actions):
    """The IK constraints and the helper bones' tracks are not shipped: the baked keys carry it all."""
    for b in rig.pose.bones:
        for c in list(b.constraints):
            b.constraints.remove(c)
    for act in actions:
        for fc in list(getattr(act, "fcurves", [])):
            if any(h in fc.data_path for h in ("ik_foot", "ik_hand", "pole_", "foot_aim")):
                act.fcurves.remove(fc)


# ---------------------------------------------------------------- previews
def preview(rig, body, actions):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.device = "CPU"
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 2
    scene.render.resolution_x, scene.render.resolution_y = 640, 480
    scene.view_settings.view_transform = "Standard"  # flat colours, as the engine shows them
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.62, 0.78, 0.95, 1)
    scene.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    target = Vector((0, 0, 0.95))

    def shoot(name, eye, action=None, frame=1):
        cam.location = eye
        cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
        rig.animation_data_create()
        rig.animation_data.action = action
        scene.frame_set(frame)
        scene.render.filepath = os.path.join(OUT, name + ".png")
        bpy.ops.render.render(write_still=True)

    shoot("preview-front34", P(-2.6, 3.0, 1.9))
    shoot("preview-side", P(-4.0, 0.0, 1.1))
    shoot("preview-back34", P(2.4, -3.2, 2.0))
    ride, throw_left, throw_right = actions
    for f in (1, 7, 13, 19):
        shoot("preview-ride-%02d" % f, P(-4.0, 0.0, 1.1), ride, f)
    # Each throw seen from the front, the throwing side nearer the camera.
    for f in (4, 7, 9, 11):
        shoot("preview-throwleft-%02d" % f, P(2.6, 3.0, 1.7), throw_left, f)
        shoot("preview-throwright-%02d" % f, P(-2.6, 3.0, 1.7), throw_right, f)
    shoot("preview-head-back", P(1.2, -1.6, 2.1))


# ---------------------------------------------------------------- main
def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start, scene.frame_end = 1, LOOP + 1
    os.makedirs(OUT, exist_ok=True)
    pose = rest_pose()
    build_bike()
    build_kid(pose)
    rig = build_armature(pose)
    body = skin(rig, "KidBike")
    ride = bake(rig, "Ride")
    throw_left = bake(rig, "ThrowLeft", "L")
    throw_right = bake(rig, "ThrowRight", "R")
    strip_helpers(rig, (ride, throw_left, throw_right))
    if PREVIEW:
        preview(rig, body, (ride, throw_left, throw_right))
    export_rigged(os.path.join(OUT, "KidBike.glb"), rig, body)
    print("KidBike written to", OUT)


main()
