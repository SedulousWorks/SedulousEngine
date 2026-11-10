# Runtime reflection in Sedulous

Where the engine, the editor and the tools use Beef's RUN TIME reflection (type data read while
the program runs), what turns it on for a type, and why each use is run time rather than
comptime. Comptime reflection (a `[Comptime]` method or an `IComptimeTypeApply` attribute
reading types while the compiler runs and emitting code) is listed at the end for contrast; it
costs nothing at run time.

Inventory taken 2026-11-10 at `b9700b89a` by searching every non-test source under `Code/`
(less `Code/Deprecated`) for `[Reflect`, `ReflectUser`, `AlwaysIncludeUser`, `[AlwaysInclude]`,
`.ReflectAttribute`, `GetField(`, `GetFields(`, `GetMethod`, `CreateObject`, `CreateValue`,
`Type.Types`, `FieldInfo`, `MethodInfo`, `GetCustomAttribute` and `HasCustomAttribute`, then
reading each hit to tell run time from comptime. Keep it current: a change that adds or removes
a run time use, or an opt-in, updates this file in the same commit.

## What turns it on

Beef reflection is opt in. Run time type data exists only for what one of these asks for.

### Attributes that reflect the types that carry them

An attribute whose `AttributeUsage` names `ReflectUser` turns reflection on for every type it is
put on (for a field attribute, the type that declares the field). Declaring the thing IS asking
for the reflection the tools need, so nobody can forget it.

| Attribute | Declared in | `ReflectUser` | Also |
|---|---|---|---|
| `[Component]` | `Foundation/Sedulous.Core/src/Reflection/ComponentAttribute.bf` | `.Type \| .NonStaticFields \| .DefaultConstructor` | |
| `[SerializableComponent]` | `Foundation/Sedulous.Core/src/Reflection/SerializableComponentAttribute.bf` | the same | comptime: registers its fields' enums with `EnumCases` |
| `[Serializable]` | `Foundation/Sedulous.Core/src/Serialization/SerializableAttribute.bf` | `.Type \| .NonStaticFields` | comptime: generates `Serialize` |
| `[Behaviour]` | `Engine/Sedulous.Engine.Gameplay/src/BehaviourAttribute.bf` | `.Type \| .NonStaticFields \| .DefaultConstructor` | `AlwaysIncludeUser = .Type \| .AssumeInstantiated`, so a class nothing names still links; comptime: `Serialize`, enum registration, refuses an unsendable `[Replicated]` field |
| `[Level]` | `Engine/Sedulous.Engine.Gameplay/src/LevelAttribute.bf` | `.Type \| .NonStaticFields \| .DefaultConstructor` | `AlwaysIncludeUser` as `[Behaviour]`; comptime: the settings block's id, versions, `SerializeSettings`, reference binds, enum registration |
| `[Game]` | `Engine/Sedulous.Engine.Gameplay/src/GameAttribute.bf` | `.Type \| .NonStaticFields` (private fields included) | comptime: enum registration only; a game is never saved |
| `[Replicated]` (on a field) | `Foundation/Sedulous.Net.Replication/src/ReplicatedAttribute.bf` | `.Type \| .NonStaticFields` | |
| `[Setting]`, `[SettingSummary]` (on a field) | `Engine/Sedulous.Engine.Project/src/SettingAttribute.bf` | `.Type \| .NonStaticFields` | |

A reflection request reaches only the class that carries it, never a subclass, which is why the
bases `Behaviour` and `Level` carry `[Reflect(.NonStaticFields)]` of their own (their `Enabled`
and `Active` are data the tools show) and each game class states `[Game]`
(`Engine/Sedulous.Engine.Gameplay/src/Game.bf`, `GameAttribute.bf`).

### `[Reflect]` on a type

