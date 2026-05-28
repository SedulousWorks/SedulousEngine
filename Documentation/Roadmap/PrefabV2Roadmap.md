# Prefab System Roadmap

Sparse delta tracking prefab system. Every property is overridable.
Only diffs are stored. Template changes propagate to instances while
preserving per-instance overrides.

## Status

### Done

- **Core data model**: `PropertyPath`, `ObjectState`, `LocalModifications` on `Scene`
- **`PrefabInstanceTag`**: tag component on prefab instance entities (not serialized)
- **`PrefabSpawner`**: instantiates prefab entities into scene via resource system, preserves template transform
- **`PrefabRebuilder`**: template change propagation - caches overrides, destroys, respawns, re-applies per-property overrides, restores `LocalModifications`
- **`SceneSerializer`**: unified serializer handling normal entities + prefab instance diffs. `PrefabInstances` section with per-entity per-component per-property overrides. Transform diff save/load (Position/Rotation/Scale as independent nested objects)
- **`DiffComponentSerializer`**: writes only modified properties during save
- **`TrackingComponentSerializer`**: records which properties were read during load, restores `LocalModifications`
- **`SceneResource`**: delegates to manager-provided `SceneSerializer`
- **Drag-drop**: asset browser items implement `IDragSource`, scene hierarchy accepts `"asset/file"` drops, spawns .prefab via `PrefabSpawner`
- **Override tracking**: inspector `OnEditEnd` marks properties in `LocalModifications` for both component properties and transform (Position/Rotation/Scale)
- **Gizmo tracking**: viewport gizmo drag marks transform overrides based on gizmo mode
- **Hot-reload**: `PrefabSpawner` loads resource through `ResourceSystem` for cache tracking, `PrefabResourceManager.ReloadResource` signals generation bump, `SceneEditorPage` listens via `IResourceChangeListener` and triggers `PrefabRebuilder`
- **`[Property]` attribute**: `DisplayName` and `SerializedName` String fields. Codegen reads them. All `[Property]` call sites specify explicit values.
- **`IPropertyDescriptor`**: two-name API (`name` = identity, `displayName` = UI label). `PropertyEditor` has `Name` (identity) and `DisplayName` (UI label, falls back to Name)
- **Serialization alignment**: component-wise fields (Color, AmbientColor, Size, Tint, UVRect) converted to nested objects. Transform serialized as Position/Rotation/Scale objects. `MaterialRefs` name aligned between `Serialize()` and codegen. All data files updated.
- **V1 cleanup**: removed `PrefabReferenceComponent`, `PrefabComponentManager`, `PrefabInstanceTag` (V1), `OverrideApplicator`, `ExposedParameterDescriptor`. TowerDefense migrated to `PrefabSpawner`.
- **Dock tab sync**: `DockTabGroup.OnTabSelected` -> `DockManager.OnPanelActivated` -> `PageManager.SetActive`. Save now targets the correct active page.
- **Unit tests**: `LocalModificationsTests` (17 tests), `PrefabSpawnerTests` (spawn, round-trip with/without overrides, mixed scenes)

### Remaining

#### "Apply to Prefab"
Push instance changes back to the template file. User selects a prefab
instance root -> context menu -> "Apply to Prefab":
1. Collect all instance entities and their current state
2. Map live entity handles back to source GUIDs via `PrefabInstanceTag`
3. Create a temporary scene with the entities (using source GUIDs)
4. Save via `PrefabSerializer` to the .prefab file
5. Clear `LocalModifications` for all affected entities
6. Hot-reload triggers rebuild of OTHER instances of the same prefab

#### "Revert Property"
Right-click an overridden property -> "Revert to Prefab":
1. Load the prefab template
2. Find the source entity by `SourceEntityId`
3. Read the template value for this property
4. Apply template value to the live component
5. Remove property from `LocalModifications`

#### "Revert All"
Right-click instance root -> "Revert All Overrides":
1. Destroy all instance entities
2. Re-instantiate from template (no overrides applied)
3. Clear `LocalModifications` for all affected entities

