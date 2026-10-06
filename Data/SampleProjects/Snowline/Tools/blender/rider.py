"""Snowline's rider: a snowboarder on the board, modelled, rigged and animated in Blender.

    blender --background --factory-startup --python rider.py -- <out dir> [preview]

Writes <out dir>/RiderModel.glb (one skinned mesh, its armature and its clips) and, with
`preview`, PNG renders. The origin is the snow under the middle of the board; the board runs along
the engine's +Z (Blender's -Y), the direction of travel. The rider stands sideways on it, left foot
forward (regular), facing the board's right side (the engine's -X, Blender's -X), head turned to
look down the board.

The rig: the board on its own bone; the legs reach the bindings and the hands their targets
through IK, baked to plain keys, so the engine plays ordinary bone tracks. Each clip keys only a
few drivers: the lean (the rider and board rolled onto an edge, about the board's length), the
hips (the crouch, and the shift toward the toes or heels), the spine's bend and the hands.

- Ride: two seconds, looping: the neutral stance, a slight bob.
- CarveToe, CarveHeel: one second, looping: on the toe edge (leaning over the toes) and the heel
  edge (sitting back over the heels). The animation graph blends them with Ride by the lean.
- Tuck, TuckToe, TuckHeel: one second, looping: low and compact, hands by the knees; square over
  the board, and leaning onto the toe edge or the heel edge (the graph blends them by the lean, as
  it does the carves, so a tucked rider leans into the turn it makes).
- Air: one second, looping: knees drawn up, arms out for balance.
- Grab: one second, looping: crouched in the air, the front hand on the board's toe edge.
- Land: half a second: the knees soak up the landing and rise back to Ride's stance.
- Crash: one and a half seconds: caught on the heel edge, thrown down onto the snow.
Every clip but Crash starts and ends in Ride's stance, so switching never snaps.
"""
import bpy, math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball, two_bone, turn_quat

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "rider-out")
PREVIEW = "preview" in ARGS
FPS = 24

kit3d.PALETTE.update({
    "Jacket": (0.95, 0.42, 0.08), "JacketDark": (0.70, 0.26, 0.05), "Pants": (0.10, 0.16, 0.30),
    "Helmet": (0.92, 0.93, 0.95), "Strap": (0.08, 0.08, 0.10), "Lens": (0.95, 0.65, 0.10),
    "Glove": (0.07, 0.07, 0.08), "Boot": (0.22, 0.22, 0.25), "Skin": (0.80, 0.56, 0.42),
    "Deck": (0.10, 0.62, 0.62), "DeckStripe": (0.95, 0.90, 0.30), "Base": (0.10, 0.10, 0.12),
    "Binding": (0.12, 0.12, 0.14),
})

# ---------------------------------------------------------------- the layout (P = x, forward, up)
BOARD_TOP = 0.05
STANCE = 0.27                       # each binding's distance from the board's middle
HIP_Y = 0.88                        # the hips' height in Ride's stance (knees soft)
FRONT, BACK = 1, -1                 # the left foot leads (regular)
HIP = lambda end: P(0, end * 0.11, HIP_Y)
ANKLE = lambda end: P(0, end * STANCE, BOARD_TOP + 0.09)
TOE = lambda end: P(-0.14, end * STANCE, BOARD_TOP + 0.05)  # the toes point the way the rider faces (-X)
SHOULDER = lambda end: P(0, end * 0.21, 1.36)
NECK = P(0, 0, 1.43)
HEAD = P(0, 0.02, 1.60)
THIGH, SHIN = 0.42, 0.44
UPPER_ARM, FOREARM = 0.27, 0.27
REST_HAND = lambda end: P(-0.12, end * 0.46, 1.02)  # arms a little out, hands low, for balance
SIDE = {FRONT: "L", BACK: "R"}


