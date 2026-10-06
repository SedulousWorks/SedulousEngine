#!/usr/bin/env python3
"""render.py [--check | --draft] <Name> | ui/<Name>...: scripts/<Name>.as, or ui/<Name>.sml, with {{Asset}}
placeholders -> Snowline's Sources/<Name>.as (.sml) with the asset ids; a script is then compile-checked
(script_validate over the editor's MCP). A placeholder whose asset does not exist yet is a nil id under
--check (nothing written) and --draft (written: a fresh project's first pass, so the prefabs and scenes
find the scripts' properties before the scripts can name them). --stage <dir> writes there instead of
Sources/ (a screen, which asset_import then copies in).

A placeholder is the asset's name, prefixed by its kind where names are shared (a course's scene, its
thumbnail and its terrain textures; the Finish screen and the Finish prefab): {{Scene:Meadow}},
{{UI:Finish}}, {{Texture:Meadow}}, {{Prefab:GemSparkle}}; a sound is its bare name, {{Pop}}."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import mcp, assets, NIL
HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = os.path.join(os.path.dirname(HERE), "Sources")
check = "--check" in sys.argv
draft = "--draft" in sys.argv
# --stage <dir>: written there instead of Sources/ (a screen, which asset_import then copies in).
args = sys.argv[1:]
stage = args[args.index("--stage") + 1] if "--stage" in args else None
names = [a for i, a in enumerate(args) if a not in ("--check", "--draft", "--stage")
         and not (i > 0 and args[i - 1] == "--stage")]
# By name; a prefab sharing a script's name is written {{Prefab:Name}}, and an animation clip
# {{Clip:Name}} (a clip sharing another asset's name).
PREFIX = {"PrefabDocument": "Prefab:", "AnimationClipAsset": "Clip:", "SceneDocument": "Scene:",
          "UIDocumentAsset": "UI:", "TextureAsset": "Texture:"}
ids, ambiguous = {}, set()
for a in assets():
    key = PREFIX.get(a["type"], "") + a["name"]
    if key in ids:
        ambiguous.add(key)  # several assets answer to it: a script must not name it (several models'
                            # Walk clips); pass such an asset as a behaviour property instead
    ids[key] = a["guid"]


def resolve(match):
    key = match.group(1)
    if key in ambiguous:
        raise SystemExit("{{%s}} names more than one asset; make it a behaviour property" % key)
    return ids.get(key, NIL) if (check or draft) else ids[key]


ok = True
for name in names:
    # A screen is named ui/<Name>: Finish is a script and a screen both.
    ui = name.startswith("ui/")
    if ui:
        name = name[3:]
    file_name = name + (".sml" if ui else ".as")
    text = open(os.path.join(HERE, "ui" if ui else "scripts", file_name)).read()
    text = re.sub(r"\{\{([^}]+)\}\}", resolve, text)
    if not check:
        open(os.path.join(stage or SOURCES, file_name), "w").write(text)
    if ui:
        print(name, "written" if not check else "resolved")
        continue
    v = mcp("script_validate", {"source": text, "language": "angelscript", "name": name + ".as"})
    print(name, "valid" if v["valid"] else "INVALID", v.get("properties"), v.get("handlers"))
    for e in v.get("errors", []):
        print("   ", e)
    ok = ok and v["valid"]
sys.exit(0 if ok else 1)
