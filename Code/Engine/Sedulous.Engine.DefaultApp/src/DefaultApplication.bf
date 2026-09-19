using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.VFS;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Input;
using Sedulous.Engine.Integration;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Net;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Script;
using Sedulous.Engine.ScriptSurface;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.UI;
using Sedulous.Graphics;
using Sedulous.Image;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Profiler;
using Sedulous.Resource;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Shell;

namespace Sedulous.Engine.DefaultApp;

/// An opinionated application base that registers the standard engine subsystems.
///
/// A game wanting the batteries included engine derives from this and adds its own in
/// Configure, calling the base first; a game wanting only its own implements the application
/// interface directly and links none of this.
///
/// It lives in its OWN library precisely so the base client never pulls the engine subsystems
/// in, and it registers ALL of them, so subsystem registration has one home rather than one
/// per entry point.
///
/// PARTIAL PORT. Raptor's version also owns the GAME SCRIPT lifecycle: the run host wiring,
/// the facade surface, the backends, the per context configurator, the load facade and the
/// script tick. The script projects are out of scope, so none of that is here, and an
/// instance runs its scenes without a Game object.
class DefaultApplication : IApplication, ISceneObserver
{
	/// BORROWED: stable for the application's lifetime.
	private IApplicationHost mHost = null;

	private SceneSubsystem mScenes = null;
	private RenderSubsystem mRender = null ~ delete _;
	private AudioSubsystem mAudio = null ~ delete _;
	private InputSubsystem mInput = null ~ delete _;
	private PhysicsSubsystem mPhysics = null;
	/// OWNED, like the other REGISTERED subsystems: the context drives one it did not create
	/// and never frees it.
	private UISubsystem mUI = null ~ delete _;

	/// OWNED: the network subsystem borrows this visitor and only clears its reference.
	private delegate void(delegate void(NetworkManager)) mEndpointSource = null ~ delete _;

	/// The primary running game, which every application level operation targets.
	private GameInstance mInstance = new .() ~ delete _;
	private List<GameInstance> mExtraInstances = new .() ~ DeleteContainerAndItems!(_);


	private AudioEngineSettings mAudioEngineSettings = null;
	private String mDataRootOverride = new .() ~ delete _;
	private String mDataRoot = new .() ~ delete _;
	/// OWNED: resolved once in Configure and handed to every consumer of engine data.
	private NativeFileSystem mDataMount = null ~ delete _;

	/// OWNED only when this application made it. Embedded in a larger host it BORROWS one,
	/// and then the host pumps it.
	private ResourceManager mOwnedResources = null ~ delete _;
	private ResourceManager mBorrowedResources = null;
	private ContentDatabase mContentDatabase = null;
	/// The runtime script surface, populated once from the root; every run binds it.
	private ScriptSurface mScriptSurface = new .() ~ delete _;

	private NetworkStartup mNetStartup = .();

	/// OWNED: physics contacts to script handlers. Uninstalled before the subsystems go.
	private ScriptPhysicsContactBridge mContactBridge = new .() ~ delete _;

	// ---- screenshots ----
	private ScreenshotCapture mScreenshot = new .() ~ delete _;
	/// OWNED: the setter takes the reference.
	private ScreenshotOptions mScreenshotOptions = new .() ~ delete _;
	/// The frames FinishFrame saw, which is what --screenshot-frame counts.
	private uint64 mRenderedFrames = 0;
	/// The --screenshot request is one shot.
	private bool mScreenshotOptionFired = false;
	private bool mScreenshotExitPending = false;
	private float mExitAfterSeconds = 0.0f;
	private float mRunSeconds = 0.0f;

	// ==================== accessors ====================

	public GameInstance Instance => mInstance;
	/// The primary instance's scene group: a scene created here renders.
	public SceneManager PrimaryScenes => mInstance.Scenes;

	public InputSubsystem Input => mInput;
	public PhysicsSubsystem Physics => mPhysics;
	public AudioSubsystem Audio => mAudio;
	public UISubsystem UI => mUI;
	public NetworkManager Net => mInstance.NetEndpoint;