def rest_pose():
    pose = {}
    for end in (FRONT, BACK):
        s = SIDE[end]
        hip, ankle = HIP(end), ANKLE(end)
        pose["hip" + s], pose["ankle" + s], pose["toe" + s] = hip, ankle, TOE(end)
        # Knees bend toward the toes (where the rider faces) and a little apart.
        pose["knee" + s] = two_bone(hip, ankle, THIGH, SHIN, P(-1, end * 0.25, 0))
        sh, hand = SHOULDER(end), REST_HAND(end)
        pose["shoulder" + s], pose["hand" + s] = sh, hand
        pose["elbow" + s] = two_bone(sh, hand, UPPER_ARM, FOREARM, P(0.3, end * 0.5, -0.6))
    return pose


# ---------------------------------------------------------------- the model
def build_board():
    box("Deck", (0.27, 1.20, 0.03), P(0, 0, BOARD_TOP - 0.015), "Deck", "board", bevel=0.012)
    box("Base", (0.27, 1.20, 0.012), P(0, 0, 0.006), "Base", "board", bevel=0.005)
    for end in (1, -1):  # the nose and tail, kicked up, rounded off
        box("Kick", (0.27, 0.22, 0.03), P(0, end * 0.68, BOARD_TOP + 0.01), "Deck", "board", bevel=0.012,
            tilt=-end * 18)
        box("Stripe", (0.06, 0.9, 0.006), P(0, 0, BOARD_TOP + 0.002), "DeckStripe", "board")
    for end in (FRONT, BACK):
        a = ANKLE(end)
        box("Binding", (0.24, 0.17, 0.05), Vector((a.x - 0.03, a.y, BOARD_TOP + 0.025)), "Binding", "board",
            bevel=0.01)
        box("Highback", (0.04, 0.16, 0.18), Vector((a.x + 0.10, a.y, BOARD_TOP + 0.11)), "Binding", "board",
            bevel=0.01, tilt=0)


def limb(name, a, b, radius, mat, bone, radius2=None):
    tube(name, a, b, radius, mat, bone, 8, radius2)
    ball(name + "Joint", b, radius2 if radius2 else radius, mat, bone, segments=(10, 8))


def build_rider(pose):
    box("Pelvis", (0.24, 0.32, 0.18), P(0, 0, HIP_Y + 0.02), "Pants", "hips", bevel=0.05)
    # The jacket: square to the board's side, shoulders along the board.
    box("Jacket", (0.27, 0.42, 0.50), P(0, 0, 1.15), "Jacket", "spine", bevel=0.08)
    box("JacketHem", (0.28, 0.43, 0.06), P(0, 0, 0.93), "JacketDark", "spine", bevel=0.02)
    box("Zip", (0.02, 0.05, 0.40), P(-0.14, 0, 1.17), "JacketDark", "spine")
    tube("Collar", NECK - Vector((0, 0, 0.06)), NECK + Vector((0, 0, 0.04)), 0.08, "JacketDark", "spine", 12)
    # The head faces down the board (the way the rider is going), in a helmet and goggles.
    ball("Head", HEAD, 0.17, "Skin", "head", scale=(0.95, 1.0, 1.05), segments=(28, 16))
    ball("Helmet", HEAD + Vector((0, 0, 0.03)), 0.19, "Helmet", "head", scale=(1.0, 1.05, 0.95), segments=(28, 16),
         cut_below=0.12)
    box("GoggleStrap", (0.40, 0.03, 0.05), HEAD + P(0, 0.02, 0.05), "Strap", "head")
    box("Goggles", (0.22, 0.06, 0.08), HEAD + P(0, 0.17, 0.04), "Lens", "head", bevel=0.02)
    for end in (FRONT, BACK):
        s = SIDE[end]
        sh, el, ha = pose["shoulder" + s], pose["elbow" + s], pose["hand" + s]
        ball("Shoulder" + s, sh, 0.085, "Jacket", "upperarm_" + s, segments=(14, 10))
        limb("UpperArm" + s, sh, el, 0.07, "Jacket", "upperarm_" + s, 0.06)
        limb("Forearm" + s, el, ha, 0.06, "Jacket", "forearm_" + s, 0.05)
        ball("Glove" + s, ha, 0.06, "Glove", "forearm_" + s, segments=(12, 8))
        hp, kn, an, toe = pose["hip" + s], pose["knee" + s], pose["ankle" + s], pose["toe" + s]
        limb("Thigh" + s, hp, kn, 0.09, "Pants", "thigh_" + s, 0.075)
        limb("Shin" + s, kn, an, 0.075, "Pants", "shin_" + s, 0.07)
        mid = (an + toe) / 2
        box("Boot" + s, (0.30, 0.13, 0.12), Vector((mid.x + 0.02, an.y, BOARD_TOP + 0.07)), "Boot", "foot_" + s,
            bevel=0.03)


