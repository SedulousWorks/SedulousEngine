#!/usr/bin/env python3
"""ghosts.py: the ghosts' materials, written through the editor's MCP.

- Materials/GhostGold, GhostSilver, GhostBronze: one per medal, its colour, see-through (alpha
  blended) and glowing a little, so a ghost reads as a ghost against the snow and in the shade.
  course.py gives a ghost's rider model this material in every slot: a silhouette in the medal's
  colour.
- Materials/GhostPlayer: the player's own best run (PlayerGhost.as), the same, in pale blue.

A material starts from the engine's own new PBR material (asset_create, then asset_data_read), so
the fields this does not set keep the engine's defaults; its uniforms are written by the offsets
the material lists (BaseColor RGBA at its offset, EmissiveColor likewise). Colours are linear.
"""
import os, struct, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import mcp, assets

ALPHA_BLEND = 2  # Sedulous.Materials BlendMode.AlphaBlend
OPACITY = 0.6
GLOW = 0.7       # the emissive colour's share of the base colour

GHOSTS = {"GhostGold": (1.0, 0.70, 0.12), "GhostSilver": (0.72, 0.78, 0.88), "GhostBronze": (0.72, 0.38, 0.16),
          "GhostPlayer": (0.35, 0.75, 1.0)}

ASSETS = assets()


def material(name, rgb):
    found = [a["guid"] for a in ASSETS if a["type"] == "MaterialAsset" and a["name"] == name]
    guid = found[0] if found else mcp("asset_create", {"creator": "PBR Material", "name": name,
                                                       "group": "Materials"})["guid"]
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']").find("object").find("object")  # the material, under its file name
    payload.find("*[@name='blendMode']").text = str(ALPHA_BLEND)
    names = [e.text for e in payload.find("array[@name='propertyNames']")]
    offsets = [int(e.text) for e in payload.find("array[@name='propertyOffsets']")]
    uniforms = payload.find("array[@name='uniformDefaults']")
    data = bytearray(int(e.text) for e in uniforms)

    def put(prop, values):
        at = offsets[names.index(prop)]
        data[at:at + 4 * len(values)] = struct.pack("<%df" % len(values), *values)

    put("BaseColor", (rgb[0], rgb[1], rgb[2], OPACITY))
    put("EmissiveColor", (rgb[0] * GLOW, rgb[1] * GLOW, rgb[2] * GLOW, 1.0))
    put("Roughness", (0.4,))
    for e, b in zip(uniforms, data):
        e.text = str(b)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    print(name, guid)
    return guid


for n, c in GHOSTS.items():
    material(n, c)
