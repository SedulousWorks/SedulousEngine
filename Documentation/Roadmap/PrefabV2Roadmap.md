# Prefab System V2 Roadmap

Clean-slate redesign of the prefab instance and override system. The template
side (PrefabResource, PrefabSerializer, PrefabResourceManager) is reusable from
V1. The instance side is rebuilt around sparse delta tracking inspired by
ZeroEngine's LocalModifications architecture.

## Vision

Create a prefab. Add it to a scene in the editor. The prefab's entities appear
in the scene hierarchy as real entities. Any property changes made to those
entities are tracked as diffs from the template. The user can "Apply to Prefab"
to push changes back to the template. Template changes propagate to all
instances, preserving per-instance overrides.

## Key Differences from V1

| Aspect | V1 | V2 |
|--------|----|----|
| Override scope | Only exposed parameters | Every property |
| Override storage | String dictionary on component | Sparse property-path set on scene |
| Instance entities | Runtime-only, excluded from scene save | Real entities, serialized as diffs |
| Instantiation | Runtime via PrefabComponentManager | Editor-time when dragging in, runtime for game spawning |
| Template update | Destroy + recreate + re-apply string overrides | Rebuild: cache diffs → recreate → re-apply diffs |
| "Apply to Prefab" | Not supported | Instance state written back as new template |
| Exposed parameters | Required for each overridable property | Gone — everything overridable |

## Architecture Overview

```
.prefab file (serialized entity subgraph, same format as V1)
    ↓ editor drag-in or runtime spawn
Scene entities with PrefabInstanceTagV2
    ↓ property edit
LocalModifications tracks which properties differ
    ↓ scene save
Only diffs serialized per prefab instance entity
    ↓ scene load
Template loaded, diffs re-applied, LocalModifications restored
    ↓ template change
PrefabRebuilderV2 caches diffs → recreates from new template → re-applies
```

## Data Model

### LocalModifications

Lives on the `Scene`. Tracks which properties on which entities differ from
their prefab template. Does NOT store override values — the live component
already has the current value. Stores only the fact that a property was modified.

```beef
class LocalModifications
{
    /// Per-entity modification state. Only entities that differ from
    /// their template have an entry.
    Dictionary<EntityHandle, ObjectState> mStates;

    /// Check if a specific property is modified on an entity.
    bool IsPropertyModified(EntityHandle entity, PropertyPath path);

    /// Mark a property as modified (editor calls this on user edit).
    void SetPropertyModified(EntityHandle entity, PropertyPath path, bool modified);

    /// Get the full ObjectState for an entity (null if unmodified).
    ObjectState GetObjectState(EntityHandle entity);

    /// Remove all modification tracking for an entity (on destroy or revert all).
    void ClearEntity(EntityHandle entity);
}
```

### ObjectState

All modifications for a single entity relative to its prefab template.

```beef
class ObjectState
{
    /// Set of properties that differ from the template.
    /// PropertyPath = (componentTypeId, propertyName) pair.
    HashSet<PropertyPath> ModifiedProperties;

    /// Child entities locally added (not in the template).
    HashSet<Guid> AddedChildren;

    /// Child entities from the template that were removed on this instance.
    HashSet<Guid> RemovedChildren;
}
```

### PropertyPath

Identifies a specific property on a specific component type.

```beef
struct PropertyPath : IHashable
{
    String ComponentTypeId;   // e.g. "Sedulous.MeshComponent"
    String PropertyName;      // e.g. "MeshRef"
}
```

### PrefabInstanceTagV2

Tag component on every entity that belongs to a prefab instance. Carries
enough information to reconstruct the link to the template.

```beef
class PrefabInstanceTagV2 : Component
{
    /// Resource ID of the .prefab file.
    Guid PrefabId;

    /// This entity's GUID within the .prefab file (for mapping back to template).
    Guid SourceEntityId;

    /// The root entity of this prefab instance (the entity the user dragged in).
    /// For the root itself, this equals Owner.
    EntityHandle InstanceRoot;
}
```

Not serialized directly — reconstructed from the scene file's prefab
instance metadata during load.

### PrefabReferenceV2

Stored per prefab instance root entity in the scene file. Not a component —
it's metadata in the scene serialization format that the scene serializer
reads to know "this entity and its children come from a prefab."

