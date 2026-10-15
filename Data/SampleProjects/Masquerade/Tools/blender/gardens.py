"""Masquerade's garden kit: the pieces the Gardens map adds to the palace kit, on its 2 m grid,
modelled in Blender.

    blender --background --factory-startup --python gardens.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>.glb for every piece (or the ones named) and, with `preview`, a PNG of each.
Every piece stands on the ground (y = 0) at its own origin; the map generator places their
colliders from the same sizes (the gardens map in maps.py):

- Grass: a 2 m square of lawn, its top at y = 0.
- Gravel: a 2 m square of a path's pale gravel, a little below the lawn's edge (top at y = 0).
- Hedge: one 2 m edge of a clipped hedge, 1.8 m high and 0.8 m thick, centred on the edge (x -1..1,
  z -0.4..0.4): high enough to hide a guest, low enough for the camera to see over.
- HedgeCorner: the 0.8 m square where hedges meet, so a corner closes.
- Statue: a figure on a pedestal, 2.6 m tall, 0.9 m square at the foot.
- Urn: a stone urn on a short plinth, 1.2 m tall, 0.6 m across.
"""
import math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "gardens-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Lawn": (0.10, 0.22, 0.07), "LawnDark": (0.08, 0.18, 0.06), "Gravel": (0.55, 0.50, 0.42),
    "Hedge": (0.05, 0.16, 0.05), "HedgeTop": (0.07, 0.20, 0.06), "Marble": (0.82, 0.80, 0.76),
    "Pedestal": (0.55, 0.52, 0.47), "UrnStone": (0.62, 0.58, 0.52),
})
kit3d.ROUGHNESS.update({"Marble": 0.3, "Hedge": 0.95, "HedgeTop": 0.95, "Lawn": 0.95})

GRID = 2.0
HEDGE_H, HEDGE_T = 1.8, 0.8


def grass():
    for i in range(2):
        for j in range(2):
            box("Lawn", (1.0, 1.0, 0.04), P(-0.5 + i, -0.5 + j, -0.02), "Lawn" if (i + j) % 2 == 0 else "LawnDark")


def gravel():
    box("Gravel", (GRID, GRID, 0.04), P(0, 0, -0.02), "Gravel")


def hedge():
    box("Hedge", (GRID, HEDGE_T, HEDGE_H - 0.1), P(0, 0, (HEDGE_H - 0.1) / 2), "Hedge", bevel=0.08)
    box("HedgeTop", (GRID - 0.04, HEDGE_T - 0.06, 0.12), P(0, 0, HEDGE_H - 0.06), "HedgeTop", bevel=0.05)


def hedge_corner():
    box("Hedge", (HEDGE_T, HEDGE_T, HEDGE_H - 0.1), P(0, 0, (HEDGE_H - 0.1) / 2), "Hedge", bevel=0.08)
    box("HedgeTop", (HEDGE_T - 0.06, HEDGE_T - 0.06, 0.12), P(0, 0, HEDGE_H - 0.06), "HedgeTop", bevel=0.05)


def statue():
    box("Plinth", (0.9, 0.9, 0.2), P(0, 0, 0.1), "Pedestal", bevel=0.03)
    box("Pedestal", (0.7, 0.7, 1.0), P(0, 0, 0.7), "Pedestal", bevel=0.02)
    box("Cap", (0.8, 0.8, 0.12), P(0, 0, 1.26), "Pedestal", bevel=0.03)
    # A draped figure: a robe, a torso, a head, one arm raised.
    tube("Robe", P(0, 0, 1.32), P(0, 0, 2.0), 0.24, "Marble", segments=14, radius2=0.16)
    tube("Torso", P(0, 0, 2.0), P(0, 0, 2.32), 0.16, "Marble", segments=12, radius2=0.13)
    ball("Head", P(0, 0, 2.45), 0.1, "Marble", segments=(12, 8))
    tube("Arm", P(0.12, 0, 2.26), P(0.3, 0.05, 2.6), 0.04, "Marble", segments=8)
    tube("ArmDown", P(-0.12, 0, 2.26), P(-0.18, 0.04, 1.95), 0.04, "Marble", segments=8)


def urn():
    box("Plinth", (0.6, 0.6, 0.35), P(0, 0, 0.175), "Pedestal", bevel=0.02)
    tube("Foot", P(0, 0, 0.35), P(0, 0, 0.5), 0.12, "UrnStone", segments=14, radius2=0.08)
    ball("Body", P(0, 0, 0.75), 0.28, "UrnStone", scale=(1, 1, 0.9), segments=(16, 10))
    tube("Lip", P(0, 0, 0.98), P(0, 0, 1.1), 0.18, "UrnStone", segments=16, radius2=0.24)
    ball("Leaves", P(0, 0, 1.12), 0.2, "Hedge", scale=(1, 1, 0.6), segments=(12, 8))


MODELS = {"Grass": grass, "Gravel": gravel, "Hedge": hedge, "HedgeCorner": hedge_corner, "Statue": statue,
          "Urn": urn}
VIEWS = {"small": (P(-1.8, 2.6, 1.8), Vector((0, 0, 0.8))), "tall": (P(-2.6, 3.6, 2.4), Vector((0, 0, 1.3)))}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            eye, target = VIEWS["tall" if name in ("Statue", "Hedge") else "small"]
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + ".glb"), name)
        print("written", name)


main()
