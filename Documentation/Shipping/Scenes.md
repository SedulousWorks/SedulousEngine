# Scenes and prefabs

A **scene** is entities in a hierarchy, each carrying components (the transform is
intrinsic; mesh, light, camera, physics body, script, audio source, ... are components). A
**prefab** is a reusable single rooted entity subtree; scenes and prefabs instantiate
prefabs by guid, and the instance re-expands from the prefab source when it loads: edit the
prefab, every instance follows.

## Sources are text

Scene and prefab sources are XML documents stored in the project. That makes them
diffable, mergeable and directly authorable by an agent; the whole MCP scene workflow is
files first: what is in the stored XML IS the scene, no editor needs to be open.

## The MCP workflow

- `scene_read` and `prefab_read`: the stored XML by guid. The same text is also exposed as
  read only resources (`project://scene/<guid>`, `project://prefab/<guid>`).
- `scene_validate`: the validation loop when authoring XML. Structure (entities, hierarchy,
  framing) AND component payloads, parsed by the same reader the engine uses with every
  engine manager present. `valid` with empty `warnings` means the engine will load it;
  warnings list genuinely unknown component types (those records would be skipped on load).
- `scene_write` and `prefab_write`: validate first mutation, refused with the full report
  unless the XML passes, stored verbatim on success. Prefabs enforce the single root rule.

## Scene level behaviour

- Each scene can carry a **Level script** (see Scripting.md) and per scene settings blocks
  (physics, post processing, audio) that serialize with it.
- The project's startup scene is `defaultScene` in the project settings; `asset_uses` on a
  scene reports that binding under `projectSettingsUses`.

## Gotchas

- A prefab source must have exactly ONE root entity; `prefab_write` refuses multi root
  content with the reason.
- Component records of a type the engine does not know are skipped WITH a warning at load
  and by `scene_validate`: treat any warning as breakage to fix, not noise.
- Deleting an asset a scene references leaves a dangling reference that only surfaces later;
  run `project_health` after destructive changes.