	public ResourceManager Resources =>
		(mBorrowedResources != null) ? mBorrowedResources : mOwnedResources;

	/// A preset role entered at startup. None leaves it offline, which is the default.
	public void SetNetworkStartup(NetworkStartup startup) => mNetStartup = startup;

	/// BORROWED: the settings outlive the call, the audio subsystem reading them at bring up.
	public void SetAudioEngineSettings(AudioEngineSettings settings) =>
		mAudioEngineSettings = settings;

	// ---- screenshots ----

	/// Captures the next presented frame of the main window to `path` as a PNG. F11 does
	/// this with a timestamped name in the working directory; --screenshot does it at a
	/// chosen frame. The write lands one frame later, the GPU having to finish the copy
	/// first.
	public void CaptureScreenshot(StringView path) => mScreenshot.Request(path);

	/// The --screenshot flags, from ScreenshotOptions.FromArguments: capture at frame N or
	/// after S seconds, optionally exiting once written. Takes ownership.
	public void SetScreenshotOptions(ScreenshotOptions options)
	{
		delete mScreenshotOptions;
		mScreenshotOptions = options;
	}

	/// Exits the host after this many seconds of updates, nought never. The player's
	/// --exit-after.
	public void SetExitAfterSeconds(float seconds) => mExitAfterSeconds = seconds;

	/// An explicit data root, which beats the discovery walk. The player fills this from
	/// --data-root; set it before Configure or it is too late to matter.
	public void SetDataRoot(StringView path) => mDataRootOverride.Set(path);

	/// Where engine data was found, empty when it was not.
	public StringView DataRoot => mDataRoot;

	/// The mount over that root, which is what every consumer of engine data is handed.
	public IFileSystem DataFileSystem => mDataMount;

	/// A data-root-relative path as an absolute one, for the few things that take a path
	/// rather than a mount: a cooked output database, a model a loader opens itself.
	public void DataPath(StringView relative, String outPath) =>
		Sedulous.VFS.DataPath(mDataRoot, relative, outPath);

	/// Hands over a manager this application does NOT own, which is what an editor embedding
	/// it does.
	public void SetResourceManager(ResourceManager borrowed) => mBorrowedResources = borrowed;

	public void SetContentDatabase(ContentDatabase database) => mContentDatabase = database;

	/// Attaches a borrowed manager AFTER startup, registering the standard factories on it.
	public void AttachResourceManager(ResourceManager borrowed, IApplicationHost host)
	{
		mBorrowedResources = borrowed;
		if (borrowed != null)
			RegisterStandardFactories(borrowed, host);
	}

	public void SetPrimaryScene(Scene scene) => mInstance.SetScene(scene);
	public Scene PrimaryScene => mInstance.GetScene();

	// ==================== configuration ====================

	/// The main window's render configuration. Declared here rather than left to the
	/// interface's default, because an interface default is reachable only through the
	/// interface: a subclass could not override it.
	public virtual RenderWindowDesc MainRenderWindow => .();

