"""Lamplight's thief: modelled, rigged and animated in Blender.

    blender --background --factory-startup --python thief.py -- <out dir> [preview]

Writes <out dir>/Thief.glb (one skinned mesh, its armature and the clips below) and, with
`preview`, PNG renders. The thief stands on the ground at its origin facing the engine's +Z, about
1.7 m tall: hooded and masked, a dark tunic belted with a pouch, gloves and soft boots.

The clips, each a loop whose stride matches the speed Thief.as moves at, so the feet do not slide:
- Idle (2 s): standing, breathing.
- Walk (1 s): two steps of 0.8 m, 1.6 m/s.
- Sneak (1.2 s): crouched, two steps of 0.6 m, 1.0 m/s.
- Run (0.6 s): leaning in, two steps of 1.35 m, 4.5 m/s.
- Crouch (2 s): crouched still, breathing.

The figure, its rig and the gait machinery are figure.py's, shared with the guards. The arms are
upper arm, forearm and hand: the chain the two-bone IK puts on a lock (the hand's head reaches the
target).
"""
import bpy, math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
import figure
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "thief-out")
PREVIEW = "preview" in ARGS
FPS = 24

kit3d.PALETTE.update({
    "Cloth": (0.045, 0.05, 0.065), "ClothDark": (0.025, 0.027, 0.035), "Mask": (0.02, 0.02, 0.024),
    "Skin": (0.62, 0.42, 0.30), "Leather": (0.16, 0.09, 0.05), "Buckle": (0.55, 0.42, 0.20),
    "Eye": (0.08, 0.06, 0.06),
})
kit3d.ROUGHNESS.update({"Cloth": 0.9, "ClothDark": 0.9, "Mask": 0.95, "Leather": 0.55, "Buckle": 0.35})
# No glow of his own here: in the dark, LightMeter.as gives his figure one (its EmissiveColor, set
# for his mesh alone), so in the light he is as he is.

BODY = figure.Body()


def build(b):
    box("Pelvis", (0.30, 0.21, 0.18), P(0, 0, 0.93), "ClothDark", "hips", bevel=0.05)
    box("Torso", (0.36, 0.22, 0.50), P(0, 0, 1.18), "Cloth", "spine", bevel=0.07)
    box("Belt", (0.37, 0.23, 0.06), P(0, 0, 0.97), "Leather", "spine", bevel=0.02)
    box("Buckle", (0.06, 0.02, 0.045), P(0, 0.12, 0.97), "Buckle", "spine")
    box("Pouch", (0.11, 0.07, 0.1), P(0.15, 0.09, 0.92), "Leather", "hips", bevel=0.02)
    tube("Neck", b.neck() - Vector((0, 0, 0.03)), b.neck() + Vector((0, 0, 0.07)), 0.05, "ClothDark", "head")
    ball("Head", b.head(), 0.17, "Skin", "head", scale=(0.95, 0.95, 1.05), segments=(28, 16))
    # The hood over the head and the mask across the lower face; the eyes show between them.
    ball("Hood", b.head() + P(0, -0.02, 0.03), 0.19, "Cloth", "head", scale=(1.04, 1.06, 1.05), segments=(28, 16),
         cut_below=-0.15)
    ball("Mask", b.head() + P(0, 0.035, -0.06), 0.165, "Mask", "head", scale=(1.0, 0.98, 0.65), segments=(24, 12))
    for side in (-1, 1):
        ball("Eye", b.head() + P(side * 0.06, 0.15, 0.025), 0.022, "Eye", "head", segments=(12, 8))
    for side in (-1, 1):
        s = "L" if side > 0 else "R"
        sh, el, ha = b.shoulder(side), b.elbow(side), b.hand(side)
        ball("Shoulder" + s, sh, 0.075, "Cloth", "upperarm_" + s, segments=(14, 10))
        tube("UpperArm" + s, sh, el, 0.058, "Cloth", "upperarm_" + s, 10, 0.05)
        ball("Elbow" + s, el, 0.048, "Cloth", "forearm_" + s, segments=(10, 8))
        tube("Forearm" + s, el, ha, 0.047, "Cloth", "forearm_" + s, 10, 0.04)
        ball("Hand" + s, ha + P(0, 0, -0.03), 0.05, "Leather", "hand_" + s, segments=(12, 8))
        hp, kn, an, toe = b.hip(side), b.knee(side), b.ankle(side), b.toe(side)
        tube("Thigh" + s, hp, kn, 0.078, "ClothDark", "thigh_" + s, 10, 0.064)
        ball("Knee" + s, kn, 0.062, "ClothDark", "shin_" + s, segments=(10, 8))
        tube("Shin" + s, kn, an, 0.06, "Leather", "shin_" + s, 10, 0.05)
        box("Boot" + s, (0.10, (toe - an).length + 0.1, 0.09), (an + toe) / 2 + Vector((0, 0, -0.005)), "Leather",
            "foot_" + s, bevel=0.035)


GAITS = {
    #        frames, thigh swing, knee lift, arm swing, elbow, thigh0, knee0, lean, bob, breathing
    "Idle":   dict(frames=48, thigh=0, knee=0, arm=0, elbow=10, thigh0=0, knee0=4, lean=2, bob=0.0, breath=1),
    "Walk":   dict(frames=24, thigh=28, knee=45, arm=22, elbow=14, thigh0=0, knee0=6, lean=5, bob=0.025, breath=0),
    "Sneak":  dict(frames=29, thigh=20, knee=25, arm=8, elbow=50, thigh0=40, knee0=75, lean=24, bob=0.015, breath=0),
    "Run":    dict(frames=14, thigh=45, knee=90, arm=40, elbow=75, thigh0=8, knee0=20, lean=14, bob=0.05, breath=0),
    "Crouch": dict(frames=48, thigh=0, knee=0, arm=0, elbow=55, thigh0=45, knee0=85, lean=26, bob=0.0, breath=1),
}


def main():
    kit3d.reset()
    scene = bpy.context.scene
    scene.render.fps = FPS
    os.makedirs(OUT, exist_ok=True)
    build(BODY)
    rig = figure.build_armature(BODY, "ThiefRig")
    body = kit3d.skin(rig, "Thief")
    rig.animation_data_create()
    actions = {name: figure.clip(rig, BODY, name, g) for name, g in GAITS.items()}
    if PREVIEW:
        cam = kit3d.studio()
        target = Vector((0, 0, 0.8))
        figure.rest(rig)
        kit3d.shoot(cam, os.path.join(OUT, "preview-front34.png"), P(-1.8, 2.4, 1.4), target)
        for name, frame in (("Walk", 7), ("Sneak", 8), ("Run", 4), ("Crouch", 1)):
            rig.animation_data.action = actions[name]
            scene.frame_set(frame)
            kit3d.shoot(cam, os.path.join(OUT, "preview-%s.png" % name), P(-3.2, 0.4, 1.0), target)
    kit3d.export_rigged(os.path.join(OUT, "Thief.glb"), rig, body)
    print("Thief written to", OUT)


main()
