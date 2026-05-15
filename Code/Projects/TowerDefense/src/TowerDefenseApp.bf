namespace TowerDefense;

using System;
using Sedulous.Engine.App;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Runtime;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Shell.Input;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
using Sedulous.Messaging.Runtime;
using Sedulous.Engine;
using Sedulous.Engine.UI;
using Sedulous.Engine.Audio;
using Sedulous.UI;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Serialization.OpenDDL;
using Sedulous.Engine.Core.Resources;
using System.IO;
using System.Collections;

class TowerDefenseApp : EngineApplication
{
	// Game subsystem
	private GameSubsystem mGameSub;

	// Scene
	private Scene mScene;

	// Model loading (first run only)
	private ModelRegistry mModels = new .() ~ delete _;

	// Model manifest (both paths - built from ModelRegistry or loaded from cache)
	private ModelManifest mManifest ~ delete _;

	// Cached project mount + index (owned by app, registered with ResourceSystem
	// for the "project://" scheme).
	private FileSystemMount mProjectMount ~ delete _;
	private InMemoryResourceIndex mProjectIndex ~ delete _;

	// Camera
	private TDCameraController mCamera = new .() ~ delete _;

	// Tower placement
	private TowerPlacement mTowerPlacement = new .() ~ delete _;

	// UI
	private HUDManager mHUD = new .() ~ delete _;
	private MainMenuUI mMainMenu = new .() ~ delete _;
	private GameOverUI mGameOverUI = new .() ~ delete _;
	private PauseUI mPauseUI = new .() ~ delete _;

	// Audio
	private GameAudio mGameAudio = new .() ~ delete _;

	// Particles
	private ParticleEffects mParticleEffects = new .() ~ delete _;

	// ==================== Configuration ====================

	protected override void OnConfigure(Context context)
	{
		// Register messaging subsystem (drains at -500)
		context.RegisterSubsystem<MessagingSubsystem>(new MessagingSubsystem());

		// Register game subsystem (state + scene injection at -200)
		mGameSub = new GameSubsystem();
		context.RegisterSubsystem<GameSubsystem>(mGameSub);

		// Models and Resources will be set in OnStartup after they're available
	}

	// ==================== Startup ====================

	protected override void OnStartup()
	{
		Console.WriteLine("=== Tower Defense OnStartup ===");

		SDLImageLoader.Initialize();
		STBImageLoader.Initialize();

		// Project assets directory (RuntimeDirectory/assets)
		let assetsDir = scope String();
		Path.InternalCombine(assetsDir, RuntimeDirectory, "assets");
		let registryPath = scope String();
		Path.InternalCombine(registryPath, assetsDir, "project.registry");
		let scenePath = scope String();
		Path.InternalCombine(scenePath, assetsDir, "gamescene.scene");
		let manifestPath = scope String();
		Path.InternalCombine(manifestPath, assetsDir, "models.manifest");

		if (File.Exists(registryPath) && File.Exists(scenePath) && File.Exists(manifestPath))
			LoadFromCache(assetsDir, manifestPath);
		else
			BuildFromScratch(assetsDir);

		// Wire manifest to tower placement
		mTowerPlacement.Manifest = mManifest;

		// Camera setup (both paths)
		mCamera.LookTarget = .(6, 0, 6);
		mCamera.Zoom = 14.0f;
		mCamera.ApplyToScene(mScene);

		// Reduce ambient lighting via scene render settings
		if (let renderSettings = mScene.GetModule<RenderSceneModule>())
			renderSettings.AmbientColor = .(0.05f, 0.05f, 0.08f);

		// Set up UI
		SetupUI();

		// Set up audio
		let audioSub = Context.GetSubsystem<AudioSubsystem>();
		let messaging = Context.GetSubsystem<MessagingSubsystem>();
		if (audioSub != null)
			mGameAudio.Initialize(audioSub, messaging?.Bus);

		// Set up particle effects
		let assetDir = scope String();
		GetAssetPath("", assetDir);
		mParticleEffects.Initialize(mScene, messaging?.Bus, ResourceSystem, assetDir);

		Console.WriteLine("=== Tower Defense Ready ===");
	}

	/// First run: import FBX models, build scene, save everything to cache.
	private void BuildFromScratch(StringView cacheDir)
	{
		Console.WriteLine("[Startup] Building from scratch (first run)...");

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let resources = ResourceSystem;

		// Import all FBX models
		let assetPath = scope String();
		GetAssetPath("samples/models/kenney_tower-defense-kit/Models/FBX format", assetPath);
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
		ExportForEditor();
		ExportTowerPrefabs();

		// Also save manifest
		let manifestPath = scope String();
		Path.InternalCombine(manifestPath, cacheDir, "models.manifest");
		mManifest.SaveToFile(manifestPath);
		Console.WriteLine("[Startup] Saved manifest: {}", manifestPath);
	}

