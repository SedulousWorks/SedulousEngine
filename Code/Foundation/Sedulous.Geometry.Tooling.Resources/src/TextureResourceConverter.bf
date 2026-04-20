using System;
using Sedulous.Textures.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Images;

namespace Sedulous.Geometry.Tooling.Resources;

/// Converts ImportedTexture to TextureResource.
static class TextureResourceConverter
{
	/// Creates a TextureResource from an ImportedTexture.
	/// The TextureResource takes ownership of a copy of the image data.
	/// Returns null if the imported texture or its pixel data is null.
	public static TextureResource Convert(ImportedTexture imported)
	{
		if (imported == null || imported.PixelData == null)
			return null;

		// Copy the image data — TextureResource will own it
		let srcImage = imported.PixelData;
		let data = new uint8[srcImage.Data.Length];
		defer delete data;
		srcImage.Data.CopyTo(data);
		let image = new Image(srcImage.Width, srcImage.Height, srcImage.Format, data);

		let textureRes = new TextureResource(image, true);
		textureRes.Name.Set(imported.Name);
		textureRes.SetupFor3D();

		return textureRes;
	}
}
