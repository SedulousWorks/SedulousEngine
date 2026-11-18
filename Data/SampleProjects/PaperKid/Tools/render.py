#!/usr/bin/env python3
"""render.py [--check | --draft] <Name>...: scripts/<Name>.as with {{Asset}} placeholders ->
PaperKid's copy of <Name>.as (under Code/, in its group's folder) with the asset ids, then script_validate over the editor's MCP. A
placeholder whose asset does not exist yet is a nil id under --check (nothing written) and --draft
(written: a fresh project's first pass, so the kit's prefabs find the scripts' properties before
the scripts can name the prefabs)."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import mcp, assets, NIL
HERE = os.path.dirname(os.path.abspath(__file__))
CODE = os.path.join(os.path.dirname(HERE), "Code")
def project_file(root, file_name):
    """The project's copy of `file_name` under `root`, in its group's folder; `root` itself for one
    not imported yet."""
    found = [os.path.join(d, file_name) for d, _, files in os.walk(root) if file_name in files]
    return found[0] if found else os.path.join(root, file_name)
check = "--check" in sys.argv
draft = "--draft" in sys.argv
names = [a for a in sys.argv[1:] if a not in ("--check", "--draft")]
# By name; a prefab sharing a script's name is written {{Prefab:Name}}, and an animation clip
# {{Clip:Name}} (the kid's Ride and Throw clips beside the throw's sound).
PREFIX = {"PrefabDocument": "Prefab:", "AnimationClipAsset": "Clip:"}
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
    text = open(os.path.join(HERE, "scripts", name + ".as")).read()
    # A name starts with a word character, so "{{{Title}}}" (a GUI document, wanted braced) keeps its
    # outer braces: "{<id>}".
    text = re.sub(r"\{\{(\w[^{}]*)\}\}", resolve, text)
    if not check:
        open(project_file(CODE, name + ".as"), "w").write(text)
    v = mcp("script_validate", {"source": text, "language": "angelscript", "name": name + ".as"})
    print(name, "valid" if v["valid"] else "INVALID", v.get("properties"), v.get("handlers"))
    for e in v.get("errors", []):
        print("   ", e)
    ok = ok and v["valid"]
sys.exit(0 if ok else 1)
