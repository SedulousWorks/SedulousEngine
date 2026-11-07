# x2 phase 3: native game tiers

**Status:** design note, 2026-11-07, approved the same day (see Rulings). It expands phase 3 of `x2.md` (D2, D3).

## What exists

**Scripts** (`Code/Engine/Sedulous.Engine.Script`):
- **Behaviour:** `ScriptComponent` (`[SerializableComponent("script")]`) holds an ordered `List<ScriptBehavior>` that the manager owns. Each `ScriptBehavior` has a class ref, `Enabled`, `UpdateInterval` and overrides keyed by name hash.
- **Level:** `SceneScriptSettings` is `ScriptSceneSystem`'s settings block (`SettingsId "script"`).
- **Ordering:** `ScriptSceneSystem` is sim-only at `UpdateOrder -110`, ahead of the crowd (-100) and animation (-2, -1). Each tick runs the Level, then the behaviours entity by entity, then drains the deferred messages and contacts. An inactive entity freezes, and a fault disables one behaviour.
- **Fixed update:** `onFixedUpdate` reaches the Level only (`OnFixedUpdate`, line 304), although `Scripting.md` lists it for behaviours too.
- **Game:** `GameInstance.StartScript`/`TickScript`/`StopScript`. The player calls it after `Instance.Start()` and before the boot scene (`PlayerApplication.bf:213-214`). PIE calls it before loading the scene and calls `Start()` after (`GameEditorPageRun.bf:49,88`).

**Native pieces:**
- `SerializableComponentManager<T>` (struct components, identity baked at comptime) and `SceneModuleContributions` with `EnginePluginServices.AddSceneManager` (recorded and reversed on unload). NativeSample's `SpinManager` uses both.
- `IRunListener`/`RunRegistry` (`Sedulous.Run`), and `RunBase.Add/AddForSession/Register`.
- `Scene.Run`, the scene event bus, which is the run's bus (`GameInstance` ctor).
- Run services by type:
  - `GameInstance` registers `InputFacade`, `SaveFacade`, `NetFacade`, `RunSave` and `HttpFacade`;
  - the subsystems register `GuiFacade` (`GuiSubsystem.bf:514`) and `AudioFacade` per run.
- **Editor and MCP plumbing:**
  - The inspector, `FieldJson` and `PrefabEntityRefs` all work from `manager.ComponentType` plus `GetComponentAddress`, and `FieldPropertySource` already reads an object at an address (that is how `SceneScriptSettings` is shown).
  - Prefab deltas compare whole component blobs per `SerializationTypeId` (`PrefabDeltas.CollectComponentOps`), and an op whose type is absent passes through untouched.

**Tallow** (`Tallow-ecs/Engine/src/Scene/Component.bf`) has class components with virtual Awake/OnEnable/Start/FixedUpdate/Update/LateUpdate/OnDisable/OnDestroy, plus edit-time hooks. `[Component]` forces reflection and inclusion. `ScriptCallbackIndex` lists a class only under the callbacks it overrides.
- **Borrow:** the class shape, override detection for the tick lists, and LateUpdate.
- **Leave:** `TickInput`/predicted network ticks, the GameObject graph, edit-time callbacks (OnRegister/OnFrame/OnValidate: managers do edit-time work here), and compiler-written `SaveFields`.

## What the samples use

The six samples' `Sources/*.as` hold 58 files:
- 52 behaviour classes;
- 5 `Game` classes (all but ShaderGallery, whose `Gallery` is a behaviour);
- 1 `Level` (PaperKid, with 8 properties).

