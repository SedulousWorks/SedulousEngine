#!/usr/bin/env python3
"""ik.py: the hero's inverse kinematics in every level, through the editor's MCP tools.

The Player entity (the gameplay root; the Character model is its child, the importer's prefab)
gets two components, which drive the model's animator below it:
- Foot IK: the feet stand on the ground under them. The Character rig's feet are IK target bones
  off the root (detached), met by the shins; the pelvis is Body (it carries the legs).
  PlayerController turns it off in the air.
- Aim IK: the head (Neck 0.4, Head 1.0) looks at the nearest coin within reach; Coin.as picks the
  coin and sets the target, and turns it off when none is near.

`ik.py` writes every level; `ik.py Level2` one. A rerun rewrites the same values. Raptor's ik.py,
with this engine's component ids and field names (as entity_inspect shows them).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skygen import assets, mcp

LEVELS = ["Level1", "Level2", "Level3", "Level4", "Level5"]

FEET = {
    "Legs": [
        {"StartBone": "UpperLeg.L", "MidBone": "LowerLeg.L", "EndBone": "Foot.L"},
        {"StartBone": "UpperLeg.R", "MidBone": "LowerLeg.R", "EndBone": "Foot.R"},
    ],
    "PelvisBone": "Body",
    "PelvisDropMax": 0.25,
    "LiftHeight": 0.2,
}
LOOK = {
    "Bones": [{"Bone": "Neck", "Share": 0.4}, {"Bone": "Head", "Share": 1.0}],
    "MaxAngle": 70.0,
    "FadeSeconds": 0.35,
    "Active": False,  # until a coin is near
}


def scenes():
    return {a["name"]: a["guid"] for a in assets() if a["type"] == "SceneDocument"}


def has(page, component):
    entity = mcp("entity_inspect", {"page": page, "entity": "Player"})["entity"]
    return any(c["type"] == component for c in entity["components"])


def write(level, guid):
    mcp("page_open", {"guid": guid})
    for component, values in (("foot_ik", FEET), ("aim_ik", LOOK)):
        if not has(guid, component):
            mcp("component_add", {"page": guid, "entity": "Player", "component": component})
        for prop, value in values.items():
            mcp("component_set", {"page": guid, "entity": "Player", "component": component,
                                  "property": prop, "value": value})
    mcp("action_execute", {"id": "file.save"})
    print(level, "done")


def main():
    found = scenes()
    for level in (sys.argv[1:] or LEVELS):
        write(level, found[level])


main()