# ---------------------------------------------------------------- the armature
def build_armature(pose):
    arm = bpy.data.armatures.new("RiderRig")
    rig = bpy.data.objects.new("RiderRig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones

    def bone(name, head, tail, parent=None, deform=True):
        b = eb.new(name)
        b.head, b.tail, b.roll = head, tail, 0.0
        b.use_deform = deform
        if parent:
            b.parent = eb[parent]
        return b

    up = Vector((0, 0, 0.12))
    bone("root", Vector((0, 0, 0)), Vector((0, 0, 0.2)))
    bone("board", P(0, 0, BOARD_TOP), P(0, 0, BOARD_TOP) + up, "root")
    bone("hips", P(0, 0, HIP_Y - 0.06), P(0, 0, HIP_Y + 0.08), "root")
    bone("spine", P(0, 0, HIP_Y + 0.08), NECK, "hips")
    bone("head", NECK, NECK + Vector((0, 0, 0.3)), "spine")
    for end in (FRONT, BACK):
        s = SIDE[end]
        a = ANKLE(end)
        # Not deforming: where each foot goes (its binding, riding the board), the way it points,
        # where each hand goes, and the poles the knees and elbows bend toward.
        bone("ik_foot_" + s, a, a + up, "board", False)
        bone("foot_aim_" + s, pose["ankle" + s], pose["toe" + s], "board", False)
        bone("ik_hand_" + s, REST_HAND(end), REST_HAND(end) + up, "root", False)
        bone("pole_knee_" + s, HIP(end) + P(-0.9, end * 0.3, -0.2), HIP(end) + P(-0.9, end * 0.3, -0.2) + up,
             "hips", False)
        # The elbows hang down and back, as relaxed arms do; reaching out along the board too, the
        # pole had them wing out sideways.
        bone("pole_elbow_" + s, SHOULDER(end) + P(0.5, end * 0.1, -0.8),
             SHOULDER(end) + P(0.5, end * 0.1, -0.8) + up, "spine", False)
        bone("upperarm_" + s, pose["shoulder" + s], pose["elbow" + s], "spine")
        bone("forearm_" + s, pose["elbow" + s], pose["hand" + s], "upperarm_" + s).use_connect = True
        bone("thigh_" + s, pose["hip" + s], pose["knee" + s], "hips")
        bone("shin_" + s, pose["knee" + s], pose["ankle" + s], "thigh_" + s).use_connect = True
        bone("foot_" + s, pose["ankle" + s], pose["toe" + s], "shin_" + s).use_connect = True
    bpy.ops.object.mode_set(mode="POSE")
    pb = rig.pose.bones
    for end in (FRONT, BACK):
        s = SIDE[end]
        ik = pb["shin_" + s].constraints.new("IK")
        ik.target, ik.subtarget = rig, "ik_foot_" + s
        ik.pole_target, ik.pole_subtarget = rig, "pole_knee_" + s
        # +90: the knee toward its pole, over the toes. At -90 the solve turned the chain half round
        # and every knee bent back toward the heels.
        ik.pole_angle = math.radians(90)
        ik.chain_count = 2
        cr = pb["foot_" + s].constraints.new("COPY_ROTATION")
        cr.target, cr.subtarget = rig, "foot_aim_" + s
        cr.mix_mode = "REPLACE"
        ik = pb["forearm_" + s].constraints.new("IK")
        ik.target, ik.subtarget = rig, "ik_hand_" + s
        ik.pole_target, ik.pole_subtarget = rig, "pole_elbow_" + s
        # The arms reach opposite ways along the board, so the pole angle that lays the front
        # elbow out toward the nose is the opposite one for the back elbow: one angle for both
        # folded the back arm's elbow in against the ribs, its forearm sticking out to the tail.
        ik.pole_angle = math.radians(90 if end == FRONT else -90)
        ik.chain_count = 2
    for b in pb:
        b.rotation_mode = "QUATERNION"
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


# ---------------------------------------------------------------- the clips
def bone_space(offset):
    """A rest-space offset in the local axes of a bone pointing up (+Z, no roll), as the root, hips
    and helper bones are laid out: its Y is up and its Z is Blender's -Y."""
    return Vector((offset.x, offset.z, -offset.y))


TRAVEL_AXIS = (0, -1, 0)   # the board's length, nose first (Blender -Y)
FACING_AXIS = (-1, 0, 0)   # the way the rider faces (the toes)
UP_AXIS = (0, 0, 1)

# A pose: lean (degrees onto the toe edge, negative the heel edge), crouch (m the hips drop), shift
# (m the hips move toward the heels, negative the toes), bend (degrees the spine bends toward the
# toes), each hand's target offset from its rest, and drop (m the whole rider sinks: Crash).
#
# Taken from riding photos: the knees soft and over the toes, the hips centred between the feet,
# the back upright (bending at the waist is the beginner's fault), the head down the board, the
# front hand leading over the nose and the back hand low by the back hip. On the heel edge the rider
# sits back with the arms reaching forward; on the toe edge the shins press toward the snow and the
# back stays upright.
#
# The hands stay well out from the body (about four fifths of the arm's reach from the shoulder):
# a hand drawn in by the hip or up by the shoulder folds the arm hard at the elbow.
STANCE_POSE = dict(lean=0.0, crouch=0.06, shift=0.0, bend=6.0, front=P(-0.06, 0.10, 0.0), back=P(0.0, 0.06, -0.08),
                   drop=0.0, roll=0.0)


def pose_with(**changes):
    p = dict(STANCE_POSE)
    p.update(changes)
    return p


POSES = {
    "Ride": pose_with(),
    "CarveToe": pose_with(lean=24.0, crouch=0.14, shift=-0.07, bend=8.0, front=P(-0.18, 0.10, -0.06),
                          back=P(-0.12, 0.02, -0.08)),
    "CarveHeel": pose_with(lean=-22.0, crouch=0.20, shift=0.08, bend=14.0, front=P(-0.22, 0.06, -0.06),
                           back=P(-0.20, 0.06, -0.08)),
    "Tuck": pose_with(crouch=0.30, shift=0.0, bend=22.0, front=P(-0.12, -0.14, -0.30), back=P(-0.10, 0.18, -0.30)),
    "TuckToe": pose_with(lean=20.0, crouch=0.30, shift=-0.05, bend=20.0, front=P(-0.16, -0.12, -0.34),
                         back=P(-0.14, 0.16, -0.34)),
    "TuckHeel": pose_with(lean=-18.0, crouch=0.32, shift=0.07, bend=26.0, front=P(-0.18, -0.10, -0.24),
                          back=P(-0.16, 0.20, -0.24)),
    "Air": pose_with(crouch=0.24, bend=10.0, front=P(-0.04, 0.16, 0.10), back=P(-0.04, -0.16, 0.08)),
    # An indy: the knees drawn up, the back hand down to the toe edge between the bindings, the
    # front arm out over the nose for balance.
    "Grab": pose_with(crouch=0.34, shift=-0.02, bend=34.0, front=P(-0.12, 0.26, 0.14), back=P(-0.02, 0.41, -0.86)),
    "Land": pose_with(crouch=0.30, bend=18.0, front=P(-0.10, 0.12, -0.10), back=P(-0.06, -0.08, -0.14)),
    "Crash": pose_with(lean=-70.0, crouch=0.25, shift=0.20, bend=-10.0, front=P(0.35, 0.15, 0.60),
                       back=P(0.30, -0.20, 0.55), drop=0.45),
}


def mix(a, b, k):
    out = {}
    for key in a:
        out[key] = a[key] + (b[key] - a[key]) * k if not isinstance(a[key], Vector) else a[key].lerp(b[key], k)
    return out


def smooth(t):
    return t * t * (3 - 2 * t)


# Each clip: its frames, and the pose at a frame (Ride's stance at both ends, but for the loops of
# a held pose and Crash).
def clip_pose(name, t):
    """The pose at t (0..1) through the clip."""
    ride = POSES["Ride"]
    if name == "Ride":
        p = dict(ride)
        p["crouch"] = 0.02 * (1 - math.cos(2 * math.pi * t)) / 2  # a slight bob
        return p
    if name in ("CarveToe", "CarveHeel", "Tuck", "TuckToe", "TuckHeel", "Air", "Grab"):
        # Held: the pose itself, with a breath of movement so it does not freeze.
        p = dict(POSES[name])
        p["crouch"] += 0.015 * math.sin(2 * math.pi * t)
        return p
    if name == "Land":
        k = smooth(min(1.0, t / 0.25)) if t < 0.25 else smooth(1.0 - (t - 0.25) / 0.75)
        return mix(ride, POSES["Land"], k)
    if name == "Crash":
        k = smooth(min(1.0, t / 0.45))
        return mix(ride, POSES["Crash"], k)
    raise KeyError(name)


CLIPS = {"Ride": 2.0, "CarveToe": 1.0, "CarveHeel": 1.0, "Tuck": 1.0, "TuckToe": 1.0, "TuckHeel": 1.0, "Air": 1.0,
         "Grab": 1.0, "Land": 0.5, "Crash": 1.5}


def key_drive(rig, name, frames):
    pb = rig.pose.bones
    for f in range(1, frames + 2):
        p = clip_pose(name, (f - 1) / frames)
        # The lean rolls the whole rider and board about the board's length; Crash also sinks it.
        pb["root"].rotation_quaternion = turn_quat(rig, "root", TRAVEL_AXIS, p["lean"])
        pb["root"].location = bone_space(P(0, 0, -p["drop"]))
        pb["hips"].location = bone_space(P(p["shift"], 0, -p["crouch"]))
        pb["spine"].rotation_quaternion = turn_quat(rig, "spine", TRAVEL_AXIS, p["bend"])
        pb["ik_hand_L"].location = bone_space(p["front"])
        pb["ik_hand_R"].location = bone_space(p["back"])
        for b, path in (("root", "rotation_quaternion"), ("root", "location"), ("hips", "location"),
                        ("spine", "rotation_quaternion"), ("ik_hand_L", "location"), ("ik_hand_R", "location")):
            pb[b].keyframe_insert(path, frame=f)


def bake(rig, name):
    frames = int(round(CLIPS[name] * FPS))
    rig.animation_data_create()
    drive = bpy.data.actions.new(name + "Drive")
    rig.animation_data.action = drive
    key_drive(rig, name, frames)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.nla.bake(frame_start=1, frame_end=frames + 1, only_selected=False, visual_keying=True,
                     clear_constraints=False, use_current_action=False, bake_types={"POSE"})
    baked = rig.animation_data.action
    baked.name = name
    baked.use_fake_user = True
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.animation_data.action = None
    for b in rig.pose.bones:
        b.location = (0, 0, 0)
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


def main():
    kit3d.reset()
    bpy.context.scene.render.fps = FPS
    os.makedirs(OUT, exist_ok=True)
    pose = rest_pose()
    build_board()
    build_rider(pose)
    rig = build_armature(pose)
    body = kit3d.skin(rig, "RiderModel")
    actions = [bake(rig, name) for name in CLIPS]
    strip_helpers(rig, actions)
    if PREVIEW:
        cam = kit3d.studio()
        target = Vector((0, 0, 0.8))
        for act in actions:
            rig.animation_data_create()
            rig.animation_data.action = act
            bpy.context.scene.frame_set(int(round(CLIPS[act.name] * FPS * 0.5)) + 1)
            # From in front of the rider (the way it faces) and a little down the board.
            kit3d.shoot(cam, os.path.join(OUT, "preview-%s.png" % act.name), P(-3.2, 1.6, 1.4), target)
        rig.animation_data.action = None
    kit3d.export_rigged(os.path.join(OUT, "RiderModel.glb"), rig, body)
    print("RiderModel written to", OUT)


main()
