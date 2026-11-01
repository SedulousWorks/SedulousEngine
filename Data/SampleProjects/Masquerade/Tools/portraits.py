#!/usr/bin/env python3
"""portraits.py: each costume's head and shoulders as a picture (the HUD's mark shows the costume
to find), rendered by Blender from the costumes' own models (`blender/guest.py ... portraits`) and
imported through the editor's MCP as textures in UI/Portraits. Before importscripts.py, whose game
script names them (`{{Texture:PortraitGownRose}}`).

  Tools/portraits.py       renders into Tools/generated/portraits and imports
  Env: BLENDER (default ~/Applications/blender-5.2.2-linux-x64/blender)
"""
import os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

BLENDER = os.environ.get("BLENDER", os.path.expanduser("~/Applications/blender-5.2.2-linux-x64/blender"))
OUT = os.path.join(HERE, "generated", "portraits")
COSTUMES = ["GownRose", "GownTeal", "GownGold", "CoatBlack", "CoatPlum", "CoatIvory"]


def main():
    os.makedirs(OUT, exist_ok=True)
    subprocess.run([BLENDER, "--background", "--factory-startup", "--python", "guest.py", "--", OUT, "portraits"],
                   cwd=os.path.join(HERE, "blender"), check=True, stdout=subprocess.DEVNULL)
    for name in COSTUMES:
        path = os.path.join(OUT, "Portrait%s.png" % name)
        r = mcp("asset_import", {"source": path, "group": "UI/Portraits", "importer": "Texture"})
        print("UI/Portraits/Portrait" + name, r["guid"])


if __name__ == "__main__":
    main()
