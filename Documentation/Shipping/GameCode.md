# Game code

How a game's own code is written in Beef: where it lives, the three tiers it is written in, and
how it reaches the engine. It is compiled with the engine into the project's own editor and
player, so the compiler checks every call; the engine's sources are the reference for the
signatures named here.

## Where it lives

A project's code is its `Code/` folder, a Beef workspace: `Code/BeefSpace.toml`, the game's
package (`Code/Plugin.xml`), and its parts. The Engine part, `Code/<Game>`, is the game itself,
loaded by every host; `Code/<Game>.Editor`, `.Pipeline` and `.Tooling` are optional parts for the
editor and the tools. Project > Add Native Code (`plugin_scaffold`) writes it. The build writes
the rest, which git ignores: the entry points (`<Game>Editor`, `<Game>Player`, `<Game>PlayerWeb`,
`<Game>Tools`) under `Code/.generated`, and `Code/BeefConfig.toml`, which points Beef at the
engine SDK.

The Engine part's `Load` is the one registration point: everything the game adds is registered
there, through the engine's service, and taken out again when the project closes.

```beef
public override void Load(PluginContext context)
{
	let engine = context.Find<EnginePluginServices>();
	if (engine == null)
		return; // a host without the engine, such as the cook
	GameplayServices.AddBehaviour<Bob>(engine);
	GameplayServices.AddLevel<Arena>(engine);
	GameplayServices.SetGame<NativeSampleGame>(engine);
}
```

The scaffolded part depends on `Sedulous.Core`, `Sedulous.Runtime`, `Sedulous.Scene`,
`Sedulous.Engine.Composition` and `Sedulous.Engine.Gameplay`, enough for the tiers below; add
what else the code uses to its `BeefProj.toml`. Its `Load` finds the engine's service as above,
and registers a starter behaviour, `Rotator` (`src/Rotator.bf`, which turns its entity while the
scene simulates), so a new game builds a tier of its own at once: rename it, change it, or take
it and its `AddBehaviour` line out.

The loop: edit, Project > Build Project, then Project > Open With This Build, which starts the
project's own editor (the stock editor does not run a game's code) and closes this one. An agent
uses `project_build` and `editor_relaunch`: McpGuide.md, "Writing game code".

## Behaviour: code on an entity

A behaviour is a class whose instance rides one entity. Its public fields are its data: saved
with the scene or prefab, shown in the inspector, and read and set by the tools. Its private
fields are runtime state, neither saved nor shown (`[InspectorField]` shows one in the inspector
alone; `[Hidden]` hides a public one, `[NotSerialized]` keeps it out of the record).

```beef
[Behaviour("nativesample.Bob")]
[DisplayName("Bob"), Category("Native Sample")]
class Bob : Behaviour
{
	[Description("How far above and below its start it goes.")]
	public float Height = 0.25f;
	public float Speed = 0.5f;

	private float mBaseY = 0.0f;
	private float mPhase = 0.0f;

	protected override void OnStart()
	{
		mBaseY = Scene.GetLocalTransform(Entity).Position.Y;
	}

	protected override void OnUpdate(float dt)
	{
		mPhase += Speed * dt;
		mPhase -= Math.Floor(mPhase);
		var local = Scene.GetLocalTransform(Entity);
		local.Position.Y = mBaseY + Height * Math.Sin(mPhase * TwoPi);
		Scene.SetLocalTransform(Entity, local);
	}
}
```

- `[Behaviour("<id>")]` is the record's type on disk, stated so a rename keeps old scenes; it
  takes a data version and a minimum read version as components do. The public fields, base
  first in declaration order, are the record: field order is the binary format. `Enabled`, the
  base's own field, leads it.
- Field types: `float`, `int32`, `bool`, `String` (owned: `new .() ~ delete _`), `Float3`,
  `Color`, enums, `EntityRef` (an entity of the scene; `Scene.FindEntity(ref.Id)`) and `Ref<T>`
  (an asset; its `Id` is the guid the facades take; `Get` is the loaded resource once the scene
  is resolved, null for an id that names nothing).
- `GameplayServices.AddBehaviour<T>(engine)` puts `T`'s manager in every scene (and in Add
  Component); one instance per class per entity. The base has `Scene`, `Entity`, `Run`,
  `Random`, `Enabled` and `IsActive`.

