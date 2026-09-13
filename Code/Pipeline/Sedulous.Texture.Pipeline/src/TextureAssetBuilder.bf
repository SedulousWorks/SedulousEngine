using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Sedulous.Texture.Pipeline;

/// Decodes a texture's source and cooks it into a record plus a pixel stream.
class TextureAssetBuilder : IAssetBuilder
{
	/// The stream the pixels travel in, mip chain and all.
	public const String cPixelStreamName = "data";
	/// The stream an EMBEDDED texture's authored pixels arrive in.
	public const String cEmbeddedStreamName = "pixels";

	public Type AssetType => typeof(TextureAsset);
	public Type ProductType => typeof(TextureResource);

	/// Five, after a run of output changes for the same input: the payload gained a full mip
	/// chain, then block compression, then a normal map going to the large linear format with
	/// the packed mask guard beside it, then radiance cooking to BC6H on a BC target. Each
	/// bump forces the re-cook the new output needs.
	public int32 Version => 5;

	/// Textures are THE platform variant producer: block compression on the desktop and ASTC
	/// on the mobile web, from one source. The cook salts this builder's recipe by target and
	/// cooks once per database.
	public BuildVariance Variance => .PlatformVariant;

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let texture = (TextureAsset)asset;

		// An embedded texture reads its pixels sidecar, so the recipe hash has to chain those
		// bytes: the envelope hash does not cover a sidecar.
		if (texture.FileName.IsEmpty && (texture.EmbeddedWidth > 0))
			outDeps.AddSourceStream(cEmbeddedStreamName);

		// A cube's file name is the +X face, which is the implicit dependency. The other five
		// have to chain in too, or editing one of them never re-cooks the cube.
		if ((texture.Shape == .Cubemap) && !texture.FileName.IsEmpty)
		{
			let faces = scope List<String>();
			defer { ClearAndDeleteItems!(faces); }
			if (CubemapFaces.Detect(texture.FileName.Value, faces) case .Ok)
			{
				for (let face in faces)
				{
					if (face != texture.FileName.Value)
						outDeps.AddFile(face);
				}
			}
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let texture = (TextureAsset)asset;
		if (context.Output == null)
			return .Err(.InvalidArgument);

		// Embedded mode: the sidecar IS the decoded image, which a model import produces.
		if (texture.FileName.IsEmpty && (texture.EmbeddedWidth > 0) && (texture.EmbeddedHeight > 0))
			return BuildEmbedded(texture, context);

		if (texture.Shape == .Cubemap)
			return BuildCubemap(texture, context);

		let bytes = scope List<uint8>();
		if (AssetSource.ReadBytes(context, texture.FileName.Value, bytes) case .Err(let readError))
			return .Err(readError);

		let image = scope Image();
		if (ImageIO.LoadImageFromMemory(bytes, image) case .Err(let decodeError))
			return .Err(decodeError);

		let record = scope TextureResource();
		record.Width = image.Width;
		record.Height = image.Height;
		record.DepthOrArrayLayers = 1;
		record.MipLevels = 1;
		record.Format = TextureFormatUtils.Convert(image.Format, texture.ColorSpace);

		let pixels = scope List<uint8>();
		pixels.AddRange(image.PixelData);

		let srgb = texture.ColorSpace == .Srgb;
		if (image.Format == .RGBA8)
		{
			if (texture.GenerateMipmaps && (texture.Shape == .Texture2D))
				record.MipLevels = TextureMipChain.Append(pixels, image.Width, image.Height, srgb);

			if (texture.Shape == .Texture2D)
			{
				TextureCompress.MaybeCompress(pixels, image.Width, image.Height, record.MipLevels,
					srgb, texture.Usage, texture.Compression, TextureCompress.ProfileFor(context),
					ref record.Format);
			}
		}
		else if ((texture.Shape == .Texture2D) && (image.Format == .RGBA32F))
		{
			// Radiance, one level: a sky carries no mip chain.
			TextureCompress.MaybeCompressHdr(pixels, image.Width, image.Height, texture.Usage,
				texture.Compression, TextureCompress.ProfileFor(context), ref record.Format);
		}

		FillSampler(texture, record);
		if (context.Output.WriteObject(record) case .Err(let writeError))
			return .Err(writeError);
		return context.Output.WriteData(cPixelStreamName, pixels);
	}

