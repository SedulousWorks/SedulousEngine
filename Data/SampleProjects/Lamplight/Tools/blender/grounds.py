"""Lamplight's grounds kit: the outdoor pieces a level outside the manor is built from (the gardens,
the stable yard), on the manor kit's 2 m grid, modelled in Blender.

    blender --background --factory-startup --python grounds.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>.glb for every piece (or the ones named) and, with `preview`, a PNG of each.
Every piece stands on the ground (y = 0) at its own origin; the level generator (level.py) places
its colliders from the same sizes:

- Hedge: one 2 m grid edge of clipped yew, 1.6 m high and 0.8 m thick, centred on the edge.
- HedgeCorner: the 0.8 m square of hedge where runs meet or end.
- GardenWall: one 2 m edge of the grounds' stone wall, 2.4 m high and 0.4 m thick, with a coping.
- Pier: a 0.6 m square stone pier, 2.7 m high, where walls meet and either side of a gate.
- Gate: an iron gate's leaf (1.2 m by 1.8 m), its origin at the hinge edge (x 0..1.2), bars
  between two rails, a lock box near the far edge.
- LanternPost: an iron post with a glowing lantern on top, 2.5 m; the level hangs the point light
  in the lantern.
- Grass, Gravel, Flags, Cobbles: 2 m ground tiles, their tops at y = 0: lawn, a raked path,
  flagstones, rain-wet setts.
- HayBale (1.2 x 0.8 x 0.6 m) and Trough (1.8 x 0.6 x 0.6 m): a stable yard's cover.
"""
import math, os, random, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "grounds-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Yew": (0.035, 0.09, 0.035), "YewLight": (0.05, 0.12, 0.045), "Stone": (0.32, 0.30, 0.27),
    "Coping": (0.40, 0.38, 0.34), "Iron": (0.05, 0.05, 0.055), "Glass": (1.0, 0.72, 0.38),
    "Lawn": (0.05, 0.11, 0.035), "Gravel": (0.36, 0.33, 0.28), "Pebble": (0.45, 0.42, 0.37),
    "Flag": (0.30, 0.29, 0.27), "Joint": (0.12, 0.11, 0.10), "Cobble": (0.20, 0.19, 0.18),
    "Hay": (0.55, 0.42, 0.18), "HayDark": (0.40, 0.30, 0.12), "Twine": (0.30, 0.20, 0.10),
    "Plank": (0.22, 0.14, 0.08), "Water": (0.02, 0.03, 0.04),
})
kit3d.GLOW.update({"Glass": 6.0})
kit3d.ROUGHNESS.update({"Yew": 0.95, "YewLight": 0.95, "Stone": 0.9, "Lawn": 0.95, "Gravel": 0.95,
                        "Iron": 0.5, "Flag": 0.55, "Cobble": 0.12, "Joint": 0.2, "Hay": 0.95,
                        "HayDark": 0.95, "Water": 0.02})

GRID = 2.0


def hedge():
    h, t = 1.6, 0.8
    box("Hedge", (GRID, t, h - 0.15), P(0, 0, (h - 0.15) / 2), "Yew", bevel=0.12)
    rnd = random.Random(7)
    for i in range(7):  # the clipped top, a little uneven
        x = -GRID / 2 + 0.15 + i * (GRID - 0.3) / 6
        ball("Top", P(x, rnd.uniform(-0.05, 0.05), h - 0.22), 0.3, "YewLight" if i % 2 else "Yew",
             scale=(1.2, 1.4, 0.8), segments=(10, 6))


def hedge_corner():
    h, t = 1.6, 0.8
    box("Hedge", (t, t, h - 0.15), P(0, 0, (h - 0.15) / 2), "Yew", bevel=0.12)
    ball("Top", P(0, 0, h - 0.22), 0.32, "YewLight", scale=(1.3, 1.3, 0.8), segments=(10, 6))


def garden_wall():
    h, t = 2.4, 0.4
    box("Wall", (GRID, t, h - 0.12), P(0, 0, (h - 0.12) / 2), "Stone", bevel=0.02)
    box("Coping", (GRID, t + 0.08, 0.12), P(0, 0, h - 0.06), "Coping", bevel=0.02)


def pier():
    box("Pier", (0.6, 0.6, 2.55), P(0, 0, 1.275), "Stone", bevel=0.03)
    box("Cap", (0.72, 0.72, 0.15), P(0, 0, 2.625), "Coping", bevel=0.03)


GATE_W, GATE_H = 1.2, 1.8


def gate():
    for up in (0.15, GATE_H - 0.1):
        box("Rail", (GATE_W, 0.05, 0.06), P(GATE_W / 2, 0, up), "Iron")
    for i in range(9):
        x = 0.05 + i * (GATE_W - 0.1) / 8
        tube("Bar", P(x, 0, 0.05), P(x, 0, GATE_H + 0.1), 0.015, "Iron", segments=6)
        ball("Finial", P(x, 0, GATE_H + 0.12), 0.03, "Iron", segments=(8, 6))
    box("Lock", (0.12, 0.08, 0.16), P(GATE_W - 0.12, 0, 1.0), "Iron")