| Types | Where | Flags | Why |
|---|---|---|---|
| `Behaviour`, `Level` | `Engine/Sedulous.Engine.Gameplay/src/Behaviour.bf`, `Level.bf` | `.NonStaticFields` | the bases' own fields, beside what `[Behaviour]` and `[Level]` reflect of a subclass |
| `EntityRef` | `Foundation/Sedulous.Scene/src/EntityRef.bf` | `.NonStaticFields` | tooling finds what it names by its `Id` |
| `SceneRef` | `Foundation/Sedulous.Scene.Resource/src/SceneRef.bf` | `.NonStaticFields`, beside `[IdReference(typeof(SceneDocument))]` | `ReferenceShape` reads its `Id` |
| `Ref<T>`, every T | `Foundation/Sedulous.Resource/src/Ref.bf` | `.NonStaticFields \| .Methods` | `ReferenceShape` reads `Id` and calls `Rebind` / `ClearBinding` without naming T |
| `Transform` | `Foundation/Sedulous.Core/src/Math/Transform.bf` | `.Type \| .NonStaticFields` | property animation resolves a track's path against it; the inspector's Transform rows |
| Scene settings blocks: `EnvironmentSettings`, `PostProcessSettings` (Engine.Render), `PhysicsSceneSettings` (Engine.Physics), `NavigationSceneSettings` (Engine.Navigation) | each type's own file under `Engine/` | `.Type \| .NonStaticFields` | the inspector writes a block's field through run time reflection |
| Vegetation layers: `VegetationLayerBase`, `ProceduralVegetationLayer`, `PropVegetationLayer` | `Engine/Sedulous.Engine.Vegetation/src/` | `.All` | list elements of `TerrainVegetationComponent` the inspector makes and edits |
| Particles: `ParticleSystem` (`.Type \| .NonStaticFields \| .Methods`), `ParticleEffect` (`.Type \| .NonStaticFields`), `ParticleEmitter`, `EmissionShape`, `CollisionBehavior`, `FlipbookSettings`, `TrailSettings`, `RangeColor`, `ParticleCurveFloat`, `ParticleCurveColor`, `SubEmitterLink` (`.Type \| .NonStaticFields \| .DefaultConstructor`) | `Foundation/Sedulous.Particles/src/` | as listed | the particle effect page's grid (`FieldPropertySource`), its module lists of objects made by type |
| Input: `ActionSet`, `InputAction`, `Binding`, `Interaction`, `ActionProcessors` | `Foundation/Sedulous.Input/src/` | `.Type \| .NonStaticFields \| .DefaultConstructor` | the input map page lists their fields as the grid's rows |
| Import options: `ImportOptions` (`.NonStaticFields`), `TextureImportOptions`, `AudioImportOptions`, `ModelImportOptions`, `ClipImportSettings` (`.NonStaticFields \| .DefaultConstructor`) | `Pipeline/Sedulous.Pipeline.Importer/src/ImportOptions.bf` and each importer's | as listed | the import window's rows and `asset_import`'s `options` |
| `Asset` | `Pipeline/Sedulous.Pipeline.Core/src/Asset.bf` | `.NonStaticFields` | an asset page shows the base's source file with a concrete asset's `[Serializable]` fields |
| `AimIkBone`, `FootIkLegBones` | `Engine/Sedulous.Engine.Animation/src/IkComponents.bf` | `.DefaultConstructor` | `component_set` makes the elements |
| Enums, `.StaticFields` | e.g. `WindowMode` (Engine.Project), `AaMode`, `TonemapOperator`, `SettingsSource` (Engine.Render), `AoMode`, `SkyMode`, `PoseAssignment` (Render), `ContentRotation`, `FitMode`, `ScreenOrientation` (Core Math), `KeyCode`, `MouseButton`, `GamepadButton`, `GamepadAxis` (Shell), `ActionKind`, `BindingSource`, `InteractionKind`, `MouseAxisCode`, `StickCode` (Input), the particle enums, `ImageColorSpace`, `TextureWrap`, `CompressionChoice`, `TextureUsage`, `ModelUpAxis` (ModelImporter), `ExportBuilder` (Editor.Project) | | `.StaticFields` | their case names at run time: a setting, an import option or a row offers and takes the cases by name |

### Enum case names

An enum without `[Reflect]` has no case names at run time: `Enum.GetEnumerator` finds nothing
and a value reads as its number (`Foundation/Sedulous.Core/src/Reflection/EnumCases.bf`). Two
ways give a tool the names:

- `[Reflect(.StaticFields)]` on the enum (the table above): the engine's own enums.
- `EnumCases`: `[Behaviour]`, `[Level]`, `[Game]` and `[SerializableComponent]` register, at
  comptime, the cases of every enum their type's fields hold (`EnumCases.AppendRegistration`),
  so a game's enums need no `[Reflect]`. `EnumCases.Of` answers the registered cases, else the
  enum's reflection. `FieldJson`, `SceneReference` and the inspector ask through it.

### Attribute data

