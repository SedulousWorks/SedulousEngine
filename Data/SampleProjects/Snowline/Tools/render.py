#!/usr/bin/env python3
"""render.py [--check] [--stage <dir>] <Name>...: a screen ui/<Name>.xml (the engine GUI's) with {{Asset}}
placeholders -> Snowline's Sources/<Name>.xml with the asset ids. --check resolves without writing (a
placeholder whose asset does not exist yet is a nil id there); --stage <dir> writes there instead of
Sources/ (setup.py stages the screens so asset_import copies them in).

A placeholder is the asset's name, prefixed by its kind where names are shared (a course's scene, its
thumbnail and its terrain textures; the Finish screen and the Finish prefab): {{Texture:Meadow}},
{{Scene:Meadow}}, {{GUI:Finish}}, {{Prefab:GemSparkle}}; a sound is its bare name, {{Pop}}. The game's
code names the assets it uses by id itself (Code/Snowline/src/Assets.bf)."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import assets, NIL
HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = os.path.join(os.path.dirname(HERE), "Sources")
check = "--check" in sys.argv
args = sys.argv[1:]
stage = args[args.index("--stage") + 1] if "--stage" in args else None
names = [a for i, a in enumerate(args) if a not in ("--check", "--stage") and not (i > 0 and args[i - 1] == "--stage")]
# By name; an asset sharing another's name is written with its kind ({{Prefab:Name}}, {{Clip:Name}}).
PREFIX = {"PrefabDocument": "Prefab:", "AnimationClipAsset": "Clip:", "SceneDocument": "Scene:",
          "GuiDocumentAsset": "GUI:", "TextureAsset": "Texture:"}
ids, ambiguous = {}, set()
for a in assets():
    key = PREFIX.get(a["type"], "") + a["name"]
    if key in ids:
        ambiguous.add(key)  # several assets answer to it: a screen must not name it
    ids[key] = a["guid"]


def resolve(match):
    key = match.group(1)
    if key in ambiguous:
        raise SystemExit("{{%s}} names more than one asset" % key)
    return ids.get(key, NIL) if check else ids[key]


for name in names:
    # A screen may be named ui/<Name>, as setup.py does.
    if name.startswith("ui/"):
        name = name[3:]
    file_name = name + ".xml"
    text = open(os.path.join(HERE, "ui", file_name)).read()
    text = re.sub(r"\{\{([^{}]+)\}\}", resolve, text)
    if not check:
        open(os.path.join(stage or SOURCES, file_name), "w").write(text)
    print(name, "written" if not check else "resolved")