```
SceneFile Entity Entry:
{
    Id = <instance-guid>
    Name = "Enemy"
    PrefabSource = {
        PrefabId = <prefab-resource-guid>
        PrefabPath = "project://Prefabs/Enemy.prefab"
        SourceEntityId = <root-entity-guid-in-prefab>
    }
    // Only modified properties listed:
    Components = [
        { TypeId = "Sedulous.HealthComponent", Overrides = { Health = 500 } }
    ]
    Children = [
        {
            SourceEntityId = <child-guid-in-prefab>
            // Only overrides, or empty if matches template
        }
    ]
}
```

## Scene Serialization

### Saving a Scene with Prefab Instances

For each entity with `PrefabInstanceTagV2`:

1. If it's the instance root:
   - Write `PrefabSource` header (prefab resource ID + path + source entity ID)
   - For this entity and each child: check `LocalModifications`
   - Only serialize properties that are in `ModifiedProperties`
   - Serialize `AddedChildren` as full entities (they're not in the template)
   - Record `RemovedChildren` GUIDs

2. If it's a non-root prefab child:
   - Skip (handled as part of the root's children block)

3. Non-prefab entities serialize normally (full properties, as today)

### Loading a Scene with Prefab Instances

1. Read entity entry. If it has `PrefabSource`:
   - Load the referenced .prefab template
   - Instantiate template entities into the scene (new GUIDs, mapped from source GUIDs)
   - For each override property in the scene file: apply to the instantiated entity
   - Register all overrides in `LocalModifications`
   - Add `PrefabInstanceTagV2` to each entity
   - Handle `AddedChildren`: create them as normal entities, tag as locally added
   - Handle `RemovedChildren`: destroy the corresponding instantiated entities

2. Normal entities load as today.

## Runtime Spawning

Game code that spawns prefabs at runtime (e.g., projectile spawning, level
generation) uses `PrefabSpawnerV2`:

```beef
class PrefabSpawnerV2
{
    /// Instantiate a prefab into the scene at runtime.
    /// Returns the root entity handle.
    EntityHandle Spawn(Scene scene, PrefabResource prefab,
                       Transform transform, EntityHandle parent = .Invalid);
}
```

This creates entities from the template with `PrefabInstanceTagV2` but no
`LocalModifications` tracking (runtime instances don't need diff tracking).
Overrides can be applied directly to components after spawning.

## Template Update (Prefab Rebuild)

When a .prefab file changes (hot-reload or manual save):

```
PrefabRebuilderV2.Rebuild(scene, prefabResourceId):
  1. Find all instance roots with matching PrefabId
  2. For each instance:
     a. Read ObjectState from LocalModifications (the diffs)
     b. Read current override values from live components
     c. Store AddedChildren entity data (full serialization)
     d. Store transform overrides
     e. Destroy all instance entities
     f. Instantiate from new template
     g. Re-apply cached overrides
     h. Re-create added children
     i. Restore LocalModifications state
  3. Refresh editor UI if affected entities are selected
```

## "Apply to Prefab"

User selects a prefab instance root → context menu → "Apply to Prefab":

```
ApplyToPrefab(scene, instanceRoot):
  1. Read PrefabInstanceTagV2 to get prefab resource ID
  2. Get all instance entities (walk children with matching PrefabId)
  3. Create a temporary scene with these entities (mapped back to source GUIDs)
  4. Save via PrefabSerializer to the .prefab file
  5. Clear LocalModifications for all affected entities
  6. Hot-reload triggers rebuild of OTHER instances of the same prefab
```

## "Revert Property"

User right-clicks an overridden property → "Revert to Prefab":

```
RevertProperty(entity, propertyPath):
  1. Load the prefab template
  2. Find the source entity by SourceEntityId
  3. Read the template value for this property
  4. Apply template value to the live component (via OverrideApplicator or direct deserialization)
  5. Remove propertyPath from LocalModifications
```

## "Revert All"

User right-clicks instance root → "Revert All Overrides":

```
RevertAll(instanceRoot):
  1. Clear LocalModifications for all entities in this instance
  2. Destroy all instance entities
  3. Re-instantiate from template (no overrides applied)
```

## Editor Inspector Integration

The property grid checks `LocalModifications` when displaying properties:

- **Normal property**: regular label, regular editor
- **Modified property**: bold label (or colored indicator), "Revert" button/context menu
- **Added child**: special indicator in hierarchy (e.g., "+" icon)
- **Removed child**: could show as strikethrough in a "template children" view

When the user edits a property on a prefab instance entity:
1. Normal edit flow (component value changes)
2. Editor calls `LocalModifications.SetPropertyModified(entity, path, true)`
3. Inspector refreshes to show the override indicator

## Nesting

A prefab can contain entities that are themselves prefab instances. The scene
file nests the diff blocks:

```
Instance of PrefabA:
  ├─ Entity "Room" (from PrefabA, no overrides)
  │   └─ Instance of PrefabB:
  │       ├─ Entity "Chair" (from PrefabB, color overridden)
  │       └─ Entity "Table" (from PrefabB, no overrides)
  └─ Entity "Light" (from PrefabA, intensity overridden)
```

Rebuild of PrefabB only affects the inner instance. Rebuild of PrefabA
recreates the outer structure, which triggers inner instantiation too.

Cycle detection: track prefab GUIDs during instantiation, reject if seen twice.

## File Layout

### Engine Layer (Sedulous.Engine.Core)

| File | Purpose |
|------|---------|
| `LocalModifications.bf` | Scene-owned modification tracker |
| `ObjectState.bf` | Per-entity modification state |
| `PropertyPath.bf` | Component type + property name identifier |
| `PrefabInstanceTagV2.bf` | Tag component on prefab instance entities |
| `PrefabSpawnerV2.bf` | Runtime prefab instantiation |
| `PrefabRebuilderV2.bf` | Template change propagation |

### Engine Layer (existing, modified)

| File | Change |
|------|--------|
| `Scene.bf` | Owns `LocalModifications` instance |
| `SceneSerializer.bf` | Diff-based save/load for prefab instance entities |

### Editor

| File | Purpose |
|------|---------|
| `PrefabEditorPageFactory.bf` | Opens .prefab (unchanged from V1) |
| Inspector integration | Bold/colored overridden properties, revert menu |
| Hierarchy integration | Prefab instance indicators, add/remove child tracking |
| Context menus | "Apply to Prefab", "Revert", "Create Prefab from Selection" |

### Reused from V1 (unchanged)

| File | Purpose |
|------|---------|
| `Resources/PrefabResource.bf` | Template resource |
| `Resources/PrefabResourceManager.bf` | Template loading/saving |
| `Resources/PrefabSerializer.bf` | Template serialization |
| `PrefabAssetCreator.bf` | Create empty .prefab in editor |

## Phased Implementation

### Phase 1: Core Data Model
- `PropertyPath`, `ObjectState`, `LocalModifications`
- `PrefabInstanceTagV2` component + manager
- `Scene` owns `LocalModifications`
- Unit tests for LocalModifications (add/remove/query modifications)

### Phase 2: Editor Instantiation
- Drag .prefab into scene → entities created with PrefabInstanceTagV2
- LocalModifications tracks edits on prefab instance entities
- Inspector shows override indicators (bold/color)
- "Revert Property" context menu

### Phase 3: Scene Serialization
- SceneSerializer diff-based save for prefab instance entities
- SceneSerializer load: template + patch application
- LocalModifications restored on load
- Round-trip tests: save scene with overrides → load → verify

### Phase 4: Template Propagation
- `PrefabRebuilderV2`: detect template change → cache diffs → rebuild
- Override preservation across template updates
- "Apply to Prefab" workflow
- "Revert All" workflow

### Phase 5: Polish
- "Create Prefab from Selection" context menu
- Added/removed child tracking
- Nested prefab rebuild ordering
- Hierarchy visual indicators (prefab badge, override markers)
- Undo/redo for prefab operations
- `PrefabSpawnerV2` for runtime game code

## Verification

1. Drag .prefab into scene → entities appear in hierarchy with prefab indicators
2. Edit property on prefab instance → inspector shows override indicator
3. Save scene → only overrides serialized for prefab entities
4. Load scene → template instantiated, overrides applied, indicators restored
5. Edit .prefab template → all instances in scene update, overrides preserved
6. "Revert Property" → value returns to template default, indicator removed
7. "Apply to Prefab" → template updated, other instances get the change
8. Nested prefabs → inner/outer rebuild independently
9. "Create Prefab from Selection" → entities replaced with prefab instance
10. Runtime spawn via PrefabSpawnerV2 → entities created without diff tracking
