"""The figure Masquerade's guests share (taken from Lamplight's, which its thief and guards share):
the joints of a standing person, scaled to a height, the armature over them (root, hips, spine,
head; per side upper arm, forearm, hand, thigh, shin, foot), and gaits keyed as looping clips.
guest.py models each costume over these joints and picks its gaits; every costume has the same
rig, so one animation drives them all.

Every rotation is set from the bone's own direction (a swing turns the bone toward or away from
forward), as PaperKid's pedestrian does. Side +1 is the figure's left (+X; it faces -Y, which glTF
exports as the engine's +Z).
"""
import bpy, math
from mathutils import Vector, Quaternion
from kit3d import P


class Body:
    """A standing figure's joints at rest (arms a little out), `scale` times the thief's 1.7 m."""

    def __init__(self, scale=1.0):
        self.scale = scale
        self.hip_y = 0.90 * scale

    def _p(self, x, fwd, up):
        return P(x * self.scale, fwd * self.scale, up * self.scale)

    def hip(self, side): return self._p(side * 0.10, 0, 0.90)
    def knee(self, side): return self._p(side * 0.105, 0.02, 0.50)
    def ankle(self, side): return self._p(side * 0.11, 0, 0.09)
    def toe(self, side): return self._p(side * 0.11, 0.17, 0.04)
    def shoulder(self, side): return self._p(side * 0.20, 0, 1.38)
    def elbow(self, side): return self._p(side * 0.25, -0.02, 1.10)
    def hand(self, side): return self._p(side * 0.27, 0.03, 0.86)
    def neck(self): return self._p(0, 0, 1.45)
    def head(self): return self._p(0, 0.01, 1.60)

    def leg(self):
        """The thigh's and the shin's lengths."""
        return (self.hip(1) - self.knee(1)).length, (self.knee(1) - self.ankle(1)).length


def build_armature(body, name):
    arm = bpy.data.armatures.new(name)
    rig = bpy.data.objects.new(name, arm)
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

    s = body.scale
    bone("root", Vector((0, 0, 0)), Vector((0, 0, 0.2 * s)))
    bone("hips", P(0, 0, body.hip_y - 0.05 * s), P(0, 0, body.hip_y + 0.08 * s), "root")
    bone("spine", P(0, 0, body.hip_y + 0.08 * s), body.neck(), "hips")
    bone("head", body.neck(), body.neck() + Vector((0, 0, 0.32 * s)), "spine")
    for side in (-1, 1):
        x = "L" if side > 0 else "R"
        bone("upperarm_" + x, body.shoulder(side), body.elbow(side), "spine")
        bone("forearm_" + x, body.elbow(side), body.hand(side), "upperarm_" + x, True)
        bone("hand_" + x, body.hand(side), body.hand(side) + P(0, 0, -0.08 * s), "forearm_" + x, True)
        bone("thigh_" + x, body.hip(side), body.knee(side), "hips")
        bone("shin_" + x, body.knee(side), body.ankle(side), "thigh_" + x, True)
        bone("foot_" + x, body.ankle(side), body.toe(side), "shin_" + x, True)
    bpy.ops.object.mode_set(mode="OBJECT")
    for b in rig.pose.bones:
        b.rotation_mode = "QUATERNION"
    return rig


def swing_quat(rig, bone_name, degrees):
    """A turn of the bone in the thief's forward plane: positive turns it toward forward (Blender's
    -Y), about the axis across the body; given in the bone's own frame."""
    bone = rig.data.bones[bone_name]
    rest = bone.matrix_local.to_3x3()
    direction = rest.col[1].normalized()  # a bone's Y runs head to tail
    axis = direction.cross(Vector((0, -1, 0)))
    if axis.length < 1e-6:  # a bone already pointing forward (the foot): turn about X
        axis = Vector((1, 0, 0)) if direction.y < 0 else Vector((-1, 0, 0))
    return Quaternion(rest.inverted() @ axis.normalized(), math.radians(degrees))


