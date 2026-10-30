#!/usr/bin/env python3
"""importui.py [name ...]: the game's screens on the engine GUI (ui/*.gml and its sheet
ui/SkyHopperSheet.css, group UI, each checked with gui_validate first) imported through the
editor's MCP, the sheet made the project's GUI sheet, then cooked. With names, only those (Hud,
Title, ...). A re-run re-imports over the same assets, keeping their ids; PlatformerGame.as names
the screens by id. An asset is named by its file, so a sheet and a document may not share a name.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mcp import call

only = set(sys.argv[1:])
sheets = []
for ext in (".gml", ".css"):
    for f in sorted(os.listdir(os.path.join(HERE, "ui"))):
        name, e = os.path.splitext(f)
        if e != ext or (only and name not in only):
            continue
        source = os.path.join(HERE, "ui", f)
        # Checked as its cook will check it: a problem stops the import.
        check = call("gui_validate", {"source": open(source).read(), "kind": "document" if ext == ".gml" else "sheet"})
        if not check["valid"] or check["diagnostics"]:
            sys.exit("%s: %s" % (f, check["diagnostics"]))
        r = call("asset_import", {"source": source, "group": "UI"})
        print("UI/" + name, r["guid"])
        if ext == ".css":
            sheets.append(r["guid"])
if sheets:
    call("project_settings_set", {"guiStyleSheetIds": sheets}) # the game's look, over the GUI's theme
print(call("asset_cook", {}))
