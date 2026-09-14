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

			// A standard material carrying the model's factors, captured into a source naming
			// the built in shader, so no cooked shader is needed for an import to render.
			let built = MaterialPresets.CreatePbr(scope $"{namePrefix}.{materialName}",
				material.BaseColorFactor, material.MetallicFactor, material.RoughnessFactor);
			defer delete built;

			built.SetDefaultColor("EmissiveColor", .(material.EmissiveFactor.X,
				material.EmissiveFactor.Y, material.EmissiveFactor.Z, 1.0f));
			built.SetDefaultFloat("OcclusionStrength", material.OcclusionStrength);
			built.SetDefaultFloat("NormalScale", material.NormalScale);
			built.SetDefaultFloat("AlphaCutoff", material.AlphaCutoff);

			let asset = scope MaterialAsset();
			MaterialSource.FromMaterial(built, .Empty, asset.Source);
			asset.Source.ShaderName.Set("forward");

			WireTextures(model, material, textureGuids, bakedPacked, root, namePrefix,
				asset.Source);

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

	/// Binds every authored texture into its slot, and bakes the packed metal and roughness
	/// map when the format supplied the two separately.
	private static void WireTextures(Model model, ModelMaterial material, List<Guid> textureGuids,
		Dictionary<uint64, Guid> bakedPacked, Group root, StringView namePrefix,
		MaterialSource source)
	{
		void Wire(int32 index, StringView slot)
		{
			if ((index < 0) || (index >= textureGuids.Count) || (textureGuids[index] == Guid.Empty))
				return;
			source.TextureSlots.Add(new String(slot));
			source.TextureIds.Add(textureGuids[index]);
		}

		Wire(material.BaseColorTextureIndex, "AlbedoMap");
		Wire(material.NormalTextureIndex, "NormalMap");
		Wire(material.OcclusionTextureIndex, "OcclusionMap");
		Wire(material.EmissiveTextureIndex, "EmissiveMap");

		if (material.MetallicRoughnessTextureIndex >= 0)
		{
			// Already packed, which is what most formats supply.
			Wire(material.MetallicRoughnessTextureIndex, "MetallicRoughnessMap");
		}
		else if ((material.SeparateRoughnessTextureIndex >= 0)
			|| (material.SeparateMetalnessTextureIndex >= 0))
		{
			let key = ((uint64)(uint32)material.SeparateRoughnessTextureIndex << 32)
				| (uint64)(uint32)material.SeparateMetalnessTextureIndex;

			Guid packed;
			if (bakedPacked.TryGetValue(key, let cached))
			{
				packed = cached;
			}
			else
			{
				packed = ModelCookTextures.CookPacked(model, root, namePrefix,
					material.SeparateRoughnessTextureIndex,
					material.SeparateMetalnessTextureIndex);
				bakedPacked[key] = packed;
			}

			if (packed != Guid.Empty)
			{
				source.TextureSlots.Add(new String("MetallicRoughnessMap"));
				source.TextureIds.Add(packed);
			}
		}

		// The authored pipeline state. A masked material is an alpha tested cutout, which also
		// gives it holes in its shadow; a blended one goes to the transparent pass.
		if (material.AlphaMode == .Mask)
			source.BlendMode = .Masked;
		else if (material.AlphaMode == .Blend)
			source.BlendMode = .AlphaBlend;

		if (material.DoubleSided)
			source.CullMode = .None;

		ModelSamplerModes.For(model, material, let samplerU, let samplerV);
		source.SamplerU = (uint8)samplerU;
		source.SamplerV = (uint8)samplerV;
	}
}
