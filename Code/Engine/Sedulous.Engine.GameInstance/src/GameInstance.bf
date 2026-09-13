using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Input;
using Sedulous.Messaging;
using Sedulous.Net.Manager;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

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
	private float mInstanceTimeScale = 1.0f;

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

	public this()
	{
		// Every scene this run creates BORROWS the run bus. Setting it on the GROUP means the
		// injection happens as a scene is created, before its systems bind, rather than after.
		mSceneManager.SetSceneEventBus(mRunEvents);
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

	/// This instance has a live current scene, which is what a caller waits on rather than
	/// assuming one exists at launch.
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
	/// instance collapses to the model without it.
	public float InstanceTimeScale
	{
		get => mInstanceTimeScale;
		set => mInstanceTimeScale = value;
	}

	/// This run's scene group.
	public SceneManager Scenes => mSceneManager;

	/// This run's ONE event bus. A subscriber here sees what any of the run's scenes emitted,
	/// because they are the same bus rather than two joined by plumbing.
	public EventBus RunEvents => mRunEvents;

	/// Delivers this frame's queued events. Cascade bounded like a scene's, and safe with
	/// nothing subscribed.
	public void DrainRunEvents() => mRunEvents.Drain();

	// ==================== Scenes ====================

	/// Creates a scene in this instance's group.
	///
	/// `activate` false leaves it out of the ticking and drawing sets, which is what an async
	/// load wants: a scene being streamed must not be seen until it is whole.
	public Scene CreateScene(StringView name, bool activate = true)
	{
		// The run bus is already injected by the group before assembly, so the scene's events
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
	public bool LoadComplete(int32 ticket)
	{
		for (let load in mLoads)
		{
			if (load.Ticket == ticket)
				return load.Handle.Failed;
		}
		return true;
	}

	public bool LoadFailed(int32 ticket)
	{
		for (let load in mLoads)
		{
			if (load.Ticket == ticket)
				return load.Handle.Failed;
		}
		return false;
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
