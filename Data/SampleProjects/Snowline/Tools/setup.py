#!/usr/bin/env python3
"""setup.py: a fresh project's first run, what the other tools build on, through the editor's MCP.
Run controls.py, look.py, importall.py (each course) and sounds.py first; then this:
- UI/Thumbs/<Course>: the title's course pictures (generated/Thumbs; thumbnails.py remakes them
  from the scenes once those exist).
- Scripts/<Name>: the game's script assets (script_create), their sources then written by
  render.py (a draft first: a script naming an asset not made yet holds a nil id until the last run
  of render.py, after course.py).
- Scenes/Meadow, Forest, Ridge: the course scenes course.py writes into.
- UI/<Name>: the screens (ui/*.sml, rendered with the thumbnails' ids).
- The manifest: the start scene (Meadow) and the Game script (Snowline).
Everything is made once and found by name after, so a rerun changes nothing it made before (the
screens are written again: a changed one is imported over its asset).
"""
import os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import mcp, assets

SCRIPTS = {"Snowline": "game"}
for behaviour in ("Avalanche", "Board", "Expire", "Finish", "FollowCamera", "Gap", "Gate", "Gem", "Ghost", "Kicker",
                  "PlayerGhost", "TrackMark"):
    SCRIPTS[behaviour] = "behavior"
SCREENS = ("Title", "Hud", "Pause", "Finish", "Ending")
COURSES = ("Meadow", "Forest", "Ridge")


def have(name, asset_type):
    found = [a["guid"] for a in assets() if a["name"] == name and a["type"] == asset_type]
    return found[0] if found else None


for course in COURSES:
    if not have(course, "TextureAsset"):
        path = os.path.join(HERE, "generated", "Thumbs", course + ".png")
        print("thumbnail", course, mcp("asset_import", {"source": path, "group": "UI/Thumbs", "importer": "Texture"})["guid"])

for name, tier in SCRIPTS.items():
    if not have(name, "ScriptClassAsset"):
        r = mcp("script_create", {"name": name, "language": "angelscript", "tier": tier, "group": "Scripts"})
        print("created", name, r.get("guid"))
subprocess.run([sys.executable, os.path.join(HERE, "render.py"), "--draft"] + list(SCRIPTS), check=True)

for course in COURSES:
    if not have(course, "SceneDocument"):
        print("scene", course, mcp("asset_create", {"creator": "Scene", "name": course, "group": "Scenes"})["guid"])

# The screens: rendered into a staging folder (the import copies each into Sources/), then imported.
staging = tempfile.mkdtemp(prefix="snowline-ui-")
subprocess.run([sys.executable, os.path.join(HERE, "render.py"), "--stage", staging] + ["ui/" + s for s in SCREENS],
               check=True)
for screen in SCREENS:
    r = mcp("asset_import", {"source": os.path.join(staging, screen + ".sml"), "group": "UI"})
    print("screen", screen, r["guid"])

mcp("project_settings_set", {"defaultSceneId": have("Meadow", "SceneDocument"),
                             "startupScriptId": have("Snowline", "ScriptClassAsset")})
print(mcp("asset_cook", {}))
