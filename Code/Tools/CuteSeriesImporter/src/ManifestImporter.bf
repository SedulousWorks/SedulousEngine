namespace CuteSeriesImporter;

using System;
using System.IO;
using System.Collections;
using Sedulous.Xml;
using Sedulous.Models;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;
using Sedulous.VFS.Disk;
using Sedulous.Textures.Importer;
using Sedulous.Textures;
using Sedulous.Textures.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;

/// Reads a CuteSeriesManifest.xml and imports all assets into Sedulous resources.
class ManifestImporter
{
	private String mManifestDir = new .() ~ delete _;
	private String mSourceRoot = new .() ~ delete _;
	private String mOutputRoot = new .() ~ delete _;
	private OpenDDLSerializerProvider mSerializerProvider = new .() ~ delete _;
	private InMemoryResourceIndex mRegistry = new .() ~ delete _;
	private String mCurrentUriPrefix = new .() ~ delete _;
	private int mTotalResources;
	private int mTotalErrors;
	private int mTotalSkipped;
	private bool mDebugFirstOnly;
	private String mPackFilter ~ delete _;  // null = all packs

	/// Sets a pack name filter. Only the matching pack will be imported.
	public void SetPackFilter(StringView packName)
	{
		delete mPackFilter;
		mPackFilter = new String(packName);
	}

	public Result<void> Run(StringView manifestPath)
	{
		let xmlText = scope String();
		if (File.ReadAllText(manifestPath, xmlText) case .Err)
		{
			Console.WriteLine("ERROR: Failed to read manifest file");
			return .Err;
		}

		let doc = scope XmlDocument();
		if (doc.Parse(xmlText) != .Ok)
		{
			Console.WriteLine("ERROR: Failed to parse manifest XML");
			return .Err;
		}

		let root = doc.RootElement;
		if (root == null || root.TagName != "ImportManifest")
		{
			Console.WriteLine("ERROR: Root element must be <ImportManifest>");
			return .Err;
		}

		Path.GetDirectoryPath(manifestPath, mManifestDir);

		mSourceRoot.Set(root.GetAttribute("sourceRoot"));
		if (mSourceRoot.IsEmpty)
		{
			Console.WriteLine("ERROR: ImportManifest missing sourceRoot attribute");
			return .Err;
		}

		Path.InternalCombine(mOutputRoot, mSourceRoot, "..", "CuteSeriesOutput");

		Console.WriteLine("Source root: {}", mSourceRoot);
		Console.WriteLine("Output root: {}", mOutputRoot);

		for (let child in root.Children)
		{
			if (let element = child as XmlElement)
			{
				if (element.TagName == "Pack")
				{
					// Filter by pack name if specified
					if (mPackFilter != null && element.GetAttribute("name") != mPackFilter)
						continue;

					ProcessPack(element);
					if (mDebugFirstOnly) break;
				}
			}
		}

		// Save registry
		let registryMount = scope FileSystemMount(mOutputRoot);
		let registryStream = scope MemoryStream();
		if (mRegistry.SerializeTo(registryStream) case .Ok)
		{
			registryStream.Position = 0;
			if (registryMount.Save("cuteseries.registry", registryStream) case .Ok)
				Console.WriteLine("Registry saved: {}/cuteseries.registry", mOutputRoot);
		}

		Console.WriteLine("\n=== Summary ===");
		Console.WriteLine("Resources written: {}", mTotalResources);
		Console.WriteLine("Skipped (already exist): {}", mTotalSkipped);
		Console.WriteLine("Errors: {}", mTotalErrors);

		return .Ok;
	}

	private void ProcessPack(XmlElement packEl)
	{
		let packName = packEl.GetAttribute("name");
		let packType = packEl.GetAttribute("type");
		let sourceDir = packEl.GetAttribute("sourceDir");
		let outputDir = packEl.GetAttribute("outputDir");

		Console.WriteLine("\n--- Pack: {} ({}) ---", packName, packType);

		let packSourcePath = scope String();
		Path.InternalCombine(packSourcePath, mSourceRoot, sourceDir);

		if (!Directory.Exists(packSourcePath))
		{
			Console.WriteLine("WARNING: Pack source directory not found: {}", packSourcePath);
			return;
		}

		let outputPath = scope String();
		Path.InternalCombine(outputPath, mOutputRoot, outputDir);
		Directory.CreateDirectory(outputPath);

		let mount = scope FileSystemMount(outputPath);

		// Track base asset refs for variant processing
		let baseAssetRefs = scope Dictionary<String, AssetRefs>();
		defer { for (var kv in ref baseAssetRefs) { delete kv.key; kv.valueRef.Dispose(); } }

		// Track shared material refs
		let sharedMaterialRefs = scope Dictionary<String, ResourceRef>();
		defer { for (var kv in ref sharedMaterialRefs) { delete kv.key; kv.valueRef.Dispose(); } }

		// Pre-pass: process SharedMaterial elements
		for (let child in packEl.Children)
		{
			if (let element = child as XmlElement)
			{
				if (element.TagName == "SharedMaterial")
					ProcessSharedMaterial(element, packSourcePath, mount, sharedMaterialRefs);
			}
		}

		// First pass: process Asset elements, track all refs
		for (let child in packEl.Children)
		{
			if (let element = child as XmlElement)
			{
				if (element.TagName == "Asset")
				{
					var refs = AssetRefs();
					ProcessAsset(element, packSourcePath, mount, &refs, sharedMaterialRefs);
					baseAssetRefs[new String(element.GetAttribute("name"))] = refs;
					if (mDebugFirstOnly) break;
				}
			}
		}

		// Second pass: process Variant elements
		for (let child in packEl.Children)
		{
			if (let element = child as XmlElement)
			{
				if (element.TagName == "Variant")
				{
					let baseName = element.GetAttribute("base");
					if (baseAssetRefs.TryGetValue(scope String(baseName), let baseRefs))
						ProcessVariant(element, packSourcePath, mount, baseRefs, baseAssetRefs);
					else
						Console.WriteLine("  WARNING: Variant base '{}' not found", baseName);
				}
			}
		}

		// Third pass: process SceneManifest elements
		for (let child in packEl.Children)
		{
			if (let element = child as XmlElement)
			{
				if (element.TagName == "SceneManifest")
					ProcessSceneManifest(element, packSourcePath, mount, baseAssetRefs, sharedMaterialRefs);
			}
		}
	}

