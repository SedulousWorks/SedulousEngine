"""Masquerade's canal kit: the pieces the Canal map is built from on a 2 m grid, modelled in Blender.

    blender --background --factory-startup --python canal.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>.glb for every piece (or the ones named) and, with `preview`, a PNG of each.
Every piece stands on the ground (y = 0) at its own origin; the map generator places their
colliders from the same sizes (the canal map in maps.py):

- Paving: a 2 m square of the campo's brick paving, laid in two tones, its top at y = 0.
- Coping: one 2 m edge of a quay: a kerb of pale stone 0.4 m wide along the edge (x -1..1,
  z -0.2..0.2), its top 3 cm above the paving, and the canal wall below it down to the water (its
  face on -Z, the canal side).
- Water: a 2 m square of the canal's dark water, its surface at y = -0.9.
- Bridge: a stone bridge 8 m long (along z, -4..4) and 3 m wide, its walk rising 1.8 m over the
  first 2.8 m, level over the middle 2.4 m, falling over the last 2.8 m, with parapets 0.9 m high,
  arched underneath, high enough over the water at mid-span for a standing gondolier.
- FacadeOchre, FacadeRose, FacadeWhite: one 2 m edge of a house front, 8 m tall and 0.5 m thick,
  centred on the edge (z -0.25..0.25), its face on +Z: a stone base, a window on each of three
  floors (the first lit), a cornice.
- DoorOchre, DoorRose, DoorWhite: the same with an arched door on the ground floor.
- Pole: a striped mooring pole 3 m tall, 0.15 m across, standing in the water (from y = -0.9).
- Gondola: a gondola 7 m long (along z), its hull's top at the water line plus 0.4 m, black with a
  steel prow, and its gondolier standing at the stern with his oar (2.07 m up at his hat); origin at
  the water line.
- Wellhead: the campo's carved well, 1.3 m across and 1 m high.
- Stall: a mask seller's stall, 2 m by 1 m, a striped awning at 2.2 m, masks on the counter.
"""
import math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "canal-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Brick": (0.36, 0.16, 0.10), "BrickPale": (0.46, 0.25, 0.16), "Istrian": (0.80, 0.77, 0.70),
    "CanalWall": (0.22, 0.20, 0.17), "Algae": (0.08, 0.12, 0.07), "CanalWater": (0.02, 0.07, 0.08),
    "BridgeStone": (0.70, 0.66, 0.58), "Ochre": (0.72, 0.42, 0.16), "Rose": (0.70, 0.32, 0.30),
    "Whitewash": (0.82, 0.78, 0.70), "Shutter": (0.10, 0.22, 0.14), "WindowLit": (1.0, 0.70, 0.36),
    "WindowDark": (0.04, 0.05, 0.07), "DoorWood": (0.16, 0.08, 0.04), "PoleBlue": (0.08, 0.18, 0.45),
    "PoleWhite": (0.85, 0.85, 0.82), "Hull": (0.02, 0.02, 0.02), "Steel": (0.70, 0.70, 0.72),
    "Velvet": (0.35, 0.03, 0.05), "Gondolier": (0.85, 0.85, 0.85), "GondolierStripe": (0.05, 0.08, 0.30),
    "Skin": (0.66, 0.46, 0.34), "Straw": (0.78, 0.66, 0.34), "Oar": (0.30, 0.18, 0.08),
    "StallWood": (0.30, 0.17, 0.08), "AwningRed": (0.62, 0.06, 0.08), "AwningCream": (0.88, 0.84, 0.72),
    "MaskGold": (0.85, 0.66, 0.25), "MaskWhite": (0.90, 0.90, 0.90), "MaskTeal": (0.05, 0.40, 0.42),
})
kit3d.GLOW.update({"WindowLit": 3.0})
kit3d.ROUGHNESS.update({"CanalWater": 0.04, "Hull": 0.2, "Steel": 0.3, "Istrian": 0.5, "MaskGold": 0.25})

GRID = 2.0
WATER_Y = -0.9
FACADE_H, FACADE_T = 8.0, 0.5
BRIDGE_L, BRIDGE_W, BRIDGE_RISE, BRIDGE_RAMP = 8.0, 3.0, 1.8, 2.8


