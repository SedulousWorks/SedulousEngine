# Runtime reflection in Sedulous

Where the engine, the editor and the tools use Beef's RUN TIME reflection (type data read
while the program runs), what turns it on, and what a move to comptime would take for each
use. Comptime reflection (a `[Comptime]` method or an `IComptimeTypeApply` attribute reading
types while the compiler runs and emitting code) is listed at the end for contrast; it costs
nothing at run time.

Inventory taken 2026-09-26 at `efcd85ac` by searching every non-test source for `GetField`,
`GetFields`, `GetMethod(s)`, `FieldInfo`, `MethodInfo`, `Invoke`, `GetCustomAttribute`,
`HasCustomAttribute`, `[Reflect`, `ReflectUser` and the `Enum` name helpers, then reading each
hit to tell run time from comptime. Keep it current: a change that adds or removes a run time
use updates this file in the same commit.

## What turns it on

Beef reflection is opt in. Run time type data exists only for what one of these asks for.

| Declaration | Where | What it reflects |
|---|---|---|
| `[Component]` | `Foundation/Sedulous.Scene/src/ComponentAttribute.bf:16` | `ReflectUser = .Type \| .NonStaticFields` on every struct that carries it |
| `[SerializableComponent]` | `Foundation/Sedulous.Scene/src/SerializableComponentAttribute.bf:16` | the same, on every serializable component |
| `[Replicated]` | `Foundation/Sedulous.Net.Replication/src/ReplicatedAttribute.bf:15` | the same, on the type owning a replicated field |
| `[Reflect(.NonStaticFields \| .Methods)]` | `Foundation/Sedulous.Resource/src/Ref.bf:25` | `Ref<T>`, every T: the `Id` field and the binding methods |
| `[Reflect(.Type \| .NonStaticFields)]` | `EnvironmentSettings.bf:14`, `PostProcessSettings.bf:16` (Engine.Render), `PhysicsSceneSettings.bf:18`, `NavigationSceneSettings.bf:14`, `SceneScriptSettings.bf:15` | the scene settings blocks |
| `[Reflect(.All)]` | `VegetationLayerBase.bf:16`, `ProceduralVegetationLayer.bf:14`, `PropVegetationLayer.bf:14` (Engine.Vegetation) | the vegetation layer classes: fields, methods, constructors |

Attribute DATA is reflected by the `.ReflectAttribute` flag on the attribute's own
`AttributeUsage`. Only three attributes are read at run time: `[Hidden]` and `[ReadOnly]`
(Sedulous.Core, by the MCP inspect and write tools) and `[Replicated]` (by replication).
Every other attribute (`[Scriptable]`, `[Range]`, `[Description]`, `[VisibleWhen]` and so on)
is read only at comptime.

Enum case names and values are present at run time without any opt in. `Enum.EnumToString`
and `Enum.GetEnumerator` read them (verified: `LightType` carries no `[Reflect]` and its case
names read at run time).

## Run time uses

### In the player (ships with a game)

| Use | Where | What it does | When |
|---|---|---|---|
| Replication layout | `Foundation/Sedulous.Net.Replication/src/ReplicatedLayout.bf:53-64` | walks a component's `GetFields`, keeps those with `[Replicated]`; the `FieldInfo` list is cached per type (`sCache`) | first capture or apply per component type, then the cache |
| Prefab entity refs | `Foundation/Sedulous.Scene.Resource/src/PrefabEntityRefs.bf:40-66` | walks a component's fields for `EntityRef` and `List<EntityRef>` and remaps them in place | every prefab spawn |
| Property animation | `Foundation/Sedulous.PropertyAnimation/src/PropertyBindingResolver.bf:50,114,147,196,204`, bound in `PropertyBinding.bf` | resolves a dotted path to a `FieldInfo` chain once, then reads and writes the leaf through `GetValue` / `SetValue` and `MemberOffset` | resolve on bind; read and write every frame from `Engine.Animation/src/PropertyAnimatorComponentManager.bf:117` |

### In the editor

| Use | Where | What it does |
|---|---|---|
| Field access for undo | `Editor/Sedulous.Editor.Scene/src/Edit/RawFieldAccess.bf` | `Type.GetField(name)`, `MemberOffset`, `FieldInfo.GetValue` / `SetValue` over a raw component address |
| Component edits | `SetComponentPropertyCommand.bf`, `SetResourceRefCommand.bf`, `SetEntityRefCommand.bf` (Edit/) | a field by name through `RawFieldAccess`, re-resolved on every Execute and Undo |
| Settings edits | `Edit/SetSceneSettingCommand.bf:44,73,98` | the same over a scene settings block |
| Remove, non-serializable | `Edit/RemoveComponentCommand.bf:43` | walks `GetFields` to snapshot a component that has no serializer |
| Inspector list slots | `Inspector/SlotTarget.bf:69,85,102` | writes a list element's field by name; the element accessor itself is comptime generated. Presumably why the vegetation layers ask for reflection (not stated in `0f499939`; unverified) |
| Animatable properties | `Editor/Sedulous.Editor.PropertyAnimation/src/AnimatableProperties.bf:40` | walks a component's `GetFields` for the property animation picker |
| `entity_inspect` | `Page/ComponentJson.bf`, `Page/SceneMcpTools.bf` (Editor.Scene) | walks a component's shown fields (public, not `[Hidden]`) and writes them as JSON; enums by name through `Enum.EnumToString` |
| `component_set` | the same files, and `Edit/SetReferenceCommand.bf` | a field by name, `[ReadOnly]` refused, the write through the edit commands above |
| Reference shape | `Foundation/Sedulous.Resource/src/ReferenceShape.bf` | a `Ref<T>`'s `Id` by `GetField`, then `Rebind` or `ClearBinding` by `GetMethod(...).Invoke`, never naming T |