	/// Collected resource refs for an asset, used to generate animgraph + prefab.
	struct AssetRefs : IDisposable
	{
		public ResourceRef SkinnedMeshRef;
		public ResourceRef StaticMeshRef;
		public ResourceRef SkeletonRef;
		public ResourceRef MaterialRef;
		public ResourceRef AnimGraphRef;

		public AssetRefs Clone()
		{
			return .() {
				SkinnedMeshRef = ResourceRef(SkinnedMeshRef.Id, SkinnedMeshRef.Path ?? ""),
				StaticMeshRef = ResourceRef(StaticMeshRef.Id, StaticMeshRef.Path ?? ""),
				SkeletonRef = ResourceRef(SkeletonRef.Id, SkeletonRef.Path ?? ""),
				MaterialRef = ResourceRef(MaterialRef.Id, MaterialRef.Path ?? ""),
				AnimGraphRef = ResourceRef(AnimGraphRef.Id, AnimGraphRef.Path ?? "")
			};
		}

		public void Dispose() mut
		{
			SkinnedMeshRef.Dispose();
			StaticMeshRef.Dispose();
			SkeletonRef.Dispose();
			MaterialRef.Dispose();
			AnimGraphRef.Dispose();
		}
	}

	private void ProcessAsset(XmlElement assetEl, StringView packSourcePath,
		FileSystemMount packMount)
	{
		ProcessAsset(assetEl, packSourcePath, packMount, null, null);
	}

	private void ProcessAsset(XmlElement assetEl, StringView packSourcePath,
		FileSystemMount packMount, AssetRefs* outRefs,
		Dictionary<String, ResourceRef> sharedMaterialRefs = null)
	{
		let assetName = assetEl.GetAttribute("name");
		let sourceFolder = assetEl.GetAttribute("sourceFolder");

		let assetSourcePath = scope String();
		if (!sourceFolder.IsEmpty)
			Path.InternalCombine(assetSourcePath, packSourcePath, sourceFolder);
		else
			assetSourcePath.Set(packSourcePath);

		Console.WriteLine("  Asset: {}", assetName);

		// Create per-asset subfolder and set URI prefix for registry
		let assetSubDir = scope String(assetName);
		ResourceSerializer.SanitizePath(assetSubDir);

		let assetOutputPath = scope String();
		Path.InternalCombine(assetOutputPath, packMount.RootPath, assetSubDir);
		Directory.CreateDirectory(assetOutputPath);
		let mount = scope FileSystemMount(assetOutputPath);

		// Find first mesh element
		XmlElement meshEl = FindChild(assetEl, "Mesh");
		if (meshEl == null)
		{
			Console.WriteLine("    WARNING: No <Mesh> element, skipping");
			return;
		}

		let meshFile = meshEl.GetAttribute("file");
		let meshPath = scope String();
		Path.InternalCombine(meshPath, assetSourcePath, meshFile);

		if (!File.Exists(meshPath))
		{
			Console.WriteLine("    ERROR: Mesh file not found: {}", meshPath);
			mTotalErrors++;
			return;
		}

		// Track resource refs for animgraph + prefab generation
		var assetRefs = AssetRefs();
		defer assetRefs.Dispose();

		// Check if already imported
		let checkFile = scope String();
		checkFile.AppendF("{}.skinnedmesh", assetName);
		ResourceSerializer.SanitizePath(checkFile);
		if (mount.Exists(checkFile))
		{
			// Also check for static mesh
			let checkStatic = scope String();
			checkStatic.AppendF("{}.mesh", assetName);
			ResourceSerializer.SanitizePath(checkStatic);
			if (mount.Exists(checkStatic))
			{
				Console.WriteLine("    Already imported, skipping");
				mTotalSkipped++;

				// Still collect refs if this is a variant base
				if (outRefs != null)
					CollectExistingRefs(assetName, assetEl, assetSourcePath, mount, &assetRefs, outRefs);

				return;
			}
		}

		Console.WriteLine("    Base mesh: {}", meshFile);

		// Import mesh + skeleton + materials + textures (full import for comparison)
		if (ImportModel(meshPath, .Meshes | .SkinnedMeshes | .Skeletons | .Materials | .Textures) case .Ok(var bundle))
		{
			SaveMeshAndSkeleton(bundle.ResResult, assetName, mount);

			// Collect refs for meshes
			if (bundle.ResResult.SkinnedMeshes.Count > 0)
			{
				let meshRes = bundle.ResResult.SkinnedMeshes[0];
				let meshFileName = scope String();
				meshFileName.AppendF("{}.skinnedmesh", assetName);
				ResourceSerializer.SanitizePath(meshFileName);
				let meshUri = scope String();
				BuildRegistryUri(mount, meshFileName, meshUri);
				assetRefs.SkinnedMeshRef = ResourceRef(meshRes.Id, meshUri);
			}
			if (bundle.ResResult.StaticMeshes.Count > 0)
			{
				let meshRes = bundle.ResResult.StaticMeshes[0];
				let meshFileName = scope String();
				meshFileName.AppendF("{}.mesh", assetName);
				ResourceSerializer.SanitizePath(meshFileName);
				let meshUri = scope String();
				BuildRegistryUri(mount, meshFileName, meshUri);
				assetRefs.StaticMeshRef = ResourceRef(meshRes.Id, meshUri);
			}
			if (bundle.ResResult.Skeletons.Count > 0)
			{
				let skelRes = bundle.ResResult.Skeletons[0];
				let skelFileName = scope String();
				skelFileName.AppendF("{}.skeleton", assetName);
				ResourceSerializer.SanitizePath(skelFileName);
				let skelUri = scope String();
				BuildRegistryUri(mount, skelFileName, skelUri);
				assetRefs.SkeletonRef = ResourceRef(skelRes.Id, skelUri);
			}

			// Save the FBX-imported material as Material_Imported for comparison
			SaveFbxMaterials(bundle.ResResult, assetName, mount);

			// Build material from manifest, augmented with FBX material flags
			let matEl = FindChild(assetEl, "Material");
			if (matEl != null)
				BuildMaterialFromManifest(matEl, assetSourcePath, assetName, mount, bundle.ImportResult);

			bundle.Dispose();
		}
		else
		{
			Console.WriteLine("    ERROR: Base mesh import failed");
			mTotalErrors++;
			return;
		}

		// Collect material ref — shared material or per-asset manifest material
		let sharedMatName = assetEl.GetAttribute("sharedMaterial");
		if (!sharedMatName.IsEmpty && sharedMaterialRefs != null)
		{
			if (sharedMaterialRefs.TryGetValue(scope String(sharedMatName), let sharedRef))
				assetRefs.MaterialRef = ResourceRef(sharedRef.Id, sharedRef.Path ?? "");
		}
		else
		{
			let matFileName = scope String();
			matFileName.AppendF("{}.material", assetName);
			ResourceSerializer.SanitizePath(matFileName);
			if (mount.Exists(matFileName))
			{
				if (ReadResourceId(mount, matFileName) case .Ok(let matId))
				{
					let matUri = scope String();
					BuildRegistryUri(mount, matFileName, matUri);
					assetRefs.MaterialRef = ResourceRef(matId, matUri);
				}
			}
		}

		// Import animation clips (collects clip refs)
		let clipInfos = scope List<ClipInfo>();
		defer { for (var ci in ref clipInfos) ci.Dispose(); }

		let animsEl = FindChild(assetEl, "Animations");
		if (animsEl != null)
			ProcessAnimations(animsEl, assetSourcePath, assetName, mount, clipInfos);

		// Generate animation graph
		if (clipInfos.Count > 0)
		{
			let graphFileName = scope String();
			graphFileName.AppendF("{}.animgraph", assetName);
			ResourceSerializer.SanitizePath(graphFileName);

			if (!mount.Exists(graphFileName))
			{
				if (GenerateAnimGraph(assetName, clipInfos, graphFileName, mount))
					Console.WriteLine("    AnimGraph: {} ({} states)", assetName, clipInfos.Count);
			}

			// Collect animgraph ref
			if (ReadResourceId(mount, graphFileName) case .Ok(let gId))
			{
				let graphUri = scope String();
				BuildRegistryUri(mount, graphFileName, graphUri);
				assetRefs.AnimGraphRef = ResourceRef(gId, graphUri);
			}
		}

		// Generate prefab (skip for variant bases — variants generate their own)
		let isVariantBase = assetEl.GetAttribute("variantBase") == "true";
		if (!isVariantBase && (assetRefs.SkinnedMeshRef.IsValid || assetRefs.StaticMeshRef.IsValid))
		{
			let prefabFileName = scope String();
			prefabFileName.AppendF("{}.prefab", assetName);
			ResourceSerializer.SanitizePath(prefabFileName);

			if (!mount.Exists(prefabFileName))
			{
				if (GeneratePrefab(assetName, assetRefs, assetRefs.AnimGraphRef, prefabFileName, mount))
					Console.WriteLine("    Prefab: {}", assetName);
			}
		}

		// Output refs for variant processing
		if (outRefs != null)
			*outRefs = assetRefs.Clone();
	}

