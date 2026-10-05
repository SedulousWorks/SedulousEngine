"""PaperKid's animals: a dog and a cat for the lawns, modelled, rigged and animated in Blender.

    blender --background --factory-startup --python animals.py -- <out dir> [preview] [Dog|Cat ...]

Writes <out dir>/<Name>Model.glb (one skinned mesh, its armature and its clips) and, with `preview`,
PNG renders of each clip. Both are built by one four-legged builder from their proportions: the dog
a chunky little terrier with floppy ears, the cat smaller with pointed ears and a long tail. They
stand on the ground at their origin, facing the engine's +Z.

Every clip starts and ends in the same standing pose, so Pet.as can switch from one to the next
without a snap:
- Walk: one second, a trot (the diagonal legs together), the root travelling one stride forward:
  the engine extracts that as root motion (horizontal), so the clip itself carries the animal and
  Pet.as only steers it and sets its pace.
- Idle: two seconds, looping: the dog wags and looks about, the cat sways its tail.
- Sit: four seconds: down onto the haunches, a look round, back up.
- LieDown: five seconds: down on the lawn, the head resting, back up.
- Sniff (the dog) or Groom (the cat): three seconds, the nose to the grass or a paw to the face.
"""
import bpy, math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball, turn_quat, PITCH_AXIS, YAW_AXIS, ROLL_AXIS

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "animals-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]
FPS = 24

# The two animals, by their proportions and colours.
SPECS = {
    "Dog": dict(length=0.62, height=0.40, width=0.24, body_depth=0.22, leg=0.33, head=0.13, snout=0.11,
                neck=0.14, tail=0.22, ears="floppy", stride=0.55,
                colours={"Coat": (0.45, 0.26, 0.12), "Belly": (0.90, 0.82, 0.66), "Nose": (0.06, 0.05, 0.05),
                         "Eye": (0.06, 0.05, 0.05), "Ear": (0.26, 0.14, 0.07), "Collar": (0.80, 0.12, 0.12)},
                action="Sniff"),
    "Cat": dict(length=0.40, height=0.24, width=0.15, body_depth=0.14, leg=0.21, head=0.085, snout=0.04,
                neck=0.08, tail=0.32, ears="pointed", stride=0.32,
                colours={"Coat": (0.30, 0.30, 0.32), "Belly": (0.85, 0.85, 0.82), "Nose": (0.80, 0.45, 0.45),
                         "Eye": (0.55, 0.65, 0.15), "Ear": (0.30, 0.30, 0.32), "Collar": (0.15, 0.45, 0.80)},
                action="Groom"),
}


class Body:
    """Where an animal's joints are at rest, from its spec."""

    def __init__(self, s):
        self.s = s
        L, H, W = s["length"], s["height"], s["width"]
        self.hips = P(0, -L / 2, H)
        self.shoulders = P(0, L / 2, H)
        self.head = self.shoulders + P(0, s["neck"] * 0.7 + s["head"] * 0.4, s["neck"] + s["head"] * 0.5)
        self.legs = {}
        for key, fwd, side in (("FL", L / 2 - 0.03, 1), ("FR", L / 2 - 0.03, -1),
                               ("BL", -L / 2 + 0.04, 1), ("BR", -L / 2 + 0.04, -1)):
            top = P(side * W * 0.32, fwd, H - s["body_depth"] * 0.25)
            foot = P(side * W * 0.34, fwd + (0.0 if key[0] == "F" else -0.02), 0.03)
            knee = (top + foot) / 2 + P(0, 0.0 if key[0] == "F" else -0.035, 0)
            self.legs[key] = (top, knee, foot)
        self.tail_root = self.hips + P(0, -0.02, 0.03)
        t = s["tail"]
        self.tail_mid = self.tail_root + P(0, -t * 0.45, t * 0.35)
        self.tail_tip = self.tail_mid + P(0, -t * 0.5, t * 0.25)


