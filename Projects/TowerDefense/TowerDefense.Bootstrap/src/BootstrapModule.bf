namespace TowerDefense.Bootstrap;

using System;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine.Render;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Images.STB;
using Sedulous.Materials.Resources;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Runtime;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;
using Sedulous.Textures.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// IApplicationModule that runs once - imports the Kenney FBX kit, builds
/// the gameplay scene + tower prefabs from scratch, saves every cooked
/// asset (meshes, textures, materials, scene, prefabs, model manifest,
/// resource registry) under `<ProjectAssetDirectory>/`, then asks the
/// host to exit.
///
/// `TowerDefense.App` then runs in pure load-from-cache mode against the
/// files this module produced. Re-running the bootstrap is idempotent
/// in the sense that existing entries in the resource registry are
/// merged, not overwritten - editor-authored entries survive.
class BootstrapModule : IApplicationModule
{
	private ModelRegistry mModels = new .() ~ delete _;
	private ModelManifest mManifest ~ delete _;
	private Scene mScene;

	public Scene RuntimeScene => mScene;

	/// Fired once the bootstrap has finished writing every cooked asset.
	/// `BootstrapApp` wires this to `EngineApplication.Exit` so the host
	/// tears down on the next main-loop iteration. Owned by the module.
	public delegate void() ExitRequest ~ delete _;

	public void Configure(IApplicationHost host)
	{
		// Bootstrap needs no per-context subsystems beyond what
		// EngineApplication registers - SceneSubsystem + ResourceSystem
		// + RenderSubsystem are enough to assemble + serialise the
		// scene. Gameplay subsystems (GameSubsystem, MessagingSubsystem,
		// audio, etc.) are intentionally omitted; the bootstrap doesn't
		// run gameplay.
	}

	public void OnStartup(IApplicationHost host) { }

	public void OnLaunch(IApplicationHost host)
	{
		Console.WriteLine("=== TowerDefense Bootstrap ===");

		BuildFromScratch(host);
		ExportForEditor(host);
		ExportTowerPrefabs(host);

		// Manifest sits next to the scene/registry so the runtime can
		// resolve model names -> resource refs without re-importing FBX.
		let manifestPath = scope String();
		Path.InternalCombine(manifestPath, host.ProjectAssetDirectory, "models.manifest");
		mManifest.SaveToFile(manifestPath);
		Console.WriteLine("[Bootstrap] Saved manifest: {}", manifestPath);

		Console.WriteLine("=== Bootstrap complete ===");
		ExitRequest?.Invoke();
	}

	public void OnUpdate(IApplicationHost host, float deltaTime) { }
	public void OnFixedUpdate(IApplicationHost host, float fixedDeltaTime) { }

	public void OnExit(IApplicationHost host)
	{
		// Drop ref-counted handles + dedup state before the engine tears
		// down so refcounts read zero at shutdown.
		mModels.Shutdown();
	}

	public void OnShutdown(IApplicationHost host) { }

	// =========================================================================
	// First-run build
	// =========================================================================

	private void BuildFromScratch(IApplicationHost host)
	{
		Console.WriteLine("[Bootstrap] Building from scratch...");

		let sceneSub = host.Context.GetSubsystem<SceneSubsystem>();
		let resources = host.ResourceSystem;

		// Register the STB-backed image loader so the FBX importer can
		// decode PNG / JPG / TGA textures referenced from the FBX files.
		// Without this, ImageLoaderFactory.LoadImage returns Err, every
		// ImportedTexture's PixelData stays null, TextureResourceConverter
		// returns null, and the material's texture refs collapse to the
		// "texture_0" GUID-zero fallback (no texture written to disk and
		// the material is dangling at runtime). EngineApplication doesn't
		// register an image loader by default; the editor calls Initialize
		// in its own startup, so the same omission used to bite first-run
		// standalone TowerDefense too.
		STBImageLoader.Initialize();

		// Import all FBX models from the shared Kenney sample kit.
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

		mManifest = mModels.BuildManifest();

		// Assemble the gameplay scene's static dressing: camera, sun,
		// tile-built map. Component data only - no gameplay subsystems
		// run inside the bootstrap.
		mScene = sceneSub.CreateScene("GameScene");

		let cameraEntity = mScene.CreateEntity("Camera");
		let cameraMgr = mScene.GetModule<CameraComponentManager>();
		if (cameraMgr != null)
			cameraMgr.CreateComponent(cameraEntity);

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

		// Tower-defense map: spawn cells, path, end cell, decorations.
		let map = scope MapSystem();
		map.BuildMap(MapData.CreateMap1(), mScene, mManifest);
	}

	// =========================================================================
	// Save cooked assets
	// =========================================================================