	/// Processes a SharedMaterial element: builds a material resource shared across assets.
	private void ProcessSharedMaterial(XmlElement matEl, StringView packSourcePath,
		FileSystemMount mount, Dictionary<String, ResourceRef> outRefs)
	{
		let matName = matEl.GetAttribute("name");
		Console.WriteLine("  SharedMaterial: {}", matName);

		// Save into a _shared subfolder
		let sharedPath = scope String();
		Path.InternalCombine(sharedPath, mount.RootPath, "_shared");
		Directory.CreateDirectory(sharedPath);
		let sharedMount = scope FileSystemMount(sharedPath);

		let matFileName = scope String();
		matFileName.AppendF("{}.material", matName);
		ResourceSerializer.SanitizePath(matFileName);

		// Check if already exists
		if (sharedMount.Exists(matFileName))
		{
			if (ReadResourceId(sharedMount, matFileName) case .Ok(let id))
			{
				let uri = scope String();
				BuildRegistryUri(sharedMount, matFileName, uri);
				outRefs[new String(matName)] = ResourceRef(id, uri);
				Console.WriteLine("    Already exists");
			}
			return;
		}

		// Build material using same logic as BuildMaterialFromManifest
		BuildMaterialFromManifest(matEl, packSourcePath, matName, sharedMount);

		// Collect ref
		if (ReadResourceId(sharedMount, matFileName) case .Ok(let id))
		{
			let uri = scope String();
			BuildRegistryUri(sharedMount, matFileName, uri);
			outRefs[new String(matName)] = ResourceRef(id, uri);
		}
	}

