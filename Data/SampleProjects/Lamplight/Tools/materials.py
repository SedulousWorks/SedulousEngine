"""materials.py: Lamplight's materials, written through the editor's MCP.

Each starts from the engine's own new PBR material (asset_create, then asset_data_read), so the
fields this does not set keep the engine's defaults; its uniforms are written by the offsets the
material lists. Colours are sRGB, as entered anywhere.

- Materials/FlameOut, Materials/ChimneyOut: an oil lamp put out (Lamp.as), its wick and glass no
  longer glowing.
- Materials/Pebble: the thrown stone's grey.

The room's pieces, the thief and the guard bring their own (blender/manor.py, thief.py, guard.py).
"""
import os, struct, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import mcp, assets

MATERIALS = {
    # name: (base colour, roughness, metallic, emissive colour or None)
    # A lamp put out (Lamp.as swaps them in for the kit's glowing Flame and Chimney): a charred
    # wick, and the chimney's glass dark and glossy.
    "FlameOut": ((0.10, 0.08, 0.07), 0.8, 0.0, None),
    "ChimneyOut": ((0.42, 0.40, 0.37), 0.15, 0.0, None),
    "Pebble": ((0.45, 0.43, 0.40), 0.75, 0.0, None),  # a grey stone (prefabs.py's Pebble)
}

_assets = None


def material(name, colour, roughness, metallic, emissive):
    global _assets
    if _assets is None:
        _assets = assets()
    found = [a["guid"] for a in _assets if a["type"] == "MaterialAsset" and a["name"] == name]
    guid = found[0] if found else mcp("asset_create", {"creator": "PBR Material", "name": name,
                                                       "group": "Materials"})["guid"]
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']")
    names = [e.text for e in payload.find(".//array[@name='propertyNames']")]
    offsets = [int(e.text) for e in payload.find(".//array[@name='propertyOffsets']")]
    uniforms = payload.find(".//array[@name='uniformDefaults']")
    data = bytearray(int(e.text) for e in uniforms)

    def put(prop, values):
        at = offsets[names.index(prop)]
        data[at:at + 4 * len(values)] = struct.pack("<%df" % len(values), *values)

    put("BaseColor", (colour[0], colour[1], colour[2], 1.0))
    put("Roughness", (roughness,))
    put("Metallic", (metallic,))
    if emissive is not None:
        put("EmissiveColor", (emissive[0], emissive[1], emissive[2], 1.0))
    for e, b in zip(uniforms, data):
        e.text = str(b)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    return guid


def all_materials():
    """Every material's guid by name, made or rewritten."""
    return {name: material(name, *spec) for name, spec in MATERIALS.items()}


if __name__ == "__main__":
    for name, guid in all_materials().items():
        print(name, guid)
