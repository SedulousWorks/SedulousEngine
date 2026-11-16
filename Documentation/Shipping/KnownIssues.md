# Known issues

The CURATED, distribution facing known issues register: limitations and behaviours an
engine user, or an agent working on a game project, can actually hit. This file ships with
the engine tooling and feeds the MCP `known_issues` tool.

Curation rule: entries describe USER VISIBLE symptoms with their impact and workaround,
never internal build, porting or triage state (that lives in the engine repository and is
not distributed). When a development issue gains a user visible symptom, add the user
facing half here; remove entries when the fix ships.

---

## Android: a game with its own native packages does not export yet

An Android preset exports a game whose code is its scripts and the engine's plugins. A project
with its own native packages (Beef under `Plugins/`) is refused with that reason, since the player
with its packages is not yet built for Android. Desktop and web exports of it work.

## Android: the first export downloads Gradle

An Android export builds the app with the template's Gradle project. The first one on a machine
downloads Gradle and the Android build plugin, so it needs the network and takes minutes; later
exports reuse them, and each preset's build is kept in `<project>/.cache/android/` so the next
export builds only what changed.

## Web (WebGPU) targets: scene MSAA is 1x or 4x only

WebGPU supports sample counts 1 and 4 for the scene pass; there is no 2x. A project whose
render settings ask for 2x MSAA is clamped to the nearest supported count at runtime on
web targets. Pick 1x or 4x directly for identical results across platforms.
