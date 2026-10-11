"""Lamplight's manor kit: the modular pieces a level is built from on a 2 m grid, and the furniture
P0's room needs, modelled in Blender.

    blender --background --factory-startup --python manor.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>.glb for every piece (or the ones named) and, with `preview`, a PNG of each.
Every piece stands on the floor (y = 0) at its own origin, its colliders placed by the level
generator from the same sizes (room.py):

- Wall: one 2 m grid edge, 3 m high and 0.2 m thick, centred on the edge (x -1..1, z -0.1..0.1),
  plaster with a dark skirting and a picture rail on both faces.
- Doorway: the same edge with a 1.2 m by 2.2 m opening in the middle and a wooden frame round it.
- Post: the 0.2 m square where two walls meet at a grid corner, so a corner closes.
- Floor: a 2 m square of waxed boards, its top at y = 0 (the boards run along x).
- Door: the leaf that fills a doorway's frame (1.04 m by 2.12 m, 0.05 m thick), its origin at the
  hinge edge (x 0..1.04), with a brass lock plate and knob on both faces near the far edge.
- Table: a 1.6 m by 0.9 m table, 0.8 m high.
- OilLamp: a brass font and base with a glass chimney and its flame, 0.45 m tall; the level hangs
  its point light over it (level.py says how high, and why).
- Candelabra: three silver branches and lit candles, 0.5 m tall; its light hangs over it too.
- Hatch: a cellar's trapdoor flush with the floor, 1.2 m square: a level's way down.
- CellarWall, CellarPillar: the cellars' rough stone, a 2 m edge 3 m high and 0.4 m thick, and the
  0.5 m pillar where runs meet.
- Barrel (0.6 m across, 0.9 m tall), WineRack (2 m by 2 m, 0.5 m deep): the cellars' cover.
- TorchStand: an iron stand with a burning torch at 1.5 m; the level hangs its flickering light.
- Stairs: stone stairs up out of the cellars, 2 m wide, rising 3 m over 2 m north from the origin.
"""
import math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "manor-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Plaster": (0.62, 0.57, 0.49), "Skirting": (0.16, 0.10, 0.06), "Boards": (0.20, 0.11, 0.06),
    "TableWood": (0.30, 0.18, 0.10), "Brass": (0.78, 0.56, 0.24), "Chimney": (0.85, 0.80, 0.70),
    "Flame": (1.0, 0.70, 0.35), "DoorWood": (0.22, 0.12, 0.06), "DoorPanel": (0.18, 0.10, 0.05),
    "Silver": (0.72, 0.72, 0.74), "Wax": (0.92, 0.88, 0.78), "HatchWood": (0.20, 0.13, 0.08),
    "CellarStone": (0.22, 0.20, 0.18), "CellarStoneDark": (0.15, 0.14, 0.13), "Cask": (0.26, 0.15, 0.08),
    "Hoop": (0.08, 0.08, 0.09), "Rack": (0.18, 0.11, 0.06), "Bottle": (0.06, 0.12, 0.06),
    "TorchWood": (0.16, 0.10, 0.06), "Fire": (1.0, 0.55, 0.18), "StairStone": (0.30, 0.28, 0.25),
})
kit3d.GLOW.update({"Flame": 6.0, "Chimney": 1.5, "Fire": 8.0})
kit3d.ROUGHNESS.update({"Boards": 0.12, "Brass": 0.35, "Plaster": 0.85, "Silver": 0.25, "Wax": 0.6})

GRID, HEIGHT, THICK = 2.0, 3.0, 0.2
SKIRT_H, SKIRT_T = 0.16, 0.02   # skirting height, and how far it stands proud of the plaster
RAIL_Y, RAIL_H = 2.2, 0.05      # the picture rail


def trim(x0, x1):
    """Skirting and picture rail on both faces of a wall run from x0 to x1."""
    w, cx = x1 - x0, (x0 + x1) / 2
    for side in (-1, 1):
        z = side * (THICK / 2 + SKIRT_T / 2)
        box("Skirting", (w, SKIRT_T, SKIRT_H), P(cx, z, SKIRT_H / 2), "Skirting")
        box("Rail", (w, SKIRT_T, RAIL_H), P(cx, z, RAIL_Y), "Skirting")


def wall():
    box("Plaster", (GRID, THICK, HEIGHT), P(0, 0, HEIGHT / 2), "Plaster")
    trim(-GRID / 2, GRID / 2)


DOOR_W, DOOR_H, FRAME = 1.2, 2.2, 0.08


