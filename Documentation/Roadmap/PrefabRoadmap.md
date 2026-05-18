# Prefab System Roadmap (V1 — Superseded)

> **This document describes the V1 prefab system which has been replaced.**
> See `PrefabV2Roadmap.md` for the current implementation using sparse delta
> tracking with `LocalModifications`, `PrefabSpawner`, and `PrefabRebuilder`.

Reusable entity subgraphs that can be instantiated multiple times across scenes
with per-instance property overrides. Changes to a prefab propagate to all
linked instances.

## Design Decisions

- **Linked instances** - instances reference the prefab asset; edits propagate
  to all instances automatically
- **Exposed parameters** - prefab author marks specific properties as
  overridable per instance (e.g., health, mesh, color)
- **Open as scene** - .prefab files open in the scene editor tab, reusing all
  existing scene editing infrastructure
- **Nesting supported** - prefabs can contain instances of other prefabs for
  compositional design (room -> furniture -> handles)

## Architecture Overview

```
.prefab file (serialized entity subgraph + exposed parameter descriptors)
    ↓ load
PrefabResource (Resource)
    ↓ instantiate
PrefabReferenceComponent on an entity in a scene
    ↓ resolves
Live entity subtree under the reference entity
    ↓ overrides
Per-instance property values stored on PrefabReferenceComponent
```

## Data Model

### PrefabResource

A Resource containing a serialized entity subgraph (same OpenDDL format as
scene serialization) plus exposed parameter descriptors. Extension: `.prefab`.

The entity hierarchy is stored relative to a root entity. The root entity's
transform is identity - the instance's world transform comes from the
PrefabReferenceComponent's owning entity.

```
ResourceHeader {
  Type = "Sedulous.PrefabResource"
  Version = 1
  Id = <guid>
}

ExposedParameters {
  count = N
  [0] { Name = "Health", EntityId = <guid>, ComponentType = "Sedulous.HealthComponent", Property = "MaxHealth" }
  [1] { Name = "MeshRef", EntityId = <guid>, ComponentType = "Sedulous.MeshComponent", Property = "MeshRef" }
}

Entities {
  // Identical format to scene entity serialization
  count = M
  [0] { Id = <guid>, Name = "Root", Parent = "", Transform = {...}, Components = [...] }
  [1] { Id = <guid>, Name = "Visual", Parent = <root-guid>, Transform = {...}, Components = [...] }
}
```

### ExposedParameterDescriptor

Describes a single property that can be overridden per instance.

```beef
struct ExposedParameterDescriptor
{
    String Name;              // Display name in inspector (e.g., "Health")
    Guid EntityId;            // Which entity in the prefab
    String ComponentTypeId;   // Serialization type ID (e.g., "Sedulous.MeshComponent")
    String PropertyName;      // Property field name (e.g., "MeshRef")
}
```

### PrefabReferenceComponent

Engine-level component on the instantiation entity:

1. References a PrefabResource via ResourceRef
2. Stores per-instance parameter overrides as serialized key-value pairs
3. On resource resolution: instantiates the prefab's entity subtree as
   children of the owning entity
4. On prefab change (hot reload): destroys old subtree, re-instantiates,
   re-applies overrides

```beef
class PrefabReferenceComponent : Component, ISerializableComponent
{
    ResourceRef mPrefabRef;
    Dictionary<String, String> mOverrides;           // parameter name -> serialized value
    List<EntityHandle> mInstantiatedEntities;         // runtime: for cleanup
    PrefabResource mResolvedPrefab;                   // runtime: resolved resource
}
```

### PrefabInstanceTag

Lightweight tag component on every entity created by prefab instantiation.
Enables override targeting and re-instantiation mapping.

```beef
class PrefabInstanceTag : Component
{
    Guid PrefabId;              // Which prefab resource
    Guid SourceEntityId;        // Entity ID within the prefab file
    EntityHandle ReferenceEntity; // The entity with PrefabReferenceComponent
}
```

## Instantiation Flow

```
1. PrefabReferenceComponent resolves mPrefabRef -> PrefabResource
2. PrefabResource.Entities deserialized into temporary structure
3. For each entity in prefab:
   a. Create entity in scene (new Guid, new handle)
   b. Map: prefab entity Guid -> live entity handle
   c. Set parent (root -> reference entity, others -> mapped parent)
   d. Create components from serialized data
   e. Add PrefabInstanceTag with source IDs
4. Resolve intra-prefab EntityRefs using the Guid->handle map
5. Apply per-instance overrides from mOverrides
6. Store instantiated handles in mInstantiatedEntities for cleanup
```

### Nested Prefabs

If a prefab contains a PrefabReferenceComponent, instantiation is recursive:
the inner prefab resolves and instantiates its own subtree. The outer
prefab's overrides can target the inner PrefabReferenceComponent's parameters.

Cycle detection: track prefab Guids in an instantiation stack. If a prefab
appears twice, skip and log a warning.

## Override System

### Storing Overrides

Overrides stored as serialized name-value pairs on PrefabReferenceComponent:
```
Overrides: [
  { Parameter: "Health", Value: "200" },
  { Parameter: "MeshRef", Value: "proto:meshes/custom.mesh" },
]
```

### Applying Overrides

After instantiation, for each override:
1. Look up the ExposedParameterDescriptor by name
2. Find the instantiated entity (via Guid->handle map + SourceEntityId)
3. Find the component (via ComponentTypeId on that entity)
4. Deserialize the override value into the component's property

### Propagation

