"""Masquerade's palace kit: the pieces the Palace map is built from on a 2 m grid, modelled in
Blender.

    blender --background --factory-startup --python palace.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>.glb for every piece (or the ones named) and, with `preview`, a PNG of each.
Every piece stands on the ground (y = 0) at its own origin; the level generator places their
colliders from the same sizes (palace map in maps.py):

- Flags: a 2 m square of the courtyard's pale flagstones, its top at y = 0.
- Marble: a 2 m square of the ballroom's floor, four checks of cream and dark marble.
- Wall: one 2 m grid edge of the palace, 5 m high and 0.4 m thick, centred on the edge (x -1..1,
  z -0.2..0.2): stucco over a stone base, a cornice on top.
- Window: the same edge with a tall window, lit from inside, on its +Z face (turn it to face out).
- Pier: the 0.6 m square where two walls meet, a little taller, so a corner closes.
- Column: a round column 0.6 m across and 5 m tall, on a square plinth: the colonnade.
- Balustrade: one 2 m edge of the courtyard's low balustrade, 1 m high and 0.3 m thick.
- Fountain: a round basin 6 m across and 0.6 m high, a pillar in the middle with a bowl, water in
  both; the collider is the basin (a 3 m radius).
- Lantern: an iron post with a glowing lantern at 2.6 m; the level hangs its light there.
- Planter: a stone pot with a clipped orange tree, 2.2 m tall, 0.8 m across.
- Bench: a stone bench 1.6 m long, 0.45 m high.
- Chandelier: a gilt ring of candles 1.6 m across, hung from its top (its origin; it hangs down
  1.2 m), no collider: the level hangs it over the ballroom with a light.
- Dais: the orchestra's platform, 6 m by 3 m and 0.4 m high, with chairs and music stands.
"""
import math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "palace-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Flagstone": (0.46, 0.43, 0.38), "FlagJoint": (0.20, 0.19, 0.17),
    "MarbleCream": (0.78, 0.74, 0.64), "MarbleDark": (0.10, 0.09, 0.09),
    "Stucco": (0.74, 0.66, 0.52), "StoneBase": (0.40, 0.37, 0.32), "Cornice": (0.82, 0.78, 0.68),
    "WindowGlow": (1.0, 0.72, 0.38), "WindowFrame": (0.30, 0.26, 0.18),
    "ColumnStone": (0.80, 0.76, 0.68), "Water": (0.04, 0.10, 0.14), "Basin": (0.62, 0.58, 0.52),
    "Iron": (0.05, 0.05, 0.05), "LanternGlass": (1.0, 0.76, 0.42), "Terracotta": (0.45, 0.20, 0.10),
    "Leaves": (0.05, 0.16, 0.05), "Orange": (0.9, 0.35, 0.03), "Gilt": (0.80, 0.58, 0.22),
    "Candle": (0.95, 0.92, 0.84), "CandleFlame": (1.0, 0.78, 0.40), "DaisWood": (0.22, 0.10, 0.05),
    "Velvet": (0.35, 0.03, 0.05),
})
kit3d.GLOW.update({"WindowGlow": 3.0, "LanternGlass": 5.0, "CandleFlame": 6.0})
kit3d.ROUGHNESS.update({"MarbleCream": 0.15, "MarbleDark": 0.12, "Water": 0.05, "Gilt": 0.3, "Iron": 0.5,
                        "Stucco": 0.9, "DaisWood": 0.35})

GRID = 2.0
WALL_H, WALL_T = 5.0, 0.4
BASE_H = 0.6


def flags():
    box("Joint", (GRID, GRID, 0.02), P(0, 0, -0.011), "FlagJoint")
    for i in range(2):
        for j in range(2):
            box("Flag", (0.96, 0.96, 0.06), P(-0.5 + i, -0.5 + j, -0.03), "Flagstone", bevel=0.02)


def marble():
    for i in range(2):
        for j in range(2):
            box("Check", (1.0, 1.0, 0.1), P(-0.5 + i, -0.5 + j, -0.05),
                "MarbleCream" if (i + j) % 2 == 0 else "MarbleDark")