def doorway():
    side = (GRID - DOOR_W) / 2
    for s in (-1, 1):
        cx = s * (DOOR_W / 2 + side / 2)
        box("Plaster", (side, THICK, HEIGHT), P(cx, 0, HEIGHT / 2), "Plaster")
        trim(min(s * DOOR_W / 2, s * GRID / 2), max(s * DOOR_W / 2, s * GRID / 2))
    box("Plaster", (DOOR_W, THICK, HEIGHT - DOOR_H), P(0, 0, (HEIGHT + DOOR_H) / 2), "Plaster")
    # The frame: two jambs and a head, wrapping the opening and standing proud of both faces.
    depth = THICK + 2 * SKIRT_T
    for s in (-1, 1):
        box("Jamb", (FRAME, depth, DOOR_H), P(s * (DOOR_W / 2 - FRAME / 2), 0, DOOR_H / 2), "Skirting")
    box("Head", (DOOR_W, depth, FRAME), P(0, 0, DOOR_H - FRAME / 2), "Skirting")
    for side in (-1, 1):  # the rail runs on above the opening
        box("Rail", (GRID, SKIRT_T, RAIL_H), P(0, side * (THICK / 2 + SKIRT_T / 2), RAIL_Y), "Skirting")


LEAF_W, LEAF_H, LEAF_T = DOOR_W - 2 * FRAME, DOOR_H - FRAME, 0.05
LOCK_X, LOCK_Y = LEAF_W - 0.1, 1.0  # where the lock sits on the leaf (Door.as aims the hand at it)


def door():
    box("Leaf", (LEAF_W, LEAF_T, LEAF_H), P(LEAF_W / 2, 0, LEAF_H / 2), "DoorWood", bevel=0.008)
    for side in (-1, 1):  # raised panels on both faces, the lock's plate and knob
        z = side * (LEAF_T / 2 + 0.006)
        for up in (0.55, 1.55):
            box("Panel", (LEAF_W - 0.3, 0.012, 0.75), P(LEAF_W / 2, z, up), "DoorPanel", bevel=0.004)
        box("Plate", (0.05, 0.008, 0.16), P(LOCK_X, side * (LEAF_T / 2 + 0.008), LOCK_Y), "Brass")
        ball("Knob", P(LOCK_X, side * (LEAF_T / 2 + 0.04), LOCK_Y + 0.03), 0.028, "Brass")


def post():
    box("Plaster", (THICK, THICK, HEIGHT), P(0, 0, HEIGHT / 2), "Plaster")
    w = THICK + 2 * SKIRT_T
    box("Skirting", (w, w, SKIRT_H), P(0, 0, SKIRT_H / 2), "Skirting")
    box("Rail", (w, w, RAIL_H), P(0, 0, RAIL_Y), "Skirting")


def floor():
    boards, gap, depth = 10, 0.006, 0.04
    width = GRID / boards
    for i in range(boards):
        z = -GRID / 2 + width * (i + 0.5)
        box("Board", (GRID, width - gap, depth), P(0, z, -depth / 2), "Boards")


def table():
    w, d, h, top = 1.6, 0.9, 0.8, 0.05
    box("Top", (w, d, top), P(0, 0, h - top / 2), "TableWood", bevel=0.01)
    for sx in (-1, 1):
        for sz in (-1, 1):
            box("Leg", (0.07, 0.07, h - top), P(sx * (w / 2 - 0.08), sz * (d / 2 - 0.08), (h - top) / 2),
                "TableWood")


def oil_lamp():
    tube("Base", Vector((0, 0, 0)), Vector((0, 0, 0.03)), 0.08, "Brass", segments=16)
    tube("Stem", Vector((0, 0, 0.03)), Vector((0, 0, 0.12)), 0.025, "Brass", segments=12)
    ball("Font", Vector((0, 0, 0.17)), 0.07, "Brass", scale=(1, 1, 0.8))
    tube("Collar", Vector((0, 0, 0.21)), Vector((0, 0, 0.24)), 0.035, "Brass", segments=12)
    ball("Flame", Vector((0, 0, 0.28)), 0.02, "Flame", scale=(1, 1, 1.8))
    ball("Chimney", Vector((0, 0, 0.31)), 0.06, "Chimney", scale=(1, 1, 1.2))
    tube("ChimneyTop", Vector((0, 0, 0.36)), Vector((0, 0, 0.45)), 0.03, "Chimney", segments=12, radius2=0.025)


def candelabra():
    """A three-branch silver candelabra with its candles lit (their flames glow; the level hangs
    the light over them)."""
    tube("Base", Vector((0, 0, 0)), Vector((0, 0, 0.03)), 0.09, "Silver", segments=16)
    tube("Stem", Vector((0, 0, 0.03)), Vector((0, 0, 0.3)), 0.018, "Silver", segments=10)
    for x in (-0.14, 0.0, 0.14):
        if x != 0.0:
            tube("Arm", P(0, 0, 0.26), P(x, 0, 0.32), 0.012, "Silver", segments=8)
        tube("Cup", P(x, 0, 0.32), P(x, 0, 0.35), 0.025, "Silver", segments=10)
        tube("Candle", P(x, 0, 0.35), P(x, 0, 0.47), 0.015, "Wax", segments=10)
        ball("Flame", P(x, 0, 0.49), 0.012, "Flame", scale=(1, 1, 2.0), segments=(10, 6))


