namespace TowerDefense;

using System;
using System.Collections;
using System.IO;
using Sedulous.Engine;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.Engine.Audio;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Messaging.Runtime;
using Sedulous.UI;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;

/// Composition root for the Tower Defense game.
///
/// Extends DefaultApplication which registers all standard engine
/// subsystems (input, scene, physics, animation, audio, navigation, UI,
/// render) and owns ResourceSystem, ShaderSystem, FontService, and the
/// builtin:// asset mount.
///
/// Hosted by ApplicationHost (standalone game) or - in a later phase -
/// the editor when it loads the TowerDefense project at edit time. Owns the
/// per-game state; the App now just drives per-frame input via OnUpdate
/// and delegates everything else here.
class TowerDefenseModule : DefaultApplication
{
	// Game subsystem
	private GameSubsystem mGameSub;

	// Scene
	private Scene mScene;

	// Model manifest cached from <ProjectAssetDirectory>/models.manifest.
	// Bootstrap (TowerDefense.Bootstrap) writes this file from the FBX
	// import; runtime only reads it for resolving model names -> resource
	// refs when spawning towers / placing enemies.
	private ModelManifest mManifest ~ delete _;

	// Cached project mount + index (owned by module, registered with
	// ResourceSystem for the "project://" scheme).
	private FileSystemMount mProjectMount ~ delete _;
	private InMemoryResourceIndex mProjectIndex ~ delete _;

	// Camera
	private TDCameraController mCamera = new .() ~ delete _;

	// Tower placement
	private TowerPlacement mTowerPlacement = new .() ~ delete _;
	private ComponentTypeRegistry mTypeRegistry = new .() ~ delete _;

	// UI
	private HUDManager mHUD = new .() ~ delete _;
	private MainMenuUI mMainMenu = new .() ~ delete _;
	private GameOverUI mGameOverUI = new .() ~ delete _;
	private PauseUI mPauseUI = new .() ~ delete _;

	// Audio
	private GameAudio mGameAudio = new .() ~ delete _;

	// Particles
	private ParticleEffects mParticleEffects = new .() ~ delete _;

	// Backref so OnUpdate (still on TowerDefenseApp during transition)
	// can reach the module's per-frame state via public properties.
	public Scene Scene => mScene;
	public GameSubsystem GameSub => mGameSub;
	public TDCameraController Camera => mCamera;
	public TowerPlacement TowerPlacement => mTowerPlacement;
	public PauseUI PauseUI => mPauseUI;
	public ParticleEffects ParticleEffects => mParticleEffects;

	// ==================== Configuration ====================

	public override ApplicationSettings Settings() => .() { Title = "Tower Defense", Width = 1600, Height = 900, EnableShaderCache = true };

	public override void Configure(Sedulous.Runtime.Client.IApplicationHost host)
	{
		base.Configure(host);

		let context = host.Ctx;

		// Register messaging subsystem (drains at -500)
		context.RegisterSubsystem<MessagingSubsystem>(new MessagingSubsystem());

		// Register game subsystem (state + scene injection at -200)
		mGameSub = new GameSubsystem();
		context.RegisterSubsystem<GameSubsystem>(mGameSub);

		// Models and Resources will be set in OnStartup after they're available
	}

	// ==================== Startup ====================

	public override void OnStartup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		base.OnStartup(host);

