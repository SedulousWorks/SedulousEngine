"""Snowline's props: the mountain's trees and rocks, the slalom gates, the finish and the gems, modelled in
Blender on the shared kit.

    blender --background --factory-startup --python props.py -- <out dir> [preview] [names]

Writes <out dir>/<Name>Model.glb for each (static meshes, no rig) and, with `preview`, a PNG of
each. The vegetation scatter instances these by the thousand, so they are low in polygons: a
tree is a trunk and a few cones, each with a cap of snow.
"""
import math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bmesh
import kit3d
from kit3d import P, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "props-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Bark": (0.20, 0.12, 0.07), "Needles": (0.05, 0.16, 0.09), "NeedlesDark": (0.03, 0.11, 0.07),
    "Snow": (0.86, 0.90, 0.95), "Rock": (0.32, 0.33, 0.36),
    "Pole": (0.92, 0.92, 0.90), "PoleBand": (0.06, 0.06, 0.07),
    "FlagRed": (0.80, 0.07, 0.05), "FlagBlue": (0.04, 0.18, 0.72), "Banner": (0.85, 0.15, 0.10),
    "Gem": (0.05, 0.55, 0.85), "GemCore": (0.15, 0.75, 1.0),
    "KickerSnow": (0.80, 0.86, 0.94), "KickerLip": (0.10, 0.35, 0.80),
})
# The gem lights itself a little, so it reads against the snow in the shade and from far off.
kit3d.GLOW.update({"Gem": 0.5, "GemCore": 0.9})


def pine():
    """A snowy pine about 6 m tall: a trunk, four tiers of needles narrowing to the top, each
    with snow lying on its upper half."""
    tube("Trunk", P(0, 0, 0), P(0, 0, 1.6), 0.16, "Bark", "root", 8, 0.12)
    tiers = ((1.0, 2.6, 1.55), (2.0, 3.6, 1.2), (3.0, 4.6, 0.9), (4.0, 6.0, 0.6))
    for i, (bottom, top, radius) in enumerate(tiers):
        tube("Tier", P(0, 0, bottom), P(0, 0, top), radius, "Needles" if i % 2 == 0 else "NeedlesDark",
             "root", 10, 0.02)
        # The snow: a cone over the tier's upper part, a little proud of the needles.
        snow_bottom = bottom + (top - bottom) * 0.45
        snow_radius = radius * (top - snow_bottom) / (top - bottom) + 0.05
        tube("SnowCap", P(0, 0, snow_bottom), P(0, 0, top + 0.04), snow_radius, "Snow", "root", 10, 0.02)


def rock():
    """A boulder about 1.4 m across, half sunk in the snow, with snow on its top."""
    ball("Rock", P(0, 0, 0.2), 0.75, "Rock", scale=(1.0, 0.8, 0.6), segments=(10, 7))
    ball("RockSnow", P(0.05, 0, 0.52), 0.55, "Snow", scale=(1.0, 0.8, 0.3), segments=(10, 6), cut_below=0.0)


def gate_pole():
    """A slalom pole 1.9 m tall, white with dark bands, its foot at the origin. A gate is two of
    them; the flag hangs from each on a hinge (the scene's joint), so it swings when brushed."""
    tube("Pole", P(0, 0, 0), P(0, 0, 1.9), 0.03, "Pole", "root", 8)
    for z in (0.5, 1.0):
        tube("Band", P(0, 0, z), P(0, 0, z + 0.12), 0.034, "PoleBand", "root", 8)
    ball("Cap", P(0, 0, 1.9), 0.04, "PoleBand", segments=(8, 6))


def gate_flag(colour):
    """A gate's flag: a panel 0.55 m wide and 0.45 m tall, its ORIGIN on the hinge line (the pole's
    side, half way up the panel), the panel out along +X: the hinge turns it about up."""
    def build():
        kit3d.box("Flag", (0.55, 0.015, 0.45), P(0.3, 0, 0), colour, bevel=0.004)
    return build


def finish():
    """The finish: two posts 10 m apart and a banner across them 3 m up, its foot at the origin."""
    for side in (-1, 1):
        tube("Post", P(side * 5.0, 0, 0), P(side * 5.0, 0, 3.6), 0.08, "Pole", "root", 10)
    kit3d.box("Banner", (10.0, 0.06, 0.7), P(0, 0, 3.2), "Banner", bevel=0.02)


