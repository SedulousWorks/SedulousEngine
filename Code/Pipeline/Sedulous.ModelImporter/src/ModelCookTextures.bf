using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.RHI;
using Sedulous.Texture.Resource;

namespace Sedulous.ModelImporter;

/// Cooking a model's textures straight into the output database.
///
/// The loaders DECODE every texture into raw pixels already, whether it came from a file
/// beside the model, a data reference inside it, or a buffer view in a binary container. So
/// the cook works from those bytes: no file is read again, and an embedded texture works
/// exactly like an external one.
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
		for (int i < textures.Length)
		{
			let texture = textures[i];
			// The loaders decode to four bytes a texel; anything else is not something this
			// can cook, and an empty identity says so.
			let usable = (texture != null) && !texture.Data.IsEmpty && (texture.Width > 0)
				&& (texture.Height > 0)
				&& (texture.DataSize == (int)texture.Width * (int)texture.Height * 4);
			if (!usable)
			{
				outGuids.Add(.Empty);
				continue;
			}

			let record = scope TextureResource();
			record.Width = (uint32)texture.Width;
			record.Height = (uint32)texture.Height;
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

			let wrote = instance.WriteData(cDataStream, texture.Data);
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
