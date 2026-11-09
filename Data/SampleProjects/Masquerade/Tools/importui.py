#!/usr/bin/env python3
"""importui.py [name ...]: the game's screens on the engine GUI (ui/*.xml and its sheet
ui/MasqueradeSheet.css, group UI, each checked with gui_validate first) imported through the
editor's MCP, the sheet made the project's GUI sheet, then cooked. With names, only those (Hud,
Title, ...). A re-run re-imports over the same assets, keeping their ids: the game's code pushes
the screens by those ids (Code/Masquerade/src/Assets.bf), so a first import into a fresh project
means those ids change there. An asset is named by its file, so a sheet and a document may not
share a name.

A `{{Type:Name}}` in a document or the sheet (Type one of GUI, Scene, Prefab, Audio, Texture: the
prompts' glyphs, glyphs.py) is replaced by that asset's id before it is imported (the filled copy
goes to generated/ui/), and by the nil id when there is no such asset yet.
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, assets

TYPES = {"GUI": "GuiDocumentAsset", "Scene": "SceneDocument", "Prefab": "PrefabDocument", "Audio": "AudioClipAsset",
         "Texture": "TextureAsset"}
NIL = "00000000-0000-0000-0000-000000000000"
FILLED = os.path.join(HERE, "generated", "ui")


def filled(path):
    """The file with its {{Type:Name}} ids filled in: the original when it names none."""
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
sheets = []
for ext in (".xml", ".css"):
    for f in sorted(os.listdir(os.path.join(HERE, "ui"))):
        name, e = os.path.splitext(f)
        if e != ext or (only and name not in only):
            continue
        source = os.path.join(HERE, "ui", f)
        # Checked as its cook will check it: a problem stops the import.
        check = mcp("gui_validate", {"source": open(filled(source)).read(), "kind": "document" if ext == ".xml" else "sheet"})
        if not check["valid"] or check["diagnostics"]:
            sys.exit("%s: %s" % (f, check["diagnostics"]))
        r = mcp("asset_import", {"source": filled(source), "group": "UI"})
        print("UI/" + name, r["guid"])
        if ext == ".css":
            sheets.append(r["guid"])
if sheets:
    mcp("project_settings_set", {"guiStyleSheetIds": sheets}) # the game's look, over the GUI's theme
print(mcp("asset_cook", {}))
