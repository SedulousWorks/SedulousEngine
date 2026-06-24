namespace TowerDefense;

using System;
using System.Collections;
using System.IO;
using Sedulous.Engine;
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
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Messaging.Runtime;
using Sedulous.Serialization.OpenDDL;
using Sedulous.UI;
using Sedulous.Runtime;

/// Composition root for the Tower Defense game.
///
/// Hosted by EngineApplication (standalone game) or - in a later phase -
/// the editor when it loads the TowerDefense project at edit time. Owns the
/// per-game state that used to live on TowerDefenseApp; the App now just
/// drives per-frame input via OnUpdate and delegates everything else here.
class TowerDefenseModule : IApplicationModule
{
	// Game subsystem
	private GameSubsystem mGameSub;

	// Scene
	private Scene mScene;

	// Model loading (first run only)
	private ModelRegistry mModels = new .() ~ delete _;

	// Model manifest (built from ModelRegistry or loaded from cache)
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
	public Scene RuntimeScene => mScene;
	public GameSubsystem GameSub => mGameSub;
	public TDCameraController Camera => mCamera;
	public TowerPlacement TowerPlacement => mTowerPlacement;
	public PauseUI PauseUI => mPauseUI;
	public ParticleEffects ParticleEffects => mParticleEffects;

	// ==================== Configuration ====================

	public void Configure(IApplicationHost host)
	{
		let context = host.Context;

		// Register messaging subsystem (drains at -500)
		context.RegisterSubsystem<MessagingSubsystem>(new MessagingSubsystem());

		// Register game subsystem (state + scene injection at -200)
		mGameSub = new GameSubsystem();
		context.RegisterSubsystem<GameSubsystem>(mGameSub);

		// Models and Resources will be set in OnStartup after they're available
	}

	// ==================== Startup ====================

	public void OnStartup(IApplicationHost host)
	{
		// Tower Defense doesn't have host-persistent state that needs
		// non-runtime initialisation - all per-game-launch work lives in
		// OnLaunch. The editor invokes Configure / OnStartup at edit time
		// to register subsystems + component types, but never fires
		// OnLaunch at edit time.
	}

	// ==================== Launch (standalone or editor Play) ====================

	public void OnLaunch(IApplicationHost host)
	{
		Console.WriteLine("=== Tower Defense OnLaunch ===");

		let context = host.Context;
		let resourceSystem = host.ResourceSystem;

		// Project assets directory at the TowerDefense project root, one
		// level up from the running exe's directory. Shared by .App and
		// the future .Editor exe so both see the same content.
		let assetsDir = scope String();
		GetProjectAssetsDir(host, assetsDir);
		let registryPath = scope String();
		Path.InternalCombine(registryPath, assetsDir, "project.registry");
		let scenePath = scope String();
		Path.InternalCombine(scenePath, assetsDir, "gamescene.scene");
		let manifestPath = scope String();
		Path.InternalCombine(manifestPath, assetsDir, "models.manifest");

		if (File.Exists(registryPath) && File.Exists(scenePath) && File.Exists(manifestPath))
			LoadFromCache(host, assetsDir, manifestPath);
		else
			BuildFromScratch(host, assetsDir);

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
		host.GetAssetPath("", assetDir);
		mParticleEffects.Initialize(mScene, messaging?.Bus, resourceSystem, assetDir);

		// Reset gameplay state at every launch so a second OnLaunch
		// (editor play/stop cycle, or standalone restart) doesn't inherit
		// the previous run's gold / lives / phase / game speed / tower
		// selection. WaveSystem.Initialize handles its own per-game state
		// reset on the OnSceneCreated side.
		mGameSub.ResetGame();
		mGameSub.SetPhase(.MainMenu);
		mTowerPlacement.Reset();

		// Hand the gameplay scene to GameSubsystem so its Update starts running.
		// Until this point GameSubsystem.Update has been a no-op (mScene null),
		// which is what keeps it from clobbering editor scenes' SimulationEnabled.
		mGameSub.SetScene(mScene);

		Console.WriteLine("=== Tower Defense Ready ===");
	}

