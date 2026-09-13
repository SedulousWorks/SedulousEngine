using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.IO;

namespace Sedulous.Texture.Pipeline;

/// Authoring helpers that configure a texture asset for a source, and load a cube's faces.
///
/// An asset is filled IN PLACE rather than returned, since it owns its strings.
static class TextureImporter
{
	/// A standard surface texture, with mips and anisotropy.
	public static void Import2D(StringView path, ImageColorSpace colorSpace, TextureAsset outAsset)
	{
		outAsset.FileName.Set(path);
		outAsset.SetupFor3D();
		outAsset.ColorSpace = colorSpace;
	}

	/// A radiance sky: linear, clamped, and without mips.
	public static void ImportEquirectangular(StringView path, TextureAsset outAsset)
	{
		outAsset.FileName.Set(path);
		outAsset.SetupForEquirectangularSkybox();
	}

	/// A cube sky from six face files. The FIRST is what the asset stores; the rest derive
	/// from its naming at cook time.
	public static void ImportCubemap(StringView firstFacePath, TextureAsset outAsset)
	{
		outAsset.FileName.Set(firstFacePath);
		outAsset.SetupForCubemapSkybox();
	}

	/// Loads six faces into one buffer, concatenated in cube order, which is the layout a six
	/// layer texture expects.
	///
	/// Every face has to be square, the same size and the same format; the caller supplies the
	/// explicit paths.
	public static Result<void, ErrorCode> LoadCubemap(Span<StringView> facePaths,
		List<uint8> outPixels, out uint32 outFaceSize)
	{
		outFaceSize = 0;
		if (facePaths.Length != 6)
			return .Err(.InvalidArgument);

		let faces = scope List<Image>();
		defer { ClearAndDeleteItems!(faces); }
		uint32 faceSize = 0;
		var faceBytes = 0;

		for (int i < 6)
		{
			let face = new Image();
			faces.Add(face);
			if (ImageIO.LoadImage(facePaths[i], face) case .Err)
				return .Err(.Unknown);
			if (face.Width != face.Height)
				return .Err(.Unknown); // a cube face is square

			if (i == 0)
			{
				faceSize = face.Width;
				faceBytes = face.PixelData.Length;
			}
			else if ((face.Width != faceSize) || (face.PixelData.Length != faceBytes)
				|| (face.Format != faces[0].Format))
			{
				return .Err(.Unknown); // every face has to match
			}
		}

		if ((faceSize == 0) || (faceBytes == 0))
			return .Err(.Unknown);

		outPixels.Clear();
		for (let face in faces)
			outPixels.AddRange(face.PixelData);
		outFaceSize = faceSize;
		return .Ok;
	}
}