def hatch():
    """A cellar's trapdoor in the floor (1.2 m square, flush), with its iron ring: the way down."""
    for i in range(6):
        box("Plank", (1.2, 0.19, 0.04), P(0, -0.5 + i * 0.2, -0.015), "HatchWood", bevel=0.006)
    for x in (-0.45, 0.45):
        box("Brace", (0.08, 1.2, 0.01), P(x, 0, 0.006), "Brass")
    tube("Ring", P(0, 0.3, 0.008), P(0, 0.3, 0.016), 0.06, "Brass", segments=16)


def cellar_wall():
    """One 2 m edge of the cellars' rough stone, 3 m high and 0.4 m thick, in courses."""
    for i in range(6):
        up = 0.25 + i * 0.5
        shift = 0.12 if i % 2 else -0.12
        box("Course", (GRID, 0.4, 0.48), P(shift * 0.0, 0, up), "CellarStone" if i % 2 else "CellarStoneDark",
            bevel=0.03)


def cellar_pillar():
    box("Pillar", (0.5, 0.5, 3.0), P(0, 0, 1.5), "CellarStoneDark", bevel=0.04)


def barrel():
    """A cask on its end, 0.6 m across and 0.9 m tall, hooped."""
    tube("Cask", Vector((0, 0, 0)), Vector((0, 0, 0.9)), 0.3, "Cask", segments=16, radius2=0.3)
    for up in (0.12, 0.78):
        tube("Hoop", Vector((0, 0, up)), Vector((0, 0, up + 0.04)), 0.305, "Hoop", segments=16)


def wine_rack():
    """A rack of bottles against a wall: 2 m wide, 2 m high, 0.5 m deep."""
    for sx in (-1, 0, 1):
        box("Upright", (0.06, 0.5, 2.0), P(sx * 0.97, 0, 1.0), "Rack")
    for k in range(5):
        up = 0.2 + k * 0.42
        box("Shelf", (2.0, 0.5, 0.04), P(0, 0, up), "Rack")
        for i in range(8):
            tube("Bottle", P(-0.85 + i * 0.24, -0.22, up + 0.06), P(-0.85 + i * 0.24, 0.2, up + 0.06), 0.04,
                 "Bottle", segments=8)


def torch_stand():
    """An iron stand with a burning torch at 1.5 m (the level hangs its flickering light there)."""
    tube("Stand", Vector((0, 0, 0)), Vector((0, 0, 1.35)), 0.03, "Hoop", segments=8)
    for a in range(3):
        import math as _m
        x, y = 0.18 * _m.cos(a * 2.094), 0.18 * _m.sin(a * 2.094)
        tube("Leg", Vector((0, 0, 0.25)), Vector((x, y, 0.0)), 0.02, "Hoop", segments=6)
    tube("Cup", Vector((0, 0, 1.3)), Vector((0, 0, 1.38)), 0.06, "Hoop", segments=10, radius2=0.08)
    tube("Torch", Vector((0, 0, 1.3)), Vector((0, 0, 1.5)), 0.035, "TorchWood", segments=8)
    ball("Fire", Vector((0, 0, 1.58)), 0.07, "Fire", scale=(1, 1, 1.8), segments=(10, 8))


def stairs():
    """Stone stairs going up out of the cellars against the north wall: 2 m wide, rising to 3 m
    over 2 m (the way on; the exit's trigger is at their foot)."""
    for k in range(10):
        box("Step", (2.0, 0.2, 0.3 * (k + 1)), P(0, -k * 0.2, 0.15 * (k + 1)), "StairStone", bevel=0.01)


MODELS = {"Wall": wall, "Doorway": doorway, "Door": door, "Post": post, "Floor": floor, "Table": table,
          "OilLamp": oil_lamp, "Candelabra": candelabra, "Hatch": hatch, "CellarWall": cellar_wall,
          "CellarPillar": cellar_pillar, "Barrel": barrel, "WineRack": wine_rack, "TorchStand": torch_stand,
          "Stairs": stairs}
VIEWS = {"big": (Vector((3.5, -4.5, 3.0)), Vector((0, 0, 1.2))),
         "small": (Vector((0.9, -1.2, 0.8)), Vector((0, 0, 0.25)))}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            eye, target = VIEWS["small" if name in ("OilLamp", "Candelabra", "Hatch") else "big"]
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + ".glb"), name)
        print("written", name)


main()