def wall_body(window):
    box("Base", (GRID, WALL_T + 0.08, BASE_H), P(0, 0, BASE_H / 2), "StoneBase")
    box("Cornice", (GRID, WALL_T + 0.16, 0.3), P(0, 0, WALL_H - 0.15), "Cornice", bevel=0.04)
    if not window:
        box("Stucco", (GRID, WALL_T, WALL_H - BASE_H - 0.3), P(0, 0, (WALL_H + BASE_H - 0.3) / 2), "Stucco")
        return
    # A window 1 m wide from 1.2 m to 4 m, lit from inside: stucco round it, the glow set into it.
    w, y0, y1 = 1.0, 1.2, 4.0
    top = WALL_H - 0.3
    box("StuccoL", ((GRID - w) / 2, WALL_T, top - BASE_H), P(-(GRID + w) / 4, 0, (top + BASE_H) / 2), "Stucco")
    box("StuccoR", ((GRID - w) / 2, WALL_T, top - BASE_H), P((GRID + w) / 4, 0, (top + BASE_H) / 2), "Stucco")
    box("Sill", (w, WALL_T, y0 - BASE_H), P(0, 0, (y0 + BASE_H) / 2), "Stucco")
    box("Lintel", (w, WALL_T, top - y1), P(0, 0, (top + y1) / 2), "Stucco")
    box("Glow", (w, 0.05, y1 - y0), P(0, 0, (y0 + y1) / 2), "WindowGlow")
    for side in (-1, 1):  # the frame and its glazing bars on the face (+Z, the outside)
        box("Jamb", (0.08, 0.08, y1 - y0), P(side * (w / 2 - 0.04), WALL_T / 2, (y0 + y1) / 2), "WindowFrame")
    box("Head", (w, 0.1, 0.12), P(0, WALL_T / 2, y1), "Cornice")
    box("Bar", (0.04, 0.06, y1 - y0), P(0, WALL_T / 2, (y0 + y1) / 2), "WindowFrame")
    for k in (1, 2):
        box("Bar", (w, 0.06, 0.04), P(0, WALL_T / 2, y0 + (y1 - y0) * k / 3), "WindowFrame")


def wall():
    wall_body(False)


def window():
    wall_body(True)


def pier():
    box("PierBase", (0.68, 0.68, BASE_H), P(0, 0, BASE_H / 2), "StoneBase")
    box("Pier", (0.6, 0.6, WALL_H + 0.2), P(0, 0, (WALL_H + 0.2) / 2), "Cornice", bevel=0.03)


def column():
    box("Plinth", (0.8, 0.8, 0.3), P(0, 0, 0.15), "StoneBase", bevel=0.03)
    tube("TorusBase", P(0, 0, 0.3), P(0, 0, 0.45), 0.36, "ColumnStone", segments=20)
    tube("Shaft", P(0, 0, 0.45), P(0, 0, 4.55), 0.3, "ColumnStone", segments=20, radius2=0.26)
    tube("Neck", P(0, 0, 4.55), P(0, 0, 4.7), 0.3, "ColumnStone", segments=20)
    box("Capital", (0.8, 0.8, 0.3), P(0, 0, 4.85), "Cornice", bevel=0.04)


def balustrade():
    box("Plinth", (GRID, 0.34, 0.15), P(0, 0, 0.075), "StoneBase")
    box("Rail", (GRID, 0.34, 0.12), P(0, 0, 0.94), "Cornice", bevel=0.03)
    for k in range(5):  # the balusters, round and waisted
        x = -0.8 + 0.4 * k
        tube("Baluster", P(x, 0, 0.15), P(x, 0, 0.5), 0.06, "ColumnStone", segments=10, radius2=0.1)
        tube("Baluster", P(x, 0, 0.5), P(x, 0, 0.88), 0.1, "ColumnStone", segments=10, radius2=0.06)


def fountain():
    tube("Basin", P(0, 0, 0), P(0, 0, 0.6), 3.0, "Basin", segments=40)
    tube("Water", P(0, 0, 0.6), P(0, 0, 0.62), 2.75, "Water", segments=40)
    tube("Rim", P(0, 0, 0.6), P(0, 0, 0.7), 3.05, "Cornice", segments=40)
    tube("Pillar", P(0, 0, 0.6), P(0, 0, 1.8), 0.25, "Basin", segments=16, radius2=0.18)
    tube("Bowl", P(0, 0, 1.6), P(0, 0, 1.9), 0.3, "Basin", segments=24, radius2=1.0)
    tube("BowlWater", P(0, 0, 1.9), P(0, 0, 1.91), 0.92, "Water", segments=24)
    tube("Spout", P(0, 0, 1.9), P(0, 0, 2.5), 0.12, "Basin", segments=12, radius2=0.05)