	/// Processes a SceneManifest element: reads a scene XML and generates a .prefab
	/// containing all entities with MeshComponents.
	private void ProcessSceneManifest(XmlElement sceneEl, StringView packSourcePath,
		FileSystemMount packMount, Dictionary<String, AssetRefs> assetRefs,
		Dictionary<String, ResourceRef> sharedMaterialRefs)
	{
		let sceneFile = sceneEl.GetAttribute("file");
		if (sceneFile.IsEmpty) return;

		// Scene manifest XML is relative to the main manifest file
		let sceneManifestPath = scope String();
		Path.InternalCombine(sceneManifestPath, mManifestDir, sceneFile);

		if (!File.Exists(sceneManifestPath))
		{
			Console.WriteLine("  WARNING: Scene manifest not found: {}", sceneFile);
			return;
		}

		let xmlText = scope String();
		if (File.ReadAllText(sceneManifestPath, xmlText) case .Err)
		{
			Console.WriteLine("  ERROR: Failed to read scene manifest: {}", sceneFile);
			return;
		}

		let doc = scope XmlDocument();
		if (doc.Parse(xmlText) != .Ok)
		{
			Console.WriteLine("  ERROR: Failed to parse scene manifest XML");
			return;
		}

		let root = doc.RootElement;
		if (root == null || root.TagName != "SceneManifest")
		{
			Console.WriteLine("  ERROR: Root element must be <SceneManifest>");
			return;
		}

		let sceneName = root.GetAttribute("name");
		Console.WriteLine("  Scene: {}", sceneName);

		// Output as prefab in _scenes subfolder
		let scenesPath = scope String();
		Path.InternalCombine(scenesPath, packMount.RootPath, "_scenes");
		Directory.CreateDirectory(scenesPath);
		let sceneMount = scope FileSystemMount(scenesPath);

		let prefabFileName = scope String();
		prefabFileName.AppendF("{}.prefab", sceneName);
		ResourceSerializer.SanitizePath(prefabFileName);

		if (sceneMount.Exists(prefabFileName))
		{
			Console.WriteLine("    Already exists, skipping");
			return;
		}

		// Build the scene prefab
		let prefab = new GeneratedScenePrefab();
		defer delete prefab;
		prefab.Name.Set(sceneName);

		for (let child in root.Children)
		{
			if (let entityEl = child as XmlElement)
			{
				if (entityEl.TagName != "Entity") continue;

				let meshName = entityEl.GetAttribute("mesh");
				let materialName = entityEl.GetAttribute("material");
				let entityName = entityEl.GetAttribute("name");

				// Look up mesh ref
				var meshRef = ResourceRef();
				if (assetRefs.TryGetValue(scope String(meshName), let meshAssetRefs))
					meshRef = meshAssetRefs.StaticMeshRef;

				// Look up material ref
				var matRef = ResourceRef();
				if (sharedMaterialRefs.TryGetValue(scope String(materialName), let sharedRef))
					matRef = sharedRef;

				if (!meshRef.IsValid)
				{
					//Console.WriteLine("    WARNING: No mesh ref for '{}'", meshName);
					continue;
				}

				// Parse transform
				float px = 0, py = 0, pz = 0;
				float rx = 0, ry = 0, rz = 0, rw = 1;
				float sx = 1, sy = 1, sz = 1;

				if (float.Parse(entityEl.GetAttribute("px")) case .Ok(let v)) px = v;
				if (float.Parse(entityEl.GetAttribute("py")) case .Ok(let v)) py = v;
				if (float.Parse(entityEl.GetAttribute("pz")) case .Ok(let v)) pz = v;
				if (float.Parse(entityEl.GetAttribute("rx")) case .Ok(let v)) rx = v;
				if (float.Parse(entityEl.GetAttribute("ry")) case .Ok(let v)) ry = v;
				if (float.Parse(entityEl.GetAttribute("rz")) case .Ok(let v)) rz = v;
				if (float.Parse(entityEl.GetAttribute("rw")) case .Ok(let v)) rw = v;
				if (float.Parse(entityEl.GetAttribute("sx")) case .Ok(let v)) sx = v;
				if (float.Parse(entityEl.GetAttribute("sy")) case .Ok(let v)) sy = v;
				if (float.Parse(entityEl.GetAttribute("sz")) case .Ok(let v)) sz = v;

				var entry = GeneratedScenePrefab.EntityEntry();
				entry.Name = new String(entityName);
				entry.MeshRef = meshRef;
				entry.MaterialRef = matRef;
				entry.Position = .(px, py, pz);
				entry.Rotation = .(rx, ry, rz, rw);
				entry.Scale = .(sx, sy, sz);
				prefab.Entities.Add(entry);
			}
		}

		if (SaveResource(prefab, prefabFileName, sceneMount))
		{
			Console.WriteLine("    Scene prefab: {} ({} entities)", sceneName, prefab.Entities.Count);
			mTotalResources++;
		}
	}

	/// Collects resource refs from already-imported files for a variant base.
	private void CollectExistingRefs(StringView assetName, XmlElement assetEl,
		StringView assetSourcePath, FileSystemMount mount,
		AssetRefs* assetRefs, AssetRefs* outRefs)
	{
		// Skinned mesh
		let meshFileName = scope String();
		meshFileName.AppendF("{}.skinnedmesh", assetName);
		ResourceSerializer.SanitizePath(meshFileName);
		if (mount.Exists(meshFileName))
		{
			if (ReadResourceId(mount, meshFileName) case .Ok(let id))
			{
				let uri = scope String();
				BuildRegistryUri(mount, meshFileName, uri);
				assetRefs.SkinnedMeshRef = ResourceRef(id, uri);
			}
		}

		// Skeleton
		let skelFileName = scope String();
		skelFileName.AppendF("{}.skeleton", assetName);
		ResourceSerializer.SanitizePath(skelFileName);
		if (mount.Exists(skelFileName))
		{
			if (ReadResourceId(mount, skelFileName) case .Ok(let id))
			{
				let uri = scope String();
				BuildRegistryUri(mount, skelFileName, uri);
				assetRefs.SkeletonRef = ResourceRef(id, uri);
			}
		}

		// AnimGraph
		let graphFileName = scope String();
		graphFileName.AppendF("{}.animgraph", assetName);
		ResourceSerializer.SanitizePath(graphFileName);
		if (mount.Exists(graphFileName))
		{
			if (ReadResourceId(mount, graphFileName) case .Ok(let id))
			{
				let uri = scope String();
				BuildRegistryUri(mount, graphFileName, uri);
				assetRefs.AnimGraphRef = ResourceRef(id, uri);
			}
		}

		// Material
		let matFileName = scope String();
		matFileName.AppendF("{}.material", assetName);
		ResourceSerializer.SanitizePath(matFileName);
		if (mount.Exists(matFileName))
		{
			if (ReadResourceId(mount, matFileName) case .Ok(let id))
			{
				let uri = scope String();
				BuildRegistryUri(mount, matFileName, uri);
				assetRefs.MaterialRef = ResourceRef(id, uri);
			}
		}

		// Also process animations if not yet done (for animgraph generation)
		let animsEl = FindChild(assetEl, "Animations");
		if (animsEl != null && !assetRefs.AnimGraphRef.IsValid)
		{
			let clipInfos = scope List<ClipInfo>();
			defer { for (var ci in ref clipInfos) ci.Dispose(); }
			ProcessAnimations(animsEl, assetSourcePath, assetName, mount, clipInfos);

			if (clipInfos.Count > 0)
			{
				let gfn = scope String();
				gfn.AppendF("{}.animgraph", assetName);
				ResourceSerializer.SanitizePath(gfn);

				if (!mount.Exists(gfn))
				{
					if (GenerateAnimGraph(assetName, clipInfos, gfn, mount))
						Console.WriteLine("    AnimGraph: {} ({} states)", assetName, clipInfos.Count);
				}

				if (ReadResourceId(mount, gfn) case .Ok(let gId))
				{
					let gUri = scope String();
					BuildRegistryUri(mount, gfn, gUri);
					assetRefs.AnimGraphRef = ResourceRef(gId, gUri);
				}
			}
		}

		*outRefs = assetRefs.Clone();
	}