def paving():
    box("Bed", (GRID, GRID, 0.02), P(0, 0, -0.011), "Brick")
    for i in range(4):
        for j in range(4):
            box("Brick", (0.48, 0.48, 0.05), P(-0.75 + 0.5 * i, -0.75 + 0.5 * j, -0.025),
                "Brick" if (i + j) % 2 == 0 else "BrickPale", bevel=0.01)


def coping():
    # Forward (+fwd) is the quay, back (-fwd) the canal: the wall's face looks over the water.
    # A kerb 3 cm proud of the paving it overlaps: level with it, the two would fight for the pixels.
    box("Coping", (GRID, 0.4, 0.15), P(0, 0, -0.045), "Istrian", bevel=0.02)
    box("Wall", (GRID, 0.3, 1.2), P(0, -0.05, -0.12 - 0.6), "CanalWall")
    box("Algae", (GRID, 0.31, 0.25), P(0, -0.05, WATER_Y + 0.05), "Algae")


def water():
    box("Water", (GRID, GRID, 0.02), P(0, 0, WATER_Y), "CanalWater")


def bridge():
    half, top, ramp = BRIDGE_L / 2, BRIDGE_RISE, BRIDGE_RAMP
    angle = math.degrees(math.atan2(top, ramp))
    slope = math.hypot(top, ramp)
    # The walk: a ramp up, a level top, a ramp down (forward is +z).
    for sign in (-1, 1):
        mid = sign * (half - ramp / 2)
        box("Ramp", (BRIDGE_W, slope, 0.25), P(0, mid, top / 2 - 0.12), "BridgeStone", tilt=sign * angle)
        for side in (-1, 1):  # parapets along the ramps, tilted with them
            box("RampParapet", (0.25, slope, 0.9), P(side * (BRIDGE_W / 2 - 0.12), mid, top / 2 + 0.45), "Istrian",
                tilt=sign * angle)
    box("Top", (BRIDGE_W, 2 * (half - ramp), 0.25), P(0, 0, top - 0.12), "BridgeStone")
    for side in (-1, 1):
        box("TopParapet", (0.25, 2 * (half - ramp), 0.9), P(side * (BRIDGE_W / 2 - 0.12), 0, top + 0.45), "Istrian",
            bevel=0.03)
        # The arch's faces under the deck: a band from bank to bank, highest at mid-span (where the
        # gondolas pass), lowest at the banks.
        for k in range(9):
            t = -1.0 + k / 4.0
            z = t * (half - 0.5)
            y = top - 0.35 - 0.9 * t * t
            box("Arch", (0.3, 0.8, 0.3), P(side * (BRIDGE_W / 2 - 0.15), z, y), "BridgeStone")


def facade_body(colour, door):
    box("Base", (GRID, FACADE_T + 0.06, 0.8), P(0, 0, 0.4), "Istrian")
    box("Wall", (GRID, FACADE_T, FACADE_H - 1.1), P(0, 0, 0.8 + (FACADE_H - 1.1) / 2), colour)
    box("Cornice", (GRID, FACADE_T + 0.2, 0.3), P(0, 0.1, FACADE_H - 0.15), "Istrian", bevel=0.04)
    front = FACADE_T / 2 + 0.01
    floors = ((3.0, "WindowLit"), (5.0, "WindowDark"), (6.8, "WindowDark"))
    for y, glass in floors:
        box("Window", (0.7, 0.04, 1.1), P(0, front, y), glass)
        box("Sill", (0.9, 0.12, 0.08), P(0, front + 0.04, y - 0.6), "Istrian")
        for side in (-1, 1):
            box("Shutter", (0.3, 0.04, 1.1), P(side * 0.55, front + 0.02, y), "Shutter")
    if door:
        box("Door", (1.0, 0.05, 1.9), P(0, front, 0.95 + 0.0), "DoorWood")
        tube("DoorArch", P(-0.5, front + 0.02, 1.9), P(0.5, front + 0.02, 1.9), 0.08, "Istrian", segments=8)
    else:
        box("Window", (0.7, 0.04, 1.0), P(0, front, 1.5), "WindowDark")


def make_facade(colour, door):
    return lambda: facade_body(colour, door)


def pole():
    for k in range(6):
        y0 = WATER_Y + k * 0.65
        tube("Pole", P(0, 0, y0), P(0, 0, y0 + 0.65), 0.075, "PoleBlue" if k % 2 == 0 else "PoleWhite", segments=10)
    ball("Cap", P(0, 0, WATER_Y + 3.9), 0.09, "Steel", segments=(10, 6))


