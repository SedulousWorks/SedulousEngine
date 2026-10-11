#!/usr/bin/env python3
"""importmodels.py [Name ...]: the Blender models in generated/ imported through the editor's MCP,
then cooked: the manor kit (blender/manor.py, generated/Manor) into Models/Manor, the grounds kit
(blender/grounds.py) into Models/Grounds, the loot (blender/loot.py) into Models/Loot, and the thief
(blender/thief.py, generated/Thief) and the guard (blender/guard.py, generated/Guard) into Models,
each model its own group (Models/Manor/Wall, Models/Thief, Models/Guard). With names, only those.
A re-run re-imports over the same assets, keeping their ids.

    blender --background --factory-startup --python blender/manor.py -- generated/Manor
    blender --background --factory-startup --python blender/grounds.py -- generated/Grounds
    blender --background --factory-startup --python blender/loot.py -- generated/Loot
    blender --background --factory-startup --python blender/thief.py -- generated/Thief
    blender --background --factory-startup --python blender/guard.py -- generated/Guard
    python3 importmodels.py
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

# Each folder of generated models, and the group its models land under.
FOLDERS = (("Manor", "Models/Manor"), ("Grounds", "Models/Grounds"), ("Loot", "Models/Loot"), ("Thief", "Models"),
           ("Guard", "Models"))

only = set(sys.argv[1:])
for folder, group in FOLDERS:
    path = os.path.join(HERE, "generated", folder)
    if not os.path.isdir(path):
        continue
    for f in sorted(os.listdir(path)):
        name, ext = os.path.splitext(f)
        if ext != ".glb" or (only and name not in only):
            continue
        r = mcp("asset_import", {"source": os.path.join(path, f), "group": group})
        print(group + "/" + name, r["guid"])
print(mcp("asset_cook", {}))