**Lifecycle.** Nothing runs unless the scene simulates (a Game tab, the player, the scene page's
Simulate). Each frame, at update order -110, before the navigation crowd and animation:

1. the edges, per instance: `OnEnable` when it became active, `OnStart` the first time,
   `OnDisable` when it stopped being active;
2. `OnUpdate(dt)` for the started, active instances, type by type in registration order;
3. the end of the tick: queued contacts, then queued calls.

`OnFixedUpdate(dt)` runs on the fixed step physics runs on, before the frame's update;
`OnLateUpdate(dt)` after every system's update (a camera). `OnDestroy` runs before the instance
is deleted, if it started, after `OnDisable`; it still has its scene and its entity's
components. A class joins a tick only if it overrides that method.

A disabled instance, or one on an inactive entity, freezes: `OnDisable` on the edge, then
nothing until `OnEnable` (`OnStart` only if it never started). One added during a frame starts
on the next. The manager owns every instance and deletes it when it is removed, its entity
destroyed or the scene torn down. There is no fault isolation: a crash takes the process down.

## Level: code for a scene

A level is a class with one instance per scene, a scene system whose public fields are the
scene's settings block for it (the inspector shows it when no entity is selected).

```beef
[Level("nativesample.arena")]
[DisplayName("Arena"), Category("Native Sample")]
class Arena : Level
{
	public float TimeLimit = 60.0f;
	private float mRemaining = 0.0f;

	protected override void OnStart() { mRemaining = TimeLimit; }

	protected override void OnUpdate(float dt)
	{
		if (mRemaining <= 0.0f)
			return;
		mRemaining -= dt;
		if (mRemaining <= 0.0f)
			Emit(ArenaTimeUp(TimeLimit)); // a struct event; the game listens for it
	}
}
```

- `GameplayServices.AddLevel<T>(engine)` puts it in every scene, inactive. A scene runs it by
  turning on its `Active`, saved first in its block, so one game may have several levels and
  each scene runs the ones it turned on.
- `OnStart` at its first simulated tick while active, `OnUpdate(dt)`, `OnFixedStep(dt)` and
  `OnStop` (`Active` turned off, or the scene stopped). It updates at -111, before the
  behaviours. Turning `Active` off and on again stops it and starts it again, its fields as they
  were left.
- `OnUpdate(ScenePhase, float)`, `OnFixedUpdate` and `OnSceneStopped` drive the level; overriding
  them is a compile error, as is a class without `[Level]`.

## Game: code for the run

The code above the scenes, one per build: boot, the flow between levels, what lasts across them.

```beef
[Game]
class NativeSampleGame : Game
{
	private int mRoundsUp = 0;

	protected override void OnLaunch()
	{
		Listen<ArenaTimeUp>(new [=this] (evt) => { mRoundsUp++; });
	}
}
```

