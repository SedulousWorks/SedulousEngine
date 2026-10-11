#!/usr/bin/env python3
"""importscripts.py [name ...]: the game's UI documents (ui/*.sml, group UI) and scripts
(scripts/*.as, group Scripts) imported through the editor's MCP, then cooked; the game script
(Lamplight.as, the reserved class Game) made the project's startup script. With names, only those
(Thief, Hud, ...). A re-run re-imports over the same assets, keeping their ids.

The documents go first, so a script can name them: a `{{Type:Name}}` in a script (Type one of UI,
Scene, Prefab, Audio) is replaced by that asset's id before it is imported (the filled copy goes to
generated/scripts/), and by the nil id when there is no such asset yet (a level not built).
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, assets

TYPES = {"UI": "UIDocumentAsset", "Scene": "SceneDocument", "Prefab": "PrefabDocument", "Audio": "AudioClipAsset"}
NIL = "00000000-0000-0000-0000-000000000000"
FILLED = os.path.join(HERE, "generated", "scripts")


def filled(path):
    """The script with its {{Type:Name}} ids filled in: the original when it names none."""
    text = open(path).read()
    if "{{" not in text:
        return path
    listed = assets()

    def one(m):
        found = [a["guid"] for a in listed if a["type"] == TYPES[m.group(1)] and a["name"] == m.group(2)]
        return found[0] if found else NIL

    os.makedirs(FILLED, exist_ok=True)
    out = os.path.join(FILLED, os.path.basename(path))
    open(out, "w").write(re.sub(r"\{\{(\w+):(\w+)\}\}", one, text))
    return out


only = set(sys.argv[1:])
for folder, ext, group in (("ui", ".sml", "UI"), ("scripts", ".as", "Scripts")):
    if not os.path.isdir(os.path.join(HERE, folder)):
        continue
    for f in sorted(os.listdir(os.path.join(HERE, folder))):
        name, e = os.path.splitext(f)
        if e != ext or (only and name not in only):
            continue
        source = os.path.join(HERE, folder, f)
        r = mcp("asset_import", {"source": filled(source) if ext == ".as" else source, "group": group})
        print(group + "/" + name, r["guid"])
        if name == "Lamplight":
            mcp("project_settings_set", {"startupScriptId": r["guid"]})
print(mcp("asset_cook", {}))
