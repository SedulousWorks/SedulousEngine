#!/usr/bin/env python3
"""importmodels.py [Name ...]: the Blender exhibits in generated/Exhibits imported through the
editor's MCP into Models (each model its own group, Models/Knot and so on), then cooked. With
names, only those. A re-run re-imports over the same assets, keeping their ids.

    blender --background --factory-startup --python blender/exhibits.py -- generated/Exhibits
    python3 importmodels.py
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

only = set(sys.argv[1:])
path = os.path.join(HERE, "generated", "Exhibits")
for f in sorted(os.listdir(path)):
    name, ext = os.path.splitext(f)
    if ext != ".glb" or (only and name not in only):
        continue
    r = mcp("asset_import", {"source": os.path.join(path, f), "group": "Models"})
    print("Models/" + name, r["guid"])
print(mcp("asset_cook", {}))
