# Known issues

The CURATED, distribution facing known issues register: limitations and behaviours an
engine user, or an agent working on a game project, can actually hit. This file ships with
the engine tooling and feeds the MCP `known_issues` tool.

Curation rule: entries describe USER VISIBLE symptoms with their impact and workaround,
never internal build, porting or triage state (that lives in the engine repository and is
not distributed). When a development issue gains a user visible symptom, add the user
facing half here; remove entries when the fix ships.

---

## Native game modules do not load on Linux

A project's native module (a Beef library exposing `CreatePlugin`) loads on Windows only.
On Linux and macOS a Beef library carries a runtime of its own and cannot share the
player's, so `PlayerOptions.NativeGame` finds the library and fails to bring it up. Ship
gameplay as scripts, or link the native code into the player statically, until the Beef
toolchain gains an option to build a runtime free library.

## Web (WebGPU) targets: scene MSAA is 1x or 4x only

WebGPU supports sample counts 1 and 4 for the scene pass; there is no 2x. A project whose
render settings ask for 2x MSAA is clamped to the nearest supported count at runtime on
web targets. Pick 1x or 4x directly for identical results across platforms.

## The MCP host has no project_export yet

`project_export` arrives with the export packager. Until then a dist is not made through
the MCP host; cook with `asset_cook` and stage by hand.
