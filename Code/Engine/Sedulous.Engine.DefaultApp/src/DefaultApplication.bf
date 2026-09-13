using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Input;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Net;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.UI;
using Sedulous.Graphics;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Profiler;
using Sedulous.Resource;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
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
class DefaultApplication : IApplication
{
	/// BORROWED: stable for the application's lifetime.
	private IApplicationHost mHost = null;

	private SceneSubsystem mScenes = null;
	private RenderSubsystem mRender = null ~ delete _;
	private AudioSubsystem mAudio = null ~ delete _;
	private InputSubsystem mInput = null ~ delete _;
	private PhysicsSubsystem mPhysics = null;
	private UISubsystem mUI = null;

	/// The primary running game, which every application level operation targets.
	private GameInstance mInstance = new .() ~ delete _;
	private List<GameInstance> mExtraInstances = new .() ~ DeleteContainerAndItems!(_);

	private SceneComposition mComposition = null ~ delete _;

	private AudioEngineSettings mAudioEngineSettings = null;
	private String mUIFontPath = new .() ~ delete _;

	/// OWNED only when this application made it. Embedded in a larger host it BORROWS one,
	/// and then the host pumps it.
	private ResourceManager mOwnedResources = null ~ delete _;
	private ResourceManager mBorrowedResources = null;
	private ContentDatabase mContentDatabase = null;

	private NetworkStartup mNetStartup = .();

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

	public void SetUIFontPath(StringView path) => mUIFontPath.Set(path);

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

	public virtual void Configure(IApplicationHost host)
	{
		mHost = host;

		mScenes = host.Context.AddSubsystem<SceneSubsystem>();
		// The assembly blueprint: every registered manager's scene is built from the FULL
		// composition, which is the single source of truth.
		mComposition = EngineSceneComposition.Build();
		mScenes.SetComposition(mComposition);
		// The run's scene group lives on the instance, so it is registered here to tick on
		// the context's lane.
		mScenes.RegisterManager(mInstance.Scenes);

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			mRender = new RenderSubsystem(graphics.Raw, graphics.FramesInFlight);
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

		// The net subsystem injects the replication managers into every scene so authored
		// network components work, and OWNS the per frame transport pump. It is given the
		// endpoint enumerator because this application owns the instance list while the
		// subsystem owns the tick.
		let net = host.Context.AddSubsystem<NetworkSubsystem>();
		net.SetEndpointSource(new (visit) =>
			{
				ForEachInstance(scope (instance) =>
					{
						if (let endpoint = instance.NetEndpoint)
							visit(endpoint);
					});
			});

		mAudio = new AudioSubsystem(mAudioEngineSettings);
		host.Context.RegisterSubsystem<AudioSubsystem>(mAudio);

		mInput = new InputSubsystem((host.Shell != null) ? host.Shell.Input : null);
		host.Context.RegisterSubsystem<InputSubsystem>(mInput);
		// The primary instance reads the shell's devices by default, which is the player's
		// path; an editor tab overrides this to its own gated source.
		mInstance.SetInputSource(mInput.ShellSource);

		mUI = host.Context.AddSubsystem<UISubsystem>();
		if (!mUIFontPath.IsEmpty)
			mUI.SetFontPath(mUIFontPath);

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

	public virtual void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
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
	}

	// ==================== networking ====================

	/// Resolves a prefab a replicated spawn named, into the scene the endpoint replicates.
	private StateReplication.SpawnHandler MakeSpawnResolver()
	{
		// Without a content database there is nothing to resolve a prefab through, so a
		// spawn simply produces no entity rather than half of one.
		return new (scene, prefab, id) => EntityHandle.Invalid;
	}

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
