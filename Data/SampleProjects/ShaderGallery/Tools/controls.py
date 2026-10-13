#!/usr/bin/env python3
"""controls.py: the gallery's input map (Controls), written through the editor's MCP, and made the
project's default.

- Move: WASD or the left stick, along where the camera looks. Rise and Sink: E and Q, or the right
  and left shoulders. Fast: Left Shift, or pressing the left stick.
- Look: the mouse while its right button is held (LookHold), or the right stick (LookStick): two
  actions, since the mouse moves in pixels a frame and the stick in -1 to 1.
- TogglePanel: H, or the north button (Y): the lesson list shown or hidden.
Codes are the engine's enums' values (Sedulous.Shell KeyCode, MouseButton and GamepadButton,
Sedulous.Input StickCode and BindingSource).
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import mcp, assets

KEY, MOUSE_BUTTON, MOUSE_DELTA, GAMEPAD_BUTTON, GAMEPAD_STICK, COMPOSITE = 0, 1, 3, 4, 6, 7
BUTTON, AXIS2D = 0, 2
A, D, E, H, Q, S, W = 1, 4, 5, 8, 17, 19, 23
LEFT_SHIFT = 109
NORTH, LEFT_SHOULDER, RIGHT_SHOULDER, LEFT_STICK_PRESS = 3, 4, 5, 6
LEFT_STICK, RIGHT_STICK = 0, 1
RIGHT_MOUSE = 2

ACTIONS = [
    ("Move", AXIS2D, [dict(source=COMPOSITE, negX=A, posX=D, negY=S, posY=W),
                      dict(source=GAMEPAD_STICK, code=LEFT_STICK, invert=True)]),
    ("Rise", BUTTON, [dict(source=KEY, code=E), dict(source=GAMEPAD_BUTTON, code=RIGHT_SHOULDER)]),
    ("Sink", BUTTON, [dict(source=KEY, code=Q), dict(source=GAMEPAD_BUTTON, code=LEFT_SHOULDER)]),
    ("Fast", BUTTON, [dict(source=KEY, code=LEFT_SHIFT), dict(source=GAMEPAD_BUTTON, code=LEFT_STICK_PRESS)]),
    ("Look", AXIS2D, [dict(source=MOUSE_DELTA)]),
    ("LookHold", BUTTON, [dict(source=MOUSE_BUTTON, code=RIGHT_MOUSE)]),
    ("LookStick", AXIS2D, [dict(source=GAMEPAD_STICK, code=RIGHT_STICK, invert=True)]),
    ("TogglePanel", BUTTON, [dict(source=KEY, code=H), dict(source=GAMEPAD_BUTTON, code=NORTH)]),
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