	private void ExportForEditor(IApplicationHost host)
	{
		let outputDir = host.ProjectAssetDirectory;

		if (!Directory.Exists(outputDir))
			Directory.CreateDirectory(outputDir);

		let provider = scope OpenDDLSerializerProvider();

		// Writable mount over outputDir for all saves through the VFS.
		let mount = scope FileSystemMount(outputDir);

		// Merge into any existing registry so editor-authored entries
		// survive a re-bootstrap.
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

		// Meshes - names already carry the registry protocol from ModelRegistry.
		for (let loaded in mModels.[Friend]mLoadedModels)
		{
			if (loaded.MeshResource != null)
			{
				let locator = scope String()..AppendF("resources/{}.mesh", loaded.Name);
				if (SaveResourceText(loaded.MeshResource, mount, locator, provider) case .Ok)
				{
					index.Register(loaded.MeshResource.Id, scope $"project://{locator}");
					Console.WriteLine("[Bootstrap] Saved mesh: {}", loaded.Name);
				}
			}
		}

		// Deduped textures + materials.
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
				Console.WriteLine("[Bootstrap] Saved texture: {}", baseName);
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
				Console.WriteLine("[Bootstrap] Saved material: {}", baseName);
			}
		}

		// Scene - component ResourceRefs already carry registry protocol paths.
		if (mScene != null)
		{
			let typeReg = scope ComponentTypeRegistry();
			let sceneManager = scope SceneResourceManager(typeReg, provider);

			if (sceneManager.SaveScene(mScene, mount, "gamescene.scene") case .Ok(let guid))
			{
				index.Register(guid, "project://gamescene.scene");
				Console.WriteLine("[Bootstrap] Saved scene");
			}
		}

		// Updated registry.
		let indexStream = scope MemoryStream();
		if (index.SerializeTo(indexStream) case .Ok)
		{
			indexStream.Position = 0;
			mount.Save("project.registry", indexStream);
			Console.WriteLine("[Bootstrap] Saved registry");
		}
	}

	private void ExportTowerPrefabs(IApplicationHost host)
	{
		let outputDir = host.ProjectAssetDirectory;

		let provider = scope OpenDDLSerializerProvider();
		let typeReg = scope ComponentTypeRegistry();
		let prefabMgr = scope PrefabResourceManager(typeReg, provider);

		let mount = scope FileSystemMount(outputDir);

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

			// Skip if already exported.
			if (mount.Exists(prefabLocator))
				continue;

			let prefabScene = scope Scene();
			let meshMgr = new MeshComponentManager();
			prefabScene.AddModule(meshMgr);

			// Root: tower base.
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

			// Child: weapon.
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

			// Child of weapon: projectile spawn point. Empty entity -
			// position adjusted in the editor.
			let spawnPoint = prefabScene.CreateEntity("ProjectileSpawnPoint");
			prefabScene.SetParent(spawnPoint, weaponEntity);
			prefabScene.SetLocalTransform(spawnPoint, .() {
				Position = .(0, 0.1f, 0.3f), Rotation = .Identity, Scale = .One
			});

			if (prefabMgr.SavePrefab(prefabScene, mount, prefabLocator) case .Ok(let guid))
			{
				index.Register(guid, scope $"project://{prefabLocator}");
				Console.WriteLine("[Bootstrap] Saved tower prefab: tower_{}", towerName);
			}
		}

		let indexStream = scope MemoryStream();
		if (index.SerializeTo(indexStream) case .Ok)
		{
			indexStream.Position = 0;
			mount.Save("project.registry", indexStream);
		}
	}

	// =========================================================================
	// Helpers
	// =========================================================================

	/// Serialises a Resource's text representation to memory and writes
	/// it to `mount` at `locator`.
	private static Result<void> SaveResourceText(Resource resource, IWritableMount mount, StringView locator, ISerializerProvider provider)
	{
		let memStream = scope MemoryStream();
		if (resource.WriteToStream(memStream, provider) case .Err)
			return .Err;
		memStream.Position = 0;
		if (mount.Save(locator, memStream) case .Err)
			return .Err;
		return .Ok;
	}

	/// Extracts the base resource name from a registry protocol path.
	/// "project://resources/colormap.material" -> "colormap"
	/// "colormap" -> "colormap"
	private static void GetBaseResourceName(StringView name, String outName)
	{
		let protoIdx = name.IndexOf("://");
		StringView path = (protoIdx >= 0) ? name[(protoIdx + 3)...] : name;

		let slashIdx = path.LastIndexOf('/');
		StringView fileName = (slashIdx >= 0) ? path[(slashIdx + 1)...] : path;

		let dotIdx = fileName.LastIndexOf('.');
		if (dotIdx >= 0)
			outName.Set(fileName[...(dotIdx - 1)]);
		else
			outName.Set(fileName);
	}
}
