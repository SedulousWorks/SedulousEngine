# Known issues

The CURATED, distribution facing known issues register: limitations and behaviours an
engine user, or an agent working on a game project, can actually hit. This file ships with
the engine tooling and feeds the MCP `known_issues` tool.

Curation rule: entries describe USER VISIBLE symptoms with their impact and workaround,
never internal build, porting or triage state (that lives in the engine repository and is
not distributed). When a development issue gains a user visible symptom, add the user
facing half here; remove entries when the fix ships.

---

## Web (WebGPU) targets: scene MSAA is 1x or 4x only

WebGPU supports sample counts 1 and 4 for the scene pass; there is no 2x. A project whose
render settings ask for 2x MSAA is clamped to the nearest supported count at runtime on
web targets. Pick 1x or 4x directly for identical results across platforms.