When a prefab asset changes (file watcher or manual reload):
1. Find all PrefabReferenceComponents referencing that prefab
2. For each: destroy instantiated subtree, re-instantiate, re-apply overrides
3. Editor: refresh inspector if selected entity is affected

## Infrastructure Reuse

The prefab system builds heavily on existing engine infrastructure:

- **SceneSerializer patterns** - PrefabSerializer reuses the same entity/component
  serialization format and code paths
- **ComponentTypeRegistry** - auto-instantiates managers for unknown component types
  during prefab deserialization (no pre-registration needed)
- **EntityRef with persistent Guids** - intra-prefab entity references survive
  instantiation via Guid->handle remapping
- **ResourceRef + ResourceSystem** - standard resource loading/caching for .prefab files
- **ISerializableComponent** - components self-serialize, no special prefab handling
- **SceneEditorPage** - prefabs open as scenes in the editor (PrefabEditorPageFactory
  just creates a SceneEditorPage pointed at a .prefab file)

## File Layout

### Engine Layer (Sedulous.Engine.Core)

| File | Purpose |
|------|---------|
| `Resources/PrefabResource.bf` | Resource wrapping serialized entity subgraph + exposed params |
| `Resources/PrefabResourceManager.bf` | ResourceManager for .prefab files |
| `Resources/PrefabSerializer.bf` | Serialize/deserialize prefab data |
| `ExposedParameterDescriptor.bf` | Descriptor struct for exposed properties |
| `PrefabInstanceTag.bf` | Tag component marking instantiated entities |

### Engine Layer (Sedulous.Engine.Core, continued)

| File | Purpose |
|------|---------|
| `PrefabReferenceComponent.bf` | Component holding prefab ref + overrides |
| `PrefabComponentManager.bf` | Manages instantiation, cleanup, propagation |

### Editor

| File | Purpose |
|------|---------|
| `Assets/PrefabAssetCreator.bf` | Creates new empty .prefab files |
| `Pages/PrefabEditorPageFactory.bf` | Opens .prefab as scene editor page |
| `Inspection/PrefabReferenceEditor.bf` | Inspector with override UI |

## Editor Workflows

### Creating a Prefab

**From selection:**
1. Select entities in scene hierarchy
2. Right-click -> "Create Prefab from Selection"
3. Save dialog -> choose .prefab path in registry
4. Selected entities serialized to .prefab file
5. Original entities replaced with single entity + PrefabReferenceComponent

**From asset browser:**
1. Right-click -> Create -> Prefab
2. Empty .prefab created in current folder
3. Double-click to open and add entities

### Editing a Prefab

1. Double-click .prefab in asset browser
2. Opens in scene editor tab (same UI as scenes)
3. Edit entities, components, transforms as normal
4. Ctrl+S saves back to .prefab
5. All instances in open scenes re-instantiate automatically

### Exposing Parameters

1. Open .prefab in editor
2. Select entity + component property to expose
3. Right-click property in inspector -> "Expose as Parameter"
4. Enter display name -> added to ExposedParameters list
5. (Or: dedicated "Exposed Parameters" panel in prefab editor)

### Overriding Parameters

1. Select entity with PrefabReferenceComponent in scene
2. Inspector shows prefab reference + exposed parameters section
3. Each parameter: default value (dimmed) + override checkbox
4. Enable override -> value becomes editable
5. Override stored in PrefabReferenceComponent.mOverrides

### Instantiating in Scene

1. Drag .prefab from asset browser into viewport or hierarchy
2. Creates entity at drop position with PrefabReferenceComponent
3. Prefab resolves and instantiates child entities
4. (Or: right-click hierarchy -> Add -> Prefab Instance -> select .prefab)

## Phased Implementation

### Phase 1: Core Infrastructure
- PrefabResource + PrefabResourceManager
- PrefabSerializer (reuse SceneSerializer)
- ExposedParameterDescriptor
- PrefabInstanceTag component + manager
- Register with ComponentTypeRegistry
- .prefab file read/write

### Phase 2: Instantiation
- PrefabReferenceComponent + PrefabComponentManager
- Instantiation flow (entities, components, transforms, parenting)
- Intra-prefab EntityRef remapping
- Override application after instantiation
- Nested prefab support with cycle detection
- Cleanup on component/entity destruction

### Phase 3: Editor Integration
- PrefabEditorPageFactory (open .prefab as scene)
- PrefabAssetCreator (create empty .prefab)
- "Create Prefab from Selection" hierarchy command
- Inspector for PrefabReferenceComponent
- Override UI (parameter list with default/override toggle)
- Drag-and-drop from asset browser

### Phase 4: Propagation & Polish
- File change detection (watcher or manual reload)
- Re-instantiation on prefab change
- Override preservation across re-instantiation
- "Expose as Parameter" UI in prefab editor
- Hierarchy visual indicator for prefab instances (icon/badge)
- "Select Prefab Asset" and "Open Prefab" context menu items
- Undo/redo for prefab operations

## Verification

1. Create .prefab from asset browser -> opens as scene, edit, save
2. Drag .prefab into scene -> PrefabReferenceComponent created, entities appear
3. Edit .prefab -> save -> instances in scene update automatically
4. Override a parameter on an instance -> value persists across prefab updates
5. Nested prefab: prefab A contains instance of prefab B -> both instantiate
6. Delete prefab instance -> instantiated child entities cleaned up
7. Save/load scene with prefab instances -> overrides and references preserved
8. Cycle detection: prefab A references itself -> warning, no crash
