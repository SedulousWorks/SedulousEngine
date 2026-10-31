#!/usr/bin/env python3
"""importui.py [name ...]: the game's screens on the engine GUI (ui/*.xml and its sheet
ui/PaperKidSheet.css, group UI, each checked with gui_validate first) imported through the editor's
MCP, the sheet made the project's GUI sheet, then cooked. With names, only those (Hud, Title, ...).
A re-run re-imports over the same assets, keeping their ids. Run render.py PaperKidGame after a
first import: the game script names the screens by id. An asset is named by its file, so a sheet
and a document may not share a name. The HUD's minimap image is the Minimap render texture, by id
({{Minimap}} in its source, filled in here: setup.py makes the texture first).
"""
import os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pkgen import mcp, assets

minimap = [a["guid"] for a in assets() if a["name"] == "Minimap" and a["type"] == "RenderTextureAsset"]
if not minimap:
    sys.exit("no Minimap render texture: run setup.py first")
staging = tempfile.mkdtemp(prefix="paperkid-ui-")

only = set(sys.argv[1:])
sheets = []
for ext in (".xml", ".css"):
    for f in sorted(os.listdir(os.path.join(HERE, "ui"))):
        name, e = os.path.splitext(f)
        if e != ext or (only and name not in only):
            continue
        source = os.path.join(staging, f)
        open(source, "w").write(open(os.path.join(HERE, "ui", f)).read().replace("{{Minimap}}", minimap[0]))
        # Checked as its cook will check it: a problem stops the import.
        check = mcp("gui_validate", {"source": open(source).read(), "kind": "document" if ext == ".xml" else "sheet"})
        if not check["valid"] or check["diagnostics"]:
            sys.exit("%s: %s" % (f, check["diagnostics"]))
        r = mcp("asset_import", {"source": source, "group": "UI"})
        print("UI/" + name, r["guid"])
        if ext == ".css":
            sheets.append(r["guid"])
if sheets:
    mcp("project_settings_set", {"guiStyleSheetIds": sheets}) # the game's look, over the GUI's theme
print(mcp("asset_cook", {}))