def lantern():
    box("Foot", (0.4, 0.4, 0.2), P(0, 0, 0.1), "Iron", bevel=0.03)
    tube("Post", P(0, 0, 0.2), P(0, 0, 2.4), 0.06, "Iron", segments=10, radius2=0.045)
    box("LanternBase", (0.28, 0.28, 0.05), P(0, 0, 2.42), "Iron")
    box("LanternGlass", (0.24, 0.24, 0.34), P(0, 0, 2.62), "LanternGlass", bevel=0.01)
    tube("LanternCap", P(0, 0, 2.79), P(0, 0, 2.95), 0.2, "Iron", segments=4, radius2=0.02)


def planter():
    tube("Pot", P(0, 0, 0), P(0, 0, 0.6), 0.3, "Terracotta", segments=16, radius2=0.4)
    tube("Trunk", P(0, 0, 0.6), P(0, 0, 1.4), 0.05, "FlagJoint", segments=8)
    ball("Crown", P(0, 0, 1.75), 0.5, "Leaves", segments=(16, 10))
    for a in range(6):
        t = a * math.pi / 3
        ball("Orange", P(0.45 * math.cos(t), 0.45 * math.sin(t), 1.7 + 0.15 * math.sin(3 * t)), 0.05, "Orange",
             segments=(8, 6))


def bench():
    box("Seat", (1.6, 0.5, 0.1), P(0, 0, 0.4), "Cornice", bevel=0.03)
    for x in (-0.6, 0.6):
        box("Leg", (0.2, 0.4, 0.35), P(x, 0, 0.175), "StoneBase", bevel=0.02)


def chandelier():
    # Hung from its origin: a chain down to a gilt ring of candles, 1.2 m below.
    tube("Chain", P(0, 0, -0.7), P(0, 0, 0), 0.02, "Gilt", segments=6)
    tube("Stem", P(0, 0, -1.2), P(0, 0, -0.7), 0.05, "Gilt", segments=10)
    ball("Drop", P(0, 0, -1.25), 0.12, "Gilt", segments=(12, 8))
    for k in range(12):
        t = 2 * math.pi * k / 12
        x, f = 0.8 * math.cos(t), 0.8 * math.sin(t)
        tube("Arm", P(0, 0, -1.05), P(x, f, -1.0), 0.02, "Gilt", segments=6)
        tube("Cup", P(x, f, -1.02), P(x, f, -0.96), 0.05, "Gilt", segments=8)
        tube("Candle", P(x, f, -0.96), P(x, f, -0.8), 0.02, "Candle", segments=6)
        ball("Flame", P(x, f, -0.76), 0.025, "CandleFlame", scale=(1, 1, 1.6), segments=(6, 4))


def dais():
    box("Platform", (6.0, 3.0, 0.4), P(0, 0, 0.2), "DaisWood", bevel=0.04)
    box("Carpet", (5.6, 2.6, 0.02), P(0, 0, 0.41), "Velvet")
    for k in range(4):  # the players' chairs and stands, in an arc facing the room (+Z)
        x = -2.1 + 1.4 * k
        f = 0.2 if k in (0, 3) else 0.5
        box("ChairSeat", (0.45, 0.45, 0.06), P(x, f - 0.4, 0.86), "DaisWood")
        box("ChairBack", (0.45, 0.06, 0.5), P(x, f - 0.62, 1.12), "DaisWood")
        for dx in (-0.18, 0.18):
            for df in (-0.18, 0.18):
                box("ChairLeg", (0.04, 0.04, 0.42), P(x + dx, f - 0.4 + df, 0.62), "DaisWood")
        tube("StandPole", P(x, f + 0.3, 0.42), P(x, f + 0.3, 1.4), 0.015, "Gilt", segments=6)
        box("StandDesk", (0.4, 0.04, 0.28), P(x, f + 0.3, 1.45), "Gilt", tilt=-20)


MODELS = {"Flags": flags, "Marble": marble, "Wall": wall, "Window": window, "Pier": pier, "Column": column,
          "Balustrade": balustrade, "Fountain": fountain, "Lantern": lantern, "Planter": planter, "Bench": bench,
          "Chandelier": chandelier, "Dais": dais}
VIEWS = {"small": (P(-1.6, 2.4, 1.6), Vector((0, 0, 0.7))), "big": (P(-6.0, 8.0, 5.5), Vector((0, 0, 1.5))),
         "hung": (P(-2.4, 3.2, 0.2), Vector((0, 0, -0.9)))}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            view = "hung" if name == "Chandelier" else (
                "small" if name in ("Flags", "Marble", "Lantern", "Planter", "Bench", "Balustrade") else "big")
            eye, target = VIEWS[view]
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + ".glb"), name)
        print("written", name)


main()
