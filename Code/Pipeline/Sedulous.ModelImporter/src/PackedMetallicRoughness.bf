using System;
using System.Collections;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Baking a packed metal and roughness texture out of the separate grayscale maps some
/// formats carry.
///
/// The shading path wants ONE texture with roughness in green and metalness in blue. A format
/// that supplies them separately would otherwise need a second sampler and a second code path
/// for the whole renderer.
static class PackedMetallicRoughness
{
	/// Bakes the pair, or leaves the result EMPTY when neither map is usable, in which case
	/// the caller falls back to the scalar factors alone.
	///
	/// A missing map bakes as full, which is the identity the factor then scales. The sizes
	/// may differ, so the output takes the larger and samples the smaller nearest.
	public static void Bake(Model model, int32 roughnessIndex, int32 metalnessIndex,
		List<uint8> outPixels, out uint32 outWidth, out uint32 outHeight)
	{
		outPixels.Clear();
		outWidth = 0;
		outHeight = 0;

		ModelTexture Fetch(int32 index)
		{
			if ((index < 0) || (index >= model.Textures.Length))
				return null;
			let texture = model.Textures[index];
			if (texture == null)
				return null;
			let usable = !texture.Data.IsEmpty && (texture.Width > 0) && (texture.Height > 0)
				&& (texture.DataSize == (int)texture.Width * (int)texture.Height * 4);
			return usable ? texture : null;
		}

		let rough = Fetch(roughnessIndex);
		let metal = Fetch(metalnessIndex);
		if ((rough == null) && (metal == null))
			return;

		let width = (uint32)Math.Max((rough != null) ? rough.Width : 0,
			(metal != null) ? metal.Width : 0);
		let height = (uint32)Math.Max((rough != null) ? rough.Height : 0,
			(metal != null) ? metal.Height : 0);

		uint8 Sample(ModelTexture texture, uint32 x, uint32 y)
		{
			if (texture == null)
				return 255; // the identity the scalar factor carries the real value through
			let sx = (width > 1) ? (x * (uint32)texture.Width) / width : 0;
			let sy = (height > 1) ? (y * (uint32)texture.Height) / height : 0;
			return texture.Data[((int)sy * (int)texture.Width + (int)sx) * 4]; // grey, so red
		}

		outPixels.Count = (int)width * (int)height * 4;
		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				let texel = &outPixels[((int)y * (int)width + (int)x) * 4];
				texel[0] = 255; // unused here, where a packed occlusion would live
				texel[1] = Sample(rough, x, y);
				texel[2] = Sample(metal, x, y);
				texel[3] = 255;
			}
		}

		outWidth = width;
		outHeight = height;
	}
}
