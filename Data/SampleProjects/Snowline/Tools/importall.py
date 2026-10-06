#!/usr/bin/env python3
"""importall.py <course>: bring a course's generated files and the props into the project.

Run terrain.py <course> and the Blender props script first (blender/props.py, into
Tools/generated/Props). Imports, each once (a re-run finds each by name and type and leaves it):
- Terrain/<Course>: the heightfield (sized from <course>.json), the splatmap, and the terrain
  asset that ties them to the layers' textures (base snow, then the course, rock and forest).
- Terrain/Textures: the layers' textures.
- Models/Rider/RiderModel: the rider on the board, rigged, with its clips (blender/rider.py, into
  Tools/generated/Rider).
- Models/Props/<Name>Model: the props (a prefab and its mesh each; the kicker its collision too).
Then cooks.
"""
import json, os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import mcp, assets

HERE = os.path.dirname(os.path.abspath(__file__))
name = sys.argv[1] if len(sys.argv) > 1 else "Meadow"
gen = os.path.join(HERE, "generated", name)
info = json.load(open(os.path.join(gen, name + ".json")))


def existing():
    return assets()


# What each importer makes, by its short type name: an asset already of that name and type is the
# import, found again rather than imported twice.
MAKES = {"Texture": "TextureAsset", "Heightfield": "HeightfieldAsset", "Splatmap": "SplatmapAsset",
         "Model": "ModelManifestAsset"}


def imported(path, group, importer, options=None):
    name = os.path.splitext(os.path.basename(path))[0]
    found = [a["guid"] for a in existing() if a["name"] == name and a["type"] == MAKES[importer]]
    if found:
        return found[0]
    args = {"source": path, "group": group, "importer": importer}
    if options:
        args["options"] = options
    r = mcp("asset_import", args)
    print("imported", os.path.basename(path), "->", r["type"], r["guid"])
    return r["guid"]


def write_fields(guid, values):
    """Set payload fields of an asset's envelope (as the editor stores it)."""
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']").find("object")  # the stored object
    for key, value in values.items():
        field = payload.find("*[@name='%s']" % key)
        if field is None:
            raise SystemExit("no field %s on %s" % (key, guid))
        if isinstance(value, (list, tuple)) and field.tag == "array":
            for child in list(field):
                field.remove(child)
            field.set("count", str(len(value)))
            for v in value:
                item = ET.SubElement(field, "string" if isinstance(v, str) else "f32")
                item.text = str(v)
        elif isinstance(value, (list, tuple)):
            for child, v in zip(field, value):
                child.text = repr(float(v))
        else:
            field.text = str(value) if not isinstance(value, float) else repr(value)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})


textures = {}
for layer in ("Snow", "Course", "Rock", "ForestSnow"):
    textures[layer] = imported(os.path.join(gen, layer + ".png"), "Terrain/Textures", "Texture")

height = imported(os.path.join(gen, name + "Height.png"), "Terrain/" + name, "Heightfield")
write_fields(height, {"size": info["size"], "worldSize": (info["world"], info["world"]),
                      "minY": info["min_y"], "maxY": info["max_y"]})
splat = imported(os.path.join(gen, name + "Splat.png"), "Terrain/" + name, "Splatmap")

terrain_name = name + "Terrain"
found = [a["guid"] for a in existing() if a["name"] == terrain_name and a["type"] == "TerrainAsset"]
terrain = found[0] if found else mcp("asset_create", {"creator": "Terrain", "name": terrain_name,
                                                      "group": "Terrain/" + name})["guid"]
write_fields(terrain, {"heightfieldId": height, "weightsId": splat, "baseAlbedoId": textures["Snow"],
                       "baseTileScale": 6.0,
                       "paletteAlbedoIds": [textures["Course"], textures["Rock"], textures["ForestSnow"]],
                       "paletteTileScales": [6.0, 4.0, 6.0],
                       # The layer textures are 256 square: an array slice any larger only upscales them
                       # and ships the extra texels.
                       "paletteTextureSize": 256})
print("terrain", terrain)

rider = os.path.join(HERE, "generated", "Rider", "RiderModel.glb")  # blender/rider.py
if os.path.exists(rider):
    imported(rider, "Models/Rider", "Model")

props = os.path.join(HERE, "generated", "Props")
# The kicker is ridden, so it carries its collision (a triangle mesh: the rider rides its curve).
COLLIDES = {"Kicker"}
for model in ("Pine", "Rock", "GatePole", "GateFlagRed", "GateFlagBlue", "Finish", "Gem", "Kicker"):
    path = os.path.join(props, model + "Model.glb")
    if os.path.exists(path):
        imported(path, "Models/Props", "Model", {"Generate collision": True} if model in COLLIDES else None)

print(json.dumps(mcp("asset_cook", {}), indent=None))