- `GameplayServices.SetGame<T>(engine)` registers it; a second one is refused, and a class
  without `[Game]` is a compile error (`[Game]` reflects its fields for the editor's play tools).
- Each session makes a fresh one and deletes it as the session stops. The player launches it
  before its boot scene; a Game tab launches it before loading its scene. Either way it sees
  `OnLaunch`, then `OnSceneActivated` with that first scene, then `OnSceneActivated` again for
  each scene that becomes current. `OnUpdate(dt)` runs every frame with a delta the run's time
  scale does not touch, so a game that pauses its scenes keeps its own timers. `OnExit` runs as
  the session stops, before the run writes its save.
- `Instance` is the run (`GameInstance`): `LoadScene(guid)`, `LoadSceneAsync(guid)`,
  `RequestExit()`, `InstanceTimeScale` (nought pauses the scenes), `RealDeltaTime`, and its
  services through `Instance.Get<T>()`.
- A project that also names a startup script runs the native game; a warning says the script is
  not started. The scene page's Simulate launches no game.

## Struct components: the fast path

A behaviour costs a virtual call per instance per frame. Many of a kind (a thousand coins, a
crowd of spinners) belong in a struct component with a manager that loops over all of them:
`[SerializableComponent("<id>")]` on a struct, and a `SerializableComponentManager<T>` that
does the work in its `OnUpdate`. NativeSample's `Spin` is the pattern: `SpinComponent`, its
`SpinManager` (`IsSimulationOnly`, a `ForEach` over the components in `OnUpdate`), registered as
a `SceneModuleContribution` with `engine.AddSceneManager`. Choose a behaviour for per-entity
logic with state and callbacks; a struct component for data many entities share a loop over.

## Reaching things

- **Components:** `Scene.GetComponent<T>(entity)` (or `Get<T>()` in a behaviour, for its own
  entity) gives the live `T*`, or null. It is transient: ask again after anything adds or
  removes a `T`. `Get<B>()` gives a behaviour of this entity, or null.
- **Scene systems:** `Scene.GetSystem<T>()`, null when the scene has none.
- **Run services:** from a behaviour or level, `RunServices.Get<T>(Run)`; from the game,
  `Instance.Get<T>()`. Null outside a run. `InputFacade` (`WasPressed`, `IsDown`, `Value`,
  `Rumble`, `PushSet`), `AudioFacade` (`PlayOneShot`, `PlayMusic`, the bus volumes), `SaveFacade`
  (`GetInt`, `SetInt`, `Flush`, ...), `GuiFacade`, `NetFacade`, `HttpFacade`, and `GameInstance`
  itself. `Random` on all three tiers is the run's `RunRandom` (`Range`, `IntRange`, `Bool`),
  back to its default seed as each session stops.

The scripts' scene facades are one-line forwards to the managers; native code calls the
managers:

| Script | Native |
|---|---|
| `scene.Prefabs.Spawn(prefab, at)` | `Scene.GetSystem<PrefabSpawnSystem>().Spawn(prefab, position, rotation, parent)` |
| `scene.Physics.RayCast`, `ApplyImpulse`, `SetVelocity`, `SetForce` | the same on `Scene.GetSystem<PhysicsSceneSystem>()` |
| `scene.Physics.MoveCharacter(e, vx, vz)`, `JumpCharacter` | `Scene.GetComponent<CharacterComponent>(e).Move(vx, vz)`, `.Jump(speed)` |
| `scene.Animation.Play(e)`, `Stop`, `SetClip` | the same on `SkeletalAnimationComponentManager` |
| `scene.Animation.SetFloat(e, name, v)`, `SetBool`, `SetTrigger` | the same on `AnimationGraphComponentManager` |
| `scene.Audio.Play(e)`, `Stop` | the same on `AudioSceneSystem` |
| `scene.Particles.Play(e)`, `Stop`, `Restart` | the same on `ParticleEffectComponentManager` |
| `Audio.PlayOneShot(clip)` | `AudioFacade.PlayOneShot(clip)` |
| `Run.LoadScene(id)`, `Run.TimeScale` | `GameInstance.LoadScene(id)`, `InstanceTimeScale` |

`LoadScene` replaces and destroys the current scene. Asked for from a scene's own code (a
behaviour's or a level's `OnUpdate`, `OnFixedUpdate`/`OnFixedStep`, a queued call or contact at the
end of the behaviours' tick, or a behaviour's or a level's `Listen` handler, wherever the event is
delivered from) it starts the load and returns true, and the swap happens at the host's next
`PumpLoads`, after the frame's scene update, where finished loads activate: the scene that asked
is not destroyed under its own code, and the game hears `OnSceneActivated` then. Until then
`CurrentScene` is still the old scene. From the game's own code (its hooks and its `Listen`
handlers) the load is immediate, and the new scene is current when the call returns.

## Events and queued calls

An event is a struct type, its value the payload; a misspelt event fails to compile.

- `Emit(evt)` delivers now, inside the caller. `Post(evt)` queues it for the run's drain at the
  end of the host's frame (`GameInstance.DrainRunEvents`).
- `Listen<T>(handler)` hears every `T` emitted or posted in the run. Behaviours, levels and the
  game each have it, and each ends its subscriptions itself: a behaviour as it is released, a
  level as it stops, the game at its exit. A behaviour hears only while it ticks (started,
  enabled, its entity active), a level while it runs. Outside a run it returns false.
  `GameEvents.Emit/Post/Listen` take the run explicitly, for code outside the tiers.