	/// Processes a Variant element: imports texture, creates material and prefab.
	/// Uses the base asset's skeleton and animgraph. Mesh can be overridden via mesh= attribute.
	private void ProcessVariant(XmlElement variantEl, StringView packSourcePath,
		FileSystemMount packMount, AssetRefs baseRefs,
		Dictionary<String, AssetRefs> allAssetRefs)
	{
		let variantName = variantEl.GetAttribute("name");
		let textureFile = variantEl.GetAttribute("texture");
		let meshOverride = variantEl.GetAttribute("mesh");
		let emissiveTextureFile = variantEl.GetAttribute("emissiveTexture");
		let emissiveColorStr = variantEl.GetAttribute("emissiveColor");

		Console.WriteLine("  Variant: {}", variantName);

		// Use the base asset's subfolder for shared resources, variant subfolder for variant-specific
		let variantSubDir = scope String(variantName);
		ResourceSerializer.SanitizePath(variantSubDir);

		let variantOutputPath = scope String();
		Path.InternalCombine(variantOutputPath, packMount.RootPath, variantSubDir);
		Directory.CreateDirectory(variantOutputPath);
		let mount = scope FileSystemMount(variantOutputPath);

		// Check if already imported
		let prefabFileName = scope String();
		prefabFileName.AppendF("{}.prefab", variantName);
		ResourceSerializer.SanitizePath(prefabFileName);
		if (mount.Exists(prefabFileName))
		{
			Console.WriteLine("    Already imported, skipping");
			mTotalSkipped++;
			return;
		}

		// Import albedo texture
		// Note: don't Dispose albedoRef — SetTextureRef takes ownership of the Path string
		var albedoRef = ResourceRef();
		if (!textureFile.IsEmpty)
		{
			let texPath = scope String();
			Path.InternalCombine(texPath, packSourcePath, textureFile);

			if (File.Exists(texPath))
			{
				if (TextureImporter.Import2D(texPath) case .Ok(let texRes))
				{
					texRes.Name.Set(variantName);
					let texFileName = scope String();
					texFileName.AppendF("{}.texture", variantName);
					ResourceSerializer.SanitizePath(texFileName);

					if (SaveTextureWithSidecar(texRes, texFileName, mount))
					{
						Console.WriteLine("    Texture: {}", variantName);
						mTotalResources++;
					}

					let texUri = scope String();
					BuildRegistryUri(mount, texFileName, texUri);
					albedoRef = ResourceRef(texRes.Id, texUri);

					delete texRes;
				}
			}
			else
				Console.WriteLine("    WARNING: Texture not found: {}", textureFile);
		}

		// Import emissive texture if present
		// Note: don't Dispose emissiveRef — SetTextureRef takes ownership of the Path string
		var emissiveRef = ResourceRef();
		if (!emissiveTextureFile.IsEmpty)
		{
			let texPath = scope String();
			Path.InternalCombine(texPath, packSourcePath, emissiveTextureFile);

			if (File.Exists(texPath))
			{
				if (TextureImporter.Import2D(texPath) case .Ok(let texRes))
				{
					let emissiveName = scope String();
					emissiveName.AppendF("{}_Emission", variantName);
					texRes.Name.Set(emissiveName);
					let texFileName = scope String();
					texFileName.AppendF("{}.texture", emissiveName);
					ResourceSerializer.SanitizePath(texFileName);

					if (SaveTextureWithSidecar(texRes, texFileName, mount))
					{
						Console.WriteLine("    Emissive Texture: {}", emissiveName);
						mTotalResources++;
					}

					let texUri = scope String();
					BuildRegistryUri(mount, texFileName, texUri);
					emissiveRef = ResourceRef(texRes.Id, texUri);

					delete texRes;
				}
			}
		}

		// Parse emissive color
		Vector4 emissiveColor = .(1, 1, 1, 1);
		bool isEmissive = !emissiveTextureFile.IsEmpty;
		if (isEmissive && !emissiveColorStr.IsEmpty)
		{
			let parts = scope List<StringView>();
			for (let part in emissiveColorStr.Split(','))
				parts.Add(part);
			if (parts.Count >= 3)
			{
				if (float.Parse(parts[0]) case .Ok(let r)) emissiveColor.X = r;
				if (float.Parse(parts[1]) case .Ok(let g)) emissiveColor.Y = g;
				if (float.Parse(parts[2]) case .Ok(let b)) emissiveColor.Z = b;
				if (parts.Count >= 4)
					if (float.Parse(parts[3]) case .Ok(let a)) emissiveColor.W = a;
			}
		}

		// Create material
		let mat = Materials.CreatePBR(variantName, "forward");
		mat.SetDefaultFloat("Metallic", 0.0f);
		mat.SetDefaultFloat("Roughness", 1.0f);
		mat.SetDefaultFloat("AlphaCutoff", 0.5f);

		if (isEmissive)
		{
			mat.ShaderFlags |= .Emissive;
			mat.PipelineConfig.ShaderFlags |= .Emissive;
			mat.SetDefaultFloat4("EmissiveColor", emissiveColor);
		}

		let matRes = new MaterialResource(mat, true);
		defer delete matRes;
		matRes.Name.Set(variantName);

		if (albedoRef.IsValid)
			matRes.SetTextureRef("AlbedoMap", albedoRef);
		if (emissiveRef.IsValid)
			matRes.SetTextureRef("EmissiveMap", emissiveRef);

		let matFileName = scope String();
		matFileName.AppendF("{}.material", variantName);
		ResourceSerializer.SanitizePath(matFileName);

		var matRef = ResourceRef();
		defer matRef.Dispose();
		if (SaveResource(matRes, matFileName, mount))
		{
			Console.WriteLine("    Material: {}", variantName);
			mTotalResources++;

			let matUri = scope String();
			BuildRegistryUri(mount, matFileName, matUri);
			matRef = ResourceRef(matRes.Id, matUri);
		}

		// Resolve mesh ref — use override if specified, otherwise base
		var meshRef = baseRefs.SkinnedMeshRef;
		if (!meshOverride.IsEmpty)
		{
			if (allAssetRefs.TryGetValue(scope String(meshOverride), let meshAssetRefs))
				meshRef = meshAssetRefs.SkinnedMeshRef;
			else
				Console.WriteLine("    WARNING: mesh override '{}' not found", meshOverride);
		}

		// Generate prefab
		var variantRefs = AssetRefs();
		variantRefs.SkinnedMeshRef = meshRef;
		variantRefs.SkeletonRef = baseRefs.SkeletonRef;
		variantRefs.MaterialRef = matRef;
		variantRefs.AnimGraphRef = baseRefs.AnimGraphRef;
		// Don't dispose variantRefs — it borrows base/mesh refs

		if (GeneratePrefab(variantName, variantRefs, baseRefs.AnimGraphRef, prefabFileName, mount))
		{
			Console.WriteLine("    Prefab: {}", variantName);
		}
	}

	/// Clip reference collected during animation import.
	struct ClipInfo : IDisposable
	{
		public String Name;
		public Guid Id;
		public String Uri;

		public void Dispose() mut
		{
			delete Name;
			delete Uri;
		}
	}

