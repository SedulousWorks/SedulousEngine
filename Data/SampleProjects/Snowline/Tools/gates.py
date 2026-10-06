#!/usr/bin/env python3
"""gates.py: the slalom gates' and the finish's prefabs, written through the editor's MCP.

Needs the Blender props imported first (blender/props.py into generated/Props, then importall.py):
GatePole, GateFlagRed, GateFlagBlue and Finish, each a model with its prefab.

- Prefabs/GateRed, Prefabs/GateBlue: two poles HALF_WIDTH either side of the gate's origin (visual
  only: a rider brushing a pole is not stopped dead) and a flag on each, 1.55 m up, out from the
  gate. Each flag is a light dynamic body on a hinge about up anchored in the world (no pole body:
  the joint's target is nil), limited to about 75 degrees either way: gravity does not swing it,
  and its damping takes a swing out. The flags are in collision group FLAG_GROUP, which the scene
  keeps from colliding with anything (course.py): a flag pinned at its limit is a wall, and a rider
  riding into one stopped dead. Gate.as swings a flag the rider brushes past instead.
- Prefabs/GateRedNarrow, Prefabs/GateBlueNarrow: the same, NARROW_HALF_WIDTH either side (Forest).
- Prefabs/FinishLine: the finish arch.

The scene places them (course.py): a gate is an entity with Gate.as and one of these under it.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import Doc, mcp, yaw, assets

HALF_WIDTH = 4.0      # half the gap between a gate's poles (m); Gate.as's halfWidth
NARROW_HALF_WIDTH = 3.0 # Forest's narrower gates (Prefabs/GateRedNarrow, GateBlueNarrow)
FLAG_HEIGHT = 1.55    # the hinge's height, half way up the panel (m)
FLAG_REACH = 0.3      # from the hinge to the panel's centre (m)
FLAG_GROUP = 1        # the flags' collision group; course.py's matrix has it collide with nothing

ASSETS = assets()


def model_prefab(name):
    return next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                and a.get("group", "") == "Models/Props/%sModel" % name)


def existing(name):
    found = [a["guid"] for a in ASSETS if a["type"] == "PrefabDocument" and a["name"] == name
             and a.get("group") == "Prefabs"]
    return found[0] if found else None


def gate(name, flag, half_width=HALF_WIDTH):
    d = Doc(name)
    root = d.entity(name)
    for side, label in ((-1, "L"), (1, "R")):
        pole = d.entity("Pole" + label, (side * half_width, 0, 0), parent=root)
        d.instance(model_prefab("GatePole"), parent=pole)
        # The flag's body sits at its panel's centre, turned so its +X points out from the gate
        # (the model's panel runs along +X from its hinge).
        hinge_x = side * (half_width + 0.03)
        body = d.entity("Flag" + label, (hinge_x + side * FLAG_REACH, FLAG_HEIGHT, 0),
                        yaw(0 if side > 0 else 180), parent=root)
        d.add(body, "physics.RigidBody", motion=2, layer=1, shape=0,
              halfExtents={"x": 0.275, "y": 0.225, "z": 0.01}, mass=0.3, linearDamping=0.6, angularDamping=3.0,
              collisionGroup=FLAG_GROUP)
        d.add(body, "physics.Joint", kind=2, localAnchor={"x": -FLAG_REACH, "y": 0.0, "z": 0.0},
              localAxis={"x": 0.0, "y": 1.0, "z": 0.0}, limitMin=-1.3, limitMax=1.3)
        d.instance(model_prefab(flag), (-FLAG_REACH, 0, 0), parent=body)
    print(name, d.write(existing(name), prefab=True, group="Prefabs"))


def finish_line():
    d = Doc("FinishLine")
    root = d.entity("FinishLine")
    d.instance(model_prefab("Finish"), parent=root)
    print("FinishLine", d.write(existing("FinishLine"), prefab=True, group="Prefabs"))


gate("GateRed", "GateFlagRed")
gate("GateBlue", "GateFlagBlue")
gate("GateRedNarrow", "GateFlagRed", NARROW_HALF_WIDTH)
gate("GateBlueNarrow", "GateFlagBlue", NARROW_HALF_WIDTH)
finish_line()
