#!/usr/bin/env python3
"""importscripts.py [name ...]: the gallery's GUI documents and sheets (ui/*.gml and ui/*.css,
group UI, each checked with gui_validate first) and scripts (scripts/*.as, group Scripts) imported
through the editor's MCP, the sheets made the project's GUI sheets, then cooked. With names, only
those (Gallery, ...). A re-run re-imports over the same assets, keeping their ids. ui.py writes
ui/Gallery.gml, ui/GallerySheet.css and scripts/Gallery.as first (from lessons.py).

The documents go first, so a script can name them: a `{{Type:Name}}` in a script (Type one of GUI,
Scene, Prefab, Audio) is replaced by that asset's id before it is imported (the filled copy goes to
generated/scripts/), and by the nil id when there is no such asset yet (a level not built).
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, assets

TYPES = {"GUI": "GuiDocumentAsset", "Scene": "SceneDocument", "Prefab": "PrefabDocument", "Audio": "AudioClipAsset"}
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
sheets = []
for folder, ext, group in (("ui", ".gml", "UI"), ("ui", ".css", "UI"), ("scripts", ".as", "Scripts")):
    if not os.path.isdir(os.path.join(HERE, folder)):
        continue
    for f in sorted(os.listdir(os.path.join(HERE, folder))):
        name, e = os.path.splitext(f)
        if e != ext or (only and name not in only):
            continue
        source = os.path.join(HERE, folder, f)
        if ext in (".gml", ".css"):
            # Checked as its cook will check it: a problem stops the import.
            check = mcp("gui_validate", {"source": open(source).read(), "kind": "document" if ext == ".gml" else "sheet"})
            if not check["valid"] or check["diagnostics"]:
                sys.exit("%s: %s" % (f, check["diagnostics"]))
        r = mcp("asset_import", {"source": filled(source) if ext == ".as" else source, "group": group})
        print(group + "/" + name, r["guid"])
        if ext == ".css":
            sheets.append(r["guid"])
if sheets:
    mcp("project_settings_set", {"guiStyleSheetIds": sheets}) # the game's look, over the GUI's theme
print(mcp("asset_cook", {}))
