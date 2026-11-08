#!/usr/bin/env python3
"""importui.py [name ...]: the gallery's GUI documents and sheets (ui/*.xml and ui/*.css, group
UI, each checked with gui_validate first) imported through the editor's MCP, the sheets made the
project's GUI sheets, then cooked. With names, only those (Gallery, GallerySheet). A re-run
re-imports over the same assets, keeping their ids. ui.py writes ui/Gallery.xml and
ui/GallerySheet.css first (from lessons.py); hall.py names the list's document on the camera's
Gallery behaviour.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

only = set(sys.argv[1:])
sheets = []
for ext in (".xml", ".css"):
    for f in sorted(os.listdir(os.path.join(HERE, "ui"))):
        name, e = os.path.splitext(f)
        if e != ext or (only and name not in only):
            continue
        source = os.path.join(HERE, "ui", f)
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
