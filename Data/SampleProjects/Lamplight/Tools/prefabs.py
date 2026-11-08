#!/usr/bin/env python3
"""prefabs.py: Lamplight's prefabs (Prefabs/), written through the editor's MCP.

- Prefabs/Pebble: the stone the thief throws (the Thief spawns it and gives it its speed): a small
  dynamic sphere with continuous collision so a fast throw does not pass through a wall, the
  seeded Sphere mesh scaled down under it (the body stays unscaled), and the Pebble behaviour,
  whose first hard landing makes a Noise a guard may hear.

The behaviour is the game's own (lamplight.pebble: Code/Lamplight), so the editor this talks to is
the project's own (README.md).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import Doc, mcp, assets
from materials import all_materials

RADIUS = 0.04


def asset(asset_type, name):
    found = [a["guid"] for a in assets() if a["type"] == asset_type and a["name"] == name]
    return found[0] if found else None


def pebble(mats):
    d = Doc("Pebble")
    root = d.entity("Pebble")
    d.add(root, "physics.RigidBody", motion=2, layer=1, shape=1, radius=RADIUS, mass=0.1,
          continuousCollision=True, friction=0.8, restitution=0.3)
    stone = d.entity("Stone", scale=(RADIUS * 2, RADIUS * 2, RADIUS * 2), parent=root)
    d.add(stone, "mesh", mesh=asset("StaticMeshAsset", "Sphere"), materials=["<string>%s</string>" % mats["Pebble"]])
    d.add(root, "lamplight.pebble")
    return d.write(asset("PrefabDocument", "Pebble"), prefab=True, group="Prefabs")


if __name__ == "__main__":
    print("Pebble", pebble(all_materials()))
