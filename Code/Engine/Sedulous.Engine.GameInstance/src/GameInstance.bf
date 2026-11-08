using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Input;
using Sedulous.Messaging;
using Sedulous.Net.Manager;
using Sedulous.Net.Tls;
#if !BF_PLATFORM_WASM
using Sedulous.Net.Tls.MbedTLS;
#endif
using Sedulous.Http.Script;
using Sedulous.Http.Client;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Input; // InputFacade
using Sedulous.Engine.Script;
using Sedulous.Engine.Script.Facades;

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
///
/// It IS its run, through RunBase: its id, name, sessions, event
/// bus, and what it owns registered on it, so others reach those through the run.
///
/// Its own stop hook (IRunService) ends a session in order: the native game's OnExit, then the
/// save written, then the networking the game used closed, then the handlers native code gave
/// Net and Http dropped and the run's random numbers restarted.
[Scriptable, ScriptService, DisplayName("Run")]
class GameInstance : RunBase, IRunService
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

	/// OWNED: this run's scenes, ticked once registered with the scene subsystem.
	private SceneManager mSceneManager = new .() ~ delete _;
	/// BORROWED: the current scene, which the group owns.
	private Scene mScene = null;

	private bool mHeadless = false;

	/// OWNED: the platform's TLS backend for this run (Mbed TLS natively; none in a browser,
	/// which does TLS itself), made on first use: https requests and wss joins check with it.
	private ITlsBackend mTls = null ~ delete _;
	/// OWNED: this run's networking.
	private NetworkController mNetwork = new .() ~ delete _;
	/// OWNED: `Http` to this run's scripts and its native code. Its client is made on the first
	/// request, pumped by TickScript and reset by StopScript and as each session stops.
	private HttpFacade mHttpFacade = new .() ~ delete _;

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
	/// The tickets of LoadScene calls made while a scene of the run was being ticked: started
	/// at the call, and finished (resources pumped out, then activated) by the next PumpLoads,
	/// once the scenes' frame is over.
	private List<int32> mFinishAtPump = new .() ~ delete _;
	/// How deep calls into a scene's own code run outside the scenes' tick: a behaviour's or a
	/// level's event handler, delivered by the run's drain or by an Emit from the game. Its scene
	/// must not be replaced under it, so a LoadScene then defers as one inside the tick does.
	private int32 mSceneCodeDepth = 0;

	private SceneActivationPolicy mActivationPolicy = null ~ delete _;

	// ---- the Game tier ----

	/// What the APP does to turn a scene id into a load on this instance: the content
	/// database lookup and the prefab resolver are its. TAKES OWNERSHIP of the delegate.
	public typealias SceneLoader = delegate SceneLoadHandle(Guid sceneId);
	/// Where `Run.RequestExit` goes: the host's loop, or the editor's Game tab session.
	/// TAKES OWNERSHIP of the delegate.
	public typealias ExitRequest = delegate void(int32 code);
	/// Shows or hides the app's profiler overlay.
	public typealias ProfilerOverlayRequest = delegate void(bool shown);
	/// Whether the app can show a profiler overlay.
	public typealias ProfilerAvailability = delegate bool();

	/// OWNED: this run's script host, the gameplay context the game script AND this
	/// instance's scenes' behaviours share. The subsystem wires it like its own; its scripts find
	/// this run's services (`Run`, `Input`, `Save`, `Net`, `Http`) through it, before the
	/// application's.
	private ScriptRunHost mRunHost = new .() ~ delete _;
	/// OWNED: `Input` to this run's scripts, over this run's action runtime alone.
	private InputFacade mInputFacade = null ~ delete _;
	/// OWNED: this run's save, and `Save` to its scripts over it.
	private RunSave mSave = new .() ~ delete _;
	private SaveFacade mSaveFacade = null ~ delete _;
	/// OWNED: `Net` to this run's scripts, over the networking controller.
	private NetFacade mNetFacade = null ~ delete _;
	/// OWNED: this run's random numbers, its native code's and (through the host's
	/// ScriptRandom) its scripts' alike; back to the default seed as each session stops.
	private RunRandom mRandom = new .() ~ delete _;
	/// The orchestrator: an instance of the game script's class. Null when no script runs.
	private ScriptObject mGame = null;
	/// BORROWED: the resource manager owns the product.
	private ScriptClass mGameClass = null;
	/// Why the last game script stopped on its own: the handler it faulted in and the
	/// runtime's problems, or that it did not instantiate. Empty while it runs or after a
	/// clean stop; a start clears it.
	private String mScriptFault = new .() ~ delete _;
	/// Seconds of frames TickScript has run since ResetRunClock: the host's delta, NOT scaled
	/// by the context's, the run's or the scene's time scale, so it keeps going while the game
	/// pauses its scene with Run.TimeScale = 0 (a menu over a paused scene still takes clicks).
	/// A scripted playtest times its input by it.
	private double mRunTime = 0;
	/// The host's delta of the last TickScript, before any time scale.
	private float mRealDelta = 0;
	private SceneLoader mSceneLoader = null ~ delete _;
	private ExitRequest mExitRequest = null ~ delete _;
	private ProfilerOverlayRequest mProfilerOverlay = null ~ delete _;
	private ProfilerAvailability mProfilerAvailable = null ~ delete _;
	private Dictionary<String, uint32> mGameSubscriptions = new .() ~ DeleteDictionaryAndKeys!(_);
	private List<delegate void(Variant)> mGameCallbacks = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mGameHandlerNames = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: the native game LaunchGame made, which the run holds as a session service
	/// (under IGameHooks) and deletes as the session ends. Null when none runs, and from its
	/// OnExit on, so nothing reaches it between its exit and its deletion.
	private IGameHooks mNativeGame = null;

	public this() : base("Game")
	{
		// This instance IS the run: its scenes carry it, so their bus is the run's (ONE object,
		// nothing relaying between them) and run scoped systems (audio) group them by it. Set on
		// the GROUP, so each scene has it as it is created, before its systems bind.
		mSceneManager.SetSceneRun(this);
		mInputFacade = new InputFacade(mInputRuntime);
		mSaveFacade = new SaveFacade(mSave);
		mNetFacade = new NetFacade(mNetwork);
		// Every context of this run finds this run's services through the run (Run, its input, its
		// save, its HTTP, its networking), a behaviour's as much as a game script's.
		mRunHost.OwningRun = this;
		// Its scripts' `Random` draws from the run's generator, the one its native code reaches.
		mRunHost.Random.Use(mRandom);
		// The run's HTTP client is made on its scripts' first request, and https and a wss join
		// use the run's TLS backend, made when first needed.
		mHttpFacade.SetFactory(new () => HttpClients.Create(TlsBackend));
		mNetwork.TlsBackendSource = new () => TlsBackend;
		// What the run owns and others reach through it (RunServices.Get, and its scripts by type):
		// borrowed, fields all.
		Register<GameInstance>(this);
		Register<InputFacade>(mInputFacade);
		Register<SaveFacade>(mSaveFacade);
		Register<NetFacade>(mNetFacade);
		Register<NetworkController>(mNetwork);
		Register<INetworkController>(mNetwork); // how the engine's network subsystem reaches it (below this library)
		Register<ActionRuntime>(mInputRuntime);
		Register<RunSave>(mSave);
		Register<ScriptRunHost>(mRunHost);
		Register<HttpFacade>(mHttpFacade);
		Register<RunRandom>(mRandom);
	}

	/// The platform's TLS backend for this run, made on first use; null in a browser.
	public ITlsBackend TlsBackend
	{
		get
		{
#if !BF_PLATFORM_WASM
			if (mTls == null)
				mTls = new MbedTlsBackend();
#endif
			return mTls;
		}
	}

	/// This run's HTTP for its scripts.
	public HttpFacade Http => mHttpFacade;

	public ~this()
	{
		// A native game launched outside a session has no stop to end it: it ends here, while
		// what it reaches still exists. In a session the stop below ends it.
		if (State == .Idle)
			StopGame();
		// Disposed first, while the fields registered on it still exist: their stop hooks run,
		// and the run's manager hears it go.
		Dispose();
		// The game script, then the scenes, whose behaviours live on the host, then the
		// host itself with the fields. The input source is borrowed and may be gone by now, so
		// the script's stop asks no pad of it to stop rumbling.
		mInputSource = null;
		// The host goes below whatever pins it, and the subsystem that installed its check may
		// already be gone at shutdown: the check is not asked again.
		DeleteAndNullify!(mRunHost.TeardownCheck);
		StopScript();
		ClearScenes();
		mRunHost.Teardown();
	}

	/// Pairs a scene in as the current one. The native game hears of a scene that was not
	/// current already.
	public void SetScene(Scene scene)
	{
		let previous = mScene;
		PairScene(scene);
		if ((scene != null) && (scene !== previous))
			ReportSceneActivated(scene);
	}

	/// The current scene, and what follows it, without telling the game: a tracked load tells it
	/// once the app's policy has run.
	private void PairScene(Scene scene)
	{
		mScene = scene;
		// Replication follows the current scene across loads.
		mNetwork.SetReplicatedScene(scene);

		// An ADOPTED scene belongs to this run too, and so shares its bus.
		if (scene != null)
			scene.SetRun(this);
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
	/// whose update(dt) does not take this scale, keeps going and can resume.
	[Scriptable, ScriptName("TimeScale")]
	public float InstanceTimeScale
	{
		get => mSceneManager.TimeScale;
		set => mSceneManager.TimeScale = value;
	}

	/// This run's scene group.
	public SceneManager Scenes => mSceneManager;

	/// Whether a scene's own code is running: the scenes' tick (fixed steps or Update), or a
	/// behaviour's or a level's handler called from outside it. What would replace the current
	/// scene (LoadScene's activation) waits until it is false.
	public bool SceneCodeRunning => mSceneManager.IsUpdating || (mSceneCodeDepth > 0);

	/// Brackets a call into a scene's own code made outside the scenes' tick (the gameplay
	/// tier's handler wrappers): each Enter is matched by one Leave.
	internal void EnterSceneCode() => mSceneCodeDepth++;
	internal void LeaveSceneCode() => mSceneCodeDepth--;

	/// Delivers this frame's queued events. Cascade bounded like a scene's, and safe with
	/// nothing subscribed.
	/// Held while debug paused, so what was published during the pause is delivered after
	/// it rather than into a held run or dropped.
	public void DrainRunEvents()
	{
		if (!mRunHost.IsDebugPaused)
			Events.Drain();
	}

	// ==================== Scenes ====================

	/// Creates a scene in this instance's group: it belongs to this run, so its behaviours run
	/// on this run's host, one gameplay context per run.
	///
	/// `activate` false leaves it out of the ticking and drawing sets, which is what an async
	/// load wants: a scene being streamed must not be seen until it is whole.
	public Scene CreateScene(StringView name, bool activate = true)
	{
		// The group gives the scene this run before it assembles, so the script subsystem binds
		// its behaviours to this run's host (the one registered on it), and the scene's events
		// and the run's are one object by the time anything binds to either.
		return mSceneManager.CreateScene(name, activate);
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
		mFinishAtPump.Clear();
		SetScene(null);
		mSceneManager.Clear();

		// The group's time scale is RUN scoped, and the group survives a stop, so a game
		// paused at the stop must not leave the next play frozen.
		mSceneManager.TimeScale = 1.0f;
	}

	/// Loads a cooked scene into this group and resolves its resources SYNCHRONOUSLY.
	///
	/// The scene comes back active and fully resolved but NOT started: what happens to it
	/// next is the app's policy. Null if the load itself failed. The prefabs it places come
	/// from `resources`, each read once however many times it is placed.
	public Scene LoadScene(Instance sceneInstance, ResourceManager resources)
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
			ScenePrefabs.ResolveScenePrefabs(scene, resources);
			// And bind what the prefabs brought with them.
			SceneResolve.ResolveSceneResources(scene, resources);
		}

		return scene;
	}

	/// Loads a cooked scene INACTIVE and puts its resource binds on the workers.
	///
	/// The handle is polled for progress, which is what a loading screen reads, and the scene
	/// is activated once it completes. It never ticks or draws while it loads. The prefabs it
	/// places bind at once, as a spawn's do, since placing one needs its payload now.
	public SceneLoadHandle LoadSceneAsync(Instance sceneInstance, ResourceManager resources)
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
			ScenePrefabs.ResolveScenePrefabs(scene, resources);

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
	///
	/// The hosts call it after the scenes' frame (fixed steps and Update); asked while a scene's
	/// own code runs (SceneCodeRunning) it does nothing, since an activation replaces and
	/// destroys the current scene, and the host's next call does the work. The LoadScene calls
	/// deferred out of scene code finish here first.
	public void PumpLoads()
	{
		if (SceneCodeRunning)
			return;

		if (!mFinishAtPump.IsEmpty)
		{
			for (let ticket in mFinishAtPump)
				FinishLoad(ticket);
			mFinishAtPump.Clear();
		}

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
			let previous = mScene;
			PairScene(activated);
			mSceneManager.CurrentScene = activated;
			if (mActivationPolicy != null)
				mActivationPolicy(activated);

			// A level load REPLACES the level it lands over. Left alone, the old one kept
			// ticking unseen beside the new: its player still read the input, its falls still
			// reached the run bus, and every restart stacked one more.
			if ((previous != null) && (previous !== activated))
				DestroyScene(previous);

			// Retired: the ticket now reads terminal safe through the fallback.
			mLoads.RemoveAt(i);

			// The game hears last, of a started scene with the old one gone; retired first, so a
			// load it starts from here is a fresh entry.
			if (activated !== previous)
				ReportSceneActivated(activated);
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

	/// The app's profiler overlay, behind Run.SetProfilerOverlay and Run.ProfilerAvailable.
	/// TAKES OWNERSHIP of both; either may be null, and unwired nothing shows and the
	/// profiler reads unavailable.
	public void SetProfilerOverlay(ProfilerOverlayRequest request, ProfilerAvailability available)
	{
		delete mProfilerOverlay;
		mProfilerOverlay = request;
		delete mProfilerAvailable;
		mProfilerAvailable = available;
	}

	/// Starts a level load by id: the ticket a script polls, or nought when the load could
	/// not start, a wrong id or no loader. The scene activates through the app's policy once
	/// its resources land, on the pump, and replaces the current one then.
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

	/// Loads a level and activates it now, the app's policy applied, in place of the current
	/// one, which is destroyed. False when it could not, and the current one stays.
	///
	/// Asked from a scene's own code (SceneCodeRunning: a behaviour's or a level's update or
	/// fixed step, what a behaviour's queued calls and contacts run at the end of its tick, or a
	/// behaviour's or a level's event handler wherever it is delivered), the load starts now and
	/// finishes at the host's next PumpLoads, after the frame's scene update: the scene whose
	/// code asked is not destroyed under it. True then means the load started; the current scene
	/// is still the old one until then. A game's own code (its hooks, its handlers, a game
	/// script) loads at once, and reads the new scene when the call returns.
	[Scriptable]
	public bool LoadScene(Guid sceneId)
	{
		let ticket = LoadSceneAsync(sceneId);
		if (ticket == 0)
			return false;
		if (SceneCodeRunning)
		{
			mFinishAtPump.Add(ticket);
			return true;
		}
		FinishLoad(ticket);
		PumpLoads();
		return !LoadFailed(ticket);
	}

	/// Pumps a tracked load's resources until it completes. The binds run on workers; pumping
	/// them out here is what makes LoadScene the synchronous convenience it claims to be. A
	/// ticket no longer tracked (its scene destroyed, the scenes cleared) is passed over.
	private void FinishLoad(int32 ticket)
	{
		for (let load in mLoads)
		{
			if (load.Ticket != ticket)
				continue;
			let handle = load.Handle;
			while (!handle.IsComplete)
				handle.Resources.Pump(0.010);
		}
	}

	/// LoadSceneAsync for the scene a field names (a level's exit): its ticket, or nought.
	public int32 LoadSceneAsync(SceneRef scene) => LoadSceneAsync(scene.Id);

	/// LoadScene for the scene a field names: false, the current one kept, when it names none
	/// or the load fails.
	public bool LoadScene(SceneRef scene) => LoadScene(scene.Id);

	/// Ends the run with an exit code: the standalone host stops its loop, an editor stops
	/// the Game tab's session. Nothing wired is a no-op.
	[Scriptable]
	public void RequestExit(int32 code = 0)
	{
		if (mExitRequest != null)
			mExitRequest(code);
	}

	/// Shows or hides the app's profiler overlay (frame times, the longest scopes and GPU
	/// passes, the counters), for a game's debug menu. The app decides what that means; in a
	/// ShippingRelease build nothing shows. Bound in every build, so a script compiles the
	/// same in the shipped game; unwired, a no-op.
	[Scriptable]
	public void SetProfilerOverlay(bool shown)
	{
		if (mProfilerOverlay != null)
			mProfilerOverlay(shown);
	}

	/// Whether SetProfilerOverlay can show anything here: false in a ShippingRelease build and
	/// where the app has no overlay, so a debug menu can hide its entry; false unwired.
	[Scriptable]
	public bool ProfilerAvailable() => (mProfilerAvailable != null) && mProfilerAvailable();

	/// Publishes on the run bus, which every scene of this run shares: the Game orchestrator
	/// and every behaviour declaring `on<Event>` hear it when the bus drains.
	[Scriptable]
	public void Emit(StringView eventName) => Events.Publish(StringHash(eventName), Variant());
	[Scriptable]
	public void Emit(StringView eventName, float payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, int32 payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, bool payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, StringView payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, EntityHandle payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, Float3 payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));
	[Scriptable]
	public void Emit(StringView eventName, Float4 payload) => Events.Publish(StringHash(eventName), ScriptPayloads.Of(payload));

	/// Whether a game script is running: instantiated and not faulted.
	public bool ScriptRunning => mGame != null;
	/// Reads a property of the running game script (a score, a lives count) into `value`;
	/// false with no script running or no such property.
	public bool GetScriptProperty(StringView name, ref ScriptValue value)
	{
		if ((mGame == null) || (mRunHost.Runtime == null))
			return false;
		return mRunHost.Runtime.GetProperty(mGame, name, ref value);
	}

	/// Why the game script stopped on its own; empty when it did not (see mScriptFault).
	public StringView ScriptFault => mScriptFault;
	/// Seconds of frames since ResetRunClock, unscaled (see mRunTime); standing still while
	/// the debugger holds the run.
	public double RunTime => mRunTime;
	/// A run's clock from zero: its time, and its real delta, which `launch()` would otherwise
	/// read as the previous run's last frame.
	public void ResetRunClock()
	{
		mRunTime = 0;
		mRealDelta = 0;
	}

	/// This frame's seconds before any time scale, the context's included. `update(dt)`
	/// already ignores Run.TimeScale; coroutine waits stand still at TimeScale 0.
	[Scriptable, ScriptName("RealDeltaTime")]
	public float RealDeltaTime => mRealDelta;
	/// Seconds of frames since the run started, unscaled: RunTime to a script.
	[Scriptable, ScriptName("RealTime")]
	public float RealTime => (float)mRunTime;

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
		mScriptFault.Clear();
		if (scriptClass == null)
			return false;
		let game = mRunHost.Instantiate(scriptClass);
		if (game == null)
		{
			GlobalLog(.Error, scope $"Run: the game script '{scriptClass.ClassName}' did not instantiate");
			mScriptFault.AppendF("the game script '{}' did not instantiate (log_read, category Script, has why)", scriptClass.ClassName);
			return false;
		}
		mGame = game;
		mGameClass = scriptClass;
		mRunHost.HasGameScriptHold = true;
		SubscribeGameHandlers(scriptClass);
		InvokeGame("launch", default);
		GlobalLog(.Information, scope $"Run: game script '{scriptClass.ClassName}' launched");
		return mGame != null;
	}

	/// `exit()`, then release. Idempotent; the fault path lands here too.
	public void StopScript()
	{
		ClearGameSubscriptions();
		// Any rumble the game started ends with it: no pad is left buzzing after its run.
		if (mInputSource != null)
			ActionRuntime.StopAllRumble(mInputSource);
		// What the game saved and did not write yet is kept: the run writes it as it ends.
		mSave.Flush();
		if (mGame != null)
		{
			InvokeGame("exit", default);
			if ((mGame != null) && (mRunHost.Runtime != null))
			{
				mRunHost.Runtime.CancelCoroutinesFor(mGame);
				mRunHost.Runtime.Release(mGame);
			}
			mGame = null;
			mGameClass = null;
			// The game held the host; it may go now, when no scene of the run still pins it.
			mRunHost.HasGameScriptHold = false;
			mRunHost.CheckTeardown();
			// Networking belongs to the game's run: what it hosted or joined closes with it,
			// after its exit() had the chance to say goodbye. An editor's Game tab stopped and
			// started again would otherwise come back still a server, its port still held.
			// Only a game's stop: StartScript stops first, and an app's startup preset hosts
			// or joins before the game launches.
			mNetwork.StopNetworking();
		}
		// So do its HTTP requests: no answer reaches a script that has stopped.
		mHttpFacade.Reset();
	}

	/// Ticks the game script and moves the run's clock: once per frame, before the run bus
	/// drains. A faulting update stops THIS run's script, not the run.
	///
	/// The orchestrator's `update(dt)` is the host's delta through the context's and the
	/// current scene's scales, NOT the run's (Run.TimeScale): the Game sets that scale to pause
	/// or slow its scenes, and the timers it keeps over them (a celebration, a countdown on a
	/// frozen screen) go on in real time. The run's coroutines, behaviours' among them, advance
	/// by gameplay time, the run's scale included, so a pause still holds them.
	public void TickScript(float hostDeltaTime, float contextTimeScale)
	{
		// Debug paused: the debugger holds a suspended call. A new update each frame would
		// hit the breakpoint again per frame and orphan the held call; script time stands
		// still, like the scene sim.
		if (mRunHost.IsDebugPaused)
			return;
		// The host's pause (the editor's toolbar) holds the game still with its scene: no update
		// for the Game class, the run's clock not counting, and its HTTP answers waiting. A game's
		// own pause (time scale nought) is the game's business and still ticks it.
		if (State == .Paused)
			return;
		let sceneScale = (mScene != null) ? mScene.TimeScale : 1.0f;
		let orchestrator = FrameTime(hostDeltaTime, contextTimeScale, 1.0f, sceneScale).SceneDelta;
		let gameplay = FrameTime(hostDeltaTime, contextTimeScale, mSceneManager.TimeScale, sceneScale).SceneDelta;
		mRunTime += hostDeltaTime;
		mRealDelta = hostDeltaTime;
		// Answers to the run's HTTP requests reach their handlers here, on the game's thread,
		// whether a game script or behaviours sent them.
		mHttpFacade.Pump();
		if (mGame != null)
		{
			var args = ScriptValue[1](.FromFloat(orchestrator));
			InvokeGame("update", .(&args[0], 1));
		}
		// The native game's update takes the orchestrator's delta too.
		if (mNativeGame != null)
			mNativeGame.Update(orchestrator);
		mRunHost.Advance(gameplay);
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
		mScriptFault.Set(scope $"faulted in {handler}");
		let problems = scope String();
		mRunHost.ReportProblems(problems);
		if (!problems.IsEmpty)
			mScriptFault.AppendF(": {}", problems);
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
			mGameSubscriptions[name] = Events.Subscribe(StringHash(eventName), callback);
		}
	}

	private void ClearGameSubscriptions()
	{
		for (let entry in mGameSubscriptions)
			Events.Unsubscribe(entry.value);
		DeleteDictionaryAndKeys!(mGameSubscriptions);
		mGameSubscriptions = new .();
		ClearAndDeleteItems!(mGameCallbacks);
		ClearAndDeleteItems!(mGameHandlerNames);
	}

	// ==================== The native game ====================

	/// Whether a native game is running: launched, and not yet at its OnExit.
	public bool HasNativeGame => mNativeGame != null;
	/// The running native game, or null. BORROWED: the run deletes it as the session ends.
	public IGameHooks NativeGame => mNativeGame;
	/// Whether a game of either kind runs: the native game, or a game script.
	public bool GameRunning => HasNativeGame || ScriptRunning;

	/// Launches the native game: the factory among the run's services (IGameFactory; the
	/// engine's game runner, when the build registered a game) makes it, the run holds it for
	/// this session (AddForSession, deleted as the session stops), and its OnLaunch runs. From
	/// then on TickScript updates it, SetScene and the tracked loads tell it of each scene that
	/// becomes current, and the session's stop ends it (OnRunStopping).
	///
	/// The hosts call it where they start a game script: the player before its boot scene,
	/// a Game tab before its scene loads, so a scene current before the launch is not reported.
	/// False, with nothing launched, when no factory is registered (a build without a game),
	/// when a game runs already (logged), when the run is stopping or gone, or when the factory
	/// made none (logged).
	public bool LaunchGame()
	{
		if (mNativeGame != null)
		{
			GlobalLog(.Warning, "Run: a game is running already; the second launch is refused");
			return false;
		}
		if ((State == .Stopping) || (State == .Disposed))
			return false;
		let factory = Get<IGameFactory>();
		if (factory == null)
			return false;
		let game = factory.CreateGame(this);
		if (game == null)
		{
			GlobalLog(.Error, "Run: the game's factory made no game");
			return false;
		}
		AddForSession<IGameHooks>(game);
		mNativeGame = game;
		game.Launch();
		GlobalLog(.Information, "Run: game launched");
		return true;
	}

	/// Ends the native game outside a session's stop, which is what a host does when it
	/// abandons a launch before starting the session (a Game tab whose scene failed to load):
	/// OnExit, the save written, its networking closed, and the game deleted. Nothing when none
	/// runs.
	public void StopGame()
	{
		if (mNativeGame == null)
			return;
		EndNativeGame();
		DropNativeCallbacks();
		Remove<IGameHooks>();
	}

	/// The session ends (RunBase.Stop): the native game's OnExit, then the save written, so
	/// what the game saved as it exited is in the file, then the networking it hosted or
	/// joined closed after its exit had the chance to say goodbye. A game script's exit() ran
	/// earlier, in StopScript, so what it saved is written here too. The run deletes the game
	/// after the hooks, with the session's other services.
	///
	/// Then what native code handed the run's facades goes, its Net handlers and its HTTP
	/// requests under way, since the game, its levels and its behaviours they call into go with
	/// the session; and the run's random numbers go back to the default seed, so the next
	/// session draws what this one did.
	void IRunService.OnRunStopping(IRun run)
	{
		if (mNativeGame != null)
			EndNativeGame();
		else
			mSave.Flush();
		DropNativeCallbacks();
		mRandom.Reset();
	}

	/// The Net handlers native code registered, deleted, and every HTTP request under way
	/// dropped, its handler never called: nothing reaches a game that has ended.
	private void DropNativeCallbacks()
	{
		mNetFacade.DropNativeHandlers();
		mHttpFacade.Reset();
	}

	/// OnExit, the save, the networking, in that order; the game is no longer reached after.
	private void EndNativeGame()
	{
		let game = mNativeGame;
		mNativeGame = null;
		game.Exit();
		mSave.Flush();
		mNetwork.StopNetworking();
	}

	/// The native game hears that `scene` became current.
	private void ReportSceneActivated(Scene scene)
	{
		if (mNativeGame != null)
			mNativeGame.SceneActivated(scene);
	}

	// ==================== Save ====================

	/// Names this run's save file and reads it (the player's user data directory, a Game tab's
	/// project Editor/ folder). The run's scripts reach it through the `Save` service, and the
	/// run writes it when its script stops if anything changed. Empty: values kept for the run
	/// only.
	public void SetSaveFile(StringView path) => mSave.Open(path);

	/// This run's save.
	public RunSave Saves => mSave;

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
		TraceInput();
	}

	/// SEDULOUS_INPUT_TRACE set: twice a second, what the input path saw (each pad's left
	/// stick and south button as the device reports them) and what the actions made of it.
	/// For a device where input misbehaves and no debugger reaches, a handheld say.
	private void TraceInput()
	{
		if (sTraceInput == 0)
		{
			let value = scope String();
			sTraceInput = ((Environment.GetEnvironmentVariable("SEDULOUS_INPUT_TRACE", value) case .Ok) && !value.IsEmpty) ? 1 : -1;
		}
		if ((sTraceInput < 0) || ((mInputRuntime.Frame % 30) != 0))
			return;
		let line = scope String();
		line.AppendF("InputTrace: frame {} source {} pads {}", mInputRuntime.Frame, mInputSource.GetType().GetName(.. scope .()), mInputSource.GamepadCount);
		for (int32 i < mInputSource.GamepadCount)
		{
			if (let pad = mInputSource.GetGamepad(i))
				line.AppendF(" [{} '{}' connected {} left ({:0.00},{:0.00}) south {}]", pad.Index, pad.Name, pad.Connected,
					pad.Axis(.LeftX), pad.Axis(.LeftY), pad.IsButtonDown(.South));
		}
		let actions = scope String();
		mInputRuntime.AppendStateSummary(actions);
		line.AppendF(" | {}", actions);
		GlobalLog(.Information, line);
	}

	/// Nought unread, 1 tracing, -1 not.
	private static int sTraceInput = 0;

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
