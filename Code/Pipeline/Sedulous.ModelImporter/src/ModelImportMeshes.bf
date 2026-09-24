using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// Fanning a model's meshes out as mesh assets, folding authored levels of detail into the
/// mesh they belong to.
static class ModelImportMeshes
{
	private const String cStaticType = "Sedulous.Geometry.Pipeline.StaticMeshAsset";
	private const String cSkinnedType = "Sedulous.Geometry.Pipeline.SkinnedMeshAsset";

	/// A mesh big enough that a generated chain is worth having, counted in indices.
	private const int cAutoLodIndexThreshold = 3 * 10000;

	/// Creates one asset per mesh that is not a level of another, filling the manifest's
	/// parallel mesh arrays and recording each slot's plan name for the collision pass.
	public static Result<void, ErrorCode> Import(Model model, Group group,
		ModelManifestSource manifest, List<String> claimed,
		List<DeferredImportWrite> deferredWrites, bool generateLods, ImportOptions options,
		List<String> outMeshSourceNames, bool lazyGeometry = false)
	{
		let hasSkin = !model.Skins.IsEmpty;
		let meshes = model.Meshes;

		let foldsInto = scope List<int32>();
		let lodLevels = scope List<List<int>>();
		defer { ClearAndDeleteItems!(lodLevels); }
		ModelLodFold.Compute(model, foldsInto, lodLevels);

		for (int i < meshes.Length)
		{
			let mesh = meshes[i];
			let skinned = ModelCook.IsSkinned(mesh) && hasSkin;
			let baseName = new String();
			ImportedNames.ForAsset(mesh.Name, "mesh", i, baseName);
			outMeshSourceNames.Add(baseName);

			let parts = mesh.Parts;
			// A mesh that is a LEVEL of another, or one the dialog turned off, still HOLDS its
			// manifest slot. A node names its mesh by MODEL mesh index, so dropping an entry
			// shifts every later one and the hierarchy silently loses meshes or points at the
			// wrong ones.
			if ((foldsInto[i] >= 0) || !options.SelectionEnabled(.Mesh, baseName))
			{
				manifest.MeshGuid.Add(.Empty);
				manifest.MeshSkinned.Add(skinned);
				manifest.MeshMaterial.Add(parts.IsEmpty ? -1 : parts[0].MaterialIndex);
				manifest.AddMeshMaterialSlots(.()); // a held slot draws nothing
				continue;
			}

			let name = options.SelectionName(.Mesh, baseName);
			Instance instance = null;
			if (skinned)
			{
				let asset = new SkinnedMeshAsset();
				var ownsAsset = true;
				defer { if (ownsAsset) delete asset; }

				MeshConvert.SkinnedFromModel(mesh, 0, asset.Source);
				// The skinned overload keeps the parallel skinning stream in lockstep, and a
				// level that cannot is refused rather than appended half attached.
				for (let levelIndex in lodLevels[i])
					LodChain.AppendFromModel(meshes[levelIndex], asset.Source);
				// An AUTHORED chain always wins. Generation is for the big chainless meshes,
				// and it only drops indices, so the skinning stream is untouched by it.
				if ((asset.Source.LodCount <= 1) && generateLods
					&& (asset.Source.IndexData.Count >= cAutoLodIndexThreshold))
				{
					MeshOptimize.GenerateLodChain(asset.Source);
				}

				instance = ClaimedInstances.Claim(group, name, cSkinnedType, claimed);
				if (instance == null)
					return .Err(.Unknown);

				if (deferredWrites != null)
				{
					let geometry = scope List<uint8>();
					MeshAssetStorage.SkinnedGeometryBytes(asset, geometry);
					Defer(deferredWrites, instance, asset, geometry);
					ownsAsset = false;
				}
				else if (MeshAssetStorage.WriteSkinned(instance, asset) case .Err(let error))
				{
					return .Err(error);
				}
			}
			else
			{
				let asset = new StaticMeshAsset();
				var ownsAsset = true;
				defer { if (ownsAsset) delete asset; }

				// The conversion, the level chain and the serialization are the import's CPU
				// bulk. They run HERE only when this call owns the model; when the caller
				// keeps a prepared one alive through the flush they ride the deferred write
				// and happen on the worker instead.
				if (!lazyGeometry)
					BuildStaticSource(mesh, meshes, lodLevels[i], generateLods, asset);

				instance = ClaimedInstances.Claim(group, name, cStaticType, claimed);
				if (instance == null)
					return .Err(.Unknown);

				if (deferredWrites != null)
				{
					if (lazyGeometry)
					{
						DeferLazyStatic(deferredWrites, instance, asset, mesh, meshes,
							lodLevels[i], generateLods);
					}
					else
					{
						let geometry = scope List<uint8>();
						MeshAssetStorage.StaticGeometryBytes(asset, geometry);
						Defer(deferredWrites, instance, asset, geometry);
					}
					ownsAsset = false;
				}
				else if (MeshAssetStorage.WriteStatic(instance, asset) case .Err(let error))
				{
					return .Err(error);
				}
			}

			manifest.MeshGuid.Add(instance.Id);
			manifest.MeshSkinned.Add(skinned);
			// ONE material per mesh, taken from the first submesh, which is what a manifest can
			// carry: a mesh with several keeps them in its own submesh table.
			manifest.MeshMaterial.Add(parts.IsEmpty ? -1 : parts[0].MaterialIndex);
			let slots = scope List<int32>();
			MeshConvert.CollectMaterialSlots(mesh, slots);
			manifest.AddMeshMaterialSlots(slots);
		}
		return .Ok;
	}