| Area | Use |
|---|---|
| Lifecycle | onUpdate 50, onStart 39; onEnable/onDisable/onDestroy/onFixedUpdate/onStop **0**; Game launch 5, update 7 files, exit 2 |
| Properties | 346 annotated: float 265, int 39, Entity 33, asset Guid 18, bool 8, string 2, Float3 2; 23 `replicated` (Masquerade) |
| Scene data | ~1,429 behaviour records; 1,395 entities carry 1 behaviour, 32 carry 2-4; every `updateInterval` is 0 |
| Events | `scene.Scripts.Emit` 59 + `Run.Emit` 5; ~85 `on<Event>` handlers; `Send` 13; contacts: onTriggerEnter 3, onContactBegin 2 |
| Coroutines | `yield()` **0** |
| Component handles `X::of` | 69: NavAgent 23, Character 13, InstanceMember 6, SkeletalAnimation 5, PathFollow 5, Light 5, others ≤2 |
| Entity ops | GetWorldPosition 103, IsValid 100, GetLocalTransform 23, Destroy 11, SetActive 4; `scene.FindEntityByName` 22 |
| Audio | PlayOneShot 48, PlayMusic 6, StopMusic 3, bus volume 4; scene.Audio 6 |
| Input | WasPressed 28, Rumble 14, IsDown 12, Value 8, Push/PopSet 2 |
| GUI | `Gui.Root().Find` 44; `node.On("click")` 14 + `On("tag")` 1 (78 `EventHandler` uses); `Label/Slider/ProgressBar/...::Of` 38; ScreenStack Push 35/Pop 14; Bind/OnCommand/data values **0** |
| Run | TimeScale 27, LoadScene 7, RequestExit 5, RealDeltaTime 5 |
| Save | 46 (GetInt 20, SetInt 8, GetFloat 7, Flush 6, floats lists 2) |
| Random | 44 (Range 33, IntRange 8, Bool 3) |
| Net | 35, all Masquerade: IsClient 14; On/OnNumber/OnText/OnJoin/OnLeave 6 |
| Scene facades | Animation 28, Prefabs.Spawn 17, Physics 14, Render 8, Particles 5, Splines 4; Http **0** |

## The Behaviour tier

A new library holds all three tiers: `Code/Engine/Sedulous.Engine.Gameplay` (namespace `Sedulous.Engine.Gameplay`). Its dependencies are Scene, Scene.Resource, Run, Messaging, Net.Replication (its `[Replicated]`), Engine.Physics, Engine.GameInstance and Engine.Composition. Nothing script-related.

```beef
[Behaviour("skyhopper.coin"), DisplayName("Coin"), Category("Sky Hopper")]
class Coin : Behaviour
{
	[Description("Points it is worth")] public int32 Points = 10;
	public Ref<AudioClip> PickupSound;
	public EntityRef Spinner;
	[Replicated] public bool Taken;
	private float mBob; // state: neither saved nor shown

	protected override void OnStart() { ... }
	protected override void OnUpdate(float dt) { ... }
	protected override void OnTriggerEnter(EntityHandle other) { ... }
}
```

- **Base:** `abstract class Behaviour`. It carries BORROWED `Scene` and `Entity` (an `EntityHandle`), with `Run` (`Scene.Run`), `Get<T>() where T : struct` (T*, see `Scene.GetComponent<T>` below), `Get<B>() where B : Behaviour`, `Enabled` and `IsActive`.
- **Lifecycle virtuals,** by presence: OnEnable, OnStart (once), OnUpdate(dt), OnFixedUpdate(dt), OnLateUpdate(dt), OnDisable, OnDestroy, and the contacts OnContactBegin/End and OnTriggerEnter/Exit.
- **Simulation only:** nothing runs in edit mode. A constructor and field initialisers must not touch the scene; they are the defaults the inspector reads from a default-constructed instance (`FieldPropertySource`).
- **Order:**
  - one `BehaviourSystem` per scene (sim-only, `UpdateOrder -110`, the script tier's slot), so the read-last-frame/write-this-frame contract in `Scripting.md` holds unchanged;
  - per frame: enable/start edges, then OnUpdate per type in registration order, each type's instances in pool order (type-major, so a type's loop stays tight), then the contact queue;
  - OnFixedUpdate rides `SceneSystem.OnFixedUpdate`, the lane physics steps in before the frame's Update (`SceneSubsystem.BeginFrame`);
  - OnLateUpdate runs in `PostUpdate` (for cameras).
  - Following Tallow, a type's tick lists are found once by reflection: only types that override OnUpdate/OnFixedUpdate/OnLateUpdate join them.