		// Tower Defense doesn't have host-persistent state that needs
		// non-runtime initialisation - all per-game-launch work lives in
		// OnLaunch. The editor invokes Configure / OnStartup at edit time
		// to register subsystems + component types, but never fires
		// OnLaunch at edit time.
	}

	// ==================== Launch (standalone or editor Play) ====================

	public override void OnLaunch(Sedulous.Runtime.Client.IApplicationHost host)
	{
		Console.WriteLine("=== Tower Defense OnLaunch ===");

		let context = host.Ctx;
		let resourceSystem = mResourceSystem;

		// Project assets directory exposed by the host. Standalone hosts
		// derive it from RuntimeDirectory (cwd's parent + assets/); the
		// editor returns the currently open project's directory. Read
		// from the host dynamically so the editor's late project open
		// is reflected.
		let assetsDir = host.ProjectAssetDirectory;
		let registryPath = scope String();
		Path.InternalCombine(registryPath, assetsDir, "project.registry");
		let scenePath = scope String();
		Path.InternalCombine(scenePath, assetsDir, "gamescene.scene");
		let manifestPath = scope String();
		Path.InternalCombine(manifestPath, assetsDir, "models.manifest");

		if (!File.Exists(registryPath) || !File.Exists(scenePath) || !File.Exists(manifestPath))
		{
			Console.WriteLine("ERROR: TowerDefense cooked assets missing under {}.", assetsDir);
			Console.WriteLine("       Run TowerDefense.Bootstrap once to import the Kenney FBX kit");
			Console.WriteLine("       and generate the gamescene + manifest + prefabs.");
			return;
		}

		LoadFromCache(host, assetsDir, manifestPath);

		// Wire manifest and resource infrastructure to tower placement
		mTowerPlacement.Manifest = mManifest;
		mTowerPlacement.ResourceSystem = resourceSystem;
		mTowerPlacement.SerializerProvider = resourceSystem.SerializerProvider;
		mTowerPlacement.TypeRegistry = mTypeRegistry;

		// Camera setup (both paths)
		mCamera.LookTarget = .(6, 0, 6);
		mCamera.Zoom = 14.0f;
		mCamera.ApplyToScene(mScene);

		// Reduce ambient lighting via scene render settings
		if (let renderSettings = mScene.GetModule<RenderSceneModule>())
			renderSettings.AmbientColor = .(0.05f, 0.05f, 0.08f);

		// Set up UI
		SetupUI(host);

		// Set up audio
		let audioSub = context.GetSubsystem<AudioSubsystem>();
		let messaging = context.GetSubsystem<MessagingSubsystem>();
		if (audioSub != null)
			mGameAudio.Initialize(audioSub, messaging?.Bus);

		// Set up particle effects
		let assetDir = scope String();
		GetAssetPath("", assetDir);
		mParticleEffects.Initialize(mScene, messaging?.Bus, resourceSystem, assetDir);

		// Reset gameplay state at every launch so a second OnLaunch
		// (editor play/stop cycle, or standalone restart) doesn't inherit
		// the previous run's gold / lives / phase / game speed / tower
		// selection.
		mGameSub.ResetGame();
		mGameSub.SetPhase(.MainMenu);
		mTowerPlacement.Reset();

		// Hand the gameplay scene to GameSubsystem so its Update starts running.
		// Until this point GameSubsystem.Update has been a no-op (mScene null),
		// which is what keeps it from clobbering editor scenes' SimulationEnabled.
		mGameSub.SetScene(mScene);

		// Initialize the wave system against the game scene's enemy
		// manager. GameSubsystem.OnSceneCreated injects the three
		// gameplay component managers into every scene (so the editor
		// can author them at edit time), but the wave runner's per-game
		// state and bus subscriptions are scoped to the play session
		// only and live here. Mirrored in OnExit.
		mGameSub.Waves.Initialize(messaging?.Bus, mGameSub.EnemyMgr);

		Console.WriteLine("=== Tower Defense Ready ===");
	}

	/// Subsequent runs: load from cached files, no FBX import.
	private void LoadFromCache(Sedulous.Runtime.Client.IApplicationHost host, StringView cacheDir, StringView manifestPath)
	{
		Console.WriteLine("[Startup] Loading from cache...");

		let sceneSub = host.Ctx.GetSubsystem<SceneSubsystem>();
		let resourceSystem = mResourceSystem;

		// Mount the cache directory under "project://" and load its identity index
		// through the same mount so all reads route through the VFS.
		mProjectMount = new FileSystemMount(cacheDir);
		resourceSystem.Mount("project", mProjectMount);

		mProjectIndex = new InMemoryResourceIndex();
		if (mProjectMount.Exists("project.registry"))
		{
			let regStream = mProjectMount.Open("project.registry");
			if (regStream case .Ok(let s))
			{
				defer delete s;
				mProjectIndex.DeserializeFrom(s);
			}
		}
		resourceSystem.AddIndex(mProjectIndex);

		// Load model manifest and wire to game subsystem
		mManifest = new ModelManifest();
		mManifest.LoadFromFile(manifestPath);
		mGameSub.Manifest = mManifest;

		// Create scene (triggers ISceneAware - component managers get manifest)
		mScene = sceneSub.CreateScene("GameScene");
		RuntimeScene = mScene;

		// Deserialize scene from file through the project mount.
		let provider = resourceSystem.SerializerProvider;
		let fileText = scope String();
		{
			let openResult = mProjectMount.Open("gamescene.scene");
			if (openResult case .Err) return;
			let stream = openResult.Value;
			defer delete stream;
			let len = (int)stream.Length;
			if (len > 0)
			{
				let buf = scope uint8[len];
				if (stream.TryRead(.(&buf[0], len)) case .Err) return;
				fileText.Append((char8*)&buf[0], len);
			}
		}
		let reader = provider.CreateReader(fileText);
		defer delete reader;

		let typeReg = scope ComponentTypeRegistry();
		let sceneSerializer = scope SceneSerializer(typeReg, provider, resourceSystem);
		let sceneRes = scope SceneResource();
		sceneRes.Scene = mScene;
		sceneRes.SceneSerializer = sceneSerializer;
		sceneRes.Serialize(reader);

		// Find camera entity by name
		for (let entity in mScene.Entities)
		{
			if (mScene.GetEntityName(entity) == "Camera")
			{
				mCamera.CameraEntity = entity;
				break;
			}
		}

		// Init map data without building entities (scene already has them)
		mGameSub.Map.InitMapData(MapData.CreateMap1());
		mGameSub.UpdateWaypoints();

		Console.WriteLine("[Startup] Loaded from cache");
	}


	// ==================== Per-frame tick ====================

	public override void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		if (mScene == null)
			return;

		// Clean up expired particle effects
		mParticleEffects.Update(deltaTime);

		// Pull devices from the host, not shell directly. Standalone hosts
		// Pull devices from the host, not shell directly. Standalone hosts
		// passthrough to shell.InputManager; the editor wraps these so
		// the cursor coords land in the page-viewport's local space and
		// keyboard / hotkeys gate on viewport focus.
		let keyboard = host.Keyboard;
		let mouse = host.Mouse;
		if (keyboard == null || mouse == null) return;

		// Camera controls (always available except menu)
		if (mGameSub.Phase != .MainMenu)
		{
			mCamera.Update(deltaTime, keyboard, mouse);
			mCamera.ApplyToScene(mScene);
		}

		// Pause toggle (P or Escape during gameplay)
		if (keyboard.IsKeyPressed(.P) || keyboard.IsKeyPressed(.Escape))
		{
			if (mGameSub.IsGameplayPhase)
			{
				mGameSub.PauseGame();
				let uiSub = host.Ctx.GetSubsystem<EngineUISubsystem>();
				if (uiSub?.ScreenView != null)
					mPauseUI.Show();
			}
			else if (mGameSub.Phase == .Paused)
			{
				mGameSub.ResumeGame();
				mPauseUI.Hide();
			}
		}

		// Gameplay input (active gameplay phases only)
		if (mGameSub.IsGameplayPhase)
		{
			// Space to start next wave
			if (keyboard.IsKeyPressed(.Space) && (mGameSub.Phase == .WaitingToStart || mGameSub.Phase == .WavePaused))
				StartWave();

			// Tower selection (1-4 keys, 0 to deselect)
			if (keyboard.IsKeyPressed(.Num1)) { mTowerPlacement.SelectedType = .Ballista; }
			if (keyboard.IsKeyPressed(.Num2)) { mTowerPlacement.SelectedType = .Cannon; }
			if (keyboard.IsKeyPressed(.Num3)) { mTowerPlacement.SelectedType = .Catapult; }
			if (keyboard.IsKeyPressed(.Num4)) { mTowerPlacement.SelectedType = .Turret; }
			if (keyboard.IsKeyPressed(.Num0)) { mTowerPlacement.SelectedType = null; }

			// Tower placement (mouse click on grid). Polls Shell.Mouse - in
			// the editor that's window-space coordinates, so clicks won't
			// align with the page viewport until we abstract IMouse per
			// host. Tracked under Editor Roadmap Phase 6.
			mTowerPlacement.Update(mouse, mScene, mGameSub, mGameSub.TowerMgr, mCamera.CameraEntity);

			// Debug draws + health bars target the scene's pipeline-specific
			// DebugDraw so they show up wherever the scene is being rendered
			// (the standalone swapchain pipeline OR the editor's
			// GameEditorPage pipeline).
			let sceneRenderer = host.Ctx.GetSubsystemByInterface<ISceneRenderer>();
			let pipeline = sceneRenderer?.GetPipeline(mScene);
			if (pipeline?.DebugDraw != null)
			{
				mTowerPlacement.DrawDebug(pipeline.DebugDraw, mGameSub);

				// Health bars - billboard using camera vectors
				let offsetY = mCamera.Zoom * Math.Cos(mCamera.ViewAngle);
				let offsetZ = mCamera.Zoom * Math.Sin(mCamera.ViewAngle);
				let camPos = mCamera.LookTarget + Vector3(0, offsetY, offsetZ);
				let camFwd = Vector3.Normalize(mCamera.LookTarget - camPos);
				let camRight = Vector3.Normalize(Vector3.Cross(camFwd, .(0, 1, 0)));
				let camUp = Vector3.Cross(camRight, camFwd);
				mGameSub.EnemyMgr?.DrawHealthBars(pipeline.DebugDraw, camRight, camUp);
			}
		}
	}

	// ==================== Exit (mirror of OnLaunch) ====================

	public override void OnExit(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// Drop the scene reference before tear-down so GameSubsystem.Update
		// returns to its dormant no-op state if anything keeps ticking
		// during shutdown.
		mGameSub.SetScene(null);

		// Drop the wave runner's bus subscriptions before the message
		// bus survives into edit-mode. Mirror of the Waves.Initialize
		// at the end of OnLaunch.
		mGameSub.Waves.Shutdown();

		// Clean up effects and audio
		mParticleEffects.Shutdown();
		mGameAudio.Shutdown();

		// Clean up UI subscriptions AND detach UI views from the screen
		// view tree. Each UI's Setup re-creates its root panel; without
		// removing the prior one from EngineUISubsystem.ScreenView.Root
		// every play/stop cycle stacks another ghost overlay on top.
		let messaging = host.Ctx.GetSubsystem<MessagingSubsystem>();
		let bus = messaging?.Bus;
		let uiSub = host.Ctx.GetSubsystem<EngineUISubsystem>();
		let screenRoot = uiSub?.ScreenView?.Root;
		mHUD.Shutdown(bus, screenRoot);
		mGameOverUI.Shutdown(bus, screenRoot);
		mPauseUI.Shutdown(screenRoot);
		mMainMenu.Shutdown(screenRoot);

		// Tear down everything OnLaunch built so the next OnLaunch starts
		// from a clean slate. Without this the editor leaks a FileSystemMount
		// + index per play/stop/play cycle (and the second OnLaunch warns
		// 'A mount is already registered for scheme project').
		let context = host.Ctx;
		let sceneSub = context.GetSubsystem<SceneSubsystem>();
		if (mScene != null)
		{
			sceneSub?.DestroyScene(mScene);
			mScene = null;
			RuntimeScene = null;
		}

		let resourceSystem = mResourceSystem;
		if (mProjectIndex != null)
		{
			resourceSystem.RemoveIndex(mProjectIndex);
			delete mProjectIndex;
			mProjectIndex = null;
		}
		if (mProjectMount != null)
		{
			resourceSystem.Unmount("project");
			delete mProjectMount;
			mProjectMount = null;
		}
		if (mManifest != null)
		{
			delete mManifest;
			mManifest = null;
		}
	}

	// ==================== Shutdown ====================

	public override void OnShutdown(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// No host-persistent teardown - everything Tower Defense owns is
		// allocated lazily in OnLaunch and released in OnExit.

		base.OnShutdown(host);
	}

	// ==================== UI Setup ====================

	private void SetupUI(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let uiSub = host.Ctx.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView == null)
			return;

		let root = uiSub.ScreenView.Root;
		let messaging = host.Ctx.GetSubsystem<MessagingSubsystem>();
		let bus = messaging?.Bus;

		// HUD (DockLayout with top and bottom bars, fills screen). Tower
		// preview images come from cooked ImageResources loaded via the
		// host's ResourceSystem - the HUD constructs each URI by
		// concatenating the weapon-model name onto a fixed prefix.
		mHUD.Setup(bus, mGameSub, mTowerPlacement, mResourceSystem);
		mHUD.StartWaveCallback = new () => StartWave();
		mHUD.SetSpeedCallback = new (speed) => mGameSub.SetGameSpeed(speed);
		root.AddView(mHUD.Root, new LayoutParams() { Width = .Match, Height = .Match });

		// Game over / victory overlay (subscribes to GameOverMsg)
		mGameOverUI.Setup(root, bus,
			new () => RestartGame(),
			new () => { ReturnToMainMenu(host); }
		);

		// Pause overlay
		mPauseUI.Setup(root,
			new () => { mGameSub.ResumeGame(); mPauseUI.Hide(); },
			new () => { mPauseUI.Hide(); ReturnToMainMenu(host); },
			new () => { host.RequestExit(); }
		);

		// Main menu (full-screen overlay, shown on top of everything)
		mMainMenu.Setup(root, new () => StartGame(),
			new () => { host.RequestExit(); });
		mMainMenu.Show();
	}

	private void StartGame()
	{
		mMainMenu.Hide();
		mGameSub.SetPhase(.WaitingToStart);
		Console.WriteLine("[Game] Ready - place towers, then press Space or click Start Wave");
	}

	private void RestartGame()
	{
		// Reset game state
		mGameSub.ResetGame();
		mGameSub.SetPhase(.WaitingToStart);
		Console.WriteLine("[Game] Restarted");
	}

	private void ReturnToMainMenu(Sedulous.Runtime.Client.IApplicationHost host)
	{
		mGameSub.SetPhase(.MainMenu);
		mGameSub.ResetGame();

		let uiSub = host.Ctx.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView != null)
			mMainMenu.Show();
	}

	public void StartWave()
	{
		if (!mGameSub.Waves.IsWaveActive)
		{
			mGameSub.Waves.StartNextWave();
			mGameSub.SetPhase(.WaveInProgress);
		}
	}
}
