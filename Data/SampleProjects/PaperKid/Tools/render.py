#!/usr/bin/env python3
"""render.py [--check | --draft] <Name>...: scripts/<Name>.as with {{Asset}} placeholders ->
PaperKid's Sources/<Name>.as with the asset ids, then script_validate over the editor's MCP. A
placeholder whose asset does not exist yet is a nil id under --check (nothing written) and --draft
(written: a fresh project's first pass, so the kit's prefabs find the scripts' properties before
the scripts can name the prefabs)."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import mcp, assets, NIL
HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = os.path.join(os.path.dirname(HERE), "Sources")
check = "--check" in sys.argv
draft = "--draft" in sys.argv
names = [a for a in sys.argv[1:] if a not in ("--check", "--draft")]
# By name; a prefab sharing a script's name is written {{Prefab:Name}}.
ids = {}
for a in assets():
    ids[("Prefab:" if a["type"] == "PrefabDocument" else "") + a["name"]] = a["guid"]
ok = True
for name in names:
    text = open(os.path.join(HERE, "scripts", name + ".as")).read()
    text = re.sub(r"\{\{([^}]+)\}\}", lambda m: ids.get(m.group(1), NIL) if (check or draft) else ids[m.group(1)], text)
    if not check:
        open(os.path.join(SOURCES, name + ".as"), "w").write(text)
    v = mcp("script_validate", {"source": text, "language": "angelscript", "name": name + ".as"})
    print(name, "valid" if v["valid"] else "INVALID", v.get("properties"), v.get("handlers"))
    for e in v.get("errors", []):
        print("   ", e)
    ok = ok and v["valid"]
sys.exit(0 if ok else 1)
