using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Model;
using Sedulous.RHI;
using Sedulous.Texture.Resource;

namespace Sedulous.ModelImporter;

/// Cooking a model's textures straight into the output database.
///
/// The loaders DECODE most textures into raw pixels already, whether one came from a file
/// beside the model, a data reference inside it, or a buffer view in a binary container, so
/// the cook works from those bytes and an embedded texture works exactly like an external one.
///
/// A texture the loader left ON DISK, a GPU ready DDS, is the exception and is decoded here.
/// This DIRECT path has no pass through, that being the asset pipeline's, so its level nought
/// cooks as RGBA8 like everything else.
static class ModelCookTextures
{
	/// The stream the pixels travel in, which is the same one a cooked texture uses.
	public const String cDataStream = "data";

	/// One identity per model texture, EMPTY where the texture had no usable pixels.
	///
	/// The list stays parallel to the model's own, index for index, because every material
	/// refers to its textures by that index.
	public static void Cook(Model model, Group root, StringView namePrefix, List<Guid> outGuids)
	{
		let linear = scope List<bool>();
		ModelTextureClassify.LinearTextures(model, linear);

		let textures = model.Textures;
		let decoded = scope Image();
		for (int i < textures.Length)
		{
			let texture = textures[i];
			var pixels = (texture != null) ? texture.Data : Span<uint8>();
			var width = (texture != null) ? (uint32)Math.Max(texture.Width, 0) : 0;
			var height = (texture != null) ? (uint32)Math.Max(texture.Height, 0) : 0;

			// A texture the loader left on disk decodes here, its level nought standing in.
			if ((texture != null) && pixels.IsEmpty && !texture.SourceFile.IsEmpty)
			{
				if ((ImageIO.LoadImage(texture.SourceFile, decoded) case .Ok)
					&& (decoded.Format == .RGBA8))
				{
					pixels = decoded.PixelData;
					width = decoded.Width;
					height = decoded.Height;
				}
			}

			// The loaders decode to four bytes a texel; anything else is not something this
			// can cook, and an empty identity says so.
			let usable = !pixels.IsEmpty && (width > 0) && (height > 0)
				&& (pixels.Length == (int)width * (int)height * 4);
			if (!usable)
			{
				outGuids.Add(.Empty);
				continue;
			}

			let record = scope TextureResource();
			record.Width = width;
			record.Height = height;
			// The colour space follows USAGE: a data map stays linear, since decoding one as
			// sRGB corrupts its values, and a colour map is sRGB encoded.
			record.Format = ((i < linear.Count) && linear[i]) ? TextureFormat.RGBA8Unorm
				: TextureFormat.RGBA8UnormSrgb;
			record.MipLevels = 1;
			record.GenerateMipmaps = false;

			let textureName = scope String();
			ImportedNames.ForTexture(texture, i, textureName);
			let name = scope String();
			root.UniqueInstanceName(scope $"{namePrefix}.{textureName}", name);

			let instance = root.CreateInstance(name, "Sedulous.Texture.Resource.TextureResource");
			if ((instance == null) || (instance.WriteObject(record) case .Err))
			{
				outGuids.Add(.Empty);
				continue;
			}

			let wrote = instance.WriteData(cDataStream, pixels);
			outGuids.Add((wrote case .Ok) ? instance.Id : Guid.Empty);
		}
	}

	/// Cooks one BAKED packed metal and roughness texture and returns its identity, or an
	/// empty one when there was nothing to bake.
	public static Guid CookPacked(Model model, Group root, StringView namePrefix,
		int32 roughnessIndex, int32 metalnessIndex)
	{
		let pixels = scope List<uint8>();
		PackedMetallicRoughness.Bake(model, roughnessIndex, metalnessIndex, pixels, let width,
			let height);
		if (pixels.IsEmpty)
			return .Empty;

		let record = scope TextureResource();
		record.Width = width;
		record.Height = height;
		record.Format = .RGBA8Unorm; // a data map, so linear
		record.MipLevels = 1;
		record.GenerateMipmaps = false;

		let name = scope $"{namePrefix}.mr.packed.{roughnessIndex}.{metalnessIndex}";
		let instance = root.CreateInstance(name, "Sedulous.Texture.Resource.TextureResource");
		if (instance == null)
			return .Empty;
		if (instance.WriteObject(record) case .Err)
			return .Empty;
		if (instance.WriteData(cDataStream, pixels) case .Err)
			return .Empty;
		return instance.Id;
	}
}
