#!/usr/bin/env python3
"""surfaces.py: what the manor is made of, as physical materials (Surfaces/), written through the
editor's MCP. A floor's collider names one (room.py), which sets how it grips and how a step on it
sounds: Footsteps.as reads the material under the foot (RayCastHit.material) and plays that
surface's steps (sounds.py's Audio/Step<Surface><take>), louder on gravel, softer on grass.
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import mcp, num, assets

# name: (friction, restitution, density kg/m^3)
SURFACES = {
    "Wood": (0.6, 0.05, 700.0),
    "Stone": (0.7, 0.02, 2500.0),
    "Gravel": (0.9, 0.0, 1700.0),
    "Grass": (0.8, 0.0, 1100.0),
}


def surfaces():
    """Every surface's guid by name, made the first time and its fields rewritten each time."""
    listed = assets()
    out = {}
    for name, values in SURFACES.items():
        found = [a["guid"] for a in listed if a["type"] == "PhysicalMaterialAsset" and a["name"] == name]
        guid = found[0] if found else mcp("asset_create", {"creator": "Physical Material", "name": name,
                                                           "group": "Surfaces"})["guid"]
        root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
        payload = root.find("object[@name='payload']")
        for key, value in zip(("friction", "restitution", "density"), values):
            payload.find(".//f32[@name='%s']" % key).text = num(value)
        mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
        out[name] = guid
    return out


if __name__ == "__main__":
    for name, guid in surfaces().items():
        print(name, guid)
