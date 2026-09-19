using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Input;
using Sedulous.Messaging;
using Sedulous.Net.Manager;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.GameInstance;

/// ONE running game, as an object.
///
/// It owns a scene group, that group's event bus, this run's input runtime, its networking,
/// and its time scale. A player owns one; an editor owns an array of them, which is what
/// makes several games in flight at once, and a headless dedicated server beside them,
/// possible at all.
///
/// The scene is CREATED BY THE CALLER and paired in, and the app keeps its own policy: what
/// to load, and what to do to a scene once it is live. What lives here is the orchestration
/// both of those would otherwise hand roll identically.
/// TO A SCRIPT it is `Run`: the run's tier above the scenes, reached as a per run service,
/// so the instance a script's calls land on is the one whose runtime ran the script and
/// never another's. Its verbs are the level loads, the exit, the time scale and the run
/// bus, which is what a `Game` orchestrator drives boot and level flow with:
/// `let t = Run.LoadSceneAsync(id); while (!Run.LoadComplete(t)) yield();`.
[Scriptable, ScriptService, DisplayName("Run")]
class GameInstance
{
	/// What the APP does to a scene the moment one of its tracked loads completes: find a
	/// camera, start it, enable simulation. Pairing it as the current scene is the instance's
	/// own bookkeeping and happens first.
	public typealias SceneActivationPolicy = delegate void(Scene scene);

	/// One tracked load and the ticket it answers to.
	private struct TrackedLoad
	{
		public int32 Ticket;
		public SceneLoadHandle Handle;
	}

	/// OWNED: the run scoped bus, injected into every scene this instance creates or adopts,
	/// so a scene's events and the run's are ONE object and nothing has to relay between
	/// them.
	private EventBus mRunEvents = new .() ~ delete _;

	/// OWNED: this run's scenes, ticked once registered with the scene subsystem.
	private SceneManager mSceneManager = new .() ~ delete _;
	/// BORROWED: the current scene, which the group owns.
	private Scene mScene = null;

	private bool mHeadless = false;

	/// OWNED: this run's networking.
	private NetworkController mNetwork = new .() ~ delete _;

	/// OWNED: this run's action state, so one instance's input never reaches another's.
	private ActionRuntime mInputRuntime = new .() ~ delete _;
	/// BORROWED: the viewport or the shell's devices. Null means no input at all.
	private IInputSourceProvider mInputSource = null;

	/// The loads in flight, keyed by ticket. An entry lives only while its load is IN FLIGHT
	/// or has FAILED: a successful activation RETIRES its entry, and a retired ticket then
	/// reads terminal safe through the unknown ticket fallback, which is exactly the answer
	/// after activation anyway. A failed one lingers so the failure stays truthful, and
	/// failures are exceptional, so this stays bounded across level changes.
	private List<TrackedLoad> mLoads = new .() ~ delete _;
	/// Only ever grows, so a ticket never aliases a retired one.
	private int32 mNextTicket = 0;

	private SceneActivationPolicy mActivationPolicy = null ~ delete _;

	// ---- the Game tier ----

	/// What the APP does to turn a scene id into a load on this instance: the content
	/// database lookup and the prefab resolver are its. TAKES OWNERSHIP of the delegate.
	public typealias SceneLoader = delegate SceneLoadHandle(Guid sceneId);
	/// Where `Run.RequestExit` goes: the host's loop, or the editor's Game tab session.
	/// TAKES OWNERSHIP of the delegate.
	public typealias ExitRequest = delegate void(int32 code);