	private void ProcessAnimations(XmlElement animsEl, StringView assetSourcePath,
		StringView assetName, FileSystemMount mount, List<ClipInfo> outClips)
	{
		for (let child in animsEl.Children)
		{
			if (let clipEl = child as XmlElement)
			{
				if (clipEl.TagName != "Clip") continue;

				let clipFile = clipEl.GetAttribute("file");
				let clipName = clipEl.GetAttribute("name");

				if (clipFile.IsEmpty || clipName.IsEmpty) continue;

				let animFileName = scope String();
				animFileName.AppendF("{}.animation", clipName);
				ResourceSerializer.SanitizePath(animFileName);

				let clipPath = scope String();
				Path.InternalCombine(clipPath, assetSourcePath, clipFile);

				if (!File.Exists(clipPath))
				{
					Console.WriteLine("    WARNING: Animation file not found: {}", clipFile);
					mTotalErrors++;
					continue;
				}

				// Check if already imported — still collect ref for animgraph
				if (mount.Exists(animFileName))
				{
					// We need the GUID. Re-read the header from the saved file.
					if (ReadResourceId(mount, animFileName) case .Ok(let id))
					{
						let uri = new String();
						BuildRegistryUri(mount, animFileName, uri);
						outClips.Add(.() { Name = new String(clipName), Id = id, Uri = uri });
					}
					continue;
				}

				if (ImportModel(clipPath, .Animations | .Skeletons) case .Ok(var bundle))
				{
					// Rename clips from Take001 to the manifest name
					for (let anim in bundle.ResResult.Animations)
					{
						if (anim.Name != null)
							anim.Name.Set(clipName);
						else
							anim.Name = new String(clipName);
					}

					// Save animation resources only
					for (let anim in bundle.ResResult.Animations)
					{
						if (SaveResource(anim, animFileName, mount))
						{
							Console.WriteLine("    Clip: {}", clipName);
							mTotalResources++;

							let uri = new String();
							BuildRegistryUri(mount, animFileName, uri);
							outClips.Add(.() { Name = new String(clipName), Id = anim.Id, Uri = uri });
						}
					}

					bundle.Dispose();
				}
				else
				{
					Console.WriteLine("    ERROR: Animation import failed: {}", clipFile);
					mTotalErrors++;
				}
			}
		}
	}

	// ==================== Material Building ====================

	/// Builds a MaterialResource from the manifest <Material> element.
	/// Creates a PBR material via Materials.CreatePBR, sets properties from
	/// manifest, imports textures from PSD/PNG files.
	private void BuildMaterialFromManifest(XmlElement matEl, StringView assetSourcePath,
		StringView assetName, FileSystemMount mount, ModelImportResult fbxResult = null)
	{
		// Read manifest properties into local vars first
		bool isEmissive = matEl.GetAttribute("emissive") == "true";
		bool isDoubleSided = matEl.GetAttribute("doubleSided") == "true";
		let blendMode = matEl.GetAttribute("blendMode");

		// Augment with FBX material flags (FBX is authoritative for DoubleSided
		// since the Unity .mat doesn't reliably expose it)
		if (fbxResult != null && fbxResult.Materials.Count > 0)
		{
			let fbxMat = fbxResult.Materials[0];
			if (fbxMat.DoubleSided)
				isDoubleSided = true;
		}

		// Default PBR values
		Vector4 baseColor = .(1, 1, 1, 1);
		Vector4 emissiveColor = .(0, 0, 0, 1);
		float metallic = 0.0f;
		float roughness = 0.5f;
		float ao = 1.0f;
		float alphaCutoff = 0.0f;

		// Override from manifest Float/Color elements
		for (let child in matEl.Children)
		{
			if (let el = child as XmlElement)
			{
				if (el.TagName == "Float")
				{
					let propName = el.GetAttribute("name");
					let propValue = el.GetAttribute("value");
					if (float.Parse(propValue) case .Ok(let val))
					{
						if (propName == "Metallic") metallic = val;
						else if (propName == "Roughness") roughness = val;
						else if (propName == "AO") ao = val;
						else if (propName == "AlphaCutoff") alphaCutoff = val;
					}
				}
				else if (el.TagName == "Color")
				{
					let propName = el.GetAttribute("name");
					float r = 0, g = 0, b = 0, a = 1;
					if (float.Parse(el.GetAttribute("r")) case .Ok(let v)) r = v;
					if (float.Parse(el.GetAttribute("g")) case .Ok(let v)) g = v;
					if (float.Parse(el.GetAttribute("b")) case .Ok(let v)) b = v;
					if (float.Parse(el.GetAttribute("a")) case .Ok(let v)) a = v;
					if (propName == "BaseColor") baseColor = .(r, g, b, a);
					else if (propName == "EmissiveColor") emissiveColor = .(r, g, b, a);
				}
			}
		}

		// Create PBR material via the standard factory
		let mat = Materials.CreatePBR(assetName, "forward");

		mat.SetDefaultFloat4("BaseColor", baseColor);
		mat.SetDefaultFloat("Metallic", metallic);
		mat.SetDefaultFloat("Roughness", roughness);
		mat.SetDefaultFloat("AO", ao);
		mat.SetDefaultFloat("AlphaCutoff", alphaCutoff);
		mat.SetDefaultFloat4("EmissiveColor", emissiveColor);

		// Shader flags
		if (isEmissive)
		{
			mat.ShaderFlags |= .Emissive;
			mat.PipelineConfig.ShaderFlags |= .Emissive;
		}
		if (isDoubleSided)
		{
			mat.ShaderFlags |= .DoubleSided;
			mat.PipelineConfig.ShaderFlags |= .DoubleSided;
			mat.PipelineConfig.CullMode = .None;
		}
		if (blendMode == "cutout")
		{
			mat.ShaderFlags |= .AlphaTest;
			mat.PipelineConfig.ShaderFlags |= .AlphaTest;
			mat.PipelineConfig.BlendMode = .Masked;
		}
		else if (blendMode == "fade" || blendMode == "transparent")
		{
			mat.PipelineConfig.BlendMode = .AlphaBlend;
			mat.PipelineConfig.DepthMode = .ReadOnly;
		}

		// Wrap in resource
		let matRes = new MaterialResource(mat, true);
		defer delete matRes;
		matRes.Name.Set(assetName);

		// Import textures and wire into material
		for (let child in matEl.Children)
		{
			if (let el = child as XmlElement)
			{
				if (el.TagName != "Texture") continue;

				let texFile = el.GetAttribute("file");
				let slot = el.GetAttribute("slot");
				if (texFile.IsEmpty || slot.IsEmpty) continue;

				let texPath = scope String();
				Path.InternalCombine(texPath, assetSourcePath, texFile);

				if (!File.Exists(texPath))
				{
					Console.WriteLine("    WARNING: Texture not found: {}", texFile);
					continue;
				}

				if (TextureImporter.Import2D(texPath) case .Ok(let texRes))
				{
					// Name based on asset + slot
					let texName = scope String();
					if (slot == "AlbedoMap")
						texName.Set(assetName);
					else
					{
						let slotShort = scope String();
						if (slot == "EmissiveMap") slotShort.Set("Emission");
						else if (slot == "NormalMap") slotShort.Set("Normal");
						else if (slot == "MetallicRoughnessMap") slotShort.Set("MetallicRoughness");
						else if (slot == "OcclusionMap") slotShort.Set("Occlusion");
						else slotShort.Set(slot);
						texName.AppendF("{}_{}", assetName, slotShort);
					}
					texRes.Name.Set(texName);

					let texFileName = scope String();
					texFileName.AppendF("{}.texture", texName);
					ResourceSerializer.SanitizePath(texFileName);

					// Wire into material with full registry URI
					let texUri = scope String();
					BuildRegistryUri(mount, texFileName, texUri);
					matRes.SetTextureRef(slot, ResourceRef(texRes.Id, texUri));

					// Enable normal map shader flag if normal texture is assigned
					if (slot == "NormalMap")
					{
						mat.ShaderFlags |= .NormalMap;
						mat.PipelineConfig.ShaderFlags |= .NormalMap;
					}

					if (SaveTextureWithSidecar(texRes, texFileName, mount))
					{
						Console.WriteLine("    Texture [{}]: {}", slot, texName);
						mTotalResources++;
					}

					delete texRes;
				}
				else
				{
					Console.WriteLine("    WARNING: Failed to import texture: {}", texFile);
				}
			}
		}

		// Save material
		let matFileName = scope String();
		matFileName.AppendF("{}.material", assetName);
		ResourceSerializer.SanitizePath(matFileName);
		if (SaveResource(matRes, matFileName, mount))
		{
			Console.WriteLine("    Material: {}", assetName);
			mTotalResources++;
		}
	}

