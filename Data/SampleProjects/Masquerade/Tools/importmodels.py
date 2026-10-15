#!/usr/bin/env python3
"""importmodels.py [Name ...]: the Blender models in generated/ imported through the editor's MCP,
then cooked: the palace kit (blender/palace.py, generated/Palace) into Models/Palace, the canal kit
(blender/canal.py, generated/Canal) into Models/Canal, the garden kit (blender/gardens.py,
generated/Gardens) into Models/Gardens, and the guests
(blender/guest.py, generated/Guests) into Models/Guests, each model its own group
(Models/Palace/Column, Models/Guests/GuestGownRose). With names, only those. A re-run re-imports
over the same assets, keeping their ids.

    blender --background --factory-startup --python blender/palace.py -- generated/Palace
    blender --background --factory-startup --python blender/canal.py -- generated/Canal
    blender --background --factory-startup --python blender/gardens.py -- generated/Gardens
    blender --background --factory-startup --python blender/guest.py -- generated/Guests
    python3 importmodels.py
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

# Each folder of generated models, and the group its models land under.
FOLDERS = (("Palace", "Models/Palace"), ("Canal", "Models/Canal"), ("Gardens", "Models/Gardens"),
           ("Guests", "Models/Guests"))

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