# A gait: how far the arms swing, how deep the crouch, how much the body leans. A standing gait
# (no `speed`) keeps the feet under the hips: thighs forward by `thigh0`, knees bent by `knee0`,
# the hips dropped by what that takes off the leg's height, and `bob` and `breath` move the body.
# A moving gait (`speed`, m/s) places the feet instead (see planted): each is on the ground for
# `stance` of the cycle, gliding back at exactly the speed the character moves, so it does not
# slide, then lifts `lift` metres as it swings forward to its next step; the legs reach those
# feet, and the hips rise and fall once a step, smoothly, within what the legs allow (thigh0 and
# knee0 still cap them, a crouch; see hip_wave). A character's gaits are a dict of these
# (guest.py's GAITS). Optional: `holdLeft` (upper arm, elbow degrees) holds the left arm still,
# `look` (degrees) turns the head side to side once a cycle, `gesture` (degrees) moves the right
# arm forward and bent as someone talking does, `arms` (upper arm, elbow degrees) lifts both arms
# forward and sways them against each other (a dance), and `sway` (metres) moves the hips from
# side to side once a cycle.


# How much of the bob the legs allow a moving gait's hips take: all of it reads as bouncing.
HIP_BOB = 0.5


def crouch_drop(body, thigh0, knee0):
    a, b = math.radians(thigh0), math.radians(thigh0 - knee0)
    l1, l2 = body.leg()
    return l1 + l2 - (l1 * math.cos(a) + l2 * math.cos(b))


def _rest_angle(top, bottom):
    """A leg bone's angle from straight down at rest, forward positive (radians)."""
    fwd = -(bottom.y - top.y)  # Blender's -Y is forward
    return math.atan2(fwd, top.z - bottom.z)


def leg_angles(body, forward, down):
    """The thigh's and the shin's angles from straight down (forward positive) that put the ankle
    `forward` ahead of the hip and `down` below it, the knee bending forward."""
    l1, l2 = body.leg()
    d = max(1e-4, min(math.hypot(forward, down), (l1 + l2) * 0.999))
    line = math.atan2(forward, down)
    clamp = lambda c: max(-1.0, min(1.0, c))
    at_hip = math.acos(clamp((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)))
    at_ankle = math.acos(clamp((l2 * l2 + d * d - l1 * l1) / (2 * l2 * d)))
    return line + at_hip, line - at_ankle


def planted(body, g, t, frames):
    """For a moving gait at time t (0..1 of the cycle): each leg's ankle (forward of the hip, its
    lift above the ground, on the ground or not) and the highest the hips can be with every leg
    reaching its foot. A foot strikes the ground a quarter cycle in (where the old sine stride put
    the leg furthest forward, so the arms keep their swing against it), the right half a cycle
    after the left."""
    fps = bpy.context.scene.render.fps
    seconds = frames / fps
    stance = g["stance"]
    half = g["speed"] * seconds * stance / 2  # a planted foot sweeps the body's travel
    reach = 0.985 * sum(body.leg())            # how far a leg reaches, the knee not locked
    ankle_z = body.ankle(1).z
    legs = {}
    for side, offset in ((1, 0.0), (-1, 0.5)):
        u = (t - 0.25 + offset) % 1.0
        if u < stance:
            w = u / stance
            legs[side] = (half - 2 * half * w, 0.0, True)
        else:
            w = (u - stance) / (1 - stance)
            ease = w * w * (3 - 2 * w)
            legs[side] = (-half + 2 * half * ease, g["lift"] * body.scale * math.sin(math.pi * w), False)
    highest = body.hip_y - crouch_drop(body, g["thigh0"], g["knee0"])  # thigh0 and knee0's cap
    for forward, lift, down in legs.values():
        highest = min(highest, ankle_z + lift + math.sqrt(max(0.0, reach * reach - forward * forward)))
    return legs, highest


def hip_wave(body, g):
    """A moving gait's hips over the cycle: one smooth rise and fall a step, under what the legs
    allow at every moment (planted's highest, which kinks where a foot lands or lifts). The wave
    is that limit's own step-rate harmonic, HIP_BOB of it, lowered until it fits beneath."""
    n = 240
    limit = [planted(body, g, i / n, g["frames"])[1] for i in range(n)]
    c = sum(v * math.cos(4 * math.pi * i / n) for i, v in enumerate(limit)) * 2 / n
    s = sum(v * math.sin(4 * math.pi * i / n) for i, v in enumerate(limit)) * 2 / n
    wave = lambda t: HIP_BOB * (c * math.cos(4 * math.pi * t) + s * math.sin(4 * math.pi * t))
    base = min(v - wave(i / n) for i, v in enumerate(limit))
    return lambda t: base + wave(t)