	/// Saves FBX-imported materials and their textures with _Imported suffix
	/// so they can be compared with the manifest-generated material.
	private void SaveFbxMaterials(ResourceImportResult result, StringView assetName,
		FileSystemMount mount)
	{
		// Save textures first — rename each to include _Imported suffix.
		// The FBX converter already set texture names and material refs point to "{texName}.texture".
		// After renaming textures, we update material refs to match.
		for (let texRes in result.Textures)
		{
			let origName = scope String();
			origName.Set(texRes.Name);

			let texName = scope String();
			if (!origName.IsEmpty)
				texName.AppendF("{}_Imported", origName);
			else
				texName.AppendF("{}_Imported_tex{}", assetName, @texRes.Index);

			texRes.Name.Set(texName);

			let texFileName = scope String();
			texFileName.AppendF("{}.texture", texName);
			ResourceSerializer.SanitizePath(texFileName);

			if (SaveTextureWithSidecar(texRes, texFileName, mount))
			{
				Console.WriteLine("    Texture [FBX]: {}", texName);
				mTotalResources++;
			}
		}

		// Save materials — rename and remap texture refs to full registry URIs
		for (let matRes in result.Materials)
		{
			let matName = scope String();
			matName.AppendF("{}_Imported", assetName);
			matRes.Name.Set(matName);

			// Collect slot updates (can't modify dictionary while iterating)
			let updates = scope List<(String slot, ResourceRef newRef)>();
			for (let kv in matRes.TextureRefs)
			{
				let texRef = kv.value;
				if (texRef.Id == .()) continue;

				// Find the renamed texture by GUID to get its current name
				for (let texRes in result.Textures)
				{
					if (texRes.Id == texRef.Id)
					{
						let texFileName = scope:: String();
						texFileName.AppendF("{}.texture", texRes.Name);
						ResourceSerializer.SanitizePath(texFileName);

						let texUri = scope:: String();
						BuildRegistryUri(mount, texFileName, texUri);

						updates.Add((scope:: String(kv.key), ResourceRef(texRef.Id, texUri)));
						break;
					}
				}
			}

			for (let update in updates)
				matRes.SetTextureRef(update.slot, update.newRef);

			let matFileName = scope String();
			matFileName.AppendF("{}.material", matName);
			ResourceSerializer.SanitizePath(matFileName);
			if (SaveResource(matRes, matFileName, mount))
			{
				Console.WriteLine("    Material [FBX]: {}", matName);
				mTotalResources++;
			}
		}
	}

	// ==================== AnimGraph & Prefab Generation ====================

	/// Generates an AnimationGraphResource with one ClipStateNode per clip.
	/// Default state = first clip (index 0, typically "Idle").
	private bool GenerateAnimGraph(StringView assetName, List<ClipInfo> clips,
		StringView fileName, FileSystemMount mount)
	{
		let graph = new AnimationGraph();
		defer delete graph;

		let layer = new AnimationLayer("Base Layer");
		layer.DefaultStateIndex = 0;

		for (let clip in clips)
		{
			var clipRef = ResourceRef(clip.Id, clip.Uri);
			let node = new ClipStateNode(null, clipRef);
			clipRef.Dispose();

			let state = new AnimationGraphState(clip.Name, node, ownsNode: true);
			state.Loop = true;
			state.Speed = 1.0f;
			layer.AddState(state);
		}

		graph.AddLayer(layer);

		let resource = new AnimationGraphResource(graph);
		defer delete resource;
		resource.Name.Set(assetName);

		if (SaveResource(resource, fileName, mount))
		{
			mTotalResources++;
			return true;
		}
		return false;
	}

	/// Generates a prefab file with a single entity containing SkinnedMeshComponent
	/// and AnimationGraphComponent. Writes the serialized format directly to avoid
	/// pulling in Engine.Render dependencies.
	private bool GeneratePrefab(StringView assetName, AssetRefs refs,
		ResourceRef graphRef, StringView fileName, FileSystemMount mount)
	{
		let prefab = new GeneratedPrefabResource();
		defer delete prefab;
		prefab.Name.Set(assetName);
		prefab.EntityName.Set(assetName);
		prefab.SkinnedMeshRef = refs.SkinnedMeshRef;
		prefab.StaticMeshRef = refs.StaticMeshRef;
		prefab.SkeletonRef = refs.SkeletonRef;
		prefab.MaterialRef = refs.MaterialRef;
		prefab.GraphRef = graphRef;

		if (SaveResource(prefab, fileName, mount))
		{
			mTotalResources++;
			return true;
		}
		return false;
	}