def gondola():
    # The hull: a long, shallow, curved shape, sitting in the water (origin at the water line).
    ball("Hull", P(0, 0, 0.05), 0.5, "Hull", scale=(1.3, 7.0, 0.7), segments=(24, 12), cut_below=-0.6)
    box("Deck", (1.1, 4.5, 0.05), P(0, 0, 0.32), "Velvet")
    tube("Prow", P(0, 3.2, 0.3), P(0, 3.5, 1.0), 0.06, "Steel", segments=6)
    box("Ferro", (0.06, 0.25, 0.5), P(0, 3.55, 0.95), "Steel")
    tube("Stern", P(0, -3.2, 0.3), P(0, -3.45, 0.75), 0.06, "Hull", segments=6)
    # The gondolier at the stern, with his straw hat and oar.
    s, up = -2.6, -0.1  # standing in the hull, his hat clear of the bridges' arches (2.07 m up)
    tube("Legs", P(0, s, 0.35 + up), P(0, s, 1.15 + up), 0.1, "Gondolier", segments=8)
    tube("Body", P(0, s, 1.15 + up), P(0, s, 1.75 + up), 0.17, "GondolierStripe", segments=10, radius2=0.15)
    ball("Head", P(0, s, 1.92 + up), 0.13, "Skin", segments=(12, 8))
    tube("Hat", P(0, s, 2.02 + up), P(0, s, 2.07 + up), 0.24, "Straw", segments=14)
    tube("Crown", P(0, s, 2.05 + up), P(0, s, 2.17 + up), 0.12, "Straw", segments=12)
    tube("Oar", P(0.45, s + 0.2, 1.6 + up), P(0.6, s - 0.6, -0.3), 0.03, "Oar", segments=6)


def wellhead():
    tube("Step", P(0, 0, 0), P(0, 0, 0.15), 0.8, "Istrian", segments=8)
    tube("Vera", P(0, 0, 0.15), P(0, 0, 0.95), 0.6, "BridgeStone", segments=8, radius2=0.65)
    tube("Rim", P(0, 0, 0.95), P(0, 0, 1.05), 0.68, "Istrian", segments=8)
    tube("Hole", P(0, 0, 1.0), P(0, 0, 1.06), 0.42, "WindowDark", segments=16)


def stall():
    box("Counter", (2.0, 0.8, 0.9), P(0, 0.1, 0.45), "StallWood", bevel=0.03)
    for x in (-0.95, 0.95):
        for f in (-0.4, 0.45):
            tube("Post", P(x, f, 0), P(x, f, 2.2), 0.04, "StallWood", segments=6)
    for k in range(6):  # the striped awning, sloping down to the front
        x = -0.85 + k * 0.34
        box("Awning", (0.34, 1.3, 0.03), P(x, 0.1, 2.25), "AwningRed" if k % 2 == 0 else "AwningCream", tilt=-12)
    for k, mask in enumerate(("MaskGold", "MaskWhite", "MaskTeal", "MaskGold", "MaskWhite")):
        ball("Mask", P(-0.7 + 0.35 * k, 0.35, 0.98), 0.1, mask, scale=(1.3, 0.5, 0.7), segments=(12, 8))


MODELS = {"Paving": paving, "Coping": coping, "Water": water, "Bridge": bridge,
          "FacadeOchre": make_facade("Ochre", False), "FacadeRose": make_facade("Rose", False),
          "FacadeWhite": make_facade("Whitewash", False), "DoorOchre": make_facade("Ochre", True),
          "DoorRose": make_facade("Rose", True), "DoorWhite": make_facade("Whitewash", True),
          "Pole": pole, "Gondola": gondola, "Wellhead": wellhead, "Stall": stall}
VIEWS = {"small": (P(-1.6, 2.4, 1.6), Vector((0, 0, 0.6))), "big": (P(-7.0, 9.0, 6.0), Vector((0, 0, 1.5))),
         "tall": (P(-3.0, 9.0, 4.5), Vector((0, 0, 4.0)))}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            view = "tall" if name.startswith(("Facade", "Door")) else (
                "big" if name in ("Bridge", "Gondola") else "small")
            eye, target = VIEWS[view]
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + ".glb"), name)
        print("written", name)


main()