- **Inactive entities** freeze: no calls, start deferred, as scripts do. There is no fault isolation: native code that crashes takes the process down (Beef has no exceptions).
- **Storage and ownership:** `BehaviourManager<T> : ComponentManagerBase where T : Behaviour, new`, one per type.
  - It OWNS its instances: a dense `List<T>` plus an entity index, swap-remove, delete on remove, on entity destroy and on scene teardown, OnDestroy first when started.
  - `ComponentType => typeof(T)` and `GetComponentAddress` returns the object, so the inspector, Add Component, `entity_inspect`/`component_set`, `component_schema` and `PrefabEntityRefs` see a behaviour as one more component.
  - It is a manager per type, not a list component like `ScriptComponent`. Each class therefore gets its own record and its own prefab op (deltas are per type id), and an absent type's records are preserved like any plugin's.
  - The cost: one instance per class per entity. The samples never put the same class twice on one entity.
- **Serialization:**
  - `[Behaviour(typeId, dataVersion, minReadDataVersion)]` is `IComptimeTypeApply`. It forces reflection (type, non-static fields, default constructor, AlwaysInclude) and emits `Serialize` over the public fields, reusing `[Serializable]`'s walker (keyed, declaration order).
  - `[Hidden]` hides a field and `[NotSerialized]` drops it. A private field is shown with `[InspectorField]`.
  - Field types: those `FieldPropertySource` handles (float, int, bool, String, Float3, Color, enum, `Ref<T>`, `EntityRef`, lists). That covers all 346 sample properties.
  - `ReadComponent` on an existing instance deletes it and makes a fresh one, so Simulate's restore (`SceneSimulation`, which restores into the same scene) and a re-read never keep runtime state.
  - Prefab overrides need no new code: the whole-blob diff covers them.
- **Registration:** explicit, in the Engine part's `Load`, as Spin's is:
  - `GameplayServices.AddBehaviour<Coin>(engine)` adds a `SceneModuleContribution` for `BehaviourManager<Coin>`, recorded and reversed by the existing scene contribution recorder;
  - the first one also contributes `BehaviourSystem`.