`IReflectedList` (`Foundation/Sedulous.Core/src/Reflection/IReflectedList.bf`) serves
`entity_inspect`'s list walk but is interface dispatch, given to `List<T>` by extension, not
reflection.

### In the MCP tools

| Use | Where | What it does |
|---|---|---|
| `type_list`, `type_info` | `Foundation/Sedulous.Mcp.Reflection/src/ReflectionTools.bf:131,145` | report a type's fields and methods from Beef's type table, for whatever the build reflects |

## Comptime only (no run time cost)

For contrast, and so nobody moves these twice:

- The script surface walker (`Foundation/Sedulous.Script/src/ScriptSurfaceWalker.bf`): every
  script binding thunk is generated at comptime.
- The inspector row emitter (`Editor/Sedulous.Editor.Scene/src/Inspector/InspectorRows.bf`).
- `[Serializable]` and `[SerializableRegistry]` (`Foundation/Sedulous.Core/src/Serialization/`).
- `SerializableComponentManager.EmitIdentity` (`Foundation/Sedulous.Scene/src/SerializableComponentManager.bf`):
  the serialization id and data versions, baked in.

## What comptime itself needs reflected

Comptime is not free of the flags. Checked against the compiler (`IDEHelper/Compiler`):

- **Fields: nothing.** Comptime builds a type's data with `forceReflectFields` set
  (`CeMachine.cpp:4189`, applied at `BfModule.cpp:7796`), so a `[Comptime]` method sees every
  field of any type without `[Reflect]`.
- **Methods: nothing.** The comptime type data skips methods (`BfModule.cpp:8027`); `GetMethods`
  at comptime goes through the `Comptime_GetMethodCount` and `Comptime_GetMethod` intrinsics
  (`corlib Type.bf:806-807`), which do not consult reflection flags.
- **A TYPE's attributes: nothing.** Read from the compiler's own data (`CeMachine.cpp:6749`).
- **A MEMBER's attributes: the attribute must be `.ReflectAttribute`.** Field (and method)
  attributes travel in the type data, and `_HandleCustomAttrs` (`BfModule.cpp:7643-7675`) keeps
  one only when its attribute type's `AttributeUsage` carries `.ReflectAttribute`. That is why
  `[Scriptable]`, `[Hidden]`, `[Range]`, `[Description]` and the rest declare it: without it the
  script surface walker and the inspector emitter could not see them on a field.

So a move to comptime can drop the `ReflectUser` field reflection and the `[Reflect]`s below,
but NOT the `.ReflectAttribute` flag on our attribute types. The flag only decides which
attributes ride along with a member whose data is emitted; with no run time member data, none
reach the binary.

## Moving to comptime: what each use would need

- **Replication layout.** The `[Replicated]` fields are known per component type at compile
  time: a comptime-emitted capture and apply per component (the serializer's pattern) replaces
  the cached `FieldInfo` list. It needs a generic entry point the replicator calls per type.
- **Prefab entity refs.** The `EntityRef` and `List<EntityRef>` fields are known at compile
  time: a comptime-emitted remap per component, reached through the manager (it knows T),
  replaces the field walk.
- **Property animation.** Paths are authored data, so a path still has to resolve at run time.
  A comptime-emitted table per component of (path, offset, leaf type, getter, setter) would
  replace `FieldInfo`, with the resolver looking the path up in it. This is the only per frame
  use, so it matters most in the player.
- **Editor field access and commands.** The inspector already emits its rows at comptime; the
  commands could take a comptime-emitted accessor (an offset and a typed get and set) instead
  of a name and `FieldInfo`. The name is persisted in undo records only as a lookup key.
- **`entity_inspect` and `component_set`.** A comptime-emitted JSON writer and reader per
  component (as `[Serializable]` emits `Serialize`), registered on the manager; resource
  references and enums are known at compile time there, so `ReferenceShape` and the reflection
  on `Ref<T>` would go with it.
- **Animatable properties.** A comptime-emitted list per component, which property animation's
  table above would also serve.
- **MCP type tools.** By nature a view of the run time type table. Either they stay
  reflection-based (and report only what the build reflects) or they read a comptime-emitted
  catalogue of the authored surface, as `script_api` does for scripts.

Once none of these remain, the `ReflectUser` on `[Component]`, `[SerializableComponent]` and
`[Replicated]`, and the `[Reflect]` on `Ref<T>`, the settings blocks and the vegetation layers
can go, which shrinks the binary's type data. The `.ReflectAttribute` flags stay (see above).

## Tests that rely on it

Test fixtures opt in the same way (`[Reflect]` on `TestComponent`, `AnimComponent`,
`AnimLight`, `Widget`, `TestComp`, `PreviewComp`, `WindSettings` and others). They follow
whatever the code under test needs and move with it.