- `Post(call)` on a behaviour or level queues a call for the end of its scene's next tick
  (the scene's behaviour system runs it, so a game that registers no behaviour cannot), dropped
  if the behaviour is released, or the level stops, first. To call another entity's
  code now, call it: `Scene.GetSystem<BehaviourManager<Door>>()?.Get(e)?.Knock()`.
- What a drain's deliveries queue waits for the next drain. Delegates passed to `Listen` and
  `Post` are the engine's from then on.

**Contacts:** a behaviour overriding `OnContactBegin`/`OnContactEnd(other, point, normal,
speed)` or `OnTriggerEnter`/`OnTriggerExit(other)` hears its entity's physics contacts, the far
side as `other`. Both sides hear them, queued from the physics step and delivered at the end of
the next tick.

## Networking

A behaviour's field marked `[Replicated]` (`Sedulous.Net.Replication`) travels with a networked
entity. The kinds are `bool`, `int32`, `float`, `String`, `Float3` and `Color`; any other (an
`EntityRef`, an asset, a list) is refused at compile time, naming the field. A received value
is written straight into the field with no call, so a behaviour that reacts to a change compares
with what it last saw.

`NetFacade` is the run's networking (`StartServer`, `Connect`, `Disconnect`, `IsServer`,
`IsClient`, `LocalPlayer`, `Rpc`, `RpcNumber`, `RpcText`, `Spawn`, `IsMine`). Native code
receives with delegates: `On(name, delegate void(int32 player))`, `OnNumber(name, delegate
void(int32 player, double value))`, `OnText(name, delegate void(int32 player, StringView
text))`, `OnJoin`, `OnLeave`. The facade owns them; `Off(name)`, `OffJoin` and `OffLeave` delete
them, a later registration of the name replaces them, and the session's stop drops them all.
What goes mid-session (a level's scene unloaded, a behaviour destroyed) calls `Off` for what it
registered. `HttpFacade.Get`, `Post` and `Request` take `delegate void(int32 status, StringView
body, StringView error)`, deleted after the answer, on `Cancel`, or as the session stops.

## GUI

`RunServices.Get<GuiFacade>(Run).Root()` is the run's GUI root node; find a widget with
`FindElement(id)` and cast it (`as Label`). Every delegate passed below is the GUI's from then on.

- `node.On("click", new (e) => { ...; return true; })` calls the handler on an event by name
  (returning true takes the event), and answers a token for `node.Off(token)`.
- `BindText(property, delegate void(String outText))`, `BindNumber(property, delegate
  double())` and `BindBool(property, delegate bool())` keep a property following a value;
  `BindProperty` binds any.
- `node.Animate(property, to, seconds)` answers a tween; `.OnFinished(delegate void())` runs at
  its end. Release the tween with `ReleaseRef()` when done shaping it.

## Rules that bite

- **No early return in a destructor.** A `return` in `~this` skips the fields' `~ delete _`, and
  they leak. Use an `if` block.
- **Constructors and field initialisers must not touch the scene or the run.** A default
  instance is also where the inspector reads defaults, and it has neither.
- **A read replaces the instance.** Loading a record into an existing behaviour (Simulate's
  restore, a prefab override, a re-read) deletes the old instance and makes a fresh one, so
  runtime state never survives it. Do not keep a behaviour across one.
- **Enums need no `[Reflect]`.** `[Behaviour]`, `[Level]`, `[Game]` and `[SerializableComponent]`
  register the cases of the enums their fields hold, so the tools name them (`entity_inspect`,
  `component_set` by name, the inspector's dropdown, pie_run's probes). An enum held only by
  something else (a private field of a base class, a plain `[Component]`) still needs it.
- **A destroy waits for the end of the frame.** `Scene.DestroyEntity` from `OnUpdate` or
  `OnFixedUpdate` takes effect as the frame's update ends: until then the entity is valid and its
  behaviours still get the rest of the frame (the remaining fixed steps, `OnUpdate`,
  `OnLateUpdate`). Check a flag of your own, not `IsValid`, to stop acting on it.
- **Turning an entity off and on** runs `OnDisable` and `OnEnable`, not `OnStart` again.
