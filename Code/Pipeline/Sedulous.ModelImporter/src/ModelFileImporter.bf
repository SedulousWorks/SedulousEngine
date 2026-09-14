using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// Imports a model file: the source file lands in the sources tree and everything inside it
/// fans out as its own asset in a subgroup named after the file.
///
/// A subgroup rather than a flat drop, because one model can carry dozens of meshes, materials
/// and textures, and a browser that mixed them in with everything else would be unusable after
/// two imports.
class ModelFileImporter : IFileImporter
{
	private const String cManifestType = "Sedulous.ModelImporter.ModelManifestAsset";

	public StringView Label => "Model";

	public bool Accepts(StringView @extension)
	{
		switch (@extension)
		{
		case "glb", "gltf", "fbx", "obj":
			return true;
		default:
			return false;
		}
	}

	public ImportOptions CreateOptions() => new ModelImportOptions();

	/// Parsing the file and decoding its images is nearly all of a model import, and none of
	/// it touches the project, so it belongs off the interface thread.
	public bool WantsWorkerPrepare => true;

	public Object PrepareOnWorker(StringView sourcePath)
	{
		let loaded = new LoadedModel();
		if (ModelFileLoad.Load(sourcePath, loaded.Model) != .Ok)
		{
			delete loaded;
			return null;
		}
		return loaded;
	}

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan)
	{
		let defaults = scope ModelImportOptions();
		var opt = options as ModelImportOptions;
		if (opt == null)
			opt = defaults;

		// The worker already loaded it in the two phase path; a headless caller or a test gets
		// the inline load instead.
		let inlineModel = scope Model();
		var model = inlineModel;
		if (let payload = prepared as LoadedModel)
		{
			model = payload.Model;
		}
		else if (ModelFileLoad.Load(sourcePath, inlineModel) != .Ok)
		{
			return;
		}

		void Add(ImportResourceKind kind, StringView name)
			=> outPlan.Add(new ImportPlanEntry(kind, name, name));

		if (opt.ImportTextures)
		{
			let textures = model.Textures;
			for (int i < textures.Length)
			{
				let texture = textures[i];
				// An undecodable image never becomes an asset, so it is not offered either.
				if ((texture == null) || texture.Data.IsEmpty || (texture.Width <= 0)
					|| (texture.Height <= 0)
					|| (texture.DataSize != (int)texture.Width * (int)texture.Height * 4))
				{
					continue;
				}
				let name = scope String();
				ImportedNames.ForTexture(texture, i, name);
				Add(.Texture, name);
			}
		}

		if (opt.ImportMaterials)
		{
			let materials = model.Materials;
			for (int i < materials.Length)
			{
				let name = scope String();
				ImportedNames.ForAsset(materials[i].Name, "mat", i, name);
				Add(.Material, name);
			}
		}

		if (opt.ImportAnimations && !model.Skins.IsEmpty)
		{
			let skeletonName = scope String();
			ImportedNames.ForSkeleton(model.Skins[0], skeletonName);
			Add(.Skeleton, skeletonName);

			let animations = model.Animations;
			for (int a < animations.Length)
			{
				let name = scope String();
				ImportedNames.ForAsset(animations[a].Name, "anim", a, name);
				Add(.AnimationClip, name);
			}
		}

		// The SAME fold the fan out runs, so the dialog lists exactly the mesh assets the
		// import will create rather than one per model mesh.
		let hasSkin = !model.Skins.IsEmpty;
		let meshes = model.Meshes;
		let foldsInto = scope List<int32>();
		let lodLevels = scope List<List<int>>();
		defer { ClearAndDeleteItems!(lodLevels); }
		ModelLodFold.Compute(model, foldsInto, lodLevels);

		for (int i < meshes.Length)
		{
			if (foldsInto[i] >= 0)
				continue;

			let name = scope String();
			ImportedNames.ForAsset(meshes[i].Name, "mesh", i, name);
			Add(.Mesh, name);

			if (opt.GenerateCollision && !(ModelCook.IsSkinned(meshes[i]) && hasSkin))
				Add(.Collision, scope $"{name}.collision");
		}
	}

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
	{
		let stem = ImportPaths.StemOf(ImportPaths.FileNameOf(sourcePath));
		let modelGroup = group.GetGroup(stem);
		if (modelGroup == null)
			return;

		let instance = modelGroup.GetInstance(stem);
		if ((instance == null) || (instance.TypeName != cManifestType))
			return;

		// THE CALLER OWNS what the read returns.
		let object = instance.ReadObject();
		if (object == null)
			return;
		defer delete object;

		// An interface handle reaches its class through the object it is part of.
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as ModelManifestAsset;
		if (asset == null)
			return;

		// COPIED out rather than handed over: the asset it lives on is deleted on the way out
		// of this call, and the plan has to outlive it.
		for (let entry in asset.ImportSelection.Entries)
		{
			let copy = new ImportPlanEntry(entry.Kind, entry.SourceName, entry.TargetName);
			copy.Enabled = entry.Enabled;
			outPlan.Add(copy);
		}
	}

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let defaults = scope ModelImportOptions();
		var opt = options as ModelImportOptions;
		if (opt == null)
			opt = defaults;

		// The source's NAME is known without copying it; the copy itself, and the sidecars
		// below, are bulk file work that goes to the worker when there is one.
		let sourceFileName = ImportPaths.FileNameOf(sourcePath);
		if (sourceFileName.IsEmpty)
			return .Err(.InvalidArgument);

		let fileName = scope String();
		if (deferredWrites != null)
		{
			fileName.Set(sourceFileName);
			let copy = new DeferredImportWrite();
			copy.CopyFrom.Set(sourcePath);
			PathJoin(context.SourcesRoot, sourceFileName, copy.CopyTo);
			deferredWrites.Add(copy);
		}
		else if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let error))
		{
			return .Err(error);
		}

		// The load either arrived from the worker phase or runs inline. Either way it reads
		// the ORIGINAL path: a .gltf names sidecars living beside the file it was dropped
		// from, not beside the copy in the sources tree.
		let inlineModel = scope Model();
		var model = inlineModel;
		if (let payload = prepared as LoadedModel)
		{
			model = payload.Model;
		}
		else if (ModelFileLoad.Load(sourcePath, inlineModel) != .Ok)
		{
			return .Err(.InvalidArgument);
		}

		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		if (suffix == "gltf")
			GltfSidecars.Copy(sourcePath, context, deferredWrites);

		let stem = ImportPaths.StemOf(fileName);
		let modelGroup = group.CreateGroup(stem);
		if (modelGroup == null)
			return .Err(.Unknown);

		let manifestAsset = scope ModelManifestAsset();
		manifestAsset.FileName.Set(fileName);
		let manifest = manifestAsset.Manifest;
		manifest.BoundsMin = model.Bounds.Min;
		manifest.BoundsMax = model.Bounds.Max;

		// Re-import memory: what the dialog settled this time is what the next import starts
		// from.
		for (let entry in opt.Selection.Entries)
		{
			let copy = new ImportPlanEntry(entry.Kind, entry.SourceName, entry.TargetName);
			copy.Enabled = entry.Enabled;
			manifestAsset.ImportSelection.Add(copy);
		}

		// Names claimed THIS run, which is the scope a numeric suffix disambiguates within.
		let claimed = scope List<String>();
		defer { ClearAndDeleteItems!(claimed); }

		let textureGuids = scope List<Guid>();
		if (opt.ImportTextures)
		{
			ModelImportTextures.Import(model, modelGroup, opt, textureGuids, claimed,
				deferredWrites);
		}
		else
		{
			// The list stays parallel to the model's textures whether they imported or not, so
			// a material's texture index still lands where it should.
			for (int i < model.Textures.Length)
				textureGuids.Add(.Empty);
		}

		if (opt.ImportMaterials)
		{
			ModelImportMaterials.Import(model, modelGroup, textureGuids, manifest, claimed,
				deferredWrites, opt);
		}
		if (opt.ImportAnimations)
			ModelImportSkeleton.Import(model, modelGroup, manifest, claimed, opt);

		// Per manifest mesh slot, which is what the collision pass keys its decisions on.
		let meshSourceNames = scope List<String>();
		defer { ClearAndDeleteItems!(meshSourceNames); }
		if (ModelImportMeshes.Import(model, modelGroup, manifest, claimed, deferredWrites,
			opt.GenerateLods, opt, meshSourceNames) case .Err(let meshError))
		{
			return .Err(meshError);
		}

		if (opt.GenerateCollision)
		{
			ModelImportCollision.Import(modelGroup, manifest, opt.CollisionConvex, claimed, opt,
				meshSourceNames);
		}
		ModelImportNodes.Import(model, manifest);

		let instance = modelGroup.CreateInstance(stem, cManifestType);
		if (instance == null)
			return .Err(.Unknown);
		if (instance.WriteObject(manifestAsset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