	public virtual void Configure(IApplicationHost host)
	{
		mHost = host;

		// The data root is resolved ONCE, here, and mounted. Nothing below the application
		// knows where it is, only what it reads relative to it.
		ResolveDataRoot(mDataRootOverride, mDataRoot);
		if (mDataRoot.IsEmpty)
		{
			// The mount still points at where a dist would keep it, so every miss on the way
			// out names the place rather than reading as an unexplained absence.
			GlobalLog(.Error,
				"DefaultApplication: no data root, so there are no engine shaders and no built in font. Put Data beside the executable, or pass {} <dir>.",
				cDataRootArgument);
			PathJoin(GetExecutableDirectory(.. scope String()), "Data", mDataRoot);
			host.RequestExit(1);
		}
		mDataMount = new NativeFileSystem(mDataRoot);

		EngineScriptSurface.Populate(mScriptSurface);
		mScenes = host.Context.AddSubsystem<SceneSubsystem>();
		// The assembly blueprint: every registered manager's scene is built from the FULL
		// composition, which is the single source of truth.
		// TAKES OWNERSHIP, so nothing here keeps a reference to free a second time.
		mScenes.SetComposition(EngineSceneComposition.Build());
		// The run's scene group lives on the instance, so it is registered here to tick on
		// the context's lane.
		mScenes.RegisterManager(mInstance.Scenes);
		// A script's Spawn reaches the content through the scene's spawn system, which only
		// the app can point at the database and the manager.
		mScenes.RegisterObserver(this, .SystemsReady);

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			mRender = new RenderSubsystem(graphics.Raw, graphics.FramesInFlight, mDataMount);
			host.Context.RegisterSubsystem<RenderSubsystem>(mRender);

			// Drives skeletal animation off the scene tick, and needs the render managers.
			host.Context.AddSubsystem<AnimationSubsystem>();
			host.Context.AddSubsystem<ParticleSubsystem>();
			// The terrain renderer registers itself on the opaque category and wires the
			// manager scene composition already injected.
			host.Context.AddSubsystem<TerrainSubsystem>();
		}

		mPhysics = host.Context.AddSubsystem<PhysicsSubsystem>();
		host.Context.AddSubsystem<NavigationSubsystem>();

		// Scripting: the backend, and the run's surface. The COMPLETE runtime surface, from
		// the composition root, never a hand picked subset: a list kept here would drift.
		AngelScriptBackend.Register();
		let scripts = host.Context.AddSubsystem<ScriptSubsystem>();
		scripts.Configure = new (runtime) =>
			{
				runtime.Bind(mScriptSurface);
				for (let p in runtime.Problems)
					GlobalLog(.Warning, scope $"Script: {p}");
				ClearAndDeleteItems!(runtime.Problems);
			};
		// Physics contacts reach behaviours through the composition root's bridge: neither
		// subsystem names the other.
		mContactBridge.Install(mPhysics, scripts);

		// The net subsystem injects the replication managers into every scene so authored
		// network components work, and OWNS the per frame transport pump. It is given the
		// endpoint enumerator because this application owns the instance list while the
		// subsystem owns the tick.
		let net = host.Context.AddSubsystem<NetworkSubsystem>();
		// The subsystem BORROWS the visitor, so it is held here rather than handed over.
		mEndpointSource = new (visit) =>
			{
				ForEachInstance(scope (instance) =>
					{
						if (let endpoint = instance.NetEndpoint)
							visit(endpoint);
					});
			};
		net.SetEndpointSource(mEndpointSource);

		mAudio = new AudioSubsystem(mAudioEngineSettings);
		host.Context.RegisterSubsystem<AudioSubsystem>(mAudio);

		mInput = new InputSubsystem((host.Shell != null) ? host.Shell.Input : null);
		host.Context.RegisterSubsystem<InputSubsystem>(mInput);
		// The primary instance reads the shell's devices by default, which is the player's
		// path; an editor tab overrides this to its own gated source.
		mInstance.SetInputSource(mInput.ShellSource);

		mUI = new UISubsystem(mDataMount);
		host.Context.RegisterSubsystem<UISubsystem>(mUI);