def lantern_post():
    tube("Post", Vector((0, 0, 0)), Vector((0, 0, 2.15)), 0.05, "Iron", segments=10)
    tube("Foot", Vector((0, 0, 0)), Vector((0, 0, 0.25)), 0.11, "Iron", segments=10, radius2=0.06)
    box("Glass", (0.2, 0.2, 0.26), P(0, 0, 2.3), "Glass")
    for sx in (-1, 1):
        for sz in (-1, 1):
            tube("Frame", P(sx * 0.1, sz * 0.1, 2.16), P(sx * 0.1, sz * 0.1, 2.44), 0.012, "Iron", segments=6)
    box("Roof", (0.3, 0.3, 0.06), P(0, 0, 2.46), "Iron", bevel=0.02)
    ball("Knob", P(0, 0, 2.52), 0.04, "Iron", segments=(8, 6))


def grass():
    box("Lawn", (GRID, GRID, 0.04), P(0, 0, -0.02), "Lawn")


def gravel():
    box("Gravel", (GRID, GRID, 0.04), P(0, 0, -0.02), "Gravel")
    rnd = random.Random(11)
    for _ in range(60):  # loose stones on the raked surface
        ball("Pebble", P(rnd.uniform(-0.95, 0.95), rnd.uniform(-0.95, 0.95), 0.0), rnd.uniform(0.012, 0.025),
             "Pebble", scale=(1.3, 1.0, 0.5), segments=(6, 4))


def flags():
    box("Bed", (GRID, GRID, 0.03), P(0, 0, -0.025), "Joint")
    rnd = random.Random(5)
    for i in range(3):  # three courses of slabs, each broken differently
        z0 = -GRID / 2 + i * GRID / 3
        x = -GRID / 2
        while x < GRID / 2 - 0.05:
            w = min(rnd.uniform(0.45, 0.8), GRID / 2 - x)
            box("Flag", (w - 0.02, GRID / 3 - 0.02, 0.03), P(x + w / 2, z0 + GRID / 6, -0.012), "Flag", bevel=0.006)
            x += w


def cobbles():
    """Rain-wet setts: dark, glossy (SSR shows the lamps in them), each a little proud of the
    joints between."""
    box("Bed", (GRID, GRID, 0.03), P(0, 0, -0.025), "Joint")
    rnd = random.Random(9)
    n = 10
    for i in range(n):
        for j in range(n):
            x = -GRID / 2 + (i + 0.5) * GRID / n + (0.05 if j % 2 else 0.0)
            if x > GRID / 2 - 0.08:
                continue
            z = -GRID / 2 + (j + 0.5) * GRID / n
            box("Sett", (GRID / n - 0.025, GRID / n - 0.025, 0.03), P(x, z, -0.012 + rnd.uniform(-0.004, 0.004)),
                "Cobble", bevel=0.008)


def hay_bale():
    box("Bale", (1.2, 0.8, 0.6), P(0, 0, 0.3), "Hay", bevel=0.06)
    for x in (-0.3, 0.3):
        box("Twine", (0.03, 0.82, 0.62), P(x, 0, 0.3), "Twine")
    box("Straw", (1.1, 0.7, 0.04), P(0, 0, 0.61), "HayDark", bevel=0.02)


def trough():
    t = 0.06  # the planks' thickness: a hollow box, the water inside
    box("Bottom", (1.8, 0.6, 0.1), P(0, 0, 0.05), "Plank", bevel=0.01)
    for side in (-1, 1):
        box("Side", (1.8, t, 0.6), P(0, side * (0.3 - t / 2), 0.3), "Plank", bevel=0.01)
        box("End", (t, 0.6, 0.6), P(side * (0.9 - t / 2), 0, 0.3), "Plank", bevel=0.01)
    box("Water", (1.8 - 2 * t, 0.6 - 2 * t, 0.02), P(0, 0, 0.5), "Water")


MODELS = {"Hedge": hedge, "HedgeCorner": hedge_corner, "GardenWall": garden_wall, "Pier": pier, "Gate": gate, "LanternPost": lantern_post,
          "Grass": grass, "Gravel": gravel, "Flags": flags, "Cobbles": cobbles, "HayBale": hay_bale,
          "Trough": trough}
VIEWS = {"big": (Vector((3.5, -4.5, 3.0)), Vector((0, 0, 1.0))), "tile": (Vector((2.0, -2.5, 2.5)), Vector((0, 0, 0))),
         "prop": (Vector((2.2, -2.6, 1.8)), Vector((0, 0, 0.3)))}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            eye, target = VIEWS["tile" if name in ("Grass", "Gravel", "Flags", "Cobbles") else
                                ("prop" if name in ("HayBale", "Trough") else "big")]
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + ".glb"), name)
        print("written", name)


main()
