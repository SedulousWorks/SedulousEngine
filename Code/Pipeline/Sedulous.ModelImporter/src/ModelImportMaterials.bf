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
		Dictionary<uint64, Guid> alphaCopies, ModelManifestSource manifest, List<String> claimed,
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

			// On the built-in its shading model names, every texture it reads wired in; FBX's
			// separate metal and rough maps baked into one packed texture asset here, once a pair.
			let asset = scope MaterialAsset();
			ModelMaterialBuild.Build(model, material, materialName, textureGuids,
				scope (roughIndex, metalIndex) => ModelImportTextures.GetOrBakePacked(model, group, bakedPacked, roughIndex, metalIndex,
					claimed, deferredWrites), asset);

			// An alpha tested material reads the copy of its base colour that keeps its own
			// cutoff's coverage, where the texture's asset keeps another's or none
			// (ModelImportTextures.Import).
			let albedoIndex = material.BaseColorTextureIndex;
			var albedo = ((albedoIndex >= 0) && (albedoIndex < textureGuids.Count)) ? textureGuids[albedoIndex] : Guid.Empty;
			if ((albedoIndex >= 0) && (ModelTextureClassify.BaseColorAlphaUse(material) == .Tested)
				&& alphaCopies.TryGetValue(ModelTextureClassify.AlphaCopyKey(albedoIndex, ModelTextureClassify.AlphaCutoffStep(material.AlphaCutoff)), let copy))
			{
				for (int slot < asset.Source.TextureSlots.Count)
				{
					if (asset.Source.TextureSlots[slot] == "AlbedoMap")
						asset.Source.TextureIds[slot] = copy;
				}
				albedo = copy;
			}

			let instance = ClaimedInstances.Claim(group,
				options.SelectionName(.Material, materialName), cAssetType, claimed);
			if ((instance == null) || (instance.WriteObject(asset) case .Err))
			{
				manifest.MaterialGuid.Add(.Empty);
				manifest.MaterialAlbedo.Add(.Empty);
				continue;
			}
			manifest.MaterialGuid.Add(instance.Id);
			manifest.MaterialAlbedo.Add(albedo);
		}
	}
}