An attribute's data reaches run time only when its `AttributeUsage` carries
`.ReflectAttribute`, and only on a member or type whose own data is emitted. These are read at
run time, and by what:

| Attribute | Declared in | Read at run time by |
|---|---|---|
| `[Hidden]` | `Foundation/Sedulous.Core/src/Reflection/HiddenAttribute.bf` | `FieldJson.IsShown` (the inspector, `entity_inspect`, `component_set`), `ImportOptions.GetSettings` |
| `[DisplayName]` | `.../Reflection/DisplayNameAttribute.bf` | `FieldPropertySource` (fields and `[InspectorProperty]` methods), `SceneReference`, `ImportOptions.SettingLabel`, and on types: `SceneInspectorView` (a component's title), `AssetObjectPage`, `AssetsView`, `AssetPickerWindow`, `GenericAssetEditorPage` |
| `[Description]` | `.../Reflection/DescriptionAttribute.bf` | `FieldPropertySource`, `SceneReference`, `SceneInspectorView` (a component type's) |
| `[Category]` | `.../Reflection/CategoryAttribute.bf` | `SceneInspectorView` and `EditorIcons` (on types), `SceneReference` (on fields) |
| `[Range]` | `.../Reflection/RangeAttribute.bf` | `FieldPropertySource`, `SceneReference`, `SettingFields.CountRange`, `SettingsDialog` |
| `[VisibleWhen]` | `.../Reflection/VisibleWhenAttribute.bf` | `FieldPropertySource`, `SceneReference` |
| `[ReadOnly]` | `.../Reflection/ReadOnlyAttribute.bf` | `FieldPropertySource`, `component_set` (`SceneMcpTools.bf`), which refuses it |
| `[InspectorField]` | `.../Reflection/InspectorFieldAttribute.bf` | `FieldPropertySource.IsShown`: a private field shown as a row (the inspector alone; `FieldJson` still sees only public fields) |
| `[InspectorProperty]` | `.../Reflection/InspectorPropertyAttribute.bf` | `FieldPropertySource`: a getter shown as a row, written through its named setter by `GetMethod(...)` |
| `[AsColor]`, `[References]` | `.../Reflection/AsColorAttribute.bf`, `ReferencesAttribute.bf` | `FieldPropertySource` |
| `[SceneOnly]` | `.../Reflection/SceneOnlyAttribute.bf` | `SceneEditContext` (a settings edit), `SettingsProfilePage` |
| `[IdReference]` (on a struct) | `Foundation/Sedulous.Resource/src/IdReferenceAttribute.bf` | `ReferenceShape.IsIdReference` / `Target` |
| `[Setting]`, `[SettingSummary]` | `Engine/Sedulous.Engine.Project/src/SettingAttribute.bf` | `SettingFields` |
| `[Replicated]` | `Foundation/Sedulous.Net.Replication/src/ReplicatedAttribute.bf` | `ReplicatedLayout.IsReplicated` |
| `[BoneName]` | `Engine/Sedulous.Engine.Animation/src/BoneNameAttribute.bf` | `FieldPropertySource`, through the hint `BoneNameEditor` registers (`RegisterHintAttribute`), so the row offers the skeleton's bones |

`[NotSerialized]` and `[Appended]` are `.ReflectAttribute` too, but read only at comptime
(`SerializableAttribute`, `ResourceRefFields`). `[GuiProperty]`, `[GuiList]` and
`[GuiReference]` are `.ReflectAttribute` so the comptime `[GuiReflect]` generator sees them on a
field (see Comptime only below).

### `[AlwaysInclude]` for a reflected call

`ParticleSystem.SetMaxParticles` (`Foundation/Sedulous.Particles/src/ParticleSystem.bf`) is
`[AlwaysInclude]`: nothing calls it by name in code, only `FieldPropertySource` through the
`[InspectorProperty]` row's setter, so it would otherwise not link.

## Run time uses

### In the player (ships with a game)

| Use | file: symbol | Reflects over | Opted in by | Why run time |
|---|---|---|---|---|
| Replication layout | `Foundation/Sedulous.Net.Replication/src/ReplicatedLayout.bf`: `Fields` (cached per type in `sCache`), used by `FieldCodec` and `InterpolationBuffer` | a component's fields, keeping the `[Replicated]` ones of a supported type | `[Replicated]` | the replicator holds a manager, not T; both peers derive the same layout from the same type. A behaviour's replicated fields do not go this way: its manager emits their reads and writes at comptime (`BehaviourManager`, `BehaviourReplication`) |
| Prefab entity refs | `Foundation/Sedulous.Scene.Resource/src/PrefabEntityRefs.bf`: `Remap` (called by `PrefabSpawn`, `PrefabDeltas`, `SceneResolve`) | a component's fields of type `EntityRef` and `List<EntityRef>`, remapped in place; a behaviour's too, its manager answering the instance's address | `[Component]`, `[SerializableComponent]`, `[Behaviour]` | covers every component through its manager, with no per type code |
| Unbound id references | `Foundation/Sedulous.Scene/src/SerializableComponentManager.bf`: `CollectUnboundReferences` | a component's own fields that are id references (`ReferenceShape.IsIdReference`), for a pruned export | `[SerializableComponent]` (behaviours and levels emit theirs at comptime) | the manager's generic body, shared by every component |
| Property animation | `Foundation/Sedulous.PropertyAnimation/src/PropertyBindingResolver.bf`: `Resolve`, `Read`, `Write`, the chain held in `PropertyBinding.bf`; driven by `Engine/Sedulous.Engine.Animation/src/PropertyAnimatorComponentManager.bf` | a dotted path resolved to a `FieldInfo` chain once, then the leaf read and written every frame through `GetValue` / `SetValue` and `MemberOffset` | the component's own opt in; `Transform`'s `[Reflect]` | a track's path is authored data, known only when the clip loads |
| Reference shape | `Foundation/Sedulous.Resource/src/ReferenceShape.bf`: `Is`, `IsIdReference`, `Target`, `Id`, `Assign` | a `Ref<T>`'s `Id` by `GetField`, then `Rebind` or `ClearBinding` by `GetMethod(...).Invoke`; an `[IdReference]` struct's attribute and `Id` | `Ref<T>`'s `[Reflect]`; `[IdReference]` plus the struct's `[Reflect]` | generic tooling reads and writes a reference without naming T. Its callers are editor and tool code, and `CollectUnboundReferences` above |

### In the editor

| Use | file: symbol | Reflects over | Opted in by | Why run time |
|---|---|---|---|---|
| The property grid's source | `Editor/Sedulous.Editor.App/src/FieldPropertySource.bf`: `FieldPropertySource` | the shown fields (and `[InspectorProperty]` methods) of a value at an address: rows, defaults from `CreateValue` / `CreateObject`, writes by `GetField(name)` and `MemberOffset`, a list of objects adding any made type deriving from its element type (`Type.Types`, `IsSubtypeOf`, `CreateObject`), a `[References]` target by name (`Type.Types`) | the type's opt in, as each caller below | one source serves every component, settings block, asset and behaviour, a game's included, from a `Type` and an address; the GUI's own comptime tables (`[GuiReflect]`) describe GUI objects, not these |
| Component sections | `Editor/Sedulous.Editor.Scene/src/Inspector/SceneInspectorView.bf` (the transform over `Transform`, each component and behaviour section); commits through `ComponentTarget.Mutate` (the serializer, not reflection) | as above; a component type's `[DisplayName]`, `[Category]`, `[Description]` | `[Component]`, `[SerializableComponent]`, `[Behaviour]`, `Transform`'s `[Reflect]` | as above |
| Scene settings and levels | `Editor/Sedulous.Editor.Scene/src/Inspector/SceneSettingsSource.bf` (a block's own values and its profile's); `Editor/Sedulous.Editor.Render/src/Profile/SettingsProfilePage.bf` (a profile asset, `[SceneOnly]` fields left out) | a block's `SettingsType`, a level's being its own class | the blocks' `[Reflect]`, `[Level]` | as above |
| Asset pages | `Editor/Sedulous.Editor.App/src/AssetObjectPage.bf` | the asset object read from its file | `[Serializable]`, `Asset`'s `[Reflect]` | as above |
| Import window | `Editor/Sedulous.Editor.App/src/ImportDialog.bf`, over `ImportOptions.GetSettings` / `FindSetting` (`Pipeline/Sedulous.Pipeline.Importer/src/ImportOptions.bf`); importers' `DescribeSetting` / `SettingChanged` take a `FieldInfo` | an importer's options object | `ImportOptions`' and each options class's `[Reflect]` | an importer declares its settings once, as fields |
| Particle and input pages | `Editor/Sedulous.Editor.Particles/src/Particles/ParticleEffectEditorPage.bf` (over `ParticleSystem`), `Editor/Sedulous.Editor.Input/src/InputMapEditorPage.bf` (over `ActionSet`) | those types and what they hold | their `[Reflect]` | as above |
| Field edit commands | `Editor/Sedulous.Editor.Scene/src/Edit/`: `SetComponentPropertyCommand`, `SetComponentStringCommand`, `SetEntityRefCommand`, `SetReferenceCommand` (through `ReferenceShape`), `SetResourceRefCommand`, `SetSceneSettingCommand`, `SetSceneSettingRefCommand`, each finding the field by `RawFieldAccess.FindField` (`Editor/Sedulous.Editor.App/src/RawFieldAccess.bf`) on every Execute and Undo; `SceneEditContext` checks `[SceneOnly]` | a component's or settings block's field by name | the type's opt in | an undoable edit named by field, reached through `SceneEditContext` by `component_set` and by `ComponentTarget` / `SettingsTarget` |
| Remove a component | `Editor/Sedulous.Editor.Scene/src/Edit/RemoveComponentCommand.bf` | walks `GetFields` to snapshot a component that has no serializer | `[Component]` | the one case with nothing else to copy it through |
| Project settings and export presets | `Engine/Sedulous.Engine.Project/src/SettingAttribute.bf`: `SettingFields`; read by `Editor/Sedulous.Editor.App/src/SettingsDialog.bf` (its rows) and `ProjectHomeView.bf` (the summary, `DefaultSceneId` by `GetField`) | the `[Setting]` fields of `ProjectSettings` and `ExportPreset`, and of a plugin's settings object | `[Setting]` | a field added with `[Setting]` is offered by the dialog and the tools at once, rather than by whichever hand list remembered it |
| Type lookups by name | `Editor/Sedulous.Editor.Core/src/EditorPageRegistry.bf`: `FindTypeByFullName`; `SettingsDialog`'s source types | `Type.Types`, every type the build has data for, by full name | none (type names) | an asset record names its type as text |
| Type labels | `Editor/Sedulous.Editor.Core/src/EditorIcons.bf` (`[Category]` up the chain), `AssetsView.bf`, `AssetPickerWindow.bf`, `GenericAssetEditorPage.bf` (`[DisplayName]`) | a type's attributes | the type's opt in | the type is known only as a `Type` |
| Animatable properties | `Editor/Sedulous.Editor.PropertyAnimation/src/AnimatableProperties.bf`: `Collect`; the preview in `ClipPreview.bf` | a component's fields, each path checked by `PropertyBindingResolver.Resolve` | the component's opt in | it offers what the runtime resolver can drive |
| Play probes | `Editor/Sedulous.Editor.Play/src/Game/NativeGameFields.bf`, used by `PieRunTool.bf` (`pie_run`'s `game` and `level` probes) | a field of the running `Game`, or of a scene's active `Level`, public or private, by name | `[Game]`, `[Level]` | an agent names the field it watches while the game runs |

`Editor/Sedulous.Editor.Scene/src/Inspector/SlotTarget.bf` still writes a list element's field
by `GetField(name)`, but nothing constructs a `SlotTarget` now: the grid's list rows go through
`FieldPropertySource`.

`IReflectedList` (`Foundation/Sedulous.Core/src/Reflection/IReflectedList.bf`) serves
`FieldJson`'s list walk, but it is interface dispatch given to `List<T>` by extension, not
reflection.

### In the MCP tools

| Tool | file: symbol | Reflects over | Opted in by | Why run time |
|---|---|---|---|---|
| `entity_inspect` | `Editor/Sedulous.Editor.Scene/src/Page/SceneMcpTools.bf`: `EntityJson`, over `Editor/Sedulous.Editor.App/src/FieldJson.bf`: `FieldsJson`, `ValueJson` | every component's and behaviour's shown fields (public, instance, not `[Hidden]`) as JSON: references as guids (`ReferenceShape`), enums by name (`EnumCases`), lists through `IReflectedList` | the component's or behaviour's opt in | one walk for every type, a game's included |
| `component_set` | the same file: the field by `GetField`, `[ReadOnly]` refused, a list of objects made by `CreateObject` and filled by field name; the write through the edit commands above | as above | as above | as above |
| `component_schema`, `docs://generated/SceneSchema.json` | `Editor/Sedulous.Editor.Mcp/src/SceneReference.bf` | joins each recorded wire key to the component's or settings block's field (`GetFields`), reads its `[DisplayName]`, `[Description]`, `[Category]`, `[Range]` and `[VisibleWhen]`, an enum's cases (`EnumCases.Of`), a reference's target (`ReferenceShape.Target`) | the component's or block's opt in | it describes what the running host has registered, plugins' managers included, generated when asked |
| `project_info`, `project_settings_set`, `export_presets`, `export_preset_set`, the plugin tools' settings, `project_health` | `Editor/Sedulous.Editor.Mcp/src/ReflectedFields.bf` over `SettingFields`; `ProjectInfoTool.bf`, `ExportPresetTools.bf`, `PluginTools.bf`, `ProjectHealthTool.bf` | the `[Setting]` fields: the answer, the arguments' schema, the check and the write | `[Setting]` | as the settings dialog |
| `asset_import`'s `options` | `Editor/Sedulous.Editor.Mcp/src/AssetWriteTools.bf` | an importer's options by label (`ImportOptions.FindSetting`), a choice through `SettingFields.WriteChoice` and `Enum.EnumToString` | the options class's `[Reflect]`; the enum's `[Reflect(.StaticFields)]` | an importer declares its settings once, as fields |
| `type_list`, `type_info` | `Foundation/Sedulous.Mcp.Reflection/src/ReflectionTools.bf` | `Type.Types`, a type's `GetFields` and `GetMethods` | whatever the build reflects | by nature a view of the run time type table |

## Comptime only (no run time cost)

For contrast, and so nobody moves these twice:

- `[Serializable]` and `[SerializableRegistry]` (`Foundation/Sedulous.Core/src/Serialization/`):
  the `Serialize` body, walking the fields (`[NotSerialized]`, `[Appended]`).
- `[SerializableComponent]` and `SerializableComponentManager.EmitIdentity`
  (`Foundation/Sedulous.Scene/src/SerializableComponentManager.bf`): the id and data versions,
  baked in.
- `[Behaviour]`, `[Level]` and `[Game]`'s `ApplyToType`; `BehaviourManager`'s `EmitIdentity`,
  `EmitTickLists` (which ticks and contact callbacks a class overrides, found from its methods
  rather than by reflection at run time), `EmitBindReferences`, `EmitCollectIdReferences` and the
  replication writers and readers; `ResourceRefFields`; `Level.EmitChecks` and `Game.EmitChecks`
  (`Engine/Sedulous.Engine.Gameplay/src/`).
- `EnumCases.AppendRegistration` (`Foundation/Sedulous.Core/src/Reflection/EnumCases.bf`).
- `[GuiReflect]` (`Foundation/Sedulous.GUI/src/Core/GuiReflect.bf`): every GUI type's table of
  `[GuiProperty]` properties with typed get and set thunks, which markup, sheets, bindings and the
  toolkit's `ReflectedSource` (`Foundation/Sedulous.GUI.Toolkit/src/ReflectedSource.bf`) use. No
  run time reflection.

## What comptime itself needs reflected

Comptime is not free of the flags. Checked against the compiler (the Beef repo's
`IDEHelper/Compiler`):

- **Fields: nothing.** Comptime builds a type's data with `forceReflectFields` set
  (`CeMachine.cpp:4188`, applied at `BfModule.cpp:7821`), so a `[Comptime]` method sees every
  field of any type without `[Reflect]`.
- **Methods: nothing.** `GetMethods` at comptime goes through the `Comptime_GetMethodCount` and
  `Comptime_GetMethod` intrinsics (`BeefLibs/corlib/src/Type.bf:806-807`).
- **A MEMBER's attributes: the attribute must be `.ReflectAttribute`.** Field attributes travel
  in the type data, and `_HandleCustomAttrs` (`BfModule.cpp:7668`) keeps one only when its
  attribute type's `AttributeUsage` carries `.ReflectAttribute`. That is why `[NotSerialized]`,
  `[Appended]` and `[GuiProperty]` declare it though nothing reads them at run time.

So a move of a use to comptime can drop the `ReflectUser` or `[Reflect]` that serves it, but not
the `.ReflectAttribute` flag on the attributes a generator reads.

## Tests that rely on it

Test fixtures opt in the same way (`[Reflect]`, `[Component]`, `[Behaviour]` on their own
types). They follow whatever the code under test needs and move with it.
