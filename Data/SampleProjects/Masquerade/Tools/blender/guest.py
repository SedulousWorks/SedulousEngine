"""Masquerade's guests: the costumes of the ball, modelled, rigged and animated in Blender on the
figure they share (figure.py), every one on the same rig, so one animation drives them all.

    blender --background --factory-startup --python guest.py -- <out dir> [preview]

Writes <out dir>/Guest<Costume>.glb for each costume below (one skinned mesh, its armature and the
clips) and, with `preview`, PNG renders. A guest stands on the ground at its origin facing the
engine's +Z, about 1.7 m tall, masked: a half mask over the eyes in the costume's mask colour.
Gowns have a wide skirt to the floor, long gloves, a bun and a plume on the mask; coats a tailcoat,
breeches, a cravat and a tricorne. Each costume's materials carry its name (GownRoseSilk), so the
imported models never share a material by accident; the skin and the eyes are shared on purpose.

The clips, each a loop:
- Idle (2 s): standing, breathing.
- Walk (28 frames): two steps of 0.58 m, a guest's stroll at 1.0 m/s (Guest.as moves at it).
- Talk (3 s): standing, the right arm moving with the words, the head turning a little.
- Dance (2 s): arms lifted, the hips swaying, stepping from foot to foot.
"""
import bpy, math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
import figure
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "guest-out")
PREVIEW = "preview" in ARGS
FPS = 24

# kind, the main colour, the trim's, the mask's (linear RGB). Players wear these too: a target is
# found by its costume, which several guests share.
COSTUMES = {
    "GownRose":  ("gown", (0.55, 0.06, 0.12), (0.80, 0.62, 0.30), (0.85, 0.66, 0.25)),
    "GownTeal":  ("gown", (0.02, 0.22, 0.24), (0.75, 0.75, 0.72), (0.80, 0.80, 0.82)),
    "GownGold":  ("gown", (0.62, 0.42, 0.10), (0.10, 0.06, 0.04), (0.04, 0.04, 0.05)),
    "CoatBlack": ("coat", (0.03, 0.03, 0.04), (0.80, 0.62, 0.30), (0.85, 0.85, 0.85)),
    "CoatPlum":  ("coat", (0.20, 0.04, 0.18), (0.80, 0.80, 0.78), (0.85, 0.66, 0.25)),
    "CoatIvory": ("coat", (0.70, 0.66, 0.56), (0.25, 0.05, 0.06), (0.55, 0.06, 0.12)),
}

BODY = figure.Body(1.0)

GAITS = {
    # Standing: frames, thigh swing, knee lift, arm swing, elbow, thigh0, knee0, lean, bob, breathing.
    # Moving: speed (m/s), stance (of the cycle) and lift (m) place the feet instead (figure.py).
    "Idle": dict(frames=48, thigh=0, knee=0, arm=0, elbow=12, thigh0=0, knee0=3, lean=1, bob=0.0, breath=1),
    "Walk": dict(frames=28, speed=1.0, stance=0.6, lift=0.08, arm=12, elbow=14, thigh0=0, knee0=4, lean=1,
                 breath=0),
    "Talk": dict(frames=72, thigh=0, knee=0, arm=0, elbow=12, thigh0=0, knee0=3, lean=1, bob=0.0, breath=1,
                 gesture=22, look=12),
    "Dance": dict(frames=48, thigh=8, knee=14, arm=0, elbow=0, thigh0=0, knee0=6, lean=0, bob=0.03, breath=0,
                  arms=(85, 45), sway=0.05),
}


def head_and_mask(b, name, trim, mask):
    s = b.scale
    tube("Neck", b.neck() - Vector((0, 0, 0.03)), b.neck() + Vector((0, 0, 0.07)), 0.05 * s, "Skin", "head")
    ball("Head", b.head(), 0.16 * s, "Skin", "head", scale=(0.92, 0.95, 1.06), segments=(28, 16))
    # The half mask: a curved shell over the eyes, standing proud of the face; its back half sits
    # inside the head, so from behind there is no mask. The eyes show dark through it.
    ball(name + "Mask", b.head() + b._p(0, 0.09, 0.025), 0.12 * s, name + "Mask", "head",
         scale=(1.25, 0.6, 0.4), segments=(28, 10))
    for side in (-1, 1):
        ball("Eye", b.head() + b._p(side * 0.055, 0.158, 0.03), 0.02 * s, "Eye", "head", segments=(12, 8))