def gem():
    """A gem about 0.85 m tall (big enough to pick out down the slope): an eight-sided double cone,
    its centre at the origin (Gem.as spins and bobs it there), a brighter band round its waist."""
    tube("Crown", P(0, 0, 0), P(0, 0, 0.36), 0.31, "Gem", "root", 8, 0.0)
    tube("Pavilion", P(0, 0, 0), P(0, 0, -0.48), 0.31, "Gem", "root", 8, 0.0)
    tube("Girdle", P(0, 0, -0.03), P(0, 0, 0.03), 0.318, "GemCore", "root", 8)


KICKER_CURVE = 5.4   # the ramp's curve, from its buried start to the lip (m)
KICKER_HEIGHT = 1.4  # the lip's height above the snow (m)
KICKER_BURY = 0.12   # how deep the curve starts under the snow (m)
KICKER_TABLE = 0.8   # the flat top past the lip (m)
KICKER_BACK = 2.5    # the slope down behind it (m)
KICKER_WIDTH = 5.0
# Where the curve comes out of the snow: the origin. From there to the lip is the run; the curve
# leaves the snow at 9 degrees and reaches the lip at 29.
KICKER_EMERGE = KICKER_CURVE * math.sqrt(KICKER_BURY / (KICKER_HEIGHT + KICKER_BURY))
KICKER_RUN = KICKER_CURVE - KICKER_EMERGE


def kicker():
    """A kicker: a ramp of packed snow rising forward (+Z in the engine) along a curve (height
    (H + b) (u / C)^2 - b over its length C), a short flat table, then a slope down behind. The
    curve starts `b` under the snow, so no edge of it stands proud of the snow however the
    terrain's surface lies; the origin is where it comes out, at 9 degrees, glancing, and it
    reaches the lip at 29. A painted stripe marks the lip. Imported with collision (a triangle
    mesh, so the rider rides the curve)."""
    rise = KICKER_HEIGHT + KICKER_BURY
    profile = [(KICKER_CURVE * i / 10 - KICKER_EMERGE, rise * (i / 10) ** 2 - KICKER_BURY) for i in range(11)]
    profile.append((KICKER_RUN + KICKER_TABLE, KICKER_HEIGHT))
    profile.append((KICKER_RUN + KICKER_TABLE + KICKER_BACK, -KICKER_BURY))
    half = KICKER_WIDTH / 2
    bm = bmesh.new()
    left = [bm.verts.new(P(-half, f, h)) for f, h in profile]
    right = [bm.verts.new(P(half, f, h)) for f, h in profile]
    for i in range(len(profile) - 1):
        bm.faces.new((left[i], right[i], right[i + 1], left[i + 1]))  # the riding surface
    bm.faces.new(list(reversed(left)))  # the sides
    bm.faces.new(list(right))
    bm.faces.new((left[0], left[-1], right[-1], right[0]))  # the base, under the snow
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    kit3d.finish("Kicker", bm, "KickerSnow")
    # The lip's stripe: paint on the table just past the lip, 3 mm up, flat. It is in the collision
    # too, so it must stand proud of nothing: a raised strip at the lip deflected riders upward.
    stripe = bmesh.new()
    corners = [P(-half, KICKER_RUN, KICKER_HEIGHT + 0.003), P(half, KICKER_RUN, KICKER_HEIGHT + 0.003),
               P(half, KICKER_RUN + 0.4, KICKER_HEIGHT + 0.003), P(-half, KICKER_RUN + 0.4, KICKER_HEIGHT + 0.003)]
    stripe.faces.new([stripe.verts.new(c) for c in reversed(corners)])  # counter-clockwise from above: facing up
    kit3d.finish("Lip", stripe, "KickerLip")


MODELS = {"Pine": pine, "Rock": rock, "GatePole": gate_pole, "GateFlagRed": gate_flag("FlagRed"),
          "GateFlagBlue": gate_flag("FlagBlue"), "Finish": finish, "Gem": gem, "Kicker": kicker}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            eye, target = {"Pine": (P(-6, 9, 4), P(0, 0, 3)), "Finish": (P(-8, 14, 5), P(0, 0, 2)),
                           "Kicker": (P(-7, -3, 3), P(0, 3.5, 0.6)),
                           "GatePole": (P(-1.5, 2.5, 1.5), P(0, 0, 1.0))}.get(
                name, (P(-1.2, 2.0, 0.8), P(0.25, 0, 0.0)) if name.startswith("GateFlag") else
                (P(-2, 3, 1.5), P(0, 0, 0.3)))
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + "Model.glb"), name + "Model")
        print("written", name)


main()
