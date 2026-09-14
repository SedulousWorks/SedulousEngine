using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Pipeline.Importer;
using Sedulous.Texture.Pipeline;

namespace Sedulous.ModelImporter;

/// Fanning a model's images out as texture ASSETS, which the cook then compresses and mips.
///
/// The loaders decode every image already, whether it came from a file beside the model or
/// from a buffer inside it, so an embedded texture and an external one arrive here the same
/// way: as pixels that travel in the asset's own sidecar stream.
static class ModelImportTextures
{
	private const String cAssetType = "Sedulous.Texture.Pipeline.TextureAsset";

	/// One identity per model texture, EMPTY where the image was unusable or deselected.
	///
	/// The list stays parallel to the model's own, index for index, because a material names
	/// its textures by that index and a hole in the list would shift every later one.
	public static void Import(Model model, Group group, ImportOptions options,
		List<Guid> outGuids, List<String> claimed, List<DeferredImportWrite> deferredWrites)
	{
		// Colour space follows USAGE: a data map stays linear, since sRGB decoding one
		// corrupts its values, and a flat normal would arrive bent.
		let linear = scope List<bool>();
		ModelTextureClassify.LinearTextures(model, linear);

		let textures = model.Textures;
		for (int i < textures.Length)
		{
			let texture = textures[i];
			let usable = (texture != null) && !texture.Data.IsEmpty && (texture.Width > 0)
				&& (texture.Height > 0)
				&& (texture.DataSize == (int)texture.Width * (int)texture.Height * 4);
			if (!usable)
			{
				outGuids.Add(.Empty); // never an asset, so dependents wire nothing
				continue;
			}

			let textureName = scope String();
			ImportedNames.ForTexture(texture, i, textureName);
			if (!options.SelectionEnabled(.Texture, textureName))
			{
				outGuids.Add(.Empty);
				continue;
			}

			let asset = scope TextureAsset();
			asset.EmbeddedWidth = (uint32)texture.Width;
			asset.EmbeddedHeight = (uint32)texture.Height;
			asset.ColorSpace = ((i < linear.Count) && linear[i]) ? .Linear : .Srgb;
			asset.GenerateMipmaps = true;
			// Provenance for the texture page, and DISPLAY ONLY: the asset's name prefers the
			// file stem, so a rename or an embedded image can leave the two disagreeing, and
			// nothing may load from this.
			asset.SourceHint.Set(texture.Uri);

			let instance = ClaimedInstances.Claim(group,
				options.SelectionName(.Texture, textureName), cAssetType, claimed);
			if ((instance == null) || (instance.WriteObject(asset) case .Err))
			{
				outGuids.Add(.Empty);
				continue;
			}

			if (deferredWrites != null)
			{
				// Decoded pixels are the bulk of an import, hundreds of megabytes for a big
				// model, so they are parked for the worker flush. The view BORROWS from the
				// prepared model, which the caller keeps alive until the flush is done.
				let write = new DeferredImportWrite();
				write.Instance = instance;
				write.StreamName.Set(TextureAssetBuilder.cEmbeddedStreamName);
				write.View = texture.Data;
				deferredWrites.Add(write);
				outGuids.Add(instance.Id);
				continue;
			}

			let wrote = instance.WriteData(TextureAssetBuilder.cEmbeddedStreamName, texture.Data);
			outGuids.Add((wrote case .Ok) ? instance.Id : Guid.Empty);
		}
	}

	/// Bakes ONE packed metal and roughness texture from a format that supplied the two
	/// separately, returning its identity or an empty one when there was nothing to bake.
	///
	/// Cached by the PAIR rather than per material, since materials in one model routinely
	/// share the same two maps and baking is not cheap.
	public static Guid GetOrBakePacked(Model model, Group group, Dictionary<uint64, Guid> cache,
		int32 roughnessIndex, int32 metalnessIndex, List<String> claimed,
		List<DeferredImportWrite> deferredWrites)
	{
		let key = ((uint64)(uint32)roughnessIndex << 32) | (uint64)(uint32)metalnessIndex;
		if (cache.TryGetValue(key, let hit))
			return hit;

		let pixels = scope List<uint8>();
		PackedMetallicRoughness.Bake(model, roughnessIndex, metalnessIndex, pixels, let width,
			let height);
		if (pixels.IsEmpty)
		{
			cache[key] = .Empty;
			return .Empty;
		}

		let asset = scope TextureAsset();
		asset.EmbeddedWidth = width;
		asset.EmbeddedHeight = height;
		asset.ColorSpace = .Linear; // a data map
		asset.GenerateMipmaps = true;

		let name = scope $"mr.packed.{roughnessIndex}.{metalnessIndex}";
		let instance = ClaimedInstances.Claim(group, name, cAssetType, claimed);
		if ((instance == null) || (instance.WriteObject(asset) case .Err))
		{
			cache[key] = .Empty;
			return .Empty;
		}

		if (deferredWrites != null)
		{
			// Baked HERE rather than borrowed from the model, so the deferred write owns the
			// bytes and outlives this call.
			let write = new DeferredImportWrite();
			write.Instance = instance;
			write.StreamName.Set(TextureAssetBuilder.cEmbeddedStreamName);
			write.Owned.AddRange(pixels);
			deferredWrites.Add(write);
		}
		else if (instance.WriteData(TextureAssetBuilder.cEmbeddedStreamName, pixels) case .Err)
		{
			cache[key] = .Empty;
			return .Empty;
		}

		cache[key] = instance.Id;
		return instance.Id;
	}
}
