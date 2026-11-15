#!/usr/bin/env python3
"""Writes the workspace's Android platform sections (BeefSpace.toml).

A BeefBuild for Android compiles every project the workspace enables for that platform, and with
no section of its own every one is enabled: the editor, the tools, the tests, the deprecated UI.
The sections this writes enable only what the Android targets below reach through their
dependencies, so an Android build compiles the player's tree and nothing beside it. The Test
config's section enables the test suites that run on a phone (Tools/android-tests.sh) instead,
and each of those suites' project files gets its Android Test section: Beef builds every project
for Android as a static library unless told it is a test.

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
# The headless suites Tools/android-tests.sh runs on a phone, built in the Test config.
TEST_TARGETS = [
    "Sedulous.Core.Tests",
    "Sedulous.Json.Tests",
    "Sedulous.Messaging.Tests",
    "Sedulous.VFS.Tests",
    "Sedulous.VFS.Zip.Tests",
    "Sedulous.VFS.Pak.Tests",
    "Sedulous.Content.Tests",
    "Sedulous.Scene.Tests",
]
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


def closure(targets):
    reached = set()
    pending = list(targets)
    while pending:
        name = pending.pop()
        if name in reached or name == "corlib":
            continue
        if name not in projects:
            sys.exit(f"android-workspace: '{name}' is not a project of the workspace")
        reached.add(name)
        pending += dependencies(name)
    return reached


def section(config, reached):
    disabled = sorted(name for name in projects if name not in reached)
    selections = ", ".join(f'"{name}" = {{Enabled = false}}' for name in disabled)
    return [f'[Configs.{config}."{PLATFORM}"]', 'AllocType = "CRT"', f"ConfigSelections = {{{selections}}}", ""]


reached = closure(TARGETS)
tested = closure(TEST_TARGETS)
sections = [BEGIN]
for config in CONFIGS:
    sections += section(config, reached)
sections += section("Test", tested)
sections.append(END)
block = "\n".join(sections) + "\n"

if BEGIN in space:
    space = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n", lambda m: block, space, flags=re.S)
else:
    space = space.rstrip("\n") + "\n\n" + block
open(space_path, "w").write(space)

# A suite's own Android Test section: BuildKind Test, so BeefBuild compiles it as a test executable
# (its own link then fails here, as no host linker takes Android objects; android-tests.sh links it).
SUITE_SECTION = f'[Configs.Test."{PLATFORM}"]\nBuildKind = "Test"\n'
for name in TEST_TARGETS:
    path = os.path.join(code, projects[name], "BeefProj.toml")
    text = open(path).read()
    if f'[Configs.Test."{PLATFORM}"]' not in text:
        open(path, "w").write(text.rstrip("\n") + "\n\n" + SUITE_SECTION)
print(f"android-workspace: {len(reached)} projects enabled for {PLATFORM}, {len(tested)} for its tests")
