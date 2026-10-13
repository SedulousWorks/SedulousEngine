#!/usr/bin/env python3
"""shaders.py [n ...]: each lesson's shader and material, through the editor's MCP (lessons.py's
table). With lesson numbers, only those.

For each lesson: the shader file (shaders/NN_Name.hlsl) checked with shader_validate, imported into
the Shaders group (a re-run re-imports over the same asset), the generated textures imported into
Textures, a cook, then the lesson's material (Materials/<Name>, made once) put on its shader with
material_set_shader, its parameters and textures set by property name in its envelope with its
blend and cull modes, and a cook.
textures.py runs first (it writes generated/).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, assets
from materialvalues import set_values
from lessons import LESSONS, shader_file


def assets_by(type_name):
    return {a["name"]: a["guid"] for a in assets() if a["type"] == type_name}


def import_file(path, group):
    return mcp("asset_import", {"source": path, "group": group})["guid"]


def main():
    only = {int(a) for a in sys.argv[1:]}
    lessons = [l for l in LESSONS if not only or l["n"] in only]

    for l in lessons:
        path = os.path.join(HERE, "shaders", shader_file(l))
        check = mcp("shader_validate", {"source": open(path).read(), "name": shader_file(l)})
        if not check["valid"]:
            raise SystemExit("%s: %s" % (shader_file(l), check["errors"]))
        import_file(path, "Shaders")
        print("shader", shader_file(l), check["kind"])
    wanted = {t for l in lessons for t in l.get("textures", {}).values()}
    for texture in sorted(wanted):
        path = os.path.join(HERE, "generated", texture)
        import_file(path + (".jpg" if os.path.exists(path + ".jpg") else ".png"), "Textures")
    mcp("asset_cook", {})

    shaders = assets_by("ShaderAsset")
    materials = assets_by("MaterialAsset")
    textures = assets_by("TextureAsset")
    for l in lessons:
        shader = shaders[os.path.splitext(shader_file(l))[0]]
        guid = materials.get(l["name"])
        if guid is None:
            guid = mcp("asset_create", {"creator": "PBR Material", "name": l["name"], "group": "Materials"})["guid"]
        mcp("material_set_shader", {"material": guid, "shader": shader})
        set_values(guid, l.get("params", {}), l.get("textures", {}), textures, l.get("blend", 0),
                   l.get("cull", 1))
        print("material", l["name"])
    mcp("asset_cook", {})


main()