	/// Subsequent runs: load from cached files, no FBX import.
	private void LoadFromCache(StringView cacheDir, StringView manifestPath)
	{
		Console.WriteLine("[Startup] Loading from cache...");

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();

		// Mount the cache directory under "project://" and load its identity index
		// through the same mount so all reads route through the VFS.
		mProjectMount = new FileSystemMount(cacheDir);
		ResourceSystem.Mount("project", mProjectMount);

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
		ResourceSystem.AddIndex(mProjectIndex);

		// Load model manifest and wire to game subsystem
		mManifest = new ModelManifest();
		mManifest.LoadFromFile(manifestPath);
		mGameSub.Manifest = mManifest;

		// Create scene (triggers ISceneAware - component managers get manifest)
		mScene = sceneSub.CreateScene("GameScene");

		// Deserialize scene from file through the project mount.
		let provider = ResourceSystem.SerializerProvider;
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
		let sceneRes = scope SceneResource();
		sceneRes.Scene = mScene;
		sceneRes.TypeRegistry = typeReg;
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
	private void ExportForEditor()
	{
		let outputDir = scope String();
		Path.InternalCombine(outputDir, RuntimeDirectory, "assets");

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
	private void ExportTowerPrefabs()
	{
		let outputDir = scope String();
		Path.InternalCombine(outputDir, RuntimeDirectory, "assets");

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
			let emptyParams = scope List<ExposedParameterDescriptor>();
			if (prefabMgr.SavePrefab(prefabScene, emptyParams, mount, prefabLocator) case .Ok(let guid))
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

	// ==================== Update ====================

	protected override void OnUpdate(float deltaTime)
	{
		if (mScene == null)
			return;

		// Clean up expired particle effects
		mParticleEffects.Update(deltaTime);

		let keyboard = mShell.InputManager.Keyboard;
		let mouse = mShell.InputManager.Mouse;

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
				let uiSub = Context.GetSubsystem<EngineUISubsystem>();
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
			{
				StartWave();
			}

			// Tower selection (1-4 keys, 0 to deselect)
			if (keyboard.IsKeyPressed(.Num1)) { mTowerPlacement.SelectedType = .Ballista; }
			if (keyboard.IsKeyPressed(.Num2)) { mTowerPlacement.SelectedType = .Cannon; }
			if (keyboard.IsKeyPressed(.Num3)) { mTowerPlacement.SelectedType = .Catapult; }
			if (keyboard.IsKeyPressed(.Num4)) { mTowerPlacement.SelectedType = .Turret; }
			if (keyboard.IsKeyPressed(.Num0)) { mTowerPlacement.SelectedType = null; }

			// Tower placement (mouse click on grid)
			mTowerPlacement.Update(mouse, mScene, mGameSub, mGameSub.TowerMgr, mCamera.CameraEntity);

			// Draw debug markers on tower slots and hover
			let renderSub = Context.GetSubsystem<RenderSubsystem>();
			if (renderSub != null)
			{
				mTowerPlacement.DrawDebug(renderSub.DebugDraw, mGameSub);

				// Health bars - billboard using camera vectors
			let offsetY = mCamera.Zoom * Math.Cos(mCamera.ViewAngle);
			let offsetZ = mCamera.Zoom * Math.Sin(mCamera.ViewAngle);
			let camPos = mCamera.LookTarget + Vector3(0, offsetY, offsetZ);
			let camFwd = Vector3.Normalize(mCamera.LookTarget - camPos);
			let camRight = Vector3.Normalize(Vector3.Cross(camFwd, .(0, 1, 0)));
			let camUp = Vector3.Cross(camRight, camFwd);
			mGameSub.EnemyMgr?.DrawHealthBars(renderSub.DebugDraw, camRight, camUp);
			}
		}
	}

	// ==================== Shutdown ====================

	protected override void OnShutdown()
	{
		// Clean up effects and audio
		mParticleEffects.Shutdown();
		mGameAudio.Shutdown();

		// Clean up UI message subscriptions
		let messaging = Context.GetSubsystem<MessagingSubsystem>();
		let bus = messaging?.Bus;
		mHUD.Shutdown(bus);
		mGameOverUI.Shutdown(bus);

		mModels.Shutdown();
	}

	// ==================== UI Setup ====================

	private void SetupUI()
	{
		let uiSub = Context.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView == null)
			return;

		let root = uiSub.ScreenView.Root;
		let messaging = Context.GetSubsystem<MessagingSubsystem>();
		let bus = messaging?.Bus;

		// Resolve preview image directory.
		let previewDir = scope String();
		GetAssetPath("samples/models/kenney_tower-defense-kit/Previews", previewDir);

		// HUD (DockLayout with top and bottom bars, fills screen)
		mHUD.Setup(bus, mGameSub, mTowerPlacement, previewDir);
		mHUD.StartWaveCallback = new () => StartWave();
		mHUD.SetSpeedCallback = new (speed) => mGameSub.SetGameSpeed(speed);
		root.AddView(mHUD.Root, new LayoutParams() { Width = .Match, Height = .Match });

		// Game over / victory overlay (subscribes to GameOverMsg)
		mGameOverUI.Setup(root, bus,
			new () => RestartGame(),
			new () => { ReturnToMainMenu(); }
		);

		// Pause overlay
		mPauseUI.Setup(root,
			new () => { mGameSub.ResumeGame(); mPauseUI.Hide(); },
			new () => { mPauseUI.Hide(); ReturnToMainMenu(); }
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

	private void ReturnToMainMenu()
	{
		mGameSub.SetPhase(.MainMenu);
		mGameSub.ResetGame();

		let uiSub = Context.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView != null)
			mMainMenu.Show();
	}

	private void StartWave()
	{
		if (!mGameSub.Waves.IsWaveActive)
		{
			mGameSub.Waves.StartNextWave();
			mGameSub.SetPhase(.WaveInProgress);
		}
	}
}
