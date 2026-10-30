using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Model;
using Sedulous.Pipeline.Core;

namespace Sedulous.ModelImporter;

/// Cooking a model's materials into the output database.
static class ModelCookMaterials
{
	/// Cooks every material, recording its identity and its albedo texture's.
	///
	/// The lists stay parallel to the model's own, an empty identity marking one that failed,
	/// because a mesh refers to its material by index.
	public static void Cook(Model model, Group root, StringView namePrefix,
		List<Guid> textureGuids, List<Guid> outMaterialGuids, List<Guid> outAlbedoGuids)
	{
		let builder = scope MaterialAssetBuilder();

		// Materials in one model often share the same pair of separate maps, so a bake is
		// cached by the pair rather than repeated per material.
		let bakedPacked = scope Dictionary<uint64, Guid>();

		let materials = model.Materials;
		for (int i < materials.Length)
		{
			let material = materials[i];
			let materialName = scope String();
			ImportedNames.ForAsset(material.Name, "mat", i, materialName);

			// On the built-in its shading model names, every texture it reads wired in; FBX's
			// separate metal and rough maps baked into one packed texture product, once a pair.
			let asset = scope MaterialAsset();
			ModelMaterialBuild.Build(model, material, scope $"{namePrefix}.{materialName}", textureGuids,
				scope (roughIndex, metalIndex) => PackedProduct(model, root, namePrefix, bakedPacked, roughIndex, metalIndex), asset);

			let name = scope String();
			root.UniqueInstanceName(scope $"{namePrefix}.{materialName}", name);
			let instance = root.CreateInstance(name, "Sedulous.Materials.Resource.MaterialSource");
			if (instance == null)
			{
				outMaterialGuids.Add(.Empty);
				outAlbedoGuids.Add(.Empty);
				continue;
			}

			let context = scope AssetBuildContext();
			context.Output = instance;
			outMaterialGuids.Add((builder.Build(asset, context) case .Ok) ? instance.Id
				: Guid.Empty);

			let albedoIndex = material.BaseColorTextureIndex;
			outAlbedoGuids.Add(((albedoIndex >= 0) && (albedoIndex < textureGuids.Count))
				? textureGuids[albedoIndex] : Guid.Empty);
		}
	}

	// FBX's separate metal and rough maps baked into one packed texture product, once a pair
	// (materials in one model often share the same pair).
	private static Guid PackedProduct(Model model, Group root, StringView namePrefix, Dictionary<uint64, Guid> bakedPacked,
		int32 roughIndex, int32 metalIndex)
	{
		let key = ((uint64)(uint32)roughIndex << 32) | (uint64)(uint32)metalIndex;
		if (bakedPacked.TryGetValue(key, let cached))
			return cached;
		let packed = ModelCookTextures.CookPacked(model, root, namePrefix, roughIndex, metalIndex);
		bakedPacked[key] = packed;
		return packed;
	}
}
