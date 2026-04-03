using System;
using System.IO;
using Sedulous.Models;
using Sedulous.Imaging;

namespace Sedulous.Geometry.Tooling;

/// Converts ModelTexture to ImportedTexture.
static class TextureConverter
{
	/// Creates an ImportedTexture from a ModelTexture with embedded data.
	/// Returns null if the texture has no valid data.
	public static ImportedTexture Convert(ModelTexture modelTexture)
	{
		if (modelTexture == null)
			return null;

		Image image = null;

		// Check if texture has decoded pixel data
		if (modelTexture.Width > 0 && modelTexture.Height > 0 && modelTexture.HasEmbeddedData)
		{
			let format = ConvertPixelFormat(modelTexture.PixelFormat);
			let srcData = Span<uint8>(modelTexture.GetData(), modelTexture.GetDataSize());
			let data = new uint8[srcData.Length];
			defer delete data;
			srcData.CopyTo(data);
			image = new Image((uint32)modelTexture.Width, (uint32)modelTexture.Height, format, data);
		}

		if (image == null)
			return null;

		let result = new ImportedTexture();
		result.PixelData = image;
		SetName(result, modelTexture);
		return result;
	}

	/// Creates an ImportedTexture with fallback to file loading via ImageLoaderFactory.
	public static ImportedTexture Convert(ModelTexture modelTexture, StringView basePath)
	{
		if (modelTexture == null)
			return null;

		Image image = null;

		// Check if texture has decoded pixel data
		if (modelTexture.Width > 0 && modelTexture.Height > 0 && modelTexture.HasEmbeddedData)
		{
			let format = ConvertPixelFormat(modelTexture.PixelFormat);
			let srcData = Span<uint8>(modelTexture.GetData(), modelTexture.GetDataSize());
			let data = new uint8[srcData.Length];
			defer delete data;
			srcData.CopyTo(data);
			image = new Image((uint32)modelTexture.Width, (uint32)modelTexture.Height, format, data);
		}
		// Fallback to loading from file if we have a URI
		else if (!modelTexture.Uri.IsEmpty)
		{
			let fullPath = scope String();
			if (!basePath.IsEmpty)
			{
				fullPath.Append(basePath);
				if (!fullPath.EndsWith('/') && !fullPath.EndsWith('\\'))
					fullPath.Append('/');
			}
			fullPath.Append(modelTexture.Uri);
			fullPath.Replace('/', Path.DirectorySeparatorChar);

			if (ImageLoaderFactory.LoadImage(fullPath) case .Ok(var loadedImage))
				image = loadedImage;
		}

		if (image == null)
			return null;

		let result = new ImportedTexture();
		result.PixelData = image;
		SetName(result, modelTexture);
		return result;
	}

	/// Sets the texture resource name from the model texture, stripping file extensions
	/// since the saved resource contains raw pixel data, not the original image format.
	private static void SetName(ImportedTexture tex, ModelTexture modelTexture)
	{
		let rawName = modelTexture.Name.IsEmpty ? StringView(modelTexture.Uri) : StringView(modelTexture.Name);
		// Strip file extension (e.g., "Texture.png" → "Texture")
		let dotIdx = rawName.LastIndexOf('.');
		if (dotIdx > 0)
			tex.Name.Set(rawName[0..<dotIdx]);
		else
			tex.Name.Set(rawName);
	}

	/// Converts TexturePixelFormat to Image.PixelFormat.
	private static Image.PixelFormat ConvertPixelFormat(TexturePixelFormat format)
	{
		switch (format)
		{
		case .R8:    return .R8;
		case .RG8:   return .RG8;
		case .RGB8:  return .RGB8;
		case .RGBA8: return .RGBA8;
		case .BGR8:  return .BGR8;
		case .BGRA8: return .BGRA8;
		default:     return .RGBA8;
		}
	}
}
