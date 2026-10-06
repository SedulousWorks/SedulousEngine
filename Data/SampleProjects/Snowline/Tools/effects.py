#!/usr/bin/env python3
"""effects.py: the board's marks in the snow, written through the editor's MCP.

- Effects/Track.png (generated: no third-party content): one stretch of the board's track, a soft
  groove a board wide, its ends tapered so the next mark's overlap joins it.
- Prefabs/TrackMark: the track's mark, as the board drops them behind it (Board.as spawns one every
  `trackSpacing` metres and turns it to the heading): an unrotated root carrying TrackMark.as (it
  fades the mark and removes it) and a child decal pitched to project down onto the snow (a decal
  projects along its local +Z).
"""
import math, os, random, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import Doc, mcp, pitch, assets

GEN = os.path.join(HERE, "generated", "Effects")


def track_texture(path):
    w, h = 64, 256
    rnd = random.Random(21)
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for y in range(h):
        along = y / (h - 1)
        ends = min(1.0, min(along, 1.0 - along) / 0.18)  # the ends taper into the next mark
        for x in range(w):
            across = abs(x / (w - 1) * 2.0 - 1.0)
            groove = max(0.0, 1.0 - across ** 3)          # flat in the middle, soft at the edges
            ridge = 0.25 * max(0.0, 1.0 - abs(across - 0.9) / 0.1)  # snow pushed up at the edges
            a = (groove * 0.8 + ridge) * ends * (0.85 + rnd.random() * 0.15)
            shade = 0.70 + 0.10 * ridge + rnd.random() * 0.04
            px[x, y] = (int(shade * 0.88 * 255), int(shade * 0.93 * 255), int(shade * 255), int(max(0, min(1, a)) * 255))
    img.save(path)


def main():
    os.makedirs(GEN, exist_ok=True)
    path = os.path.join(GEN, "Track.png")
    track_texture(path)
    texture = mcp("asset_import", {"source": path, "group": "Effects", "importer": "Texture"})["guid"]
    listed = assets()
    script = next(a["guid"] for a in listed if a["type"] == "ScriptClassAsset" and a["name"] == "TrackMark")
    d = Doc("TrackMark")
    root = d.entity("TrackMark")
    d.script(root, (script, {}))
    mark = d.entity("Decal", (0, 0.4, 0), pitch(90), parent=root)  # +Z down onto the snow
    d.add(mark, "decal", texture=texture, size={"x": 0.34, "y": 1.9, "z": 1.2},
          color={"r": 1.0, "g": 1.0, "b": 1.0, "a": 0.85})
    found = [a["guid"] for a in listed if a["type"] == "PrefabDocument" and a["name"] == "TrackMark"]
    print("TrackMark", d.write(found[0] if found else None, prefab=True, group="Prefabs"))


main()