def gown(b, name, main, trim):
    s = b.scale
    silk, lace = name + "Silk", name + "Trim"
    box("Bodice", (0.30 * s, 0.20 * s, 0.40 * s), b._p(0, 0, 1.18), silk, "spine", bevel=0.07)
    tube("Waist", b._p(0, 0, 0.98), b._p(0, 0, 1.06), 0.13 * s, lace, "hips", 16)
    # The skirt: a bell from the waist to just off the floor, on the hips so it sways with them;
    # the legs walk inside it and the shoes peep under the hem.
    tube("Skirt", b._p(0, 0, 0.98), b._p(0, 0, 0.06), 0.15 * s, silk, "hips", 24, 0.44 * s)
    tube("Hem", b._p(0, 0, 0.09), b._p(0, 0, 0.05), 0.445 * s, lace, "hips", 24, 0.45 * s)
    ball("Bun", b.head() + b._p(0, -0.09, 0.06), 0.08 * s, "Hair", "head", segments=(14, 10))
    ball("Hair", b.head() + b._p(0, -0.01, 0.03), 0.165 * s, "Hair", "head", scale=(0.95, 0.98, 1.0),
         segments=(24, 12), cut_below=0.1)
    # The plume rising from the mask's side.
    tube("Plume", b.head() + b._p(0.11, 0.08, 0.06), b.head() + b._p(0.16, 0.02, 0.32), 0.022 * s, lace, "head", 8,
         0.008 * s)
    for side in (-1, 1):
        x = "L" if side > 0 else "R"
        sh, el, ha = b.shoulder(side), b.elbow(side), b.hand(side)
        ball("Puff" + x, sh, 0.075 * s, silk, "upperarm_" + x, segments=(14, 10))
        tube("UpperArm" + x, sh, el, 0.045 * s, "Skin", "upperarm_" + x, 10, 0.04 * s)
        tube("Glove" + x, el, ha, 0.042 * s, lace, "forearm_" + x, 10, 0.035 * s)
        ball("Hand" + x, ha + b._p(0, 0, -0.03), 0.042 * s, lace, "hand_" + x, segments=(12, 8))
        hp, kn, an, toe = b.hip(side), b.knee(side), b.ankle(side), b.toe(side)
        tube("Thigh" + x, hp, kn, 0.07 * s, silk, "thigh_" + x, 10, 0.055 * s)
        tube("Shin" + x, kn, an, 0.05 * s, silk, "shin_" + x, 10, 0.04 * s)
        box("Shoe" + x, (0.08 * s, (toe - an).length + 0.06 * s, 0.07 * s), (an + toe) / 2, lace, "foot_" + x,
            bevel=0.03)


