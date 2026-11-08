#!/usr/bin/env python3
"""gems.py: the sparkle a taken gem leaves, its prefab written through the editor's MCP.

Needs particles.py (FX GemSparkle) first, and the project's own editor (Tools/README.md): the
Expire behaviour is the game's code.

- Prefabs/GemSparkle: the burst where a gem was taken (the Gem spawns it): the GemSparkle effect,
  which plays once, and the game's Expire behaviour (snowline.expire), which removes the entity
  once the burst is spent.

The scene places the gems themselves (course.py): a gem is an entity with the Gem behaviour and the
Gem model's prefab under it.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import Doc, mcp, assets

ASSETS = assets()


def asset(asset_type, asset_name):
    return next(a["guid"] for a in ASSETS if a["type"] == asset_type and a["name"] == asset_name)


def existing(name):
    found = [a["guid"] for a in ASSETS if a["type"] == "PrefabDocument" and a["name"] == name
             and a.get("group") == "Prefabs"]
    return found[0] if found else None


d = Doc("GemSparkle")
root = d.entity("GemSparkle")
d.add(root, "particle_effect", effect=asset("ParticleEffectAsset", "GemSparkle"))
d.add(root, "snowline.expire", life=1.2)
print("GemSparkle", d.write(existing("GemSparkle"), prefab=True, group="Prefabs"))
