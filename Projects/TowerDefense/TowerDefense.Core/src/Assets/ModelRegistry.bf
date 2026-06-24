namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Models;
using Sedulous.Models.FBX;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Renderer;
using Sedulous.RHI;
using Sedulous.Images;
using Sedulous.Images.STB;

/// Loads and caches all Kenney Tower Defense Kit FBX models.
/// Uses ImportDeduplicationContext so the shared colormap texture
/// and material are loaded once and reused across all models.
class ModelRegistry
{
	private Dictionary<String, LoadedModel> mModelCache = new .() ~ delete _;
	private List<LoadedModel> mLoadedModels = new .() ~ DeleteContainerAndItems!(_);
	private ImportDeduplicationContext mDedupContext = new .() ~ delete _;

	private String mBasePath = new .() ~ delete _;

	/// Registry name for constructing protocol-prefixed resource paths.
	/// When set, ResourceRefs use "{RegistryName}://resources/{name}.ext" format.
	public String RegistryName = new .() ~ delete _;

	/// A cached model with its mesh resource and material refs.
	public class LoadedModel
	{
		public String Name = new .() ~ delete _;
		public String MeshRefPath = new .() ~ delete _; // Protocol-prefixed path for ResourceRef
		public StaticMeshResource MeshResource;
		public List<ResourceRef> MaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

		/// Releases the ref on the mesh resource (registered with ResourceSystem via AddResource).
		public void ReleaseRefs()
		{
			MeshResource?.ReleaseRef();
		}
	}

	/// Initializes the FBX model loader and sets the asset base path.
	/// basePath should be the resolved full path to the FBX format directory.
	public void Initialize(StringView basePath)
	{
		FbxModels.Initialize();
		mBasePath.Set(basePath);
	}

	/// Loads a model by name (e.g., "tile", "tower-round-base", "enemy-ufo-a").
	/// Returns the cached LoadedModel, or null on failure.
	public LoadedModel LoadModel(StringView modelName, ResourceSystem resources)
	{
		// Check cache
		if (mModelCache.TryGetValue(scope String(modelName), let cached))
			return cached;

		let path = scope String();
		path.AppendF("{}/{}.fbx", mBasePath, modelName);

		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(path, model) != .Ok)
		{
			Console.WriteLine("[ModelRegistry] WARNING: Could not load model: {}", modelName);
			return null;
		}

		let importOpts = ModelImportOptions.StaticMeshOnly();
		importOpts.BasePath.Set(mBasePath);
		importOpts.ModelPath.Set(path);
		let importer = scope ModelImporter(importOpts);
		let importResult = importer.Import(model);
		defer delete importResult;

		if (importResult.StaticMeshes.Count == 0)
		{
			Console.WriteLine("[ModelRegistry] WARNING: No static meshes in: {}", modelName);
			return null;
		}

		// Convert to resources with deduplication (shared textures + materials across models)
		let resResult = ResourceImportResult.ConvertFrom(importResult, mDedupContext, path);
		defer delete resResult;

		// Register newly created resources (deduped ones already registered by earlier imports)
		for (let texRes in resResult.Textures)
			resources.AddResource<TextureResource>(texRes);
		for (let matRes in resResult.Materials)
			resources.AddResource<MaterialResource>(matRes);

		// Prevent resResult from deleting resources we registered
		resResult.Textures.Clear();
		resResult.Materials.Clear();

		// Collect material ResourceRefs with registry protocol paths
		let loaded = new LoadedModel();
		loaded.Name.Set(modelName);

		for (let importedMat in importResult.Materials)
		{
			let matRes = mDedupContext.FindMaterial(importedMat.Name);
			if (matRes != null)
			{
				let refPath = scope String();
				if (RegistryName.Length > 0)
					refPath.AppendF("{}://resources/{}.material", RegistryName, matRes.Name);
				else
					refPath.Set(matRes.Name);
				loaded.MaterialRefs.Add(ResourceRef(matRes.Id, refPath));
			}
		}

		// Take ownership of the first static mesh
		let staticMesh = importResult.StaticMeshes[0];
		let meshRes = new StaticMeshResource(staticMesh, true);
		importResult.StaticMeshes[0] = null; // transfer ownership
		meshRes.Name.Set(modelName);
		resources.AddResource<StaticMeshResource>(meshRes);
		loaded.MeshResource = meshRes;
		if (RegistryName.Length > 0)
			loaded.MeshRefPath.AppendF("{}://resources/{}.mesh", RegistryName, modelName);
		else
			loaded.MeshRefPath.Set(modelName);

		mModelCache[new String(modelName)] = loaded;
		mLoadedModels.Add(loaded);

		Console.WriteLine("[ModelRegistry] Loaded: {} ({} verts, {} materials)",
			modelName, staticMesh.VertexCount, loaded.MaterialRefs.Count);

		return loaded;
	}

	/// Gets a mesh ResourceRef for a loaded model.
	public ResourceRef GetMeshRef(StringView modelName)
	{
		if (mModelCache.TryGetValue(scope String(modelName), let loaded))
			return ResourceRef(loaded.MeshResource.Id, loaded.MeshRefPath);
		return ResourceRef();
	}

	/// Preloads a list of models by name.
	public void PreloadModels(ResourceSystem resources, Span<StringView> names)
	{
		for (let name in names)
			LoadModel(name, resources);
	}

	public void Shutdown()
	{
		// Release resource refs on loaded meshes
		for (let loaded in mLoadedModels)
			loaded.ReleaseRefs();

		// Release deduped texture/material resource refs
		mDedupContext.ReleaseAllRefs();

		// Delete dictionary keys before clearing
		for (let key in mModelCache.Keys)
			delete key;
		mModelCache.Clear();
	}
}
