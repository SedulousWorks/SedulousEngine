namespace EngineSandbox;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Models;
using Sedulous.Models.GLTF;

/// Loads and places environment models (Nature Kit, Tower Defense Kit)
/// to build the sandbox scene's ground and decoration.
class EnvironmentBuilder
{
	private Scene mScene;
	private ResourceSystem mResources;

	// Model cache and dedup
	private List<LoadedModel> mLoadedModels = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<String, LoadedModel> mModelCache = new .() ~ { for (let key in _.Keys) delete key; delete _; };
	private ImportDeduplicationContext mDedupContext = new .() ~ { _.ReleaseAllRefs(); delete _; };

	// Base asset paths (set during Build)
	private String mNatureKitPath = new .() ~ delete _;

	public this(Scene scene, ResourceSystem resources)
	{
		mScene = scene;
		mResources = resources;
	}

	/// Release resource refs. Call from OnShutdown before this object is deleted.
	public void Shutdown()
	{
		for (let loaded in mLoadedModels)
			loaded.ReleaseRefs();
	}

	/// Build the full environment. Call from OnStartup after scene is created.
	/// natureKitPath should be the resolved absolute path to the Nature Kit GLTF directory.
	public void Build(StringView natureKitPath)
	{
		mNatureKitPath.Set(natureKitPath);

		BuildGround();
		PlaceTrees();
		PlaceRocks();
		PlaceFlowers();
		PlaceGrass();
		PlaceProps();

		Console.WriteLine("Environment built: {} models loaded", mLoadedModels.Count);
	}

	// ==================== Ground ====================

	private void BuildGround()
	{
		// Tile the ground with nature kit ground pieces in a grid.
		// Each ground tile is roughly 1x1 unit in the nature kit.
		// We scale them up and tile an area.
		let tileScale = 4.0f;
		let gridSize = 5; // 5x5 grid = 20x20 unit area at scale 4

		for (int x = -gridSize; x <= gridSize; x++)
		{
			for (int z = -gridSize; z <= gridSize; z++)
			{
				let pos = Vector3((float)x * tileScale, 0, (float)z * tileScale);

				// Use path tiles for a central path, grass elsewhere
				if (Math.Abs(x) <= 0 && z >= -2 && z <= 3)
					PlaceModel("ground_pathStraight", pos, 0, tileScale);
				else if (x == 0 && z == -3)
					PlaceModel("ground_pathEnd", pos, 0, tileScale);
				else if (x == 0 && z == 4)
					PlaceModel("ground_pathEnd", pos, Math.PI_f, tileScale);
				else
					PlaceModel("ground_grass", pos, 0, tileScale);
			}
		}
	}

	// ==================== Trees ====================

	private void PlaceTrees()
	{
		// Back tree line
		PlaceModel("tree_pineRoundA", .(-16, 0, -18), 0);
		PlaceModel("tree_pineRoundB", .(-10, 0, -20), 0.5f);
		PlaceModel("tree_pineTallA", .(-4, 0, -19), 0.3f);
		PlaceModel("tree_pineRoundC", .(4, 0, -20), 1.2f);
		PlaceModel("tree_pineTallB", .(10, 0, -18), 0.8f);
		PlaceModel("tree_pineRoundD", .(16, 0, -19), 1.8f);

		// Left tree cluster
		PlaceModel("tree_default", .(-18, 0, -8), 0);
		PlaceModel("tree_default_dark", .(-20, 0, -4), 0.7f);
		PlaceModel("tree_oak", .(-19, 0, 0), 1.5f);
		PlaceModel("tree_fat", .(-17, 0, 4), 0.3f);
		PlaceModel("tree_detailed", .(-20, 0, 8), 2.1f);

		// Right tree cluster
		PlaceModel("tree_default", .(18, 0, -6), 1.0f);
		PlaceModel("tree_cone", .(20, 0, -2), 0.5f);
		PlaceModel("tree_tall", .(19, 0, 2), 2.0f);
		PlaceModel("tree_simple", .(17, 0, 6), 1.3f);
		PlaceModel("tree_detailed_dark", .(20, 0, 10), 0.8f);

		// Scattered individual trees in the scene
		PlaceModel("tree_small", .(-8, 0, 6), 1.1f);
		PlaceModel("tree_thin", .(9, 0, -8), 0.4f);
		PlaceModel("tree_cone_dark", .(-6, 0, -12), 2.5f);
	}

	// ==================== Rocks ====================

	private void PlaceRocks()
	{
		// Scattered rocks around the scene
		PlaceModel("rock_largeA", .(-12, 0, -10), 0.3f);
		PlaceModel("rock_largeB", .(14, 0, 8), 1.5f);
		PlaceModel("rock_tallA", .(-8, 0, 12), 0.7f);

		// Small rocks near paths
		PlaceModel("rock_smallA", .(-2, 0, 2), 0);
		PlaceModel("rock_smallB", .(3, 0, -1), 1.2f);
		PlaceModel("rock_smallC", .(-1, 0, 5), 2.0f);
		PlaceModel("rock_smallD", .(2, 0, 8), 0.5f);
	}

	// ==================== Flowers ====================

