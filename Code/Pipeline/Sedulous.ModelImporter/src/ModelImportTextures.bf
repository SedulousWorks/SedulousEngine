using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Pipeline.Importer;
using Sedulous.Texture.Pipeline;

namespace Sedulous.ModelImporter;

/// Fanning a model's images out as texture ASSETS, which the cook then compresses and mips.
///
/// The loaders decode most images already, whether one came from a file beside the model or
/// from a buffer inside it, so an embedded texture and an external one arrive here the same
/// way: as pixels that travel in the asset's own sidecar stream.
///
/// A GPU READY container is the exception. The loaders leave a DDS on disk, and it becomes a
/// FILE BACKED asset instead, so the cook passes its block compressed levels through rather
/// than embedding pixels that were decoded only to be encoded again.
static class ModelImportTextures
{
	private const String cAssetType = "Sedulous.Texture.Pipeline.TextureAsset";

	/// One identity per model texture, EMPTY where the image was unusable or deselected.
	///
	/// The list stays parallel to the model's own, index for index, because a material names
	/// its textures by that index and a hole in the list would shift every later one.
	public static void Import(Model model, ImportContext context, bool sidecarsCopied,
		Group group, ImportOptions options, List<Guid> outGuids, List<String> claimed,
		List<DeferredImportWrite> deferredWrites)
	{
		// Colour space follows USAGE: a data map stays linear, since sRGB decoding one
		// corrupts its values, and a flat normal would arrive bent.
		let linear = scope List<bool>();
		ModelTextureClassify.LinearTextures(model, linear);
		let normal = scope List<bool>();
		ModelTextureClassify.NormalTextures(model, normal);

		let textures = model.Textures;
		for (int i < textures.Length)
		{
			let texture = textures[i];
			let usable = (texture != null) && !texture.Data.IsEmpty && (texture.Width > 0)
				&& (texture.Height > 0)
				&& (texture.DataSize == (int)texture.Width * (int)texture.Height * 4);
			if (!usable)
			{
				// A texture the loader left ON DISK becomes a file backed asset; anything
				// else was simply unusable, so dependents wire nothing.
				let fileBacked = ((texture != null) && !texture.SourceFile.IsEmpty)
					? ImportFileBacked(texture, i, (i < normal.Count) && normal[i],
						(i < linear.Count) && linear[i], context, sidecarsCopied, group, options,
						claimed, deferredWrites)
					: null;
				outGuids.Add((fileBacked != null) ? fileBacked.Id : Guid.Empty);
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

	/// Whether a uri is MODEL RELATIVE, meaning no root, no drive and no step upwards.
	///
	/// Such a uri keeps its path under the sources tree, the way the glTF sidecar copy lays
	/// files out, so "textures/shared/x.dds" stays where the model expects it. Anything else,
	/// such as an FBX's resolved absolute path, lands flat under its file name.
	private static bool IsModelRelativeUri(StringView uri)
	{
		if (uri.IsEmpty || (uri[0] == '/') || (uri[0] == '\\'))
			return false;
		if ((uri.Length >= 2) && (uri[1] == ':'))
			return false; // a drive

		for (int k = 0; (k + 1) < uri.Length; k++)
		{
			if ((uri[k] == '.') && (uri[k + 1] == '.'))
				return false;
		}
		return true;
	}

	/// A texture the loader left on disk: copied into the sources tree and referenced by a
	/// FILE BACKED asset, so the cook passes its GPU ready levels through.
	///
	/// The usage comes from the material SLOT, which knows what the map is for, and the rest
	/// from the file's own header facts. Null means deselected, or that it could not be
	/// copied.
	private static Instance ImportFileBacked(ModelTexture texture, int index, bool normalSlot,
		bool linear, ImportContext context, bool sidecarsCopied, Group group,
		ImportOptions options, List<String> claimed, List<DeferredImportWrite> deferredWrites)
	{
		let relative = IsModelRelativeUri(texture.Uri);
		// What the asset references under the sources tree: the model relative uri, else the
		// bare file name.
		let fileName = relative
			? StringView(texture.Uri)
			: ImportPaths.FileNameOf(texture.SourceFile);
		if (fileName.IsEmpty)
			return null;

		let textureName = scope String();
		ImportedNames.ForTexture(texture, index, textureName);
		if (!options.SelectionEnabled(.Texture, textureName))
			return null;

		// The glTF sidecar pass already copies every relative uri, the same bytes to the same
		// place, so copying again here would double a large package. Only what it did not
		// cover is copied: an absolute reference, or a container with no sidecar pass.
		if (!(relative && sidecarsCopied))
		{
			if (deferredWrites != null)
			{
				let copy = new DeferredImportWrite();
				copy.CopyFrom.Set(texture.SourceFile);
				PathJoin(context.SourcesRoot, fileName, copy.CopyTo);
				deferredWrites.Add(copy);
			}
			else
			{
				let bytes = scope List<uint8>();
				if (ReadFile(texture.SourceFile, bytes) case .Err)
					return null;
				let target = scope String();
				PathJoin(context.SourcesRoot, fileName, target);
				let parent = scope String();
				PathParent(target, parent);
				if (!parent.IsEmpty)
					CreateDirectory(parent);
				if (WriteFile(target, bytes) case .Err)
					return null;
			}
		}

		let asset = scope TextureAsset();
		asset.FileName.Set(fileName);
		asset.SourceHint.Set(texture.Uri);
		// The FILE's facts first, BC5 being a normal map, BC4 a mask and a DX10 header naming
		// the colour space, and then the slot, which knows what the material does with it.
		TextureFileImporter.SetupForDds(asset, texture.SourceFile, ImportPaths.StemOf(fileName));
		if (normalSlot)
			asset.SetupForNormalMap();
		else if (linear)
			asset.SetupForDataMask();

		let instance = ClaimedInstances.Claim(group,
			options.SelectionName(.Texture, textureName), cAssetType, claimed);
		if ((instance == null) || (instance.WriteObject(asset) case .Err))
			return null;
		return instance;
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
