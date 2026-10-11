"""Lamplight's loot and targets: what the thief takes, modelled in Blender.

    blender --background --factory-startup --python loot.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>.glb for every piece (or the ones named) and, with `preview`, a PNG of each.
Each sits on the ground at its origin; the level places it, and Loot.as picks it up.

- Purse: a leather coin purse spilling a few coins: loot.
- Candlestick: a silver candlestick: loot.
- Key: the gardener's great iron key with a brass bow: the Gardens' target, carried to the exit.
- Ledger: the stable ledger, bound in red with a brass clasp: the Stable Yard's target.
- Letter: a letter under a red seal, the vault's combination: the Cellars' target.
"""
import os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, ball

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "loot-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({"Binding": (0.25, 0.06, 0.04), "Pages": (0.85, 0.80, 0.65), "PurseLeather": (0.22, 0.10, 0.04), "Gold": (0.95, 0.70, 0.25), "Silver": (0.80, 0.80, 0.82),
                      "KeyIron": (0.10, 0.10, 0.11), "Brass": (0.78, 0.56, 0.24)})
kit3d.ROUGHNESS.update({"Gold": 0.25, "Silver": 0.2, "Brass": 0.3, "KeyIron": 0.45})
kit3d.PALETTE.update({"Velvet": (0.20, 0.02, 0.05), "Ruby": (0.75, 0.04, 0.08), "Sapphire": (0.06, 0.15, 0.80),
                      "Emerald": (0.05, 0.60, 0.20)})
kit3d.GLOW.update({"Gold": 0.6, "Silver": 0.12, "Brass": 0.5, "Ruby": 0.8, "Sapphire": 0.8, "Emerald": 0.8})  # a glint, so loot reads in the dark


def purse():
    ball("Bag", Vector((0, 0, 0.09)), 0.1, "PurseLeather", scale=(1.0, 0.9, 0.9), segments=(14, 10))
    tube("Neck", Vector((0, 0, 0.16)), Vector((0, 0, 0.21)), 0.035, "PurseLeather", segments=10, radius2=0.05)
    for i, (x, y) in enumerate(((0.14, 0.02), (0.18, -0.06), (0.11, -0.1))):
        tube("Coin", P(x, y, 0.0), P(x, y, 0.012), 0.025, "Gold", segments=12)


def candlestick():
    tube("Base", Vector((0, 0, 0)), Vector((0, 0, 0.03)), 0.08, "Silver", segments=16)
    tube("Stem", Vector((0, 0, 0.03)), Vector((0, 0, 0.32)), 0.02, "Silver", segments=10)
    ball("Knop", Vector((0, 0, 0.17)), 0.035, "Silver", segments=(12, 8))
    tube("Cup", Vector((0, 0, 0.32)), Vector((0, 0, 0.36)), 0.035, "Silver", segments=12)


def key():
    tube("Bow", P(0, -0.12, 0.02), P(0, -0.12, 0.04), 0.06, "Brass", segments=16)
    tube("Shank", P(0, -0.06, 0.03), P(0, 0.2, 0.03), 0.014, "KeyIron", segments=8)
    box("Bit", (0.02, 0.05, 0.06), P(0, 0.17, 0.0), "KeyIron")


def ledger():
    box("Cover", (0.26, 0.34, 0.05), P(0, 0, 0.025), "Binding", bevel=0.008)
    box("Pages", (0.24, 0.33, 0.035), P(0.012, 0, 0.026), "Pages")
    box("Clasp", (0.03, 0.06, 0.055), P(0.13, 0, 0.026), "Brass")


def letter():
    box("Paper", (0.24, 0.16, 0.01), P(0, 0, 0.005), "Pages", bevel=0.003)
    tube("Seal", P(0, 0, 0.01), P(0, 0, 0.018), 0.025, "Binding", segments=14)


def jewels():
    """The family jewels, the last level's target: a velvet-lined casket, open, gems heaped in it."""
    box("Casket", (0.36, 0.24, 0.14), P(0, 0, 0.07), "Binding", bevel=0.01)
    box("Velvet", (0.32, 0.20, 0.01), P(0, 0, 0.135), "Velvet")
    box("Lid", (0.36, 0.02, 0.22), P(0, 0.13, 0.25), "Binding", bevel=0.01)
    for i, (x, y, c) in enumerate(((-0.09, -0.04, "Ruby"), (0.0, 0.03, "Sapphire"), (0.08, -0.05, "Emerald"),
                                    (-0.04, 0.05, "Gold"), (0.1, 0.05, "Ruby"), (0.03, -0.06, "Sapphire"))):
        ball("Gem%d" % i, P(x, y, 0.16), 0.035, c, segments=(10, 8))


MODELS = {"Purse": purse, "Candlestick": candlestick, "Key": key, "Ledger": ledger, "Letter": letter,
          "Jewels": jewels}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), Vector((0.6, -0.8, 0.6)), Vector((0, 0, 0.1)))
        kit3d.export_static(os.path.join(OUT, name + ".glb"), name)
        print("written", name)


main()
