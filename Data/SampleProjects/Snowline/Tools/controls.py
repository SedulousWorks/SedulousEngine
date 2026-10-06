#!/usr/bin/env python3
"""controls.py: Snowline's input map (Controls), written through the editor's MCP, and made the
project's default.

- Move: WASD or the left stick (x steers: carves left and right; y unused yet).
- Jump: Space, or the gamepad's south button (A): crouch to pop off a lip.
- Tuck: Left Shift, or the west button (X) or right shoulder: low and fast.
- Grab: E, or the east button (B): in the air, a hand to the board.
- Pause: Escape, or Start.
Codes are the engine's enums' values (Sedulous.Shell KeyCode and GamepadButton, Sedulous.Input
StickCode).
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import mcp, assets

KEY, GAMEPAD_BUTTON, GAMEPAD_STICK, COMPOSITE = 0, 4, 6, 7
BUTTON, AXIS2D = 0, 2
A, D, E, S, W = 1, 4, 5, 19, 23
ESCAPE, SPACE, LEFT_SHIFT = 62, 65, 109
SOUTH, EAST, WEST, RIGHT_SHOULDER, START = 0, 1, 2, 5, 14
LEFT_STICK = 0

ACTIONS = [
    ("Move", AXIS2D, [dict(source=COMPOSITE, negX=A, posX=D, negY=S, posY=W),
                      dict(source=GAMEPAD_STICK, code=LEFT_STICK, invert=True)]),
    ("Jump", BUTTON, [dict(source=KEY, code=SPACE), dict(source=GAMEPAD_BUTTON, code=SOUTH)]),
    ("Tuck", BUTTON, [dict(source=KEY, code=LEFT_SHIFT), dict(source=GAMEPAD_BUTTON, code=WEST),
                      dict(source=GAMEPAD_BUTTON, code=RIGHT_SHOULDER)]),
    ("Grab", BUTTON, [dict(source=KEY, code=E), dict(source=GAMEPAD_BUTTON, code=EAST)]),
    ("Pause", BUTTON, [dict(source=KEY, code=ESCAPE), dict(source=GAMEPAD_BUTTON, code=START)]),
]


def el(parent, tag, name=None, text=None, **attrs):
    e = ET.SubElement(parent, tag, **({"name": name} if name else {}), **attrs)
    if text is not None:
        e.text = text
    return e


def binding(parent, b):
    """One binding, every field (arrays of structs are written flat)."""
    el(parent, "u8", "source", str(b["source"]))
    el(parent, "u32", "code", str(b.get("code", 0)))
    el(parent, "u32", "modifiers", "0")
    el(parent, "i32", "device", "-1")
    el(parent, "f32", "deadZone", "0.15")
    el(parent, "f32", "scale", "1")
    el(parent, "bool", "invert", "true" if b.get("invert") else "false")
    el(parent, "bool", "normalize", "true")
    for k in ("negX", "posX", "negY", "posY"):
        el(parent, "u32", k, str(b.get(k, 0)))
    for k, v in (("regionX", "0"), ("regionY", "0"), ("regionW", "1"), ("regionH", "1"), ("stickRadius", "0.15")):
        el(parent, "f32", k, v)


def main():
    found = [a["guid"] for a in assets() if a["type"] == "InputMapAsset" and a["name"] == "Controls"]
    guid = found[0] if found else mcp("asset_create", {"creator": "Input Map", "name": "Controls"})["guid"]
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']")
    body = payload.find("object")  # the stored object, inside the payload
    old = body.find("array[@name='sets']")
    index = list(body).index(old)
    body.remove(old)
    sets = ET.Element("array", name="sets", count="1")
    body.insert(index, sets)
    el(sets, "string", "name", "Gameplay")
    el(sets, "i32", "priority", "0")
    actions = el(sets, "array", "actions", count=str(len(ACTIONS)))
    for name, kind, bindings in ACTIONS:
        el(actions, "string", "name", name)
        el(actions, "u8", "kind", str(kind))
        for k, v in (("sensitivity", "0"), ("gravity", "0")):
            el(actions, "f32", k, v)
        el(actions, "bool", "snap", "false")
        el(actions, "f32", "responseExponent", "1")
        el(actions, "bool", "timeScale", "false")
        el(actions, "u8", "interaction", "0")
        el(actions, "f32", "interactionSeconds", "0.3")
        b = el(actions, "array", "bindings", count=str(len(bindings)))
        for each in bindings:
            binding(b, each)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    mcp("project_settings_set", {"defaultInputMapId": guid})
    print("Controls", guid)


main()