	private void PlaceFlowers()
	{
		// Flower clusters near the animation meadow area
		PlaceModel("flower_redA", .(6, 0, -4), 0);
		PlaceModel("flower_redB", .(8, 0, -3), 0.5f);
		PlaceModel("flower_yellowA", .(7, 0, -6), 1.0f);
		PlaceModel("flower_yellowB", .(10, 0, -5), 1.5f);
		PlaceModel("flower_purpleA", .(5, 0, -7), 0.3f);
		PlaceModel("flower_purpleC", .(9, 0, -2), 2.0f);

		// Flowers near the central area
		PlaceModel("flower_redC", .(-3, 0, 4), 0.8f);
		PlaceModel("flower_yellowC", .(2, 0, 6), 1.2f);
		PlaceModel("flower_purpleB", .(-5, 0, 7), 0.4f);
	}

	// ==================== Grass ====================

	private void PlaceGrass()
	{
		// Grass patches scattered across the scene
		PlaceModel("grass_large", .(-4, 0, -2), 0);
		PlaceModel("grass_large", .(5, 0, 3), 1.0f);
		PlaceModel("grass_large", .(-7, 0, 8), 2.0f);
		PlaceModel("grass_leafs", .(3, 0, -5), 0.5f);
		PlaceModel("grass_leafs", .(-6, 0, 4), 1.5f);
		PlaceModel("grass_leafsLarge", .(8, 0, 5), 0.3f);
		PlaceModel("grass_leafsLarge", .(-10, 0, -6), 1.8f);
		PlaceModel("grass_large", .(12, 0, -3), 0.7f);
		PlaceModel("grass_leafs", .(-3, 0, 10), 2.5f);
		PlaceModel("grass_large", .(6, 0, 10), 1.2f);
	}

	// ==================== Props ====================

	private void PlaceProps()
	{
		// Campfire near the particles area (left side)
		PlaceModel("campfire_stones", .(-8, 0, -8), 0);

		// Stumps
		PlaceModel("stump_round", .(-14, 0, 2), 0.5f);
		PlaceModel("stump_old", .(12, 0, -10), 1.0f);

		// Mushrooms
		PlaceModel("mushroom", .(-10, 0, -4), 0);
		PlaceModel("mushroom", .(6, 0, 12), 1.5f);

		// Fence sections near the physics yard
		PlaceModel("fence_simple", .(-10, 0, 4), 0);
		PlaceModel("fence_simple", .(-10, 0, 6), 0);
		PlaceModel("fence_simple", .(-10, 0, 8), 0);

		// Sign post
		PlaceModel("sign", .(1, 0, -2), -0.3f);

		// Statue in the central area
		PlaceModel("statue_column", .(0, 0, 0), 0);
	}

	// ==================== Model Loading ====================

	private LoadedModel LoadModel(StringView modelName)
	{
		if (mModelCache.TryGetValue(scope String(modelName), let cached))
			return cached;

		let path = scope String();
		path.AppendF("{}/{}.glb", mNatureKitPath, modelName);

		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(path, model) != .Ok)
		{
			Console.WriteLine("WARNING: Could not load model: {} (path: {})", modelName, path);
			return null;
		}

		let importOpts = ModelImportOptions.StaticMeshOnly();
		importOpts.BasePath.Set(mNatureKitPath);
		importOpts.ModelPath.Set(path);
		let importer = scope ModelImporter(importOpts);
		let importResult = importer.Import(model);
		defer delete importResult;

		if (importResult.StaticMeshes.Count == 0)
		{
			Console.WriteLine("WARNING: No static meshes in model: {}", modelName);
			return null;
		}

		// Convert to resources with deduplication
		let resResult = ResourceImportResult.ConvertFrom(importResult, mDedupContext, path);
		defer delete resResult;

		// Register new resources
		for (let texRes in resResult.Textures)
			mResources.AddResource<TextureResource>(texRes);
		for (let matRes in resResult.Materials)
			mResources.AddResource<MaterialResource>(matRes);
		resResult.Textures.Clear();
		resResult.Materials.Clear();

		// Build LoadedModel
		let loaded = new LoadedModel();
		loaded.Name = new String(modelName);

		for (let importedMat in importResult.Materials)
		{
			let matRes = mDedupContext.FindMaterial(importedMat.Name);
			if (matRes != null)
				loaded.MaterialRefs.Add(ResourceRef(matRes.Id, matRes.Name));
		}

		// Take ownership of the static mesh
		let staticMesh = importResult.StaticMeshes[0];
		let meshRes = new StaticMeshResource(staticMesh, true);
		importResult.StaticMeshes[0] = null;
		meshRes.Name.Set(modelName);
		mResources.AddResource<StaticMeshResource>(meshRes);
		loaded.MeshResource = meshRes;

		mModelCache[new String(modelName)] = loaded;
		mLoadedModels.Add(loaded);

		return loaded;
	}

	private void PlaceModel(StringView modelName, Vector3 position, float yaw, float scale = 1.0f)
	{
		let loaded = LoadModel(modelName);
		if (loaded == null) return;

		var meshRef = ResourceRef(loaded.MeshResource.Id, .());
		defer meshRef.Dispose();

		let name = scope String();
		name.AppendF("env_{}", modelName);

		let entity = mScene.CreateEntity(name);
		mScene.SetLocalTransform(entity, .()
		{
			Position = position,
			Rotation = Quaternion.CreateFromYawPitchRoll(yaw, 0, 0),
			Scale = .(scale, scale, scale)
		});

		let meshMgr = mScene.GetModule<MeshComponentManager>();
		let compHandle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(compHandle))
		{
			comp.SetMeshRef(meshRef);
			for (int32 slot = 0; slot < loaded.MaterialRefs.Count; slot++)
				comp.SetMaterialRef(slot, loaded.MaterialRefs[slot]);
		}
	}
}