def coat(b, name, main, trim):
    s = b.scale
    cloth, lace = name + "Cloth", name + "Trim"
    box("Coat", (0.38 * s, 0.24 * s, 0.52 * s), b._p(0, 0, 1.16), cloth, "spine", bevel=0.07)
    box("Waistcoat", (0.20 * s, 0.03 * s, 0.34 * s), b._p(0, 0.115, 1.10), lace, "spine", bevel=0.01)
    box("Cravat", (0.10 * s, 0.05 * s, 0.10 * s), b._p(0, 0.10, 1.38), "Linen", "spine", bevel=0.02)
    box("Pelvis", (0.32 * s, 0.22 * s, 0.18 * s), b._p(0, 0, 0.93), "Breeches", "hips", bevel=0.05)
    # The tails, behind, to the knee.
    box("Tails", (0.30 * s, 0.05 * s, 0.42 * s), b._p(0, -0.11, 0.72), cloth, "hips", bevel=0.02)
    # The tricorne: a dome and a wide brim.
    ball("Crown", b.head() + b._p(0, -0.01, 0.07), 0.15 * s, cloth, "head", scale=(1.0, 1.0, 0.75),
         segments=(24, 10), cut_below=0.0)
    tube("Brim", b.head() + b._p(0, -0.01, 0.06), b.head() + b._p(0, -0.01, 0.09), 0.27 * s, cloth, "head", 3)
    tube("Braid", b.head() + b._p(0, -0.01, 0.09), b.head() + b._p(0, -0.01, 0.10), 0.26 * s, lace, "head", 3)
    for side in (-1, 1):
        x = "L" if side > 0 else "R"
        sh, el, ha = b.shoulder(side), b.elbow(side), b.hand(side)
        ball("Shoulder" + x, sh, 0.075 * s, cloth, "upperarm_" + x, segments=(14, 10))
        tube("UpperArm" + x, sh, el, 0.06 * s, cloth, "upperarm_" + x, 10, 0.052 * s)
        tube("Forearm" + x, el, ha, 0.05 * s, cloth, "forearm_" + x, 10, 0.045 * s)
        tube("Cuff" + x, el + (ha - el) * 0.8, ha, 0.055 * s, lace, "forearm_" + x, 10)
        ball("Hand" + x, ha + b._p(0, 0, -0.03), 0.045 * s, "Skin", "hand_" + x, segments=(12, 8))
        hp, kn, an, toe = b.hip(side), b.knee(side), b.ankle(side), b.toe(side)
        tube("Thigh" + x, hp, kn, 0.078 * s, "Breeches", "thigh_" + x, 10, 0.062 * s)
        tube("Stocking" + x, kn, an, 0.055 * s, "Linen", "shin_" + x, 10, 0.045 * s)
        box("Shoe" + x, (0.10 * s, (toe - an).length + 0.08 * s, 0.08 * s), (an + toe) / 2, "Shoe", "foot_" + x,
            bevel=0.03)
        box("Buckle" + x, (0.05 * s, 0.015 * s, 0.035 * s), toe + b._p(0, -0.03, 0.03), lace, "foot_" + x)


def costume(name, kind, main, trim, mask):
    kit3d.reset()
    kit3d.PALETTE.clear()
    kit3d.GLOW.clear()
    kit3d.ROUGHNESS.clear()
    kit3d.PALETTE.update({
        "Skin": (0.66, 0.46, 0.34), "Eye": (0.03, 0.03, 0.03), "Hair": (0.08, 0.05, 0.03),
        "Linen": (0.85, 0.84, 0.80), "Breeches": tuple(c * 0.6 for c in main), "Shoe": (0.03, 0.03, 0.03),
        name + "Silk": main, name + "Cloth": main, name + "Trim": trim, name + "Mask": mask,
    })
    kit3d.ROUGHNESS.update({name + "Silk": 0.35, name + "Mask": 0.25, name + "Trim": 0.45, "Shoe": 0.3})
    scene = bpy.context.scene
    scene.render.fps = FPS
    head_and_mask(BODY, name, trim, mask)
    (gown if kind == "gown" else coat)(BODY, name, main, trim)
    rig = figure.build_armature(BODY, "GuestRig")
    body = kit3d.skin(rig, "Guest" + name)
    rig.animation_data_create()
    actions = {clip: figure.clip(rig, BODY, clip, g) for clip, g in GAITS.items()}
    if PREVIEW:
        cam = kit3d.studio()
        target = Vector((0, 0, 0.9))
        figure.rest(rig)
        kit3d.shoot(cam, os.path.join(OUT, "preview-%s.png" % name), P(-2.4, 3.6, 1.6), target)
        if name == "GownRose":  # the clips, once
            for clip, frame in (("Walk", 8), ("Talk", 20), ("Dance", 13)):
                rig.animation_data.action = actions[clip]
                scene.frame_set(frame)
                kit3d.shoot(cam, os.path.join(OUT, "preview-%s.png" % clip), P(-3.0, 3.0, 1.5), target)
    kit3d.export_rigged(os.path.join(OUT, "Guest%s.glb" % name), rig, body)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (kind, main_colour, trim, mask) in COSTUMES.items():
        costume(name, kind, main_colour, trim, mask)
    print("Guests written to", OUT)


main()