	/// Reads the resource GUID from a saved resource file's header.
	private Result<Guid> ReadResourceId(FileSystemMount mount, StringView fileName)
	{
		let openResult = mount.Open(fileName);
		if (openResult case .Err)
			return .Err;
		let stream = openResult.Value;
		defer delete stream;

		let text = scope String();
		let buf = scope uint8[stream.Length];
		switch (stream.TryRead(.((.)&buf[0], buf.Count)))
		{
		case .Ok(let bytesRead):
			text.Append((char8*)&buf[0], bytesRead);
		case .Err:
			return .Err;
		}

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err;
		defer delete reader;

		// Read just the header — _id is the GUID
		var typeHash = (uint64)0;
		reader.UInt64("_type", ref typeHash);
		var version = (int32)0;
		reader.Version(ref version);

		let guidStr = scope String();
		reader.String("_id", guidStr);
		if (Guid.Parse(guidStr) case .Ok(let guid))
			return .Ok(guid);

		return .Err;
	}

	// ==================== Model Import ====================

	/// Result of a model import. Caller must delete all three in reverse order:
	/// resResult, then importResult, then model.
	struct ImportBundle
	{
		public Model Model;
		public ModelImportResult ImportResult;
		public ResourceImportResult ResResult;

		public void Dispose() mut
		{
			if (ResResult != null) delete ResResult;
			if (ImportResult != null) delete ImportResult;
			if (Model != null) delete Model;
		}
	}

	private Result<ImportBundle> ImportModel(StringView modelPath, ModelImportFlags flags)
	{
		let model = new Model();
		if (ModelLoaderFactory.LoadModel(modelPath, model) != .Ok)
		{
			delete model;
			return .Err;
		}

		let baseDir = scope String();
		Path.GetDirectoryPath(modelPath, baseDir);

		let options = new ModelImportOptions();
		options.Flags = flags;
		options.BasePath.Set(baseDir);
		options.ModelPath.Set(modelPath);

		let importer = scope ModelImporter(options);
		let importResult = importer.Import(model);

		let resResult = ResourceImportResult.ConvertFrom(importResult, null, modelPath);

		return .Ok(.() { Model = model, ImportResult = importResult, ResResult = resResult });
	}

	// ==================== Save Resources ====================

	private void SaveMeshAndSkeleton(ResourceImportResult result, StringView assetName,
		FileSystemMount mount)
	{
		for (let res in result.StaticMeshes)
		{
			let fileName = scope String();
			fileName.AppendF("{}.mesh", assetName);
			ResourceSerializer.SanitizePath(fileName);
			if (SaveResource(res, fileName, mount))
				mTotalResources++;
		}

		for (let res in result.SkinnedMeshes)
		{
			let fileName = scope String();
			fileName.AppendF("{}.skinnedmesh", assetName);
			ResourceSerializer.SanitizePath(fileName);
			if (SaveResource(res, fileName, mount))
				mTotalResources++;
		}

		for (let res in result.Skeletons)
		{
			let fileName = scope String();
			fileName.AppendF("{}.skeleton", assetName);
			ResourceSerializer.SanitizePath(fileName);
			if (SaveResource(res, fileName, mount))
				mTotalResources++;
		}
	}

	private bool SaveResource(Resource res, StringView fileName, FileSystemMount mount)
	{
		let memStream = scope MemoryStream();
		if (res.WriteToStream(memStream, mSerializerProvider) case .Err)
		{
			Console.WriteLine("    ERROR: Failed to serialize {}", fileName);
			mTotalErrors++;
			return false;
		}
		memStream.Position = 0;

		if (mount.Save(fileName, memStream) case .Err)
		{
			Console.WriteLine("    ERROR: Failed to write {}", fileName);
			mTotalErrors++;
			return false;
		}

		// Register in the resource index
		let uri = scope String();
		BuildRegistryUri(mount, fileName, uri);
		mRegistry.Register(res.Id, uri);

		return true;
	}

	private bool SaveTextureWithSidecar(TextureResource res, StringView fileName, FileSystemMount mount)
	{
		// 1. Text metadata
		{
			let memStream = scope MemoryStream();
			if (res.WriteToStream(memStream, mSerializerProvider) case .Err)
			{
				Console.WriteLine("    ERROR: Failed to serialize texture metadata {}", fileName);
				mTotalErrors++;
				return false;
			}
			memStream.Position = 0;
			if (mount.Save(fileName, memStream) case .Err)
			{
				Console.WriteLine("    ERROR: Failed to write texture metadata {}", fileName);
				mTotalErrors++;
				return false;
			}
		}

		// 2. Binary pixel sidecar (.bin)
		{
			let sidecarName = scope String();
			sidecarName.AppendF("{}.bin", fileName);

			let pixelStream = scope MemoryStream();
			if (res.WritePixelsToStream(pixelStream) case .Err)
			{
				Console.WriteLine("    ERROR: Failed to serialize texture pixels {}", sidecarName);
				mTotalErrors++;
				return false;
			}
			pixelStream.Position = 0;
			if (mount.Save(sidecarName, pixelStream) case .Err)
			{
				Console.WriteLine("    ERROR: Failed to write texture sidecar {}", sidecarName);
				mTotalErrors++;
				return false;
			}
		}

		// Register in the resource index
		let uri = scope String();
		BuildRegistryUri(mount, fileName, uri);
		mRegistry.Register(res.Id, uri);

		return true;
	}

	/// Builds the full registry URI for a file in the given mount.
	/// E.g. "cuteseries://Units/Pack01/Bat/Bat.texture"
	private void BuildRegistryUri(FileSystemMount mount, StringView fileName, String outUri)
	{
		let relPath = scope String();
		relPath.Append(mount.RootPath[(mOutputRoot.Length + 1)...]);
		relPath.Append("/");
		relPath.Append(fileName);
		relPath.Replace('\\', '/');
		outUri.AppendF("cuteseries://{}", relPath);
	}

	// ==================== Helpers ====================

	private static XmlElement FindChild(XmlElement parent, StringView tagName)
	{
		for (let child in parent.Children)
		{
			if (let el = child as XmlElement)
			{
				if (el.TagName == tagName)
					return el;
			}
		}
		return null;
	}
}
