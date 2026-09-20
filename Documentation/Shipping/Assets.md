# Assets

How content flows through a project: **source assets** are authored or imported into the
project's source database, the **cook** compiles them into runtime products in the cooked
database, and the running game loads products by guid.

## Identity

Every asset has a **guid**, its stable identity. Names and groups are organisational and
safe to change; references, from other assets, scenes and project settings, bind by guid,
so a rename or a move never breaks one. Deleting is the dangerous operation: query first
(see below).

## The workflow

1. **Import**: a source file (texture, model, audio, script, ...) is copied under the
   project's `Sources/` directory and a typed asset envelope is created in the source
   database. MCP: `asset_import`, routed by file extension, with `importer` to choose when
   several claim it.
2. **Cook**: the incremental cook compares each buildable asset's recipe (source bytes,
   settings, dependency recipes, cook logic version) against its last build and rebuilds
   only what changed, in dependency order. MCP: `asset_cook`; `project_health` reports the
   dirty count without building.
3. **Reference**: components and other assets hold guid references; the runtime resolves
   them against cooked products.

Scenes and prefabs are NOT cooked: they are XML text sources staged directly (see
Scenes.md).

## Inspecting

- `asset_list` and `asset_info`: what exists (guid, name, type, group), in either database.
- `asset_uses`: REVERSE dependencies, every direct user of an asset with the edge kind. Call
  it before deleting anything (renames and moves are guid safe, but knowing the users still
  tells you the blast radius).
- `project_health`: one call for dangling references, sources that no longer load, the
  dirty count, orphaned products and last cook failures.

## Gotchas

- An asset that imports fine can still fail to cook (a missing companion file, say); cook
  failures are per asset and reported in the cook stats and by `project_health`.
- References to a deleted asset do not fail at delete time; they surface later as dangling
  refs. Make `asset_uses` (before) and `project_health` (after) the habit.