	/// First run: import FBX models, build scene, save everything to cache.
	private void BuildFromScratch(IApplicationHost host, StringView cacheDir)
	{
		Console.WriteLine("[Startup] Building from scratch (first run)...");

		let sceneSub = host.Context.GetSubsystem<SceneSubsystem>();
		let resources = host.ResourceSystem;

		// Import all FBX models
		let assetPath = scope String();
		host.GetAssetPath("samples/models/kenney_tower-defense-kit/Models/FBX format", assetPath);
		mModels.Initialize(assetPath);
		mModels.RegistryName.Set("project");

		mModels.PreloadModels(resources, StringView[](
			// Tiles
			"tile", "tile-straight", "tile-rock",
			"tile-spawn-round", "tile-end-round",
			"tile-corner-round", "selection-a",
			// Enemies
			"enemy-ufo-a", "enemy-ufo-b", "enemy-ufo-c", "enemy-ufo-d",
			// Towers
			"tower-round-base", "tower-square-bottom-a",
			// Weapons
			"weapon-ballista", "weapon-cannon", "weapon-catapult", "weapon-turret",
			// Ammo
			"weapon-ammo-arrow", "weapon-ammo-cannonball", "weapon-ammo-boulder", "weapon-ammo-bullet"
		));

		// Build manifest from loaded models and wire to game subsystem
		mManifest = ModelManifest.BuildFromRegistry(mModels);
		mGameSub.Manifest = mManifest;

		// Create scene (triggers OnSceneCreated - component managers get manifest)
		mScene = sceneSub.CreateScene("GameScene");

		// Camera
		mCamera.CameraEntity = mScene.CreateEntity("Camera");
		let cameraMgr = mScene.GetModule<CameraComponentManager>();
		if (cameraMgr != null)
			cameraMgr.CreateComponent(mCamera.CameraEntity);

		// Directional light
		let lightEntity = mScene.CreateEntity("Sun");
		mScene.SetLocalTransform(lightEntity, Transform.CreateLookAt(.(10, 15, 10), .Zero));
		let lightMgr = mScene.GetModule<LightComponentManager>();
		if (lightMgr != null)
		{
			let lightHandle = lightMgr.CreateComponent(lightEntity);
			if (let light = lightMgr.Get(lightHandle))
			{
				light.Type = .Directional;
				light.Color = .(1.0f, 0.95f, 0.85f);
				light.Intensity = 1.2f;
				light.CastsShadows = true;
			}
		}

		// Build the map
		mGameSub.Map.BuildMap(MapData.CreateMap1(), mScene, mManifest);
		mGameSub.UpdateWaypoints();

		// Save everything to project assets
		ExportForEditor(host);
		ExportTowerPrefabs(host);

		// Also save manifest
		let manifestPath = scope String();
		Path.InternalCombine(manifestPath, cacheDir, "models.manifest");
		mManifest.SaveToFile(manifestPath);
		Console.WriteLine("[Startup] Saved manifest: {}", manifestPath);
	}

