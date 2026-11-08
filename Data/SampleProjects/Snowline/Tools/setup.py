#!/usr/bin/env python3
"""setup.py: a fresh project's first run, what the other tools build on, through the editor's MCP.
Run controls.py, look.py, importall.py (each course) and sounds.py first; then this:
- UI/Thumbs/<Course>: the title's course pictures (generated/Thumbs; thumbnails.py remakes them
  from the scenes once those exist).
- Scenes/Meadow, Forest, Ridge: the course scenes course.py writes into.
- UI/<Name>: the screens on the engine GUI (ui/*.xml, rendered with the thumbnails' ids, each checked
  with gui_validate) and their sheet (ui/SnowlineSheet.css), made the project's GUI sheet.
- The manifest: the start scene (Meadow), no startup script (the game's code runs the run: its
  [Game], Code/Snowline), and the GUI sheet.
Everything is made once and found by name after, so a rerun changes nothing it made before (the
screens are written again: a changed one is imported over its asset).
"""
import os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import mcp, assets

SCREENS = ("Title", "Hud", "Pause", "Finish", "Ending")
COURSES = ("Meadow", "Forest", "Ridge")


def have(name, asset_type):
    found = [a["guid"] for a in assets() if a["name"] == name and a["type"] == asset_type]
    return found[0] if found else None


for course in COURSES:
    if not have(course, "TextureAsset"):
        path = os.path.join(HERE, "generated", "Thumbs", course + ".png")
        print("thumbnail", course, mcp("asset_import", {"source": path, "group": "UI/Thumbs", "importer": "Texture"})["guid"])

for course in COURSES:
    if not have(course, "SceneDocument"):
        print("scene", course, mcp("asset_create", {"creator": "Scene", "name": course, "group": "Scenes"})["guid"])

# The screens: rendered into a staging folder (the import copies each into Sources/), then imported.
# A re-import keeps their ids, which the game's code (Code/Snowline/src/Assets.bf) pushes them by.
staging = tempfile.mkdtemp(prefix="snowline-ui-")
subprocess.run([sys.executable, os.path.join(HERE, "render.py"), "--stage", staging] + ["ui/" + s for s in SCREENS],
               check=True)
def checked(path, kind):
    """`path`, checked as its cook will check it: a problem stops the setup."""
    check = mcp("gui_validate", {"source": open(path).read(), "kind": kind})
    if not check["valid"] or check["diagnostics"]:
        sys.exit("%s: %s" % (os.path.basename(path), check["diagnostics"]))
    return path


for screen in SCREENS:
    r = mcp("asset_import", {"source": checked(os.path.join(staging, screen + ".xml"), "document"), "group": "UI"})
    print("screen", screen, r["guid"])
sheet = mcp("asset_import", {"source": checked(os.path.join(HERE, "ui", "SnowlineSheet.css"), "sheet"), "group": "UI"})
print("sheet SnowlineSheet", sheet["guid"])

mcp("project_settings_set", {"defaultSceneId": have("Meadow", "SceneDocument"),
                             "startupScriptId": "",
                             "guiStyleSheetIds": [sheet["guid"]]}) # the game's look, over the GUI's theme
print(mcp("asset_cook", {}))
