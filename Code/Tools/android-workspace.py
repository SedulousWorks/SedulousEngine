#!/usr/bin/env python3
"""Writes the workspace's Android platform sections (BeefSpace.toml).

A BeefBuild for Android compiles every project the workspace enables for that platform, and with
no section of its own every one is enabled: the editor, the tools, the tests, the deprecated UI.
The sections this writes enable only what the Android targets below reach through their
dependencies, so an Android build compiles the player's tree and nothing beside it.

Run it from anywhere after adding a target or a dependency to one: it replaces the sections it
wrote before and leaves the rest of the file as it is.
"""
import os
import re
import sys

# The NDK's triple, with no vendor part: Beef reads a "none" vendor ("aarch64-none-linux-android")
# as the platform None, and then defines no BF_PLATFORM_ANDROID.
PLATFORM = "aarch64-linux-android33"
CONFIGS = ["Debug", "Release", "ShippingRelease"]
TARGETS = [
    "Sedulous.Engine.Player.Android",
    "Samples.RHI.Sample001_Triangle",
]
BEGIN = "# ---- Android (written by Tools/android-workspace.py) ----"
END = "# ---- end of Android ----"

code = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
space_path = os.path.join(code, "BeefSpace.toml")
space = open(space_path).read()
projects = dict(re.findall(r'"?([\w.\-]+)"?\s*=\s*\{Path\s*=\s*"([^"]+)"', space))


def dependencies(name):
    text = open(os.path.join(code, projects[name], "BeefProj.toml")).read()
    table = re.search(r"\[Dependencies\](.*?)(\n\[|\Z)", text, re.S)
    if table:
        return re.findall(r'^\s*"?([\w.\-]+)"?\s*=', table.group(1), re.M)
    inline = re.search(r"Dependencies = \{(.*?)\}", text)
    return re.findall(r'"?([\w.\-]+)"?\s*=', inline.group(1)) if inline else []


reached = set()
pending = list(TARGETS)
while pending:
    name = pending.pop()
    if name in reached or name == "corlib":
        continue
    if name not in projects:
        sys.exit(f"android-workspace: '{name}' is not a project of the workspace")
    reached.add(name)
    pending += dependencies(name)

disabled = sorted(name for name in projects if name not in reached)
selections = ", ".join(f'"{name}" = {{Enabled = false}}' for name in disabled)
sections = [BEGIN]
for config in CONFIGS:
    sections.append(f'[Configs.{config}."{PLATFORM}"]')
    sections.append('AllocType = "CRT"')
    sections.append(f"ConfigSelections = {{{selections}}}")
    sections.append("")
sections.append(END)
block = "\n".join(sections) + "\n"

if BEGIN in space:
    space = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n", lambda m: block, space, flags=re.S)
else:
    space = space.rstrip("\n") + "\n\n" + block
open(space_path, "w").write(space)
print(f"android-workspace: {len(reached)} projects enabled for {PLATFORM}, {len(disabled)} disabled")
