#!/usr/bin/env python3
"""touch.py: Sky Hopper's touch controls, added to its input map (Controls) through the editor's MCP.

- A floating stick on the left half moves; Jump, a compact button in the bottom-right corner;
  Pause small in the top-left, under the HUD.
The engine draws a guide to them once the screen is touched. The map's other bindings stay as
they are; its touch bindings are replaced, so this can run again after a change. Regions are
x, y, width, height, normalized over the screen; codes are the engine's enums' values
(Sedulous.Input BindingSource).
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcp import call as mcp

TOUCH_BUTTON, TOUCH_STICK = 8, 9

TOUCH = {
    "Move": [dict(source=TOUCH_STICK, region=(0, 0.26, 0.5, 0.74), stickRadius=0.12, invert=True)],
    "Jump": [dict(source=TOUCH_BUTTON, region=(0.86, 0.72, 0.13, 0.25))],
    "Pause": [dict(source=TOUCH_BUTTON, region=(0.0, 0.11, 0.09, 0.13))],
}


def binding(parent, b):
    """One touch binding, every field (arrays of structs are written flat)."""
    def el(tag, name, text):
        e = ET.SubElement(parent, tag, name=name)
        e.text = text
    el("u8", "source", str(b["source"]))
    el("u32", "code", "0")
    el("u32", "modifiers", "0")
    el("i32", "device", "-1")
    el("f32", "deadZone", "0.15")
    el("f32", "scale", "1")
    el("bool", "invert", "true" if b.get("invert") else "false")
    el("bool", "normalize", "true")
    for k in ("negX", "posX", "negY", "posY"):
        el("u32", k, "0")
    for k, v in zip(("regionX", "regionY", "regionW", "regionH"), b["region"]):
        el("f32", k, str(v))
    el("f32", "stickRadius", str(b.get("stickRadius", 0.15)))


def main():
    assets = mcp("asset_list", {})["assets"]
    guid = [a["guid"] for a in assets if a["type"].rsplit(".", 1)[-1] == "InputMapAsset" and a["name"] == "Controls"][0]
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    done = set()
    for actions in root.iter("array"):
        if actions.get("name") != "actions":
            continue
        name = None
        for child in list(actions):
            if child.tag == "string" and child.get("name") == "name":
                name = child.text
            if child.tag != "array" or child.get("name") != "bindings" or name not in TOUCH:
                continue
            # The bindings, each starting at its source; keep all but the touch ones.
            groups = []
            for field in list(child):
                if field.get("name") == "source":
                    groups.append([])
                groups[-1].append(field)
                child.remove(field)
            kept = [g for g in groups if int(g[0].text) not in (TOUCH_BUTTON, TOUCH_STICK)]
            for g in kept:
                child.extend(g)
            for b in TOUCH[name]:
                binding(child, b)
            child.set("count", str(len(kept) + len(TOUCH[name])))
            done.add(name)
    missing = set(TOUCH) - done
    if missing:
        raise SystemExit("no action named %s in Controls" % ", ".join(sorted(missing)))
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    print("Controls", guid, "touch:", ", ".join(sorted(done)))


main()