- **Networking:** `[Replicated]` (Net.Replication's attribute) fields travel through `BehaviourManager<T>`'s `IReplicatedStateSource`, found at compile time like the tick lists, with the kinds `ScriptReplication` sends (bool, int32, float, String, Float3, Color), each entry named by its field's hash. A received value is written into the field with no callback, as a script's is. An `EntityRef`, asset or other field the wire cannot carry, marked `[Replicated]`, is refused at compile time by `[Behaviour]`, in the cook's words.
- **Performance:** a Behaviour is per-entity convenience: a virtual call per instance per frame. A thousand of a kind belongs in a `SerializableComponentManager`, which stays the fast path.

## The Level tier

```beef
[Level("paperkid.block"), DisplayName("Block")]
class Block : Level
{
	public float TimeLimit = 120;
	public int32 Quota = 4;
	protected override void OnStart() { ... }
}
```

- **Base:** `abstract class Level : SceneSystem`, sim-only, `UpdateOrder -111` (the Level updated before behaviours).
- **Settings:** its settings block IS itself (`SettingsType => GetType()`, `SettingsInstance => this`, `SettingsId` = the level id, `SerializeSettings` emitted by `[Level]`), plus a base `Active` bool, false by default.
- **Naming the level:** `AddLevel<Block>(engine)` contributes it to every scene. A scene chooses it by setting `Active` in the inspector's scene settings, which already shows system blocks when nothing is selected. This replaces `SceneScriptSettings.Script`, and old scenes are unaffected.
- **Lifecycle:** OnStart (at `OnSceneStarted` when Active), OnUpdate, OnFixedUpdate and OnStop (`OnSceneStopped`).

## The Game tier

```beef
class SkyHopperGame : Game
{
	protected override void OnLaunch() { ... }
	protected override void OnUpdate(float dt) { ... }
	protected override void OnSceneActivated(Scene scene) { ... }
	protected override void OnExit() { ... }
}
```

- **Registering:** `GameplayServices.SetGame<SkyHopperGame>(engine)`, recorded by a new `EnginePluginServices.AddRunListener(IRunListener)` that is reversed on unload by unsubscribing and deleting. The listener is the engine's `GameRunner`.
- **Launching:** `GameInstance.LaunchGame()` runs the factory and holds the game as a session service (`AddForSession`). The hosts call it where they call `StartScript` today (player before the boot scene; PIE before the scene load), so both keep their current order (Q4).
- **What the game receives:**
  - `GameInstance` gets an `IGameHooks` interface (OnUpdate, OnSceneActivated) for that service;
  - `TickScript` ticks the hooks with the same delta rule (unscaled by `Run.TimeScale`);
  - `SetScene` and `PumpLoads` report scene switches;
  - `OnRunStopping` reaches `OnExit` through `IRunService`, before `RunSave` writes.
- **What it can reach:** `Instance` is the run (LoadScene, LoadSceneAsync, RequestExit, InstanceTimeScale, RealDeltaTime, Saves), with the services through `Run.Get<T>()`.
- **While both exist (phase 4):** a project with a native game and a `StartupScriptId` runs the native game and logs a warning. `GameScriptRunning` becomes "a game is running", of either kind.

## Native API replacements

| Need | Native | Status |
|---|---|---|
| Component handles (69) | `Scene.GetComponent<T>(entity)`: finds the manager by `ComponentType`, cached per type; T* or null | **new**, small |
| Scene facades (Animation, Prefabs, Physics, Render, Particles, Splines, scene.Audio) | call the managers: each facade verb is a one-line forward (e.g. `PrefabsFacade.Spawn` → `PrefabSpawnSystem.Spawn`) | exists; not carried |
| Input (65) | `Run.Get<InputFacade>()`: no script types in it | exists |
| Audio (65) | `Run.Get<AudioFacade>()` | exists |
| Save (46) | `Run.Get<SaveFacade>()` / `RunSave` | exists |
| Run (51) | `GameInstance` verbs | exists |
| Random (44) | `RunRandom` run service on `Sedulous.Core.Random`, moved out of `ScriptRandom` (`Sedulous.Script`) | **move** |
| GUI find, casts, ScreenStack | `GuiFacade.Root()`, `Node.FindElement`, `as Label`, `ScreenStack.Push/Pop` | exists |
| GUI events (78) | `Node.On(StringView name, delegate bool(Event))`: the name resolution (core or `.Named`) shared with the script `On`; over `AddEventListener` | **new**, thin |
| GUI Bind/OnCommand | `BindProperty(name, delegate Variant())`, `BindData`, `OnCommand(id, delegate)` already native; typed `BindText/BindNumber/BindBool` sugar; `Tween.OnFinished(delegate)` beside `OnFinishedScript` | sugar **new** (0 sample uses) |
| Net (35) | `NetFacade` overloads taking `delegate void(int32 player)`, `...(int32, double)`, `...(int32, StringView)` beside the `ScriptDelegate` ones | **new** |
| Http (0) | `HttpFacade.Get/Post/Request` with `delegate void(int32 status, StringView body, StringView error)` | **new** |
| Profiler overlay | `GameInstance.SetProfilerOverlay` | exists |

## Events and coroutines

- **Events:** the run bus stays (`EventBus`, `StringHash` + `Variant`). It gets a typed layer, `GameEvents.Emit<T>(IRun, T)` and `Listen<T>(delegate void(T))`, keyed by the type name's hash. A `Behaviour.Listen<T>` (and the Level's and Game's) unsubscribes itself on destroy or stop, which ends the script tier's subscribe-by-presence. The samples' ~60 event names become small structs in the game's code (Q5).
- **`Send`:** dropped as a string message. Native code reaches the target directly, two ways:
  - **direct:** a method call now (`Scene.GetSystem<BehaviourManager<Door>>()?.Get(e)?.Knock()`);
  - **queued:** the same call deferred, `Post(delegate void())` on the scene's `BehaviourSystem`, run at the end of the tick where scripts' deferred messages drain today. Typed events have both forms too: `Emit<T>` delivers now (`EventBus.Send`), `Post<T>` at the run's drain (`EventBus.Post`, drained by `GameInstance.DrainRunEvents` at the host's frame end, since events are run scoped and calls scene scoped). What either drain's deliveries queue waits for the next drain.
