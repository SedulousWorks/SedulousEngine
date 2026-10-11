"""The figure the Lamplight characters share (the thief, the guards): the joints of a standing
person, scaled to a height, the armature over them (root, hips, spine, head; per side upper arm,
forearm, hand, thigh, shin, foot), and gaits keyed as looping clips. Each character script models
its own look over these joints (thief.py, guard.py) and picks its gaits.

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


# A gait: how far the legs and arms swing, how deep the crouch, how much the body leans and bobs.
# The crouch's numbers keep the feet under the hips: thighs forward by `thigh0`, knees bent by
# `knee0`, the hips dropped by what that takes off the leg's height. A character's gaits are a
# dict of these (thief.py's GAITS). Optional: `holdLeft` (upper arm, elbow degrees) holds the left
# arm still (a guard's lantern), and `look` (degrees) turns the head side to side once a cycle.


def crouch_drop(body, thigh0, knee0):
    a, b = math.radians(thigh0), math.radians(thigh0 - knee0)
    l1, l2 = body.leg()
    return l1 + l2 - (l1 * math.cos(a) + l2 * math.cos(b))


def clip(rig, body, name, g):
    action = bpy.data.actions.new(name)
    rig.animation_data.action = action
    pb = rig.pose.bones
    drop = crouch_drop(body, g["thigh0"], g["knee0"])
    for f in range(1, g["frames"] + 2):
        t = (f - 1) / g["frames"]
        phase = 2 * math.pi * t
        for side, offset in ((1, 0.0), (-1, math.pi)):
            s = "L" if side > 0 else "R"
            p = phase + offset
            thigh = g["thigh0"] + g["thigh"] * math.sin(p)
            knee = g["knee0"] + g["knee"] * max(0.0, math.cos(p))
            pb["thigh_" + s].rotation_quaternion = swing_quat(rig, "thigh_" + s, thigh)
            pb["shin_" + s].rotation_quaternion = swing_quat(rig, "shin_" + s, -knee)
            # The foot level: every leg bone turns about the same axis across the body, so the foot
            # sits at thigh - knee + its own turn, and knee - thigh takes it back to level.
            pb["foot_" + s].rotation_quaternion = swing_quat(rig, "foot_" + s, knee - thigh)
            arm = -g["arm"] * math.sin(p) + g["thigh0"] * 0.4  # against the leg; forward in a crouch
            elbow = g["elbow"]
            if side > 0 and g.get("holdLeft"):  # the left arm held still (a guard's lantern)
                arm, elbow = g["holdLeft"]
            pb["upperarm_" + s].rotation_quaternion = swing_quat(rig, "upperarm_" + s, arm)
            pb["forearm_" + s].rotation_quaternion = swing_quat(rig, "forearm_" + s, elbow)
            for bone in ("thigh_", "shin_", "foot_", "upperarm_", "forearm_"):
                pb[bone + s].keyframe_insert("rotation_quaternion", frame=f)
        breath = 0.006 * math.sin(phase) if g["breath"] else 0.0
        # Hips' local Y is up: the crouch's drop, then the bob over each planted leg (twice a cycle).
        pb["hips"].location = Vector((0, -drop + g["bob"] * (1 - math.cos(2 * phase)) / 2 + breath, 0))
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