	private static void FillSampler(TextureAsset texture, TextureResource record)
	{
		record.Shape = texture.Shape;
		record.MinFilter = texture.MinFilter;
		record.MagFilter = texture.MagFilter;
		record.WrapU = texture.WrapU;
		record.WrapV = texture.WrapV;
		record.WrapW = texture.WrapW;
		record.GenerateMipmaps = texture.GenerateMipmaps;
		record.Anisotropy = texture.Anisotropy;
	}

	/// Six faces, derived from the +X one's naming, loaded through the mount, validated square
	/// and matching, and concatenated in cube order.
	private static Result<void, ErrorCode> BuildCubemap(TextureAsset texture,
		AssetBuildContext context)
	{
		let facePaths = scope List<String>();
		defer { ClearAndDeleteItems!(facePaths); }
		if ((CubemapFaces.Detect(texture.FileName.Value, facePaths) case .Err)
			|| (facePaths.Count != 6))
		{
			return .Err(.InvalidArgument); // the file name matches no face convention
		}

		let faces = scope List<Image>();
		defer { ClearAndDeleteItems!(faces); }
		uint32 faceSize = 0;
		var faceBytes = 0;

		for (int i < 6)
		{
			let bytes = scope List<uint8>();
			if (AssetSource.ReadBytes(context, facePaths[i], bytes) case .Err(let readError))
				return .Err(readError);

			let face = new Image();
			faces.Add(face);
			if (ImageIO.LoadImageFromMemory(bytes, face) case .Err(let decodeError))
				return .Err(decodeError);

			if (face.Width != face.Height)
				return .Err(.InvalidArgument); // a cube face is square

			if (i == 0)
			{
				faceSize = face.Width;
				faceBytes = face.PixelData.Length;
			}
			else if ((face.Width != faceSize) || (face.PixelData.Length != faceBytes)
				|| (face.Format != faces[0].Format))
			{
				return .Err(.InvalidArgument); // every face has to match
			}
		}

		if ((faceSize == 0) || (faceBytes == 0))
			return .Err(.InvalidArgument);

		let record = scope TextureResource();
		record.Width = faceSize;
		record.Height = faceSize;
		record.DepthOrArrayLayers = 6;
		record.MipLevels = 1;
		record.Format = TextureFormatUtils.Convert(faces[0].Format, texture.ColorSpace);
		FillSampler(texture, record);

		if (context.Output.WriteObject(record) case .Err(let writeError))
			return .Err(writeError);

		let pixels = scope List<uint8>();
		for (let face in faces)
			pixels.AddRange(face.PixelData);
		return context.Output.WriteData(cPixelStreamName, pixels);
	}

	private static Result<void, ErrorCode> BuildEmbedded(TextureAsset texture,
		AssetBuildContext context)
	{
		if (context.Source == null)
			return .Err(.InvalidArgument);

		let stream = context.Source.ReadData(cEmbeddedStreamName);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;

		let size = stream.Size();
		let expected = (int64)texture.EmbeddedWidth * (int64)texture.EmbeddedHeight * 4;
		if (size != expected)
			return .Err(.InvalidArgument);

		let pixels = scope List<uint8>();
		pixels.Count = (int)size;
		if (stream.Read(.(pixels.Ptr, (int)size)) != (int)size)
			return .Err(.Unknown);

		let record = scope TextureResource();
		record.Width = texture.EmbeddedWidth;
		record.Height = texture.EmbeddedHeight;
		record.DepthOrArrayLayers = 1;
		record.MipLevels = 1;
		let srgb = texture.ColorSpace == .Srgb;
		record.Format = srgb ? TextureFormat.RGBA8UnormSrgb : TextureFormat.RGBA8Unorm;

		if (texture.GenerateMipmaps && (texture.Shape == .Texture2D))
		{
			record.MipLevels = TextureMipChain.Append(pixels, texture.EmbeddedWidth,
				texture.EmbeddedHeight, srgb);
		}
		if (texture.Shape == .Texture2D)
		{
			TextureCompress.MaybeCompress(pixels, texture.EmbeddedWidth, texture.EmbeddedHeight,
				record.MipLevels, srgb, texture.Usage, texture.Compression,
				TextureCompress.ProfileFor(context), ref record.Format);
		}

		FillSampler(texture, record);
		if (context.Output.WriteObject(record) case .Err(let writeError))
			return .Err(writeError);
		return context.Output.WriteData(cPixelStreamName, pixels);
	}
}