def clip(rig, body, name, g):
    action = bpy.data.actions.new(name)
    rig.animation_data.action = action
    pb = rig.pose.bones
    drop = crouch_drop(body, g["thigh0"], g["knee0"])
    moving = g.get("speed", 0.0) > 0.0
    hips = hip_wave(body, g) if moving else None
    thigh_rest = _rest_angle(body.hip(1), body.knee(1))
    shin_rest = _rest_angle(body.knee(1), body.ankle(1))
    for f in range(1, g["frames"] + 2):
        t = (f - 1) / g["frames"]
        phase = 2 * math.pi * t
        if moving:
            legs = planted(body, g, t, g["frames"])[0]
            hip_height = hips(t)
        for side, offset in ((1, 0.0), (-1, math.pi)):
            s = "L" if side > 0 else "R"
            p = phase + offset
            if moving:
                forward, lift, _ = legs[side]
                thigh_abs, shin_abs = leg_angles(body, forward, hip_height - body.ankle(1).z - lift)
                thigh = math.degrees(thigh_abs - thigh_rest)
                knee = -math.degrees((shin_abs - shin_rest) - (thigh_abs - thigh_rest))
            else:
                thigh = g["thigh0"] + g["thigh"] * math.sin(p)
                knee = g["knee0"] + g["knee"] * max(0.0, math.cos(p))
            pb["thigh_" + s].rotation_quaternion = swing_quat(rig, "thigh_" + s, thigh)
            pb["shin_" + s].rotation_quaternion = swing_quat(rig, "shin_" + s, -knee)
            # The foot level: every leg bone turns about the same axis across the body, so the foot
            # sits at thigh - knee + its own turn, and knee - thigh takes it back to level.
            pb["foot_" + s].rotation_quaternion = swing_quat(rig, "foot_" + s, knee - thigh)
            arm = -g["arm"] * math.sin(p) + g["thigh0"] * 0.4  # against the leg; forward in a crouch
            elbow = g["elbow"]
            if side > 0 and g.get("holdLeft"):  # the left arm held still
                arm, elbow = g["holdLeft"]
            if side < 0 and g.get("gesture"):  # the right arm talks: up, bent, moving with the words
                arm = 30 + g["gesture"] * math.sin(2 * phase)
                elbow = 70 + g["gesture"] * 0.8 * math.sin(3 * phase + 1.0)
            if g.get("arms"):  # both arms lifted, swaying against each other with the music
                up, bend = g["arms"]
                arm = up + 12 * math.sin(phase + (0 if side > 0 else math.pi))
                elbow = bend
            pb["upperarm_" + s].rotation_quaternion = swing_quat(rig, "upperarm_" + s, arm)
            pb["forearm_" + s].rotation_quaternion = swing_quat(rig, "forearm_" + s, elbow)
            for bone in ("thigh_", "shin_", "foot_", "upperarm_", "forearm_"):
                pb[bone + s].keyframe_insert("rotation_quaternion", frame=f)
        breath = 0.006 * math.sin(phase) if g["breath"] else 0.0
        # Hips' local Y is up: a moving gait's hips where the planted legs hold them; a standing
        # one's the crouch's drop and the bob.
        if moving:
            rise = hip_height - body.hip_y
        else:
            rise = -drop + g["bob"] * (1 - math.cos(2 * phase)) / 2
        sway = g.get("sway", 0.0) * body.scale * math.sin(phase)  # the hips' local X is across the body
        pb["hips"].location = Vector((sway, rise + breath, 0))
        pb["hips"].keyframe_insert("location", frame=f)
        pb["spine"].rotation_quaternion = swing_quat(rig, "spine", g["lean"] + (1.5 * math.sin(phase) if g["breath"] else 0))
        pb["spine"].keyframe_insert("rotation_quaternion", frame=f)
        head = swing_quat(rig, "head", -g["lean"] * 0.7)  # eyes stay ahead
        if g.get("look"):  # looking from side to side (the head bone runs up: its Y is the turn)
            head = head @ Quaternion(Vector((0, 1, 0)), math.radians(g["look"] * math.sin(phase)))
        pb["head"].rotation_quaternion = head
        pb["head"].keyframe_insert("rotation_quaternion", frame=f)
    action.use_fake_user = True
    return action


def rest(rig):
    """Back to rest: unkeyed, the pose keeps the last clip's (a preview of the rest pose)."""
    rig.animation_data.action = None
    for b in rig.pose.bones:
        b.rotation_quaternion = Quaternion()
        b.location = Vector()
