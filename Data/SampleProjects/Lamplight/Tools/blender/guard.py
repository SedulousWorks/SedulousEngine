"""Lamplight's guard: modelled, rigged and animated in Blender, on the figure the thief shares
(figure.py), a little taller.

    blender --background --factory-startup --python guard.py -- <out dir> [preview]

Writes <out dir>/Guard.glb (one skinned mesh, its armature and the clips below) and, with
`preview`, PNG renders. The guard stands on the ground at its origin facing the engine's +Z, about
1.8 m tall: a long coat in the house's dark red, a cap, a belt, boots, and a lantern held out in
the left hand. The lantern is part of the model and the left arm holds it still in every clip, so
the spot light the level hangs at the lantern (Guard.as's entity, not a bone) stays with it.

The clips, each a loop whose stride matches the speed Guard.as moves at:
- Idle (2 s): standing, breathing.
- Walk (1 s): two steps of 0.6 m, a patrol's 1.2 m/s.
- Run (0.65 s): two steps of 1.3 m, a chase's 4.0 m/s.
- Look (3 s): standing, the head turning from side to side: searching.
"""
import bpy, math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
import figure
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "guard-out")
PREVIEW = "preview" in ARGS
FPS = 24

kit3d.PALETTE.update({
    "Coat": (0.24, 0.035, 0.03), "CoatDark": (0.12, 0.02, 0.02), "Trousers": (0.05, 0.05, 0.06),
    "Skin": (0.66, 0.46, 0.34), "Leather": (0.10, 0.06, 0.04), "Brass": (0.78, 0.56, 0.24),
    "Cap": (0.06, 0.06, 0.07), "Eye": (0.06, 0.05, 0.05), "LanternGlass": (1.0, 0.75, 0.40),
})
kit3d.GLOW.update({"LanternGlass": 5.0})
kit3d.ROUGHNESS.update({"Brass": 0.35, "Leather": 0.5, "Coat": 0.85})

BODY = figure.Body(1.06)
# The left arm holds the lantern out in front at the waist (upper arm, elbow, degrees forward).
HOLD = (35.0, 55.0)


