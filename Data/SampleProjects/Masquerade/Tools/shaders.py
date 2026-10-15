#!/usr/bin/env python3
"""shaders.py: the costumes' custom shaders, through the editor's MCP. Runs after importmodels.py
(a model re-import makes its materials afresh).

Each shader in shaders/ is checked with shader_validate and imported into the Shaders group (a
re-run imports over the same asset). Then every costume's materials are put on them with
material_set_shader, which keeps the values of the same name, the costume's BaseColor among them:
- <Costume>Mask: Mask.hlsl, lacquered leaf that shifts hue with the view, and the round's flare.
- <Costume>Silk (the gowns): Silk.hlsl, a bright sheen.
- <Costume>Cloth (the coats): Silk.hlsl, a soft one, as fine wool.
The values a shader shares with PBR by name (Metallic, Roughness) are set here, not carried from
the model.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, assets
from materialvalues import set_values

COSTUMES = ["GownRose", "GownTeal", "GownGold", "CoatBlack", "CoatPlum", "CoatIvory"]

# Suffix: the shader and the values it is given.
LOOKS = {
    "Mask": ("Mask", dict(Metallic=0.85, Roughness=0.22, Shift=0.35)),
    "Silk": ("Silk", dict(Sheen=0.6, SheenPower=3.0, Roughness=0.4)),
    "Cloth": ("Silk", dict(Sheen=0.25, SheenPower=2.0, Roughness=0.75)),
}


def assets_by(type_name):
    found = {}
    for a in assets():
        if a["type"] == type_name:
            found.setdefault(a["name"], []).append(a["guid"])
    return found


def main():
    for f in sorted(os.listdir(os.path.join(HERE, "shaders"))):
        if not f.endswith(".hlsl"):
            continue
        path = os.path.join(HERE, "shaders", f)
        check = mcp("shader_validate", {"source": open(path).read(), "name": f})
        if not check["valid"]:
            raise SystemExit("%s: %s" % (f, check["errors"]))
        mcp("asset_import", {"source": path, "group": "Shaders"})
        print("shader", f, check["kind"])
    mcp("asset_cook", {})

    shaders = assets_by("ShaderAsset")
    materials = assets_by("MaterialAsset")
    for costume in COSTUMES:
        for suffix, (shader, values) in LOOKS.items():
            for guid in materials.get(costume + suffix, []):
                mcp("material_set_shader", {"material": guid, "shader": shaders[shader][0]})
                set_values(guid, values, {}, {}, 0, 1)
                print("material", costume + suffix, "->", shader)
    mcp("asset_cook", {})


main()