	/// OWNED: this run's script host, the gameplay context the game script AND this
	/// instance's scenes' behaviours share. The subsystem wires it like its own; the
	/// instance installs itself on it as the `Run` service.
	private ScriptRunHost mRunHost = new .() ~ delete _;
	/// The orchestrator: an instance of the game script's class. Null when no script runs.
	private ScriptObject mGame = null;
	/// BORROWED: the resource manager owns the product.
	private ScriptClass mGameClass = null;
	private SceneLoader mSceneLoader = null ~ delete _;
	private ExitRequest mExitRequest = null ~ delete _;
	private Dictionary<String, uint32> mGameSubscriptions = new .() ~ DeleteDictionaryAndKeys!(_);
	private List<delegate void(Variant)> mGameCallbacks = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mGameHandlerNames = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		// Every scene this run creates BORROWS the run bus. Setting it on the GROUP means the
		// injection happens as a scene is created, before its systems bind, rather than after.
		mSceneManager.SetSceneEventBus(mRunEvents);
	}

	public ~this()
	{
		// The game script, then the scenes, whose behaviours live on the host, then the
		// host itself with the fields.
		StopScript();
		ClearScenes();
		mRunHost.Teardown();
	}

	/// Pairs a scene in as the current one.
	public void SetScene(Scene scene)
	{
		mScene = scene;
		// Replication follows the current scene across loads.
		mNetwork.SetReplicatedScene(scene);

		// An ADOPTED scene shares this run's bus too.
		if (scene != null)
			scene.SetEventBus(mRunEvents);
	}

	public Scene GetScene() => mScene;
	/// The run's live scene, null until one is.
	[Scriptable]
	public Scene CurrentScene => mScene;

	/// This instance has a live current scene, which is what a caller waits on rather than
	/// assuming one exists at launch.
	[Scriptable]
	public bool SceneReady => mScene != null;

	/// Simulated and scripted, but NOT rendered by the host: no camera and no swapchain
	/// needed, which is what an in editor dedicated server is.
	public bool Headless
	{
		get => mHeadless;
		set => mHeadless = value;
	}

	/// This run's term in the time model: the delta a scene sees is the host's, times the
	/// context's scale, times THIS, times the scene's own. One by default, so a single
	/// instance collapses to the model without it. It is the scene GROUP's scale, so nought
	/// pauses the run's scenes, behaviours, physics and timers, while the Game orchestrator,
	/// which runs on the run's own clock, keeps going and can resume.
	[Scriptable, ScriptName("TimeScale")]
	public float InstanceTimeScale
	{
		get => mSceneManager.TimeScale;
		set => mSceneManager.TimeScale = value;
	}

	/// This run's scene group.
	public SceneManager Scenes => mSceneManager;

	/// This run's ONE event bus. A subscriber here sees what any of the run's scenes emitted,
	/// because they are the same bus rather than two joined by plumbing.
	public EventBus RunEvents => mRunEvents;

	/// Delivers this frame's queued events. Cascade bounded like a scene's, and safe with
	/// nothing subscribed.
	/// Held while debug paused, so what was published during the pause is delivered after
	/// it rather than into a held run or dropped.
	public void DrainRunEvents()
	{
		if (!mRunHost.IsDebugPaused)
			mRunEvents.Drain();
	}

	// ==================== Scenes ====================

	/// Creates a scene in this instance's group.
	///
	/// `activate` false leaves it out of the ticking and drawing sets, which is what an async
	/// load wants: a scene being streamed must not be seen until it is whole.
	public Scene CreateScene(StringView name, bool activate = true)
	{
		// The run bus is already injected by the group before assembly, so the scene's events
		// and the run's are one object by the time anything binds to either.
		let scene = mSceneManager.CreateScene(name, activate);
		AdoptScripting(scene);
		return scene;
	}

	/// Points a scene's behaviours at THIS run's host, after the subsystem pointed them at
	/// its default one during assembly: one gameplay context per run.
	private void AdoptScripting(Scene scene)
	{
		if (scene == null)
			return;
		if (let scripts = scene.GetSystem<ScriptSceneSystem>())
			scripts.SetRunHost(mRunHost);
	}

	/// Destroys a scene in this instance's group.
	///
	/// Any tracked load whose pending target IS this scene is dropped FIRST: the handle holds
	/// a borrowed scene, and pumping could otherwise activate one that had just been freed. A
	/// dropped ticket then reads terminal safe through the unknown ticket fallback.
	public void DestroyScene(Scene scene)
	{
		for (int i = mLoads.Count - 1; i >= 0; i--)
		{
			if (mLoads[i].Handle.Scene === scene)
				mLoads.RemoveAt(i);
		}

		// If this IS the replicated scene, the endpoint is unwired before it dies, so a later
		// connect never finds a dead scene and the live one stops replicating it.
		if (scene === mScene)
			SetScene(null);

		mSceneManager.DestroyScene(scene);
	}

	/// Tears down ALL of this instance's scenes for a stop that KEEPS the instance, which is
	/// what an editor does between plays.
	///
	/// Every load in flight is dropped first, for the reason above, then the current scene is
	/// cleared and the group destroyed.
	public void ClearScenes()
	{
		mLoads.Clear();
		SetScene(null);
		mSceneManager.Clear();

		// The group's time scale is RUN scoped, and the group survives a stop, so a game
		// paused at the stop must not leave the next play frozen.
		mSceneManager.TimeScale = 1.0f;
	}

	/// Loads a cooked scene into this group and resolves its resources SYNCHRONOUSLY.
	///
	/// The scene comes back active and fully resolved but NOT started: what happens to it
	/// next is the app's policy. Null if the load itself failed.
	public Scene LoadScene(Instance sceneInstance, ResourceManager resources,
		ScenePrefabs.PayloadResolver prefabProvider)
	{
		let scene = CreateScene(sceneInstance.Name);
		if ((scene == null) || (SceneStorage.LoadScene(sceneInstance, scene) case .Err))
		{
			if (scene != null)
				DestroyScene(scene);
			return null;
		}

		SceneResolve.ResolveSceneResources(scene, resources);

		if (scene.PendingPrefabInstanceCount > 0)
		{
			ScenePrefabs.ResolveScenePrefabs(scene, prefabProvider);
			// And bind what the prefabs brought with them.
			SceneResolve.ResolveSceneResources(scene, resources);
		}

		return scene;
	}

	/// Loads a cooked scene INACTIVE and puts its resource binds on the workers.
	///
	/// The handle is polled for progress, which is what a loading screen reads, and the scene
	/// is activated once it completes. It never ticks or draws while it loads.
	public SceneLoadHandle LoadSceneAsync(Instance sceneInstance, ResourceManager resources,
		ScenePrefabs.PayloadResolver prefabProvider)
	{
		var handle = SceneLoadHandle();
		handle.Resources = resources;

		let scene = CreateScene(sceneInstance.Name, false);
		if ((scene == null) || (SceneStorage.LoadScene(sceneInstance, scene) case .Err))
		{
			if (scene != null)
				DestroyScene(scene);

			handle.Failed = true;
			return handle;
		}

		{
			// Under the scope the scene's references bind through the async path, so the whole
			// set decodes on workers rather than one blocking build after another.
			let scope_ = AsyncBindScope(resources);
			defer scope_.Dispose();
			SceneResolve.ResolveSceneResources(scene, resources);
		}

		if (scene.PendingPrefabInstanceCount > 0)
		{
			// The spawn itself binds nothing, so it runs outside the scope and what it brought
			// binds inside a second one.
			ScenePrefabs.ResolveScenePrefabs(scene, prefabProvider);

			let scope_ = AsyncBindScope(resources);
			defer scope_.Dispose();
			SceneResolve.ResolveSceneResources(scene, resources);
		}

		handle.Scene = scene;
		// Snapshotted AFTER every bind has been issued, or the denominator would be a number
		// the load had already passed.
		handle.Total = resources.PendingCount;
		return handle;
	}

	/// Activates a COMPLETED load: into the ticking and drawing sets.
	///
	/// Null when the handle failed or has not finished. The caller then runs the same policy
	/// the synchronous path gets.
	public Scene ActivateLoadedScene(ref SceneLoadHandle handle)
	{
		if (handle.Failed || (handle.Scene == null) || !handle.IsComplete)
			return null;

		mSceneManager.ActivateScene(handle.Scene);
		return handle.Scene;
	}

	// ==================== Tracked loads ====================

	/// What the APP does to a scene once one of its tracked loads completes. TAKES OWNERSHIP
	/// of the delegate.
	public void SetSceneActivationPolicy(SceneActivationPolicy policy)
	{
		delete mActivationPolicy;
		mActivationPolicy = policy;
	}

	/// Registers a load in flight under a fresh ticket.
	///
	/// The ticket is one based, so nought is never issued and doubles as "did not start".
	public int32 TrackLoad(SceneLoadHandle handle)
	{
		mNextTicket++;

		var tracked = TrackedLoad();
		tracked.Ticket = mNextTicket;
		tracked.Handle = handle;
		mLoads.Add(tracked);

		return mNextTicket;
	}

	/// Drives the tracked loads: any whose resources finished is activated, paired in, and
	/// handed to the app's policy, EXACTLY ONCE. Cheap with nothing in flight.
	public void PumpLoads()
	{
		// An index walk rather than a range one: a successful activation retires its entry in
		// place, so the list shrinks under the loop. A failed or still streaming entry stays
		// and the walk steps past it.
		var i = 0;
		while (i < mLoads.Count)
		{
			var load = mLoads[i];
			if (load.Handle.Failed || !load.Handle.IsComplete)
			{
				i++;
				continue;
			}

			let activated = ActivateLoadedScene(ref load.Handle);
			if (activated == null)
			{
				// Complete but unactivatable, which nothing produces today: terminal.
				load.Handle.Failed = true;
				mLoads[i] = load;
				i++;
				continue;
			}

			// The instance's own bookkeeping first, then the app's policy.
			SetScene(activated);
			if (mActivationPolicy != null)
				mActivationPolicy(activated);

			// Retired: the ticket now reads terminal safe through the fallback.
			mLoads.RemoveAt(i);
		}
	}

	/// An unknown or expired ticket reads complete rather than pending, so a caller polling
	/// one in a loop can never hang on it.
	[Scriptable]
	public float LoadProgress(int32 ticket)
	{
		for (let load in mLoads)
		{
			if (load.Ticket == ticket)
				return load.Handle.Progress;
		}
		return 1.0f;
	}

	/// True once terminal, whether the load landed or failed. A retained entry is terminal
	/// only when it FAILED, every successful one having been retired.
	[Scriptable]
	public bool LoadComplete(int32 ticket)
	{
		for (let load in mLoads)
		{
			if (load.Ticket == ticket)
				return load.Handle.Failed;
		}
		return true;
	}

	[Scriptable]
	public bool LoadFailed(int32 ticket)
	{
		for (let load in mLoads)
		{
			if (load.Ticket == ticket)
				return load.Handle.Failed;
		}
		return false;
	}

	// ==================== The Game tier ====================

	/// This run's script host. The subsystem wires it; the instance's scenes' behaviours
	/// and its game script run on it.
	public ScriptRunHost RunHost => mRunHost;

	public void SetSceneLoader(SceneLoader loader)
	{
		delete mSceneLoader;
		mSceneLoader = loader;
	}

	public void SetExitRequest(ExitRequest request)
	{
		delete mExitRequest;
		mExitRequest = request;
	}

	/// Starts a level load by id: the ticket a script polls, or nought when the load could
	/// not start, a wrong id or no loader. The scene activates through the app's policy once
	/// its resources land, on the pump.
	[Scriptable]
	public int32 LoadSceneAsync(Guid sceneId)
	{
		if ((mSceneLoader == null) || (sceneId == Guid()))
			return 0;
		var handle = mSceneLoader(sceneId);
		if (handle.Failed || (handle.Scene == null))
			return 0;
		return TrackLoad(handle);
	}

	/// Loads a level and activates it now, the app's policy applied. False when it could not.
	[Scriptable]
	public bool LoadScene(Guid sceneId)
	{
		let ticket = LoadSceneAsync(sceneId);
		if (ticket == 0)
			return false;
		// The load's resources bind on workers; pumping them out here makes the call the
		// synchronous convenience it claims to be.
		for (let load in mLoads)
		{
			if (load.Ticket != ticket)
				continue;
			let handle = load.Handle;
			while (!handle.IsComplete)
				handle.Resources.Pump(0.010);
		}
		PumpLoads();
		return !LoadFailed(ticket);
	}

	/// Ends the run with an exit code: the standalone host stops its loop, an editor stops
	/// the Game tab's session. Nothing wired is a no-op.
	[Scriptable]
	public void RequestExit(int32 code = 0)
	{
		if (mExitRequest != null)
			mExitRequest(code);
	}

	/// Publishes on the run bus, which every scene of this run shares: the Game orchestrator
	/// and every behaviour declaring `on<Event>` hear it when the bus drains.
	[Scriptable]
	public void Emit(StringView eventName) => mRunEvents.Publish(StringHash(eventName), Variant());
	[Scriptable]
	public void Emit(StringView eventName, float payload) => mRunEvents.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, int32 payload) => mRunEvents.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, bool payload) => mRunEvents.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, StringView payload) => mRunEvents.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, EntityHandle payload) => mRunEvents.Publish(StringHash(eventName), ScriptPayloads.Of(payload));

	/// Whether a game script is running: instantiated and not faulted.
	public bool ScriptRunning => mGame != null;

	/// A step debugger over this run: its behaviours and its game script. The configurator
	/// applies the breakpoints and takes the pointer; TAKES OWNERSHIP of the delegate.
	public void RequestDebugger(delegate void(IScriptDebugger debugger) configurator) => mRunHost.RequestDebugger(configurator);
	public IScriptDebugger Debugger => mRunHost.Debugger;
	public bool IsDebugPaused => mRunHost.IsDebugPaused;

	/// Compiles and launches the game script: the class's constructor, then `launch()` when
	/// it has one; `update(dt)` each tick and `exit()` at the stop, all optional, its
	/// `on<Event>` handlers subscribed to the run bus. False when the class did not load or
	/// instantiate, logged. A second start stops the first.
	public bool StartScript(ScriptClass scriptClass)
	{
		StopScript();
		if (scriptClass == null)
			return false;
		let game = mRunHost.Instantiate(scriptClass);
		if (game == null)
		{
			GlobalLog(.Error, scope $"Run: the game script '{scriptClass.ClassName}' did not instantiate");
			return false;
		}
		mGame = game;
		mGameClass = scriptClass;
		// The context knows its run from here on: a call in the script lands on THIS instance.
		mRunHost.Runtime.SetService(this);
		SubscribeGameHandlers(scriptClass);
		InvokeGame("launch", default);
		GlobalLog(.Information, scope $"Run: game script '{scriptClass.ClassName}' launched");
		return mGame != null;
	}

	/// `exit()`, then release. Idempotent; the fault path lands here too.
	public void StopScript()
	{
		ClearGameSubscriptions();
		if (mGame == null)
			return;
		InvokeGame("exit", default);
		if ((mGame != null) && (mRunHost.Runtime != null))
		{
			mRunHost.Runtime.CancelCoroutinesFor(mGame);
			mRunHost.Runtime.Release(mGame);
		}
		mGame = null;
		mGameClass = null;
	}

	/// Ticks the game script with gameplay time, the host's delta through the context's,
	/// the run's and the current scene's scales, and moves the run's clock: once per frame,
	/// before the run bus drains. A faulting update stops THIS run's script, not the run.
	public void TickScript(float hostDeltaTime, float contextTimeScale)
	{
		// Debug paused: the debugger holds a suspended call. A new update each frame would
		// hit the breakpoint again per frame and orphan the held call; script time stands
		// still, like the scene sim.
		if (mRunHost.IsDebugPaused)
			return;
		let sceneScale = (mScene != null) ? mScene.TimeScale : 1.0f;
		let time = FrameTime(hostDeltaTime, contextTimeScale, mSceneManager.TimeScale, sceneScale);
		let dt = time.SceneDelta;
		if (mGame != null)
		{
			var args = ScriptValue[1](.FromFloat(dt));
			InvokeGame("update", .(&args[0], 1));
		}
		mRunHost.Advance(dt);
	}

	/// A run bus event into the orchestrator's `on<Event>(payload)`. At drain time, no
	/// script call active, so it dispatches directly; held while debug paused.
	private void DispatchGameEvent(StringView handler, Variant payload)
	{
		if ((mGame == null) || mRunHost.IsDebugPaused)
			return;
		var value = ScriptPayloads.ValueOf(payload, mScene);
		var args = ScriptValue[1](value);
		InvokeGame(handler, value.IsNil ? default : .(&args[0], 1));
	}

	/// A call on the orchestrator, gated by the class declaring it: a script without an
	/// `Update` is fine. A fault stops the script.
	private void InvokeGame(StringView handler, Span<ScriptValue> args)
	{
		let runtime = mRunHost.Runtime;
		if ((mGame == null) || (runtime == null) || !runtime.HasMethod(mGame, handler, args.Length))
			return;
		var result = ScriptValue.Nil;
		if (runtime.Invoke(mGame, handler, args, ref result))
			return;
		if (mRunHost.IsDebugPaused)
			return; // suspended at a breakpoint, not a fault; the debugger completes it
		GlobalLog(.Error, scope $"Run: the game script faulted in {handler}; stopped");
		mRunHost.ReportProblems();
		let faulted = mGame;
		mGame = null;
		runtime.CancelCoroutinesFor(faulted);
		runtime.Release(faulted);
		ClearGameSubscriptions();
	}

	private void SubscribeGameHandlers(ScriptClass scriptClass)
	{
		for (let handler in scriptClass.Handlers)
		{
			let eventName = ScriptSceneSystem.EventNameOf(handler, .. scope .());
			if (eventName.IsEmpty || mGameSubscriptions.ContainsKey(eventName))
				continue;
			let name = new String(eventName);
			let handlerName = new String(handler);
			delegate void(Variant) callback = new (payload) => { DispatchGameEvent(handlerName, payload); };
			mGameCallbacks.Add(callback);
			mGameHandlerNames.Add(handlerName);
			mGameSubscriptions[name] = mRunEvents.Subscribe(StringHash(eventName), callback);
		}
	}

	private void ClearGameSubscriptions()
	{
		for (let entry in mGameSubscriptions)
			mRunEvents.Unsubscribe(entry.value);
		DeleteDictionaryAndKeys!(mGameSubscriptions);
		mGameSubscriptions = new .();
		ClearAndDeleteItems!(mGameCallbacks);
		ClearAndDeleteItems!(mGameHandlerNames);
	}

	// ==================== Input ====================

	/// This run's input source: an editor's gated viewport, or the player's shell devices.
	///
	/// The runtime reads ONLY this source, which is what isolates input across surfaces: only
	/// the focused one reports anything. Null means no input.
	public void SetInputSource(IInputSourceProvider source)
	{
		mInputSource = source;
	}

	/// Installs the action map. Each instance has its own runtime and its own copy.
	public void SetInputMap(InputMap map) => mInputRuntime.SetMap(map);

	/// This run's action runtime.
	public ActionRuntime InputRuntime => mInputRuntime;

	/// Evaluates the runtime against its source. Nothing to do without one.
	public void DriveInput(float deltaTime, float contextTimeScale)
	{
		if (mInputSource == null)
			return;

		mInputRuntime.SetTimeScale(contextTimeScale);
		mInputRuntime.Update(mInputSource, deltaTime);
	}

	// ==================== Networking ====================

	/// This run's networking controller, exposed so an app can reach it directly. The
	/// forwards below are for callers that only want the role controls.
	public NetworkController Network => mNetwork;

	public bool StartServer(uint16 port, bool dedicated) =>
		mNetwork.StartServer(port, dedicated);
	public bool Connect(StringView host, uint16 port) => mNetwork.Connect(host, port);
	public void StopNetworking() => mNetwork.StopNetworking();
	public NetworkManager NetEndpoint => mNetwork.NetEndpoint;
}
