using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// Fanning a model's materials out as material assets.
///
/// EVERY authored texture is wired into the material's own source rather than only the albedo,
/// so a material picked straight out of the browser renders fully textured instead of only
/// looking right when a model spawns it.
static class ModelImportMaterials
{
	private const String cAssetType = "Sedulous.Materials.Pipeline.MaterialAsset";

	public static void Import(Model model, Group group, List<Guid> textureGuids,
		ModelManifestSource manifest, List<String> claimed,
		List<DeferredImportWrite> deferredWrites, ImportOptions options)
	{
		let bakedPacked = scope Dictionary<uint64, Guid>();

		let materials = model.Materials;
		for (int i < materials.Length)
		{
			let material = materials[i];
			let materialName = scope String();
			ImportedNames.ForAsset(material.Name, "mat", i, materialName);

			if (!options.SelectionEnabled(.Material, materialName))
			{
				// Deselected, but the slots still HOLD: a submesh names its material by index,
				// and dropping the entry would point every later mesh at the wrong one.
				manifest.MaterialGuid.Add(.Empty);
				manifest.MaterialAlbedo.Add(.Empty);
				continue;
			}

			// A standard material carrying the model's factors, captured into a source that
			// names the built in shader, so an import renders without a cooked shader.
			let built = MaterialPresets.CreatePbr(materialName, material.BaseColorFactor,
				material.MetallicFactor, material.RoughnessFactor);
			defer delete built;

			built.SetDefaultColor("EmissiveColor", .(material.EmissiveFactor.X,
				material.EmissiveFactor.Y, material.EmissiveFactor.Z, 1.0f));
			built.SetDefaultFloat("OcclusionStrength", material.OcclusionStrength);
			built.SetDefaultFloat("NormalScale", material.NormalScale);
			built.SetDefaultFloat("AlphaCutoff", material.AlphaCutoff);

			let asset = scope MaterialAsset();
			MaterialSource.FromMaterial(built, .Empty, asset.Source);
			asset.Source.ShaderName.Set("forward");

			WireTextures(model, material, textureGuids, bakedPacked, group, claimed,
				deferredWrites, asset.Source);

			let instance = ClaimedInstances.Claim(group,
				options.SelectionName(.Material, materialName), cAssetType, claimed);
			if ((instance == null) || (instance.WriteObject(asset) case .Err))
			{
				manifest.MaterialGuid.Add(.Empty);
				manifest.MaterialAlbedo.Add(.Empty);
				continue;
			}
			manifest.MaterialGuid.Add(instance.Id);

			let albedoIndex = material.BaseColorTextureIndex;
			manifest.MaterialAlbedo.Add(((albedoIndex >= 0)
				&& (albedoIndex < textureGuids.Count)) ? textureGuids[albedoIndex] : Guid.Empty);
		}
	}

	/// Binds every authored texture into its slot, baking the packed metal and roughness map
	/// when the format supplied the two separately.
	private static void WireTextures(Model model, ModelMaterial material, List<Guid> textureGuids,
		Dictionary<uint64, Guid> bakedPacked, Group group, List<String> claimed,
		List<DeferredImportWrite> deferredWrites, MaterialSource source)
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
			// Two grayscale maps: feeding either into the packed slot as it stands would bleed
			// one channel's data across the others, so the pair bakes into a packed one.
			let packed = ModelImportTextures.GetOrBakePacked(model, group, bakedPacked,
				material.SeparateRoughnessTextureIndex, material.SeparateMetalnessTextureIndex,
				claimed, deferredWrites);
			if (packed != Guid.Empty)
			{
				source.TextureSlots.Add(new String("MetallicRoughnessMap"));
				source.TextureIds.Add(packed);
			}
		}

		// The authored pipeline state. A masked material is an alpha tested cutout, which also
		// gives its shadow holes; a blended one goes to the transparent pass.
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