#### Inspector Override Indicators
Show which properties differ from the template:
- Bold or colored label for modified properties
- Check `LocalModifications.IsPropertyModified` when building property grid
- Requires the inspector to know the entity and component type ID

#### "Create Prefab from Selection"
Select entities in scene hierarchy -> context menu -> "Create Prefab from Selection":
1. Serialize selected entities to a new .prefab file via save dialog
2. Remove original entities from scene
3. Create a prefab instance in their place via `PrefabSpawner`
4. Register in project index

#### Hierarchy Visual Indicators
Prefab instance entities should be visually distinct in the hierarchy tree:
- Badge/icon on prefab instance entities
- Different text color or prefix for prefab children
- Check `PrefabInstanceTagManager` when rendering tree items

#### Viewport Drop
Drag .prefab onto the 3D viewport (currently only hierarchy accepts drops):
- `ViewportView` or `GizmoInputHandler` implements `IDropTarget`
- Hit-test against scene geometry to determine drop position
- Spawn prefab at the hit point

#### Added/Removed Child Tracking
Track children added to or removed from a prefab instance:
- `ObjectState` already has `AddedChildren` / `RemovedChildren` sets
- Scene serializer needs to save added children as full entities
- Scene serializer needs to record removed children and destroy them after spawn
- Editor hierarchy needs UI for adding/removing children on prefab instances

#### Nested Prefab Support
A prefab can contain entities that are themselves prefab instances:
- Inner instances should rebuild independently when their template changes
- Outer rebuild triggers inner re-instantiation
- Override chains (outer overrides on inner instance properties)
- Cycle detection (already implemented in `PrefabSpawner`)

#### Undo/Redo
Prefab operations should integrate with `EditorCommandStack`:
- Override property -> undoable
- Revert property -> undoable
- Apply to prefab -> undoable
- Drag-drop prefab -> undoable (via existing `CreateEntityCommand` pattern)

## File Layout

### Engine Layer (Sedulous.Engine.Core)

| File | Purpose |
|------|---------|
| `LocalModifications.bf` | Scene-owned modification tracker |
| `ObjectState.bf` | Per-entity modification state |
| `PropertyPath.bf` | Component type + property name identifier |
| `PrefabInstanceTag.bf` | Tag component on prefab instance entities |
| `PrefabSpawner.bf` | Prefab instantiation via resource system |
| `PrefabRebuilder.bf` | Template change propagation |
| `Resources/SceneSerializer.bf` | Unified scene serializer with prefab instance diffs |
| `Resources/SceneResource.bf` | Scene resource (delegates to manager-provided serializer) |
| `Resources/SceneResourceManager.bf` | Scene save/load coordination |
| `Resources/DiffComponentSerializer.bf` | Writes only modified properties |
| `Resources/TrackingComponentSerializer.bf` | Records read fields for LocalModifications restore |
| `Resources/PrefabResource.bf` | Template resource |
| `Resources/PrefabResourceManager.bf` | Template loading/saving with hot-reload support |
| `Resources/PrefabSerializer.bf` | Template entity serialization |

### Editor Layer

| File | Purpose |
|------|---------|
| `SceneEditorPage.bf` | Listens for prefab hot-reload, triggers rebuild |
| `ScenePageBuilder.bf` | Override tracking on inspector edits, asset drop handler |
| `GizmoInputHandler.bf` | Transform override tracking on gizmo drag |
| `AssetContentAdapter.bf` | `IDragSource` on asset browser items |
| `AssetDragData.bf` | Drag data for asset files |
| `SceneHierarchyView.bf` | Accepts asset drops, fires `OnAssetDropped` |

### Inspection Layer

| File | Purpose |
|------|---------|
| `PropertyAttribute.bf` | `[Property]` with `DisplayName` and `SerializedName` |
| `IPropertyDescriptor.bf` | Two-name API (name + displayName) |
| `PropertyEditor.bf` | `Name` (identity) + `DisplayName` (UI label) |
| `PropertyGrid.bf` | Renders `DisplayName` in label column |
| `InspectorCodegen.bf` | Reads attribute values, emits two-name descriptor calls |