def build(b):
    s = b.s
    L, W, D = s["length"], s["width"], s["body_depth"]
    kit3d.PALETTE.update(s["colours"])
    # The body: a soft barrel from the hips to the shoulders, a lighter belly under it.
    mid = (b.hips + b.shoulders) / 2
    ball("Body", mid, 1.0, "Coat", "body", scale=(W / 2, L / 2 + 0.06, D / 2), segments=(24, 14))
    ball("Belly", mid - Vector((0, 0, D * 0.18)), 1.0, "Belly", "body", scale=(W / 2 * 0.8, L / 2 * 0.8, D / 2 * 0.7),
         segments=(20, 12))
    ball("Chest", b.shoulders + P(0, 0.02, -0.01), 1.0, "Coat", "body", scale=(W / 2 * 0.95, D * 0.5, D * 0.55),
         segments=(20, 12))
    ball("Haunch", b.hips + P(0, 0.02, 0), 1.0, "Coat", "body", scale=(W / 2 * 1.02, D * 0.5, D * 0.52),
         segments=(20, 12))
    # The neck and the head, the muzzle and nose, the eyes, the ears.
    tube("Neck", b.shoulders + P(0, 0.0, 0.02), b.head - P(0, 0.01, 0.02), s["neck"] * 0.42, "Coat", "neck", 12,
         s["neck"] * 0.36)
    h = s["head"]
    ball("Head", b.head, h, "Coat", "head", scale=(1.0, 1.05, 0.95), segments=(24, 14))
    muzzle = b.head + P(0, h * 0.8, -h * 0.25)
    ball("Muzzle", muzzle + P(0, s["snout"] * 0.3, 0), 1.0, "Belly", "head",
         scale=(h * 0.55, s["snout"] * 0.7 + h * 0.2, h * 0.45), segments=(16, 10))
    ball("Nose", muzzle + P(0, s["snout"] * 0.75 + h * 0.15, h * 0.12), h * 0.16, "Nose", "head", segments=(10, 8))
    for side in (-1, 1):
        ball("Eye", b.head + P(side * h * 0.42, h * 0.72, h * 0.25), h * 0.13, "Eye", "head", segments=(10, 8))
        if s["ears"] == "floppy":  # from the top of the head, hanging down past the cheeks
            ear = b.head + P(side * h * 1.0, -h * 0.1, -h * 0.2)
            ball("Ear", ear, 1.0, "Ear", "head", scale=(h * 0.14, h * 0.4, h * 0.7), segments=(12, 8))
        else:
            base = b.head + P(side * h * 0.5, -h * 0.05, h * 0.75)
            tube("Ear", base, base + P(side * h * 0.15, 0.0, h * 0.7), h * 0.32, "Ear", "head", 4, 0.004)
    # The collar at the neck.
    tube("Collar", b.shoulders + P(0, 0.02, 0.05), b.shoulders + P(0, 0.05, 0.08), s["neck"] * 0.45, "Collar",
         "neck", 14)
    # The legs: an upper and a lower part each, and a paw.
    for key, (top, knee, foot) in b.legs.items():
        r = W * (0.2 if s["ears"] == "floppy" else 0.17)
        tube("Upper" + key, top, knee, r, "Coat", "upper_" + key, 10, r * 0.85)
        ball("Knee" + key, knee, r * 0.85, "Coat", "lower_" + key, segments=(10, 8))
        tube("Lower" + key, knee, foot + P(0, 0, 0.02), r * 0.8, "Coat", "lower_" + key, 10, r * 0.7)
        ball("Paw" + key, foot + P(0, 0.02, 0), 1.0, "Belly", "lower_" + key, scale=(r * 1.0, r * 1.4, r * 0.7),
             segments=(12, 8))
    # The tail, in two parts.
    tr = W * (0.1 if s["ears"] == "floppy" else 0.08)
    tube("Tail1", b.tail_root, b.tail_mid, tr, "Coat", "tail1", 8, tr * 0.85)
    ball("TailJoint", b.tail_mid, tr * 0.85, "Coat", "tail2", segments=(8, 6))
    tube("Tail2", b.tail_mid, b.tail_tip, tr * 0.85, "Coat", "tail2", 8, tr * 0.5)
    ball("TailTip", b.tail_tip, tr * 0.5, "Belly" if s["ears"] == "floppy" else "Coat", "tail2", segments=(8, 6))


