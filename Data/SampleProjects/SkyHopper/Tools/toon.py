#!/usr/bin/env python3
"""toon.py: Sky Hopper's toon shading. Installs Tools/shaders/Toon.hlsl as the project's Shaders/Toon
(a low-level shader; the asset is created on the first run), checks it with shader_validate, cooks,
and puts every material of the game on it; material_set_shader keeps the values whose name and type
fit (BaseColor, AlbedoMap, MainSampler, AlphaCutoff), so each keeps its colour and map from PBR.

  Tools/toon.py            the shader, then every material
  Tools/toon.py --pbr      every material back on the built-in PBR (the look before)
Needs the editor open on the project with its MCP server on (mcp.py).
"""
import json, os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mcp import call

PROJECT = os.path.dirname(HERE)


def assets(kind):
    listing = call("asset_list", {})
    items = listing if isinstance(listing, list) else listing.get("assets", [])
    # asset_list names a type in full (Sedulous.Materials.Pipeline.MaterialAsset); match on its last part
    return [a for a in items if a.get("type", "").rsplit(".", 1)[-1] == kind]


def main():
    materials = assets("MaterialAsset")
    if "--pbr" in sys.argv:
        for m in materials:
            call("material_set_shader", {"material": m["guid"], "shader": "pbr"})
        print("%d materials back on PBR" % len(materials))
        return
    shaders = [s for s in assets("ShaderAsset") if s.get("name") == "Toon"]
    guid = shaders[0]["guid"] if shaders else call("asset_create", {"creator": "Low-Level Shader", "name": "Toon",
                                                                     "group": "Shaders"})["guid"]
    source = open(os.path.join(HERE, "shaders", "Toon.hlsl")).read()
    check = call("shader_validate", {"source": source, "name": "Toon.hlsl"})
    if not check.get("valid", check.get("ok", True)) or check.get("errors"):
        sys.exit("Toon.hlsl: %s" % json.dumps(check.get("errors", check), indent=1))
    shutil.copyfile(os.path.join(HERE, "shaders", "Toon.hlsl"), os.path.join(PROJECT, "Sources", "Toon.hlsl"))
    call("asset_cook", {})
    for m in materials:
        call("material_set_shader", {"material": m["guid"], "shader": guid})
    call("asset_cook", {})
    print("Shaders/Toon %s: %d materials on it" % (guid, len(materials)))


if __name__ == "__main__":
    main()