- **Contacts:** `BehaviourSystem` is an `IContactListener` of its own scene's `PhysicsSceneSystem` (a scene listener: a scene system cannot reach `PhysicsSubsystem`, whose list the script tier's bridge joins from the composition root). It queues and delivers at the end of the tick, as scripts do.
- **Coroutines:** none (the samples have zero `yield()`). Timers stay floats in fields. Revisit only if a phase 4 port needs one (Q7).

## pie_run probes

- `{"game": "Field"}` reads the running `Game`'s reflected instance fields, public or private.
- `{"level": "Field"}` reads the active Level (`"Block.Field"` when several are active).
- Behaviour probes keep `<Type>.<field>` on the entity, now private fields too (reflection opt-in from `[Behaviour]`).
- `script` and the script-behaviour path stay until phase 6.
- The work goes in `PieRunTool` and `IPieInstancePage` (`GetGameField`, `GetLevelField` returning a `Variant`, beside `GetScriptProperty`).

## Data and migration

- Phase 3 changes no data: native records are new type ids, and `ScriptComponent` records keep loading and running.
- Both kinds can sit on one entity while phase 4 ports a sample. Each sample's `Tools/` scripts then swap script refs and overrides for behaviour components through `entity_add_component`/`component_set`, which work on behaviours once commit 7 lands.
- `behavior_add`/`behavior_set` stay script-only until phase 6, which drops old records with a warning (D7).

## Testing

New `Sedulous.Engine.Gameplay.Tests`:
- **Lifecycle:** order and edges, sim gating, inactive freeze, destroy during an update, spawn picked up next tick.
- **Serialization:** round trips in text and binary; a prefab Modify op per type; `EntityRef` remap inside a behaviour; an absent type's records preserved.
- **Replication:** `[Replicated]` fields.
- **Contacts and events:** contacts both sides; typed events and their auto-unsubscribe.
- **Level:** `Active` gating and settings round trip.
- **Game:** launch, update, scene switch and exit order through a `GameInstance`, and `RunSave` written after `OnExit`.

These port the cases in `Engine.Script.Tests` (BehaviorLifecycle, Messaging, Contact, Property, Level, Replication, NetworkIdentity) and `Engine.GameScript.Tests` (GameScript, NetFacade, HttpFacadeRun).

Elsewhere:
- **Composition:** `Engine.Composition.Tests` covers `AddRunListener` and its reversal.
- **Editor:** `Editor.App.Tests` covers `FieldPropertySource`/`FieldJson` over a behaviour.
- **NativeSample:** gains a Behaviour, a Level and a Game, so `Integration.Plugins` covers them end to end.
- **ASan:** `asan-test.py` on each new or changed test project.

## Commits