def build(b):
    s = b.scale
    box("Pelvis", (0.32 * s, 0.22 * s, 0.18 * s), b._p(0, 0, 0.93), "Trousers", "hips", bevel=0.05)
    box("Coat", (0.40 * s, 0.25 * s, 0.56 * s), b._p(0, 0, 1.16), "Coat", "spine", bevel=0.07)
    box("Skirt", (0.38 * s, 0.24 * s, 0.26 * s), b._p(0, 0, 0.82), "Coat", "hips", bevel=0.05)
    box("Belt", (0.41 * s, 0.26 * s, 0.06 * s), b._p(0, 0, 0.97), "Leather", "spine", bevel=0.02)
    box("Buckle", (0.06 * s, 0.02 * s, 0.045 * s), b._p(0, 0.135, 0.97), "Brass", "spine")
    for up in (1.05, 1.16, 1.27):
        ball("Button", b._p(0, 0.13, up), 0.016 * s, "Brass", "spine", segments=(8, 6))
    tube("Neck", b.neck() - Vector((0, 0, 0.03)), b.neck() + Vector((0, 0, 0.07)), 0.055 * s, "Skin", "head")
    ball("Head", b.head(), 0.17 * s, "Skin", "head", scale=(0.95, 0.95, 1.05), segments=(28, 16))
    ball("Cap", b.head() + b._p(0, 0, 0.06), 0.175 * s, "Cap", "head", scale=(1.02, 1.05, 0.7), segments=(28, 12),
         cut_below=0.0)
    box("Peak", (0.2 * s, 0.1 * s, 0.015 * s), b.head() + b._p(0, 0.16, 0.04), "Cap", "head")
    for side in (-1, 1):
        ball("Eye", b.head() + b._p(side * 0.06, 0.15, 0.02), 0.022 * s, "Eye", "head", segments=(12, 8))
        x = "L" if side > 0 else "R"
        sh, el, ha = b.shoulder(side), b.elbow(side), b.hand(side)
        ball("Shoulder" + x, sh, 0.08 * s, "Coat", "upperarm_" + x, segments=(14, 10))
        tube("UpperArm" + x, sh, el, 0.062 * s, "Coat", "upperarm_" + x, 10, 0.055 * s)
        ball("Elbow" + x, el, 0.05 * s, "Coat", "forearm_" + x, segments=(10, 8))
        tube("Forearm" + x, el, ha, 0.05 * s, "Coat", "forearm_" + x, 10, 0.045 * s)
        ball("Hand" + x, ha + b._p(0, 0, -0.03), 0.05 * s, "Skin", "hand_" + x, segments=(12, 8))
        hp, kn, an, toe = b.hip(side), b.knee(side), b.ankle(side), b.toe(side)
        tube("Thigh" + x, hp, kn, 0.08 * s, "Trousers", "thigh_" + x, 10, 0.066 * s)
        ball("Knee" + x, kn, 0.064 * s, "Trousers", "shin_" + x, segments=(10, 8))
        tube("Shin" + x, kn, kn + (an - kn) * 0.35, 0.062 * s, "Trousers", "shin_" + x, 10, 0.06 * s)
        tube("Boot" + x, kn + (an - kn) * 0.3, an, 0.065 * s, "Leather", "shin_" + x, 10, 0.058 * s)
        box("Sole" + x, (0.11 * s, (toe - an).length + 0.1 * s, 0.09 * s), (an + toe) / 2 + Vector((0, 0, -0.005)),
            "Leather", "foot_" + x, bevel=0.035)
    # The lantern hangs from the left hand by its bail, on the hand bone so it goes where the hand
    # does: a brass frame round a glowing glass. The hold turns the forearm forward by the sum of
    # HOLD's angles (90 degrees), so it is modelled lying back along the arm at rest (backward is
    # -forward) and hangs straight down while held.
    assert abs(sum(HOLD) - 90.0) < 1e-6
    ha = b.hand(1) + b._p(0, -0.06, 0)
    tube("Bail", ha, ha + b._p(0, -0.06, 0), 0.006 * s, "Brass", "hand_L", 6)
    top = ha + b._p(0, -0.06, 0)
    box("LanternTop", (0.12 * s, 0.03 * s, 0.12 * s), top, "Brass", "hand_L", bevel=0.01)
    box("LanternGlass", (0.1 * s, 0.14 * s, 0.1 * s), top + b._p(0, -0.09, 0), "LanternGlass", "hand_L", bevel=0.01)
    box("LanternBase", (0.12 * s, 0.03 * s, 0.12 * s), top + b._p(0, -0.175, 0), "Brass", "hand_L", bevel=0.01)

GAITS = {
    #        frames, thigh swing, knee lift, arm swing, elbow, thigh0, knee0, lean, bob, breathing
    "Idle": dict(frames=48, thigh=0, knee=0, arm=0, elbow=10, thigh0=0, knee0=4, lean=2, bob=0.0, breath=1,
                 holdLeft=HOLD),
    "Walk": dict(frames=24, thigh=22, knee=35, arm=16, elbow=12, thigh0=0, knee0=5, lean=3, bob=0.02, breath=0,
                 holdLeft=HOLD),
    "Run": dict(frames=16, thigh=42, knee=85, arm=35, elbow=70, thigh0=8, knee0=18, lean=12, bob=0.045, breath=0,
                holdLeft=HOLD),
    "Look": dict(frames=72, thigh=0, knee=0, arm=0, elbow=10, thigh0=0, knee0=4, lean=2, bob=0.0, breath=1,
                 holdLeft=HOLD, look=55),
}


def main():
    kit3d.reset()
    scene = bpy.context.scene
    scene.render.fps = FPS
    os.makedirs(OUT, exist_ok=True)
    build(BODY)
    rig = figure.build_armature(BODY, "GuardRig")
    body = kit3d.skin(rig, "Guard")
    rig.animation_data_create()
    actions = {name: figure.clip(rig, BODY, name, g) for name, g in GAITS.items()}
    if PREVIEW:
        cam = kit3d.studio()
        target = Vector((0, 0, 0.9))
        figure.rest(rig)
        kit3d.shoot(cam, os.path.join(OUT, "preview-front34.png"), P(-1.9, 2.5, 1.5), target)
        for name, frame in (("Idle", 1), ("Walk", 7), ("Run", 4), ("Look", 18)):
            rig.animation_data.action = actions[name]
            scene.frame_set(frame)
            kit3d.shoot(cam, os.path.join(OUT, "preview-%s.png" % name), P(-2.4, 2.2, 1.2), target)
    kit3d.export_rigged(os.path.join(OUT, "Guard.glb"), rig, body)
    print("Guard written to", OUT)


main()