	/// Subsequent runs: load from cached files, no FBX import.
	private void LoadFromCache(IApplicationHost host, StringView cacheDir, StringView manifestPath)
	{
		Console.WriteLine("[Startup] Loading from cache...");

		let sceneSub = host.Context.GetSubsystem<SceneSubsystem>();
		let resourceSystem = host.ResourceSystem;

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

	/// Saves all loaded resources (meshes, materials, textures) and the scene
	/// to the project assets directory so they can be opened in the editor.
	private void ExportForEditor(IApplicationHost host)
	{
		let outputDir = scope String();
		GetProjectAssetsDir(host, outputDir);

		if (!Directory.Exists(outputDir))
			Directory.CreateDirectory(outputDir);

		let provider = scope OpenDDLSerializerProvider();

		// Writable mount over outputDir for all subsequent saves through the VFS.
		let mount = scope FileSystemMount(outputDir);

		// Load existing index and merge new entries (don't overwrite editor-created entries)
		let index = scope InMemoryResourceIndex();
		if (mount.Exists("project.registry"))
		{
			let regStream = mount.Open("project.registry");
			if (regStream case .Ok(let s))
			{
				defer delete s;
				index.DeserializeFrom(s);
			}
		}

		// Save meshes - names already have registry protocol from ModelRegistry
		for (let loaded in mModels.[Friend]mLoadedModels)
		{
			if (loaded.MeshResource != null)
			{
				let locator = scope String()..AppendF("resources/{}.mesh", loaded.Name);
				if (SaveResourceText(loaded.MeshResource, mount, locator, provider) case .Ok)
				{
					index.Register(loaded.MeshResource.Id, scope $"project://{locator}");
					Console.WriteLine("[Export] Saved mesh: {}", loaded.Name);
				}
			}
		}

		// Save deduped textures and materials
		let dedupCtx = mModels.[Friend]mDedupContext;
		for (let kv in dedupCtx.[Friend]mTextures)
		{
			let texRes = kv.value;
			let baseName = scope String();
			GetBaseResourceName(texRes.Name, baseName);
			let locator = scope String()..AppendF("resources/{}.texture", baseName);
			let sidecarName = scope String()..AppendF("{}.texture.bin", baseName);

			if (SaveResourceText(texRes, mount, locator, provider) case .Ok)
			{
				let sidecarLocator = scope String()..AppendF("resources/{}", sidecarName);
				let memStream = scope MemoryStream();
				if (texRes.WritePixelsToStream(memStream) case .Ok)
				{
					memStream.Position = 0;
					mount.Save(sidecarLocator, memStream);
				}
				index.Register(texRes.Id, scope $"project://{locator}");
				Console.WriteLine("[Export] Saved texture: {}", baseName);
			}
		}

		for (let kv in dedupCtx.[Friend]mMaterials)
		{
			let matRes = kv.value;
			let baseName = scope String();
			GetBaseResourceName(matRes.Name, baseName);
			let locator = scope String()..AppendF("resources/{}.material", baseName);
			if (SaveResourceText(matRes, mount, locator, provider) case .Ok)
			{
				index.Register(matRes.Id, scope $"project://{locator}");
				Console.WriteLine("[Export] Saved material: {}", baseName);
			}
		}

		// Save scene - component ResourceRefs already carry registry protocol paths
		if (mScene != null)
		{
			let typeReg = scope ComponentTypeRegistry();
			let sceneManager = scope SceneResourceManager(typeReg, provider);

			if (sceneManager.SaveScene(mScene, mount, "gamescene.scene") case .Ok(let guid))
			{
				index.Register(guid, "project://gamescene.scene");
				Console.WriteLine("[Export] Saved scene");
			}
		}

		// Save index
		let indexStream = scope MemoryStream();
		if (index.SerializeTo(indexStream) case .Ok)
		{
			indexStream.Position = 0;
			mount.Save("project.registry", indexStream);
			Console.WriteLine("[Export] Saved registry");
		}
	}

	/// Helper: serializes a Resource's text representation into memory and writes
	/// it to `mount` at `locator`.
	private static Result<void> SaveResourceText(Resource resource, IWritableMount mount, StringView locator, Sedulous.Serialization.ISerializerProvider provider)
	{
		let memStream = scope MemoryStream();
		if (resource.WriteToStream(memStream, provider) case .Err)
			return .Err;
		memStream.Position = 0;
		if (mount.Save(locator, memStream) case .Err)
			return .Err;
		return .Ok;
	}

	/// Exports tower prefabs to the project assets directory.
	/// Each prefab has: base mesh, weapon child, projectile spawn point placeholder.
	private void ExportTowerPrefabs(IApplicationHost host)
	{
		let outputDir = scope String();
		GetProjectAssetsDir(host, outputDir);

		let provider = scope OpenDDLSerializerProvider();
		let typeReg = scope ComponentTypeRegistry();
		let prefabMgr = scope PrefabResourceManager(typeReg, provider);

		// Writable mount over outputDir; saves create intermediate directories.
		let mount = scope FileSystemMount(outputDir);

		// Load existing index to merge
		let index = scope InMemoryResourceIndex();
		if (mount.Exists("project.registry"))
		{
			let regStream = mount.Open("project.registry");
			if (regStream case .Ok(let s))
			{
				defer delete s;
				index.DeserializeFrom(s);
			}
		}

		StringView[4] towerNames = .("ballista", "cannon", "catapult", "turret");
		TowerType[4] types = .(.Ballista, .Cannon, .Catapult, .Turret);
		for (int ti = 0; ti < 4; ti++)
		{
			let towerType = types[ti];
			let towerName = towerNames[ti];
			let stats = TowerStats.Get(towerType);

			let prefabLocator = scope String()..AppendF("prefabs/tower_{}.prefab", towerName);

			// Skip if already exported
			if (mount.Exists(prefabLocator))
				continue;

			// Create a temporary scene for the prefab
			let prefabScene = scope Scene();
			let meshMgr = new MeshComponentManager();
			prefabScene.AddModule(meshMgr);

			// Root: tower base
			let baseEntity = prefabScene.CreateEntity("TowerBase");
			prefabScene.SetLocalTransform(baseEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

			let baseEntry = mManifest.Get(stats.BaseModel);
			if (baseEntry != null)
			{
				let meshHandle = meshMgr.CreateComponent(baseEntity);
				if (let mesh = meshMgr.Get(meshHandle))
				{
					var meshRef = baseEntry.GetMeshRef();
					defer meshRef.Dispose();
					mesh.SetMeshRef(meshRef);
					for (int32 slot = 0; slot < baseEntry.MaterialCount; slot++)
					{
						var matRef = baseEntry.GetMaterialRef(slot);
						defer matRef.Dispose();
						mesh.SetMaterialRef(slot, matRef);
					}
				}
			}

			// Child: weapon
			let weaponEntity = prefabScene.CreateEntity("Weapon");
			prefabScene.SetParent(weaponEntity, baseEntity);
			prefabScene.SetLocalTransform(weaponEntity, .() {
				Position = .(0, 0.5f, 0), Rotation = .Identity, Scale = .One
			});

			let weaponEntry = mManifest.Get(stats.WeaponModel);
			if (weaponEntry != null)
			{
				let meshHandle = meshMgr.CreateComponent(weaponEntity);
				if (let mesh = meshMgr.Get(meshHandle))
				{
					var meshRef = weaponEntry.GetMeshRef();
					defer meshRef.Dispose();
					mesh.SetMeshRef(meshRef);
					for (int32 slot = 0; slot < weaponEntry.MaterialCount; slot++)
					{
						var matRef = weaponEntry.GetMaterialRef(slot);
						defer matRef.Dispose();
						mesh.SetMaterialRef(slot, matRef);
					}
				}
			}

			// Child of weapon: projectile spawn point (empty entity - position adjusted in editor)
			let spawnPoint = prefabScene.CreateEntity("ProjectileSpawnPoint");
			prefabScene.SetParent(spawnPoint, weaponEntity);
			prefabScene.SetLocalTransform(spawnPoint, .() {
				Position = .(0, 0.1f, 0.3f), Rotation = .Identity, Scale = .One
			});

			// Save prefab
			if (prefabMgr.SavePrefab(prefabScene, mount, prefabLocator) case .Ok(let guid))
			{
				index.Register(guid, scope $"project://{prefabLocator}");
				Console.WriteLine("[Export] Saved tower prefab: tower_{}", towerName);
			}
		}

		// Save updated index
		let indexStream = scope MemoryStream();
		if (index.SerializeTo(indexStream) case .Ok)
		{
			indexStream.Position = 0;
			mount.Save("project.registry", indexStream);
		}
	}

	/// Resolves the TowerDefense project's assets/ directory: walks one
	/// level up from the running exe's directory (RuntimeDirectory points
	/// at the exe project, assets/ sits at the parent TowerDefense root).
	private static void GetProjectAssetsDir(IApplicationHost host, String outDir)
	{
		let projectRoot = Path.GetDirectoryPath(host.RuntimeDirectory, .. scope .());
		Path.InternalCombine(outDir, projectRoot, "assets");
	}

	/// Extracts the base resource name from a registry protocol path.
	/// "project://resources/colormap.material" -> "colormap"
	/// "colormap" -> "colormap"
	private static void GetBaseResourceName(StringView name, String outName)
	{
		// Strip protocol prefix
		let protoIdx = name.IndexOf("://");
		StringView path = (protoIdx >= 0) ? name[(protoIdx + 3)...] : name;

		// Strip directory prefix
		let slashIdx = path.LastIndexOf('/');
		StringView fileName = (slashIdx >= 0) ? path[(slashIdx + 1)...] : path;

		// Strip extension
		let dotIdx = fileName.LastIndexOf('.');
		if (dotIdx >= 0)
			outName.Set(fileName[...(dotIdx - 1)]);
		else
			outName.Set(fileName);
	}

	// ==================== Per-frame tick ====================

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		if (mScene == null)
			return;

		// Clean up expired particle effects
		mParticleEffects.Update(deltaTime);

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
				let uiSub = host.Context.GetSubsystem<EngineUISubsystem>();
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
			let sceneRenderer = host.Context.GetSubsystemByInterface<ISceneRenderer>();
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

	public void OnExit(IApplicationHost host)
	{
		// Drop the scene reference before tear-down so GameSubsystem.Update
		// returns to its dormant no-op state if anything keeps ticking
		// during shutdown.
		mGameSub.SetScene(null);

		// Clean up effects and audio
		mParticleEffects.Shutdown();
		mGameAudio.Shutdown();

		// Clean up UI subscriptions AND detach UI views from the screen
		// view tree. Each UI's Setup re-creates its root panel; without
		// removing the prior one from EngineUISubsystem.ScreenView.Root
		// every play/stop cycle stacks another ghost overlay on top.
		let messaging = host.Context.GetSubsystem<MessagingSubsystem>();
		let bus = messaging?.Bus;
		let uiSub = host.Context.GetSubsystem<EngineUISubsystem>();
		let screenRoot = uiSub?.ScreenView?.Root;
		mHUD.Shutdown(bus, screenRoot);
		mGameOverUI.Shutdown(bus, screenRoot);
		mPauseUI.Shutdown(screenRoot);
		mMainMenu.Shutdown(screenRoot);

		mModels.Shutdown();

		// Tear down everything OnLaunch built so the next OnLaunch starts
		// from a clean slate. Without this the editor leaks a FileSystemMount
		// + index per play/stop/play cycle (and the second OnLaunch warns
		// 'A mount is already registered for scheme project').
		let context = host.Context;
		let sceneSub = context.GetSubsystem<SceneSubsystem>();
		if (mScene != null)
		{
			sceneSub?.DestroyScene(mScene);
			mScene = null;
		}

		let resourceSystem = host.ResourceSystem;
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

	public void OnShutdown(IApplicationHost host)
	{
		// No host-persistent teardown - everything Tower Defense owns is
		// allocated lazily in OnLaunch and released in OnExit.
	}

	// ==================== UI Setup ====================

	private void SetupUI(IApplicationHost host)
	{
		let uiSub = host.Context.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView == null)
			return;

		let root = uiSub.ScreenView.Root;
		let messaging = host.Context.GetSubsystem<MessagingSubsystem>();
		let bus = messaging?.Bus;

		// Resolve preview image directory.
		let previewDir = scope String();
		host.GetAssetPath("samples/models/kenney_tower-defense-kit/Previews", previewDir);

		// HUD (DockLayout with top and bottom bars, fills screen)
		mHUD.Setup(bus, mGameSub, mTowerPlacement, previewDir);
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
			new () => { mPauseUI.Hide(); ReturnToMainMenu(host); }
		);

		// Main menu (full-screen overlay, shown on top of everything)
		mMainMenu.Setup(root, new () => StartGame());
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

	private void ReturnToMainMenu(IApplicationHost host)
	{
		mGameSub.SetPhase(.MainMenu);
		mGameSub.ResetGame();

		let uiSub = host.Context.GetSubsystem<EngineUISubsystem>();
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
