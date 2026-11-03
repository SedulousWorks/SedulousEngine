using System;
using System.Collections;
using System.Reflection;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Pipeline.Core;
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
	/// Listed by its manifest, while it names no single asset type (AssetTypeName): it makes several.
	public StringView ListedTypeName(StringView sourcePath) => cManifestType;

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

	/// A clip's root motion: as its asset has it from an earlier import into `group`, else the
	/// file's Root motion default (travel and turn).
	public RefCounted PartSettings(StringView sourcePath, ImportOptions options, ImportPlanEntry part, Group group)
	{
		if (part.Kind != .AnimationClip)
			return null;
		let settings = new ClipImportSettings();
		let opt = options as ModelImportOptions;
		settings.Travel = settings.Turn = (opt != null) && opt.RootMotion;
		// The clip as an earlier import made it: its folder group, named after the file.
		let stem = ImportPaths.StemOf(ImportPaths.FileNameOf(sourcePath));
		let folder = (group != null) ? group.GetGroup(stem) : null;
		let name = part.TargetName.IsEmpty ? part.SourceName : part.TargetName;
		let clip = (folder != null) ? folder.GetInstance(name) : null;
		if (clip != null)
		{
			let read = clip.ReadObject(); // ours
			defer { if (read != null) delete read; }
			if (let before = read as Sedulous.Animation.Pipeline.AnimationClipAsset)
			{
				settings.Travel = before.Source.RootHorizontal;
				settings.Vertical = before.Source.RootVertical;
				settings.Turn = before.Source.RootYaw;
			}
		}
		return settings;
	}

	/// Root motion is each clip's own; the file's setting is the default for new clips.
	public bool SettingIsPerPart(StringView setting) => setting == "RootMotion";

	/// Textures, materials, and the skeleton with its clips each have a setting that leaves them out.
	public StringView KindSetting(ImportResourceKind kind)
	{
		switch (kind)
		{
		case .Texture: return "ImportTextures";
		case .Material: return "ImportMaterials";
		case .Skeleton, .AnimationClip: return "ImportAnimations";
		default: return default;
		}
	}

	/// The import makes the model's folder group, named after the file.
	public bool ImportsIntoItsOwnGroup => true;

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

	/// What a part holds, read from the model the worker read: a mesh's triangles and its parts by
	/// material; a material's shading, colour, metallic, roughness, textures and the parts that draw
	/// with it; a texture's size and the materials using it; the skeleton's bones; a clip's length; a
	/// collision shape's mesh and kind. A part is matched to the model by the name the plan gives it.
	/// Nothing without that read.
	public void DescribePart(StringView sourcePath, ImportOptions options, Object prepared, ImportPlanEntry part,
		List<ImportPartFact> outFacts)
	{
		let loaded = prepared as LoadedModel;
		if (loaded == null)
			return;
		let model = loaded.Model;
		let name = scope String();
		switch (part.Kind)
		{
		case .Mesh, .Collision:
			let collision = part.Kind == .Collision;
			let meshes = model.Meshes;
			for (int i < meshes.Length)
			{
				let mesh = meshes[i];
				let meshName = ImportedNames.ForAsset(mesh.Name, "mesh", i, .. scope .());
				name.Set(meshName);
				if (collision)
					name.Append(".collision");
				if (name != part.SourceName)
					continue;
				if (collision)
				{
					let modelOptions = options as ModelImportOptions;
					Fact(outFacts, "From the mesh", meshName);
					Fact(outFacts, "Shape", ((modelOptions != null) && modelOptions.CollisionConvex) ? "Convex hull" : "Triangle mesh");
					Fact(outFacts, "Triangles", Grouped(MeshTriangles(mesh), .. scope .()));
					break;
				}
				Fact(outFacts, "Triangles", Grouped(MeshTriangles(mesh), .. scope .()));
				Fact(outFacts, "Skinned", ModelCook.IsSkinned(mesh) ? "Yes" : "No");
				let parts = mesh.Parts;
				Fact(outFacts, "Parts", Grouped((uint64)parts.Length, .. scope .()));
				for (int p < parts.Length)
				{
					let value = MaterialName(model, parts[p].MaterialIndex, .. scope .());
					value.Append(", ");
					Grouped((uint64)Math.Max(parts[p].IndexCount, 0) / 3, value);
					value.Append(" triangles");
					Fact(outFacts, scope $"Part {p + 1}", value);
				}
				break;
			}
		case .Material:
			let materials = model.Materials;
			for (int i < materials.Length)
			{
				let material = materials[i];
				name.Clear();
				ImportedNames.ForAsset(material.Name, "mat", i, name);
				if (name != part.SourceName)
					continue;
				StringView shading;
				switch (material.Shading)
				{
				case .Phong: shading = "Phong";
				case .Lambert: shading = "Lambert";
				case .Unlit: shading = "Unlit";
				default: shading = "PBR, metallic and roughness";
				}
				Fact(outFacts, "Shading", shading);
				let colour = material.BaseColorFactor;
				Fact(outFacts, "Base colour", scope String()..AppendF("R {:F2} G {:F2} B {:F2}", colour.X, colour.Y, colour.Z));
				Fact(outFacts, "Metallic", scope String()..AppendF("{:F2}", material.MetallicFactor));
				Fact(outFacts, "Roughness", scope String()..AppendF("{:F2}", material.RoughnessFactor));
				let slots = scope String();
				TextureSlot(model, material.BaseColorTextureIndex, "base colour", slots);
				TextureSlot(model, material.NormalTextureIndex, "normal", slots);
				TextureSlot(model, material.MetallicRoughnessTextureIndex, "metal rough", slots);
				TextureSlot(model, material.OcclusionTextureIndex, "occlusion", slots);
				TextureSlot(model, material.EmissiveTextureIndex, "emissive", slots);
				Fact(outFacts, "Textures", slots.IsEmpty ? "None" : (StringView)slots);
				let users = scope String();
				int count = 0;
				let drawing = model.Meshes;
				for (int mi < drawing.Length)
				{
					let parts = drawing[mi].Parts;
					for (int pi < parts.Length)
					{
						if (parts[pi].MaterialIndex != (int32)i)
							continue;
						if (count < 3)
						{
							if (!users.IsEmpty)
								users.Append(", ");
							users.Append(ImportedNames.ForAsset(drawing[mi].Name, "mesh", mi, .. scope .()));
							users.AppendF(", part {}", pi + 1);
						}
						count++;
					}
				}
				if (count > 3)
					users.AppendF(", and {} more", count - 3);
				Fact(outFacts, "Used by", (count == 0) ? "No part" : (StringView)users);
				break;
			}
		case .Texture:
			let textures = model.Textures;
			for (int i < textures.Length)
			{
				name.Clear();
				ImportedNames.ForTexture(textures[i], i, name);
				if (name != part.SourceName)
					continue;
				Fact(outFacts, "Size", scope String()..AppendF("{} × {}", textures[i].Width, textures[i].Height));
				let users = scope String();
				for (let material in model.Materials)
				{
					if (material == null)
						continue;
					StringView slot = default;
					if (material.BaseColorTextureIndex == (int32)i)
						slot = "base colour";
					else if (material.NormalTextureIndex == (int32)i)
						slot = "normal";
					else if (material.MetallicRoughnessTextureIndex == (int32)i)
						slot = "metal rough";
					else if (material.OcclusionTextureIndex == (int32)i)
						slot = "occlusion";
					else if (material.EmissiveTextureIndex == (int32)i)
						slot = "emissive";
					if (slot.IsEmpty)
						continue;
					if (!users.IsEmpty)
						users.Append(", ");
					users.AppendF("{} ({})", material.Name, slot);
				}
				Fact(outFacts, "Used by", users.IsEmpty ? "No material" : (StringView)users);
				break;
			}
		case .Skeleton:
			if (!model.Skins.IsEmpty)
			{
				let skin = model.Skins[0];
				Fact(outFacts, "Bones", Grouped((uint64)skin.JointCount, .. scope .()));
				let joints = skin.Joints;
				if (!joints.IsEmpty && (joints[0] >= 0) && (joints[0] < model.Bones.Length))
					Fact(outFacts, "Root bone", model.Bones[joints[0]].Name);
			}
		case .AnimationClip:
			let animations = model.Animations;
			for (int a < animations.Length)
			{
				name.Clear();
				ImportedNames.ForAsset(animations[a].Name, "anim", a, name);
				if (name != part.SourceName)
					continue;
				Fact(outFacts, "Length", scope String()..AppendF("{:F2} s", animations[a].Duration));
				Fact(outFacts, "Channels", Grouped((uint64)animations[a].ChannelCount, .. scope .()));
				break;
			}
		default:
		}
	}

	/// `count` with its thousands grouped ("4,992"), appended.
	public static void Grouped(uint64 count, String outText)
	{
		let digits = scope String()..AppendF("{}", count);
		for (int i < digits.Length)
		{
			if ((i > 0) && (((digits.Length - i) % 3) == 0))
				outText.Append(',');
			outText.Append(digits[i]);
		}
	}

	private static void Fact(List<ImportPartFact> outFacts, StringView label, StringView value) => outFacts.Add(new ImportPartFact(label, value));

	/// A mesh's triangles: its corners, three at a time (a mesh with no index buffer draws its
	/// vertices so).
	private static uint64 MeshTriangles(ModelMesh mesh)
	{
		let corners = (mesh.IndexCount > 0) ? mesh.IndexCount : mesh.VertexCount;
		return (uint64)Math.Max(corners, 0) / 3;
	}

	/// The material `index` names in `model`, appended; "No material" when it names none.
	private static void MaterialName(Model model, int32 index, String outName)
	{
		if ((index >= 0) && (index < model.Materials.Length))
			outName.Append(model.Materials[index].Name);
		else
			outName.Append("No material");
	}

	/// The texture `index` names, with its `slot`, appended to the list `outText` holds.
	private static void TextureSlot(Model model, int32 index, StringView slot, String outText)
	{
		if ((index < 0) || (index >= model.Textures.Length))
			return;
		if (!outText.IsEmpty)
			outText.Append(", ");
		outText.Append(ImportedNames.ForTexture(model.Textures[index], index, .. scope .()));
		outText.AppendF(" ({})", slot);
	}

	/// The scale's note: how tall the model comes in with it (and the up axis), from the model read
	/// on the worker.
	public void DescribeSetting(StringView sourcePath, ImportOptions options, Object prepared, FieldInfo setting,
		String outEffect, String outReason)
	{
		let loaded = prepared as LoadedModel;
		let chosen = options as ModelImportOptions;
		if ((loaded == null) || (chosen == null) || (setting.Name != "Scale"))
			return;
		let bounds = loaded.Model.Bounds;
		if (!bounds.IsValid())
			return;
		let scale = (chosen.Scale > 0.0f) ? chosen.Scale : 1.0f;
		let height = ((chosen.UpAxis == .Z) ? (bounds.Max.Z - bounds.Min.Z) : (bounds.Max.Y - bounds.Min.Y)) * scale;
		if (height < 1.0f)
			outEffect.AppendF("Makes it {:F3} m tall", height);
		else
			outEffect.AppendF("Makes it {:F2} m tall", height);
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

	/// A model claims its folder (named after the file) and the manifest in it: another file's
	/// model there is a clash of its type; anything else in the folder keeps the name apart as
	/// before (the manifest takes the next free one).
	public void FindClash(Group group, StringView sourcePath, ImportPlan plan, StringView ledgerPath, ImportClash outClash)
	{
		outClash.Clear();
		let stem = ImportPaths.StemOf(ImportPaths.FileNameOf(sourcePath));
		let modelGroup = group.GetGroup(stem);
		if (modelGroup == null)
			return;
		ImportPaths.FindImportClash(modelGroup, stem, cManifestType, sourcePath, ledgerPath, outClash);
		if (outClash.Kind == .OtherType)
			outClash.Clear();
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

		// The clash rule (ImportPaths.FindImportClash) over the model's folder: another file's
		// model there is refused, replaced or kept beside under the next folder name, as the
		// context says; this file's own earlier import is re-imported in place.
		let clash = scope ImportClash();
		FindClash(group, sourcePath, null, context.LedgerPath, clash);
		if (!ImportPaths.ImportClashAllows(clash, context.OnConflict))
			return .Err(.AlreadyExists);
		let folderName = scope String(ImportPaths.StemOf(sourceFileName));
		var overwriteOwn = false; // a new model never writes over a file another one copied in
		if ((clash.Kind == .Reimport) || ((clash.Kind == .SameType) && (context.OnConflict == .Replace)))
		{
			if (let previous = clash.Existing.ReadObject())
			{
				defer delete previous;
				if (let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(previous)) as Asset)
					overwriteOwn = asset.FileName.Value == sourceFileName;
			}
		}
		else if (clash.Kind == .SameType)
		{
			let free = scope String();
			group.UniqueGroupName(folderName, free); // KeepBoth
			folderName.Set(free);
		}

		let fileName = scope String();
		if (deferredWrites != null)
		{
			// Named now (from what is there and the ledger), copied on the worker.
			ImportPaths.SourcesNameFor(context, sourcePath, fileName, overwriteOwn);
			let copy = new DeferredImportWrite();
			copy.CopyFrom.Set(sourcePath);
			PathJoin(context.SourcesRoot, fileName, copy.CopyTo);
			deferredWrites.Add(copy);
		}
		else if (ImportPaths.CopyIntoSources(context, sourcePath, fileName, overwriteOwn) case .Err(let error))
		{
			return .Err(error);
		}

		// The load either arrived from the worker phase or runs inline. Either way it reads
		// the ORIGINAL path: a .gltf names sidecars living beside the file it was dropped
		// from, not beside the copy in the sources tree.
		let inlineModel = scope Model();
		var model = inlineModel;
		// A PREPARED model outlives the deferred flush, the caller holding it for exactly
		// that; an inline one dies with this call. Only the former can have its mesh work
		// deferred onto the worker.
		var preparedModel = false;
		if (let payload = prepared as LoadedModel)
		{
			model = payload.Model;
			preparedModel = true;
		}
		else if (ModelFileLoad.Load(sourcePath, inlineModel) != .Ok)
		{
			return .Err(.InvalidArgument);
		}
		ModelImportFrame.Apply(model, opt.Scale, opt.UpAxis); // before anything reads a length or a direction

		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		let sidecarsCopied = suffix == "gltf";
		if (sidecarsCopied)
			GltfSidecars.Copy(sourcePath, context, deferredWrites);

		let stem = StringView(folderName); // the folder's and the manifest's name
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
		// The manifest is named for the file and written last: its name is reserved first, so a
		// sub-asset named like the model (a material "Gem_Blue" in Gem_Blue.gltf) takes a suffix
		// rather than the manifest's instance.
		claimed.Add(new String(stem));

		let textureGuids = scope List<Guid>();
		if (opt.ImportTextures)
		{
			ModelImportTextures.Import(model, context, sidecarsCopied, modelGroup, opt,
				textureGuids, claimed, deferredWrites);
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
			opt.GenerateLods, opt, meshSourceNames, preparedModel && (deferredWrites != null))
			case .Err(let meshError))
		{
			return .Err(meshError);
		}

		if (opt.GenerateCollision)
		{
			ModelImportCollision.Import(modelGroup, manifest, opt.CollisionConvex, claimed, opt,
				meshSourceNames);
		}
		ModelImportNodes.Import(model, manifest);

		// A previous import's manifest is reused (its guid survives a re-import); a different type
		// squatting the name (an import from before the name was reserved) keeps its instance,
		// and the manifest takes the next free name.
		var instance = modelGroup.GetInstance(stem);
		if (instance == null)
		{
			instance = modelGroup.CreateInstance(stem, cManifestType);
		}
		else if (instance.TypeName != cManifestType)
		{
			let name = scope String();
			modelGroup.UniqueInstanceName(stem, name);
			instance = modelGroup.CreateInstance(name, cManifestType);
		}
		if (instance == null)
			return .Err(.Unknown);
		if (instance.WriteObject(manifestAsset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
