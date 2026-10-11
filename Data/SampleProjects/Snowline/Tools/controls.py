#!/usr/bin/env python3
"""controls.py: Snowline's input map (Controls), written through the editor's MCP, and made the
project's default.

- Move: WASD or the left stick (x steers: carves left and right; y unused yet).
- Jump: Space, or the gamepad's south button (A): crouch to pop off a lip.
- Tuck: Left Shift, or the west button (X) or right shoulder: low and fast.
- Grab: E, or the east button (B): in the air, a hand to the board.
- Pause: Escape, or Start.
- On a touch screen: a floating stick on the left half carves; compact buttons in the bottom-right
  corner, Jump largest in the corner, Tuck beside it, Grab above it; Pause small under the clock.
  The engine draws them (each zone is its button) once the screen is touched.
Codes are the engine's enums' values (Sedulous.Shell KeyCode and GamepadButton, Sedulous.Input
StickCode).
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import mcp, assets

KEY, GAMEPAD_BUTTON, GAMEPAD_STICK, COMPOSITE, TOUCH_BUTTON, TOUCH_STICK = 0, 4, 6, 7, 8, 9
BUTTON, AXIS2D = 0, 2
A, D, E, S, W = 1, 4, 5, 19, 23
ESCAPE, SPACE, LEFT_SHIFT = 62, 65, 109
SOUTH, EAST, WEST, RIGHT_SHOULDER, START = 0, 1, 2, 5, 14
LEFT_STICK = 0

ACTIONS = [
    ("Move", AXIS2D, [dict(source=COMPOSITE, negX=A, posX=D, negY=S, posY=W),
                      dict(source=GAMEPAD_STICK, code=LEFT_STICK, invert=True),
                      dict(source=TOUCH_STICK, region=(0, 0.26, 0.5, 0.74), stickRadius=0.12, invert=True)]),
    ("Jump", BUTTON, [dict(source=KEY, code=SPACE), dict(source=GAMEPAD_BUTTON, code=SOUTH),
                      dict(source=TOUCH_BUTTON, region=(0.86, 0.72, 0.13, 0.25))]),
    ("Tuck", BUTTON, [dict(source=KEY, code=LEFT_SHIFT), dict(source=GAMEPAD_BUTTON, code=WEST),
                      dict(source=GAMEPAD_BUTTON, code=RIGHT_SHOULDER),
                      dict(source=TOUCH_BUTTON, region=(0.73, 0.76, 0.12, 0.22))]),
    ("Grab", BUTTON, [dict(source=KEY, code=E), dict(source=GAMEPAD_BUTTON, code=EAST),
                      dict(source=TOUCH_BUTTON, region=(0.86, 0.46, 0.13, 0.24))]),
    ("Pause", BUTTON, [dict(source=KEY, code=ESCAPE), dict(source=GAMEPAD_BUTTON, code=START),
                       dict(source=TOUCH_BUTTON, region=(0.0, 0.11, 0.09, 0.13))]),
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
    region = b.get("region", (0, 0, 1, 1))  # touch: x, y, width, height, normalized over the screen
    for k, v in zip(("regionX", "regionY", "regionW", "regionH"), region):
        el(parent, "f32", k, str(v))
    el(parent, "f32", "stickRadius", str(b.get("stickRadius", 0.15)))


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