1. **Scene:** `Scene.GetComponent<T>(entity)` by component type, cached. Tests in Scene.Tests.
2. **Gameplay:** the library, `Behaviour`, `[Behaviour]` (reflection plus the emitted Serialize), `BehaviourManager<T>` (ownership, serialization, address). Tests: round trips, prefab op, EntityRef remap, preserved records.
3. **Gameplay:** `BehaviourSystem` lifecycle and `GameplayServices.AddBehaviour<T>`, plus reflected tick lists. Tests: lifecycle, gating, freeze.
4. **Gameplay:** contacts to behaviours. Tests.
5. **Gameplay:** typed run events (direct `Emit` and queued `Post`), queued calls, and auto-unsubscribe. Tests.
6. **Gameplay:** `[Replicated]` behaviour fields. Tests.
7. **Editor:** a behaviour in the inspector, Add Component, `component_schema` and `entity_inspect`/`component_set`; NativeSample gains a Behaviour. Tests, McpGuide.
8. **Gameplay:** the `Level` tier and `AddLevel<T>`; NativeSample gains a Level. Tests.
9. **Run/GameInstance/Composition:** `IGameHooks`, `LaunchGame`, `EnginePluginServices.AddRunListener`, `GameRunner`, `SetGame<T>`. Tests.
10. **Player and Editor.Play:** launch the native game at the `StartScript` sites, with the both-present warning; NativeSample gains a Game. Tests in DefaultApp.Integration and Editor.Play.
11. **Run:** `RunRandom` service. **Net/Http:** delegate overloads. Tests.
12. **GUI:** `Node.On` with a delegate, typed Bind sugar, `Tween.OnFinished`. Tests in GUI.Tests.
13. **Editor MCP:** `pie_run` `game`/`level` probes and private behaviour fields. Tests, McpGuide.
14. **Docs:** `Documentation/Shipping/GameCode.md` (the tiers, the facade-to-manager table, the build loop), and the phase 3 boxes in `x2.md`.

## Open questions

- **Q1. Registering behaviours.** *Rec:* explicit `AddBehaviour<T>()` in `Load`: compile-checked, generic managers, at most ~15 lines per sample. The alternative is a reflection scan for `[Behaviour]` types.
- **Q2. Storage.** *Rec:* one manager per behaviour type: per-type records, prefab ops and Add Component entries. The alternative is a `ScriptComponent`-shaped list on one component, which keeps several of a class on one entity but makes every override a whole-list diff.
- **Q3. How a scene names its level.** *Rec:* each Level's own settings block with `Active`. The alternative is one engine "level" picker naming a type id, with the level's fields nested.
- **Q4. When the Game launches.** *Rec:* an explicit `LaunchGame()` where `StartScript` is called today, because PIE starts the run after loading the scene and the player before. The alternative is launching from `OnRunStarted` and reordering PIE's `Start()`.
- **Q5. Events.** *Rec:* typed struct events, so a phase 4 typo fails to compile. The alternative is string names with `Variant` payloads, closer to a 1:1 port.
- **Q6. Deferred `Send`.** *Rec:* drop it for direct calls. **Ruling:** both direct and queued (see Events).
- **Q7. Coroutines.** *Rec:* none in phase 3.
- **Q8. Scene facades.** *Rec:* not carried; native code calls the managers. The alternative is moving them into Gameplay as convenience.
- **Q9. Spelling.** `Behaviour` as D3 writes it, though the script code says `ScriptBehavior`. *Rec:* `Behaviour`.

## Rulings (2026-11-07)

Q1-Q5 and Q7-Q9 as recommended. Q6: `Send` goes, but a call or an event can be direct or queued.

## To discuss

- **Destroy during the fixed step.** Destroying an entity during `OnFixedUpdate` happens immediately, while during `OnUpdate` it waits for the end of the frame (`Scene.Update` sets `mIsUpdating`; `Scene.FixedUpdate` does not). A test shows the immediate case is safe, so the scene's fixed step was left alone. Making both wait would be a change to every scene.
- **Active toggles.** Turning an entity off calls its behaviours' `OnDisable`, and turning it back on calls `OnEnable`, but not `OnStart` again. Scripts got no call when an entity was switched on or off.