		// Each instance owns its OWN endpoint and goes online at runtime through the facade,
		// so there is no application owned socket. The primary carries the prefab spawn
		// resolver and the optional startup preset; an extra gets the resolver when created.
		mInstance.Network.SetSpawnResolverFactory(new () => MakeSpawnResolver());
		ApplyNetworkStartup(mInstance);
	}

	// ==================== instances ====================

	/// An ADDITIONAL running game, which is what several games in flight at once needs, and
	/// what an in editor dedicated server is when headless.
	public GameInstance CreateInstance(bool headless = false)
	{
		if ((mScenes == null) || (mHost == null))
			return null;

		let instance = new GameInstance();
		instance.Headless = headless;

		mScenes.RegisterManager(instance.Scenes);
		instance.Network.SetSpawnResolverFactory(new () => MakeSpawnResolver());

		if (mInput != null)
			instance.SetInputSource(mInput.ShellSource);

		mExtraInstances.Add(instance);
		return instance;
	}

	public void ReleaseInstance(GameInstance instance)
	{
		if ((instance == null) || (instance === mInstance))
			return;

		let at = mExtraInstances.IndexOf(instance);
		if (at < 0)
			return;

		if (mScenes != null)
			mScenes.UnregisterManager(instance.Scenes);

		// Destroy whatever scenes are left, with the aware subsystems notified.
		instance.Scenes.Clear();

		mExtraInstances.RemoveAt(at);
		delete instance;
	}

	/// The primary first, then every extra.
	private void ForEachInstance(delegate void(GameInstance instance) fn)
	{
		fn(mInstance);
		for (let instance in mExtraInstances)
			fn(instance);
	}

	/// What the application does to a scene one of its loads just activated.
	private static void ApplyLoadedSceneActivation(Scene scene)
	{
		if (scene == null)
			return;

		scene.Start();
		scene.SetSimulationEnabled(true);
	}

	// ==================== lifecycle ====================

	public virtual void OnStartup(IApplicationHost host)
	{
		// An application gets a profiler, so the P key below has a CPU tree to print.
		//
		// Raptor's profiler is a SINGLETON that is always live; this port made it an
		// installable global instead, which is the better shape for a tool or a test that
		// wants none - but nothing was installing one, so HasGlobalProfiler was false in
		// every sample and half of DumpProfileOnRequest could never run. An application is
		// exactly the case that should have one.
		if (!HasGlobalProfiler())
			InitGlobalProfiler(new Profiler(), true);

		RegisterProductTypes();

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null) && (mUI != null))
			mUI.EnsureRenderReady(graphics.Raw, (int32)graphics.FramesInFlight);

		if ((mBorrowedResources == null) && (mContentDatabase != null))
		{
			// Shares the global job pool where there is one, so a factory can decode off the
			// main thread; without one, loads are synchronous.
			mOwnedResources = new ResourceManager(mContentDatabase,
				HasGlobalJobSystem() ? GlobalJobs() : null);
		}

		let resources = Resources;
		// A headless or content free application attaches one later, or never.
		if (resources == null)
			return;

		RegisterStandardFactories(resources, host);
	}

	/// Nothing by default: a subclass hooks the moment the engine is up and the project can
	/// start being read.
	public virtual void OnLaunch(IApplicationHost host) {}

	/// And the moment the run is asked to end, before anything is torn down.
	public virtual void OnExit(IApplicationHost host) {}

	public virtual void OnUpdate(IApplicationHost host, float deltaTime)
	{
		// A screenshot recorded last frame: the GPU has run that frame by now for any slot the
		// host reuses, but not necessarily this one, and a screenshot is a one off, so wait
		// for everything, then map, write, and honour --screenshot-exit.
		if (mScreenshot.Recorded)
		{
			let graphics = host.Graphics;
			if ((graphics != null) && (graphics.Raw != null))
			{
				graphics.Raw.WaitIdle();
				let written = scope Image();
				mScreenshot.Complete(graphics.Raw, written).IgnoreError();
			}
			if (mScreenshotExitPending)
				host.RequestExit(0);
		}

		mRunSeconds += deltaTime;
		if ((mExitAfterSeconds > 0.0f) && (mRunSeconds >= mExitAfterSeconds))
			host.RequestExit(0);

		// Finish the async loads FIRST, so this frame's spawns and ticks see ready
		// resources. Only the manager this application OWNS is pumped: embedded in a larger
		// host it borrows one, and that host pumps it, so pumping here as well would double
		// pump it.
		if (mOwnedResources != null)
			mOwnedResources.Pump();

		let contextScale = host.Context.TimeScale;

		// Every instance, the primary and any extras. Input FIRST, so a tick sees this
		// frame's keys.
		ForEachInstance(scope (instance) =>
			{
				// Activate any load that finished, which is why this follows the pump.
				instance.PumpLoads();
				instance.DriveInput(deltaTime, contextScale);
				// The run bus is drained where the script tick used to be.
				instance.DrainRunEvents();
			});

		DumpProfileOnRequest(host);
		CaptureOnRequest(host);
	}

	/// Press F11 for a timestamped PNG in the working directory.
	private void CaptureOnRequest(IApplicationHost host)
	{
		let shell = host.Shell;
		let input = (shell != null) ? shell.Input : null;
		let keyboard = (input != null) ? input.Keyboard : null;

		if ((keyboard == null) || !keyboard.IsKeyPressed(.F11))
			return;

		CaptureScreenshot(scope $"screenshot_{DateTime.Now.Ticks}.png");
	}

	/// The last thing a frame does before the host presents it: records the armed screenshot
	/// copy off the backbuffer, which is in the RenderTarget state and is left there. The
	/// base OnRenderWindow calls it; a subclass that overrides OnRenderWindow calls it at its
	/// end, after its last draw into the backbuffer.
	protected void FinishFrame(IApplicationHost host, ref FrameContext frame)
	{
		mRenderedFrames++;
		if (mScreenshotOptions.Requested && !mScreenshotOptionFired
			&& mScreenshotOptions.Due(mRenderedFrames, mRunSeconds))
		{
			mScreenshotOptionFired = true;
			mScreenshot.Request(mScreenshotOptions.Path);
			mScreenshotExitPending = mScreenshotOptions.ExitAfter;
		}

		if (!mScreenshot.Armed)
			return;

		let graphics = host.Graphics;
		if ((graphics == null) || (graphics.Raw == null) || (frame.Encoder == null)
			|| (frame.Window == null))
		{
			return; // stays armed for a frame that has a backbuffer
		}

		let recorded = mScreenshot.Record(graphics.Raw, frame.Encoder, frame.Backbuffer,
			frame.Window.Swap.Format, frame.Width, frame.Height);
		if (!recorded && mScreenshotExitPending)
			host.RequestExit(1); // asked for a file that cannot be produced: the exit code says so
	}

	/// Press P for the previous frame's processor scope tree and the per pass timings.
	///
	/// A subclass overriding the update calls the base to keep this, and the timings are read
	/// after a stall, which is fine for something asked for by hand.
	private void DumpProfileOnRequest(IApplicationHost host)
	{
		let shell = host.Shell;
		let input = (shell != null) ? shell.Input : null;
		let keyboard = (input != null) ? input.Keyboard : null;

		if ((keyboard == null) || !keyboard.IsKeyPressed(.P))
			return;

		if (HasGlobalProfiler())
		{
			let report = scope String();
			GlobalProfiler().BuildReport(report);
			Console.WriteLine(report);
		}

		if (let renderer = host.Context.GetSubsystem<RenderSubsystem>())
		{
			let gpu = scope String();
			renderer.BuildGpuProfileReport(gpu);
			Console.WriteLine(gpu);
		}
	}

	/// The scenes, the overlays, then the screenshot. A subclass that draws something of its
	/// own over the scenes overrides this and calls RenderFrame, its own drawing, then
	/// FinishFrame, in that order, so a screenshot has the whole frame in it.
	public virtual void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		RenderFrame(host, ref frame);
		FinishFrame(host, ref frame);
	}

	/// Every non headless instance's scenes and the window space overlays, into the
	/// backbuffer, which is left in the RenderTarget state.
	protected void RenderFrame(IApplicationHost host, ref FrameContext frame)
	{
		let render = host.Context.GetSubsystem<RenderSubsystem>();
		let scenes = host.Context.GetSubsystem<SceneSubsystem>();

		if ((render == null) || !render.IsReady || (scenes == null) || (frame.Encoder == null)
			|| (frame.BackbufferView == null) || (frame.Window == null))
		{
			// No renderer, so present something rather than nothing.
			frame.Clear(0.08f, 0.09f, 0.12f, 1.0f);
			return;
		}

		let colorFormat = frame.Window.Swap.Format;

		// The texture canvases draw BEFORE the scene, so a material sampling one sees this
		// frame's interface.
		if (mUI != null)
			mUI.RenderCanvasTextures(frame.Encoder, (int32)frame.FrameIndex);

		render.BeginRendering(frame.Encoder, frame.FrameIndex);

		// Every NON headless instance's scenes: a headless dedicated server simulates but is
		// never drawn. The clear comes from the scene's own camera.
		ForEachInstance(scope (instance) =>
			{
				if (instance.Headless)
					return;

				for (let scene in instance.Scenes.ActiveScenes)
					render.RenderScene(scene, frame.BackbufferView, colorFormat, frame.Width,
						frame.Height);
			});

		// The scene tier's overlays draw inside the compose.
		render.EndRendering();

		// And the window space ones composite over the finished frame through the registry,
		// so the host names no source.
		render.RenderOverlays(frame.Encoder, frame.BackbufferView, colorFormat, frame.Width,
			frame.Height, frame.FrameIndex);
	}

	public virtual void OnShutdown(IApplicationHost host)
	{
		// Paired with the install in OnStartup; owned, so this frees it.
		ShutdownGlobalProfiler();
		mContactBridge.Uninstall();

		for (let instance in mExtraInstances)
		{
			if (mScenes != null)
				mScenes.UnregisterManager(instance.Scenes);
			instance.Scenes.Clear();
		}
		ClearAndDeleteItems!(mExtraInstances);

		if (mScenes != null)
			mScenes.UnregisterManager(mInstance.Scenes);
		mInstance.Scenes.Clear();

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
			mScreenshot.Release(graphics.Raw);
	}

	// ==================== networking ====================

	/// Every composed scene's spawn system gets the app's content and resources.
	public void OnSystemsReady(Scene scene)
	{
		if (let spawner = scene.GetSystem<PrefabSpawnSystem>())
			spawner.SetSource(mContentDatabase, Resources);
	}

	/// Resolves a prefab a replicated spawn named, into the scene the endpoint replicates.
	///
	/// The APP owns this because it is the only thing that knows the content database; the
	/// NetworkController applies it to each endpoint, so a reconnect keeps it and the app
	/// hands it over once at wiring rather than rewiring per endpoint.
	///
	/// The server assigns the ids and the game rules decide relevancy. Replication then
	/// applies the transform and the fields ON TOP of what spawns here, so this only has to
	/// produce the entity, not position it.
	private StateReplication.SpawnHandler MakeSpawnResolver()
	{
		// Reads the database and the manager WHEN INVOKED, not when wired: the content
		// database is handed over after construction, and the controller asks for this once.
		return new (scene, prefab, id) =>
			ResolveNetworkPrefab(mContentDatabase, Resources, scene, prefab);
	}

	/// The resolver's body: the one spawn recipe, PrefabSpawnSystem's, with the app's
	/// database and manager supplied. A script's Spawn runs the same one through the scene.
	///
	/// Answers an unassigned handle for every failure, and does so deliberately: a replicated
	/// spawn that cannot be resolved should produce NO entity rather than half of one, and the
	/// replication that follows applies transform and fields on top of whatever this returns.
	public static EntityHandle ResolveNetworkPrefab(ContentDatabase database,
		ResourceManager resources, Scene scene, Guid prefab)
		=> PrefabSpawnSystem.SpawnInto(scene, database, resources, prefab);

	/// Enters a preset role at startup. None leaves it offline.
	private void ApplyNetworkStartup(GameInstance instance)
	{
		switch (mNetStartup.Role)
		{
		case .None:
		case .Server:
			instance.StartServer(mNetStartup.ListenPort, mNetStartup.Dedicated);
		case .Client:
			instance.Connect(mNetStartup.ServerHost, mNetStartup.ServerPort);
		}
	}
}