def build_armature(b, name):
    arm = bpy.data.armatures.new(name + "Rig")
    rig = bpy.data.objects.new(name + "Rig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones

    def bone(n, head, tail, parent=None, connect=False):
        e = eb.new(n)
        e.head, e.tail, e.roll = head, tail, 0.0
        if parent:
            e.parent = eb[parent]
            e.use_connect = connect
        return e

    bone("root", Vector((0, 0, 0)), Vector((0, 0, 0.1)))
    bone("body", b.hips, b.shoulders, "root")          # pointing forward: pitching it tips the body
    bone("neck", b.shoulders, b.head - P(0, b.s["head"] * 0.2, 0), "body")
    bone("head", b.head - P(0, b.s["head"] * 0.2, 0), b.head + P(0, b.s["head"], 0), "neck", True)
    bone("tail1", b.tail_root, b.tail_mid, "body")
    bone("tail2", b.tail_mid, b.tail_tip, "tail1", True)
    for key, (top, knee, foot) in b.legs.items():
        bone("upper_" + key, top, knee, "body")
        bone("lower_" + key, knee, foot, "upper_" + key, True)
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return rig


# ---------------------------------------------------------------- the clips
def smooth(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def ease_hold(t, down, up, length):
    """0 at rest, rising to 1 over `down` seconds, held, falling back to 0 over the last `up` seconds."""
    if t < down:
        return smooth(t / down)
    if t > length - up:
        return smooth((length - t) / up)
    return 1.0


class Keyer:
    """Poses set bone by bone for one frame, then keyed."""

    def __init__(self, rig):
        self.rig = rig
        self.pb = rig.pose.bones

    def pose(self, frame, turns, drop=0.0, lift_body=0.0, travel=0.0):
        """turns: bone -> [(axis, degrees), ...], applied in order; drop: the root lowered (m);
        travel: the root moved forward (m), the walk's root motion."""
        for pb in self.pb:
            pb.rotation_quaternion = (1, 0, 0, 0)
        for name, items in turns.items():
            q = None
            for axis, deg in items:
                t = turn_quat(self.rig, name, axis, deg)
                q = t if q is None else t @ q
            self.pb[name].rotation_quaternion = q
        # The root bone points up: its -Y is down, and its +Z is forward (the engine's +Z, as the
        # exported file shows).
        self.pb["root"].location = Vector((0, -drop, travel))
        self.pb["body"].location = Vector((0, 0, lift_body))
        for pb in self.pb:
            pb.keyframe_insert("rotation_quaternion", frame=frame)
            if pb.name in ("root", "body"):
                pb.keyframe_insert("location", frame=frame)


def clip(rig, name, seconds, posefn):
    rig.animation_data_create()
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    k = Keyer(rig)
    frames = int(round(seconds * FPS))
    for f in range(frames + 1):
        posed = posefn(f / FPS)
        turns, drop = posed[0], posed[1]
        travel = posed[2] if len(posed) > 2 else 0.0
        k.pose(f + 1, turns, drop, travel=travel)
    return action


def add(turns, bone, axis, deg):
    turns.setdefault(bone, []).append((axis, deg))


def walk_pose(t, b):
    p0 = 2 * math.pi * t  # one second, one full trot cycle
    turns = {}
    for key, offset in (("FL", 0.0), ("BR", 0.0), ("FR", math.pi), ("BL", math.pi)):
        p = p0 + offset
        add(turns, "upper_" + key, PITCH_AXIS, 24 * math.sin(p))
        bend = 34 * max(0.0, math.cos(p))
        add(turns, "lower_" + key, PITCH_AXIS, bend if key[0] == "F" else -bend)
    add(turns, "tail1", YAW_AXIS, 12 * math.sin(2 * p0))
    add(turns, "head", PITCH_AXIS, 3 * math.sin(2 * p0))
    return turns, 0.012 * (1 - math.cos(2 * p0)) / 2, b.s["stride"] * t


def idle_pose(t, b, wag):
    turns = {}
    if wag:  # the dog: a happy wag, three times a second, and a look about
        add(turns, "tail1", YAW_AXIS, 28 * math.sin(2 * math.pi * 3 * t))
        add(turns, "tail2", YAW_AXIS, 14 * math.sin(2 * math.pi * 3 * t - 0.6))
    else:    # the cat: a slow sway, the tip lagging
        add(turns, "tail1", YAW_AXIS, 18 * math.sin(math.pi * t))
        add(turns, "tail2", YAW_AXIS, 28 * math.sin(math.pi * t - 0.9))
        add(turns, "tail2", PITCH_AXIS, 15)
    add(turns, "head", YAW_AXIS, 14 * math.sin(math.pi * t))
    add(turns, "neck", PITCH_AXIS, 2 * math.sin(2 * math.pi * t))
    return turns, 0.0


def sit_pose(t, b):
    a = ease_hold(t, 0.6, 0.7, 4.0)
    turns = {}
    add(turns, "body", PITCH_AXIS, 30 * a)               # the front rises, pivoting at the hips
    for key in ("FL", "FR"):
        add(turns, "upper_" + key, PITCH_AXIS, -30 * a)  # the front legs stay upright
    for key in ("BL", "BR"):
        add(turns, "upper_" + key, PITCH_AXIS, 55 * a)   # the haunches fold under
        add(turns, "lower_" + key, PITCH_AXIS, -105 * a)
    look = smooth((t - 1.2) / 0.5) * smooth((3.0 - t) / 0.5) if 1.2 < t < 3.0 else 0.0
    add(turns, "neck", PITCH_AXIS, -20 * a)
    add(turns, "head", YAW_AXIS, 30 * math.sin(math.pi * (t - 1.2) / 1.8) * look)
    add(turns, "tail1", PITCH_AXIS, -40 * a)
    return turns, b.s["height"] * 0.42 * a


def lie_pose(t, b):
    a = ease_hold(t, 0.9, 0.9, 5.0)
    turns = {}
    for key in ("FL", "FR"):
        add(turns, "upper_" + key, PITCH_AXIS, 75 * a)   # the forelegs out in front
        add(turns, "lower_" + key, PITCH_AXIS, 10 * a)
    for key in ("BL", "BR"):
        add(turns, "upper_" + key, PITCH_AXIS, 60 * a)   # the hind legs tucked
        add(turns, "lower_" + key, PITCH_AXIS, -115 * a)
    rest = smooth((t - 1.4) / 0.6) * smooth((3.8 - t) / 0.6) if 1.4 < t < 3.8 else 0.0
    # The head low, resting just over the forepaws, not on the grass.
    add(turns, "neck", PITCH_AXIS, -6 * a - 4 * rest)
    add(turns, "head", PITCH_AXIS, 6 * a - 4 * rest)
    add(turns, "tail1", PITCH_AXIS, -35 * a)
    add(turns, "tail1", YAW_AXIS, 30 * a)
    return turns, (b.s["height"] - b.s["body_depth"] * 0.5 - 0.01) * a


def sniff_pose(t, b):
    a = ease_hold(t, 0.5, 0.5, 3.0)
    turns = {}
    add(turns, "neck", PITCH_AXIS, -50 * a)
    add(turns, "head", PITCH_AXIS, -25 * a)
    add(turns, "head", YAW_AXIS, 18 * math.sin(2 * math.pi * 0.8 * t) * a)
    for key in ("FL", "FR"):
        add(turns, "upper_" + key, PITCH_AXIS, -6 * a)
    add(turns, "tail1", YAW_AXIS, 20 * math.sin(2 * math.pi * 2 * t) * a)
    return turns, 0.0


def groom_pose(t, b):
    a = ease_hold(t, 0.6, 0.6, 3.0)
    turns = {}
    # Sitting a little, the left forepaw up to the face, the head turning to it and licking.
    add(turns, "body", PITCH_AXIS, 18 * a)
    for key in ("BL", "BR"):
        add(turns, "upper_" + key, PITCH_AXIS, 40 * a)
        add(turns, "lower_" + key, PITCH_AXIS, -80 * a)
    add(turns, "upper_FR", PITCH_AXIS, -18 * a)
    add(turns, "upper_FL", PITCH_AXIS, 45 * a)
    add(turns, "lower_FL", PITCH_AXIS, 70 * a)
    add(turns, "neck", PITCH_AXIS, -25 * a)
    add(turns, "head", YAW_AXIS, 25 * a)
    add(turns, "head", PITCH_AXIS, -12 * a + 8 * math.sin(2 * math.pi * 3 * t) * a)
    return turns, b.s["height"] * 0.22 * a


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(SPECS)):
        spec = SPECS[name]
        kit3d.reset()
        bpy.context.scene.render.fps = FPS
        b = Body(spec)
        build(b)
        rig = build_armature(b, name)
        body = kit3d.skin(rig, name + "Model")
        wag = spec["ears"] == "floppy"
        clips = {
            "Walk": clip(rig, "Walk", 1.0, lambda t: walk_pose(t, b)),
            "Idle": clip(rig, "Idle", 2.0, lambda t: idle_pose(t, b, wag)),
            "Sit": clip(rig, "Sit", 4.0, lambda t: sit_pose(t, b)),
            "LieDown": clip(rig, "LieDown", 5.0, lambda t: lie_pose(t, b)),
        }
        if spec["action"] == "Sniff":
            clips["Sniff"] = clip(rig, "Sniff", 3.0, lambda t: sniff_pose(t, b))
        else:
            clips["Groom"] = clip(rig, "Groom", 3.0, lambda t: groom_pose(t, b))
        if PREVIEW:
            cam = kit3d.studio((480, 360))
            size = spec["length"] * 2.8
            target = Vector((0, 0, spec["height"] * 0.7))
            shots = {"Walk": [0.0, 0.25], "Idle": [0.5], "Sit": [2.0], "LieDown": [2.5], "Sniff": [1.5], "Groom": [1.5]}
            for cname, action in clips.items():
                rig.animation_data.action = action
                for i, ts in enumerate(shots[cname]):
                    bpy.context.scene.frame_set(int(ts * FPS) + 1)
                    kit3d.shoot(cam, os.path.join(OUT, "%s-%s-%d.png" % (name, cname, i)),
                                P(-size * 1.1, size * 0.9, size * 0.55), target)
        kit3d.export_rigged(os.path.join(OUT, name + "Model.glb"), rig, body)
        print("written", name, list(clips))


main()
