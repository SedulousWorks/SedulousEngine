#!/usr/bin/env python3
"""setup.py: what a fresh project needs before the other tools, through the editor's MCP. Raptor's
project has these from its seeded content and its settings; a new project here has neither.
- Fonts/Roboto-Regular: the UI font, from Sources/Roboto-Regular.ttf, cooked as a distance field
  (mode 1) so large type stays sharp, and made the project's default UI font.
- Meshes/Sphere: the primitive the pebble (prefabs.py) is drawn with.
Each is made once and found by name after, so a re-run changes nothing it made before.
"""
import os, sys
import xml.etree.ElementTree as ET
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, assets


def have(name, asset_type):
    found = [a["guid"] for a in assets() if a["name"] == name and a["type"] == asset_type]
    return found[0] if found else None


font = have("Roboto-Regular", "FontAsset")
if font is None:
    source = os.path.join(os.path.dirname(HERE), "Sources", "Roboto-Regular.ttf")
    font = mcp("asset_import", {"source": source, "group": "Fonts"})["guid"]
root = ET.fromstring(mcp("asset_data_read", {"guid": font})["xml"])
root.find("object[@name='payload']").find("object").find("*[@name='mode']").text = "1"  # distance field
mcp("asset_data_write", {"guid": font, "xml": ET.tostring(root, encoding="unicode")})
mcp("project_settings_set", {"defaultUiFontId": font})
print("Roboto-Regular", font)

if have("Sphere", "StaticMeshAsset") is None:
    print("Sphere", mcp("asset_create", {"creator": "Sphere", "name": "Sphere", "group": "Meshes"})["guid"])
print(mcp("asset_cook", {}))