	/// The conversion, the authored level chain and the auto-generated ladder: a mesh's whole
	/// source, built from the model.
	private static void BuildStaticSource(ModelMesh mesh, Span<ModelMesh> meshes,
		List<int> levelIndices, bool generateLods, StaticMeshAsset asset)
	{
		MeshConvert.StaticFromModel(mesh, asset.Source);
		for (let levelIndex in levelIndices)
			LodChain.AppendFromModel(meshes[levelIndex], asset.Source);
		if ((asset.Source.LodCount <= 1) && generateLods
			&& (asset.Source.IndexData.Count >= cAutoLodIndexThreshold))
		{
			MeshOptimize.GenerateLodChain(asset.Source);
		}
	}

	/// Parks a static mesh's two writes with the GEOMETRY still unbuilt: the produce runs the
	/// conversion, the chain and the serialization on the worker.
	///
	/// Safe only because the caller keeps the model alive through the flush; the level indices
	/// are copied, the scope list they came from dying with the import call.
	private static void DeferLazyStatic(List<DeferredImportWrite> deferredWrites,
		Instance instance, StaticMeshAsset asset, ModelMesh mesh, Span<ModelMesh> meshes,
		List<int> levelIndices, bool generateLods)
	{
		let sidecar = new DeferredImportWrite();
		sidecar.Instance = instance;
		sidecar.StreamName.Set(MeshAssetStorage.cGeometryStreamName);

		let levels = new List<int>();
		levels.AddRange(levelIndices);
		sidecar.ProduceOwned.Add(levels);

		sidecar.Produce = new [=asset, =mesh, =meshes, =levels, =generateLods] (bytes) =>
			{
				BuildStaticSource(mesh, meshes, levels, generateLods, asset);
				MeshAssetStorage.StaticGeometryBytes(asset, bytes);
				return (Result<void, ErrorCode>).Ok;
			};

		// The ENVELOPE last, so its stored source sees the built chain.
		let envelope = new DeferredImportWrite();
		envelope.Instance = instance;
		envelope.Object = asset;
		deferredWrites.Add(sidecar);
		deferredWrites.Add(envelope);
	}

	/// Parks both halves of a mesh write, the envelope and its geometry sidecar.
	///
	/// Rendering a mesh envelope is the single most expensive serialisation an import does, so
	/// it goes to the worker with the bytes. The deferred write TAKES the asset.
	private static void Defer(List<DeferredImportWrite> deferredWrites, Instance instance,
		ISerializable asset, List<uint8> geometry)
	{
		let envelope = new DeferredImportWrite();
		envelope.Instance = instance;
		envelope.Object = asset;
		deferredWrites.Add(envelope);

		let sidecar = new DeferredImportWrite();
		sidecar.Instance = instance;
		sidecar.StreamName.Set(MeshAssetStorage.cGeometryStreamName);
		sidecar.Owned.AddRange(geometry);
		deferredWrites.Add(sidecar);
	}
}
