using System;
using System.Diagnostics;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Image;
using Sedulous.Image.DDS;
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

		// A DDS is GPU ready already: its levels pass through when they fit, else level nought
		// decodes and cooks like any image. Sniffed by MAGIC, never by extension.
		if (Dds.IsDds(bytes))
			return BuildDds(texture, context, bytes);

		let image = scope Image();
		if (ImageIO.LoadImageFromMemory(bytes, image) case .Err(let decodeError))
			return .Err(decodeError);
		return BuildFromImage(texture, context, image);
	}

	/// The image path: a decoded two dimensional image, mips by the asset's flag, and the
	/// format the policy picks.
	private static Result<void, ErrorCode> BuildFromImage(TextureAsset texture,
		AssetBuildContext context, Image image)
	{
		let record = scope TextureResource();
		record.Width = image.Width;
		record.Height = image.Height;
		record.DepthOrArrayLayers = 1;
		record.MipLevels = 1;
		record.Format = TextureFormatUtils.Convert(image.Format, texture.ColorSpace);

		let pixels = scope List<uint8>();
		pixels.AddRange(image.PixelData);

		// The cook's own profile per texture, so a slow phase NAMES itself rather than being
		// guessed at from a total.
		let clock = scope Stopwatch(true);
		var mipsMs = (int64)0;
		var compressMs = (int64)0;

		let srgb = texture.ColorSpace == .Srgb;
		if (image.Format == .RGBA8)
		{
			if (texture.GenerateMipmaps && (texture.Shape == .Texture2D))
				record.MipLevels = TextureMipChain.Append(pixels, image.Width, image.Height, srgb);
			mipsMs = clock.ElapsedMilliseconds;

			if (texture.Shape == .Texture2D)
			{
				TextureCompress.MaybeCompress(pixels, image.Width, image.Height, record.MipLevels,
					srgb, texture.Usage, texture.Compression, TextureCompress.ProfileFor(context),
					ref record.Format, context.Jobs);
			}
			compressMs = clock.ElapsedMilliseconds - mipsMs;
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

		let beforeWrite = clock.ElapsedMilliseconds;
		let written = context.Output.WriteData(cPixelStreamName, pixels);
		GlobalLog(.Information,
			"Cook: texture {}x{}, {} level(s): mips {} ms, compress {} ms, write {} ms",
			image.Width, image.Height, record.MipLevels, mipsMs, compressMs,
			clock.ElapsedMilliseconds - beforeWrite);
		return written;
	}

	// ==================== DDS sources ====================
	//
	// A DDS carries GPU ready levels, BC blocks and a mip chain. They pass through UNTOUCHED,
	// lossless against the package and with no encode, when the authored compression is not
	// None, the target reads BC, the block format fits the asset's usage by the policy table's
	// own rules, and the file carries the mip chain the asset asks for. Otherwise level nought
	// decodes and cooks as a plain image, mips generated and format by policy, which is also
	// the route for an ASTC or uncompressed target.

	private static TextureFormat DdsFormatToRhi(DdsFormat format, bool srgb)
	{
		switch (DdsFormats.WithSrgb(format, srgb))
		{
		case .BC1: return .BC1RGBAUnorm;
		case .BC1Srgb: return .BC1RGBAUnormSrgb;
		case .BC2: return .BC2RGBAUnorm;
		case .BC2Srgb: return .BC2RGBAUnormSrgb;
		case .BC3: return .BC3RGBAUnorm;
		case .BC3Srgb: return .BC3RGBAUnormSrgb;
		case .BC4: return .BC4RUnorm;
		case .BC4Snorm: return .BC4RSnorm;
		case .BC5: return .BC5RGUnorm;
		case .BC5Snorm: return .BC5RGSnorm;
		case .BC6HUf: return .BC6HRGBUfloat;
		case .BC6HSf: return .BC6HRGBFloat;
		case .BC7: return .BC7RGBAUnorm;
		case .BC7Srgb: return .BC7RGBAUnormSrgb;
		default: return .RGBA8Unorm; // an uncompressed format never passes through
		}
	}

	/// Whether a block format is one this usage may carry.
	///
	/// Normal is BC7 ALONE rather than BC5, until the shaders reconstruct Z: a BC5 normal map
	/// has no blue channel, and the forward pass reads one.
	///
	/// The usage is the SourceUsage alias because RHI has a TextureUsage of its own, which is
	/// a bind flag set rather than what a texture is for.
	private static bool DdsFitsUsage(DdsFormat format,
		Sedulous.Texture.Compression.SourceUsage usage)
	{
		// The sRGB twin is the asset's call, not the file's.
		let f = DdsFormats.WithSrgb(format, false);
		switch (usage)
		{
		case .Color: return (f == .BC1) || (f == .BC2) || (f == .BC3) || (f == .BC7);
		case .Normal: return f == .BC7;
		case .Mask: return (f == .BC4) || (f == .BC7);
		case .HDR: return (f == .BC6HUf) || (f == .BC6HSf);
		default: return false;
		}
	}

	private static bool DdsPassesThrough(TextureAsset texture, DdsImage dds,
		Sedulous.Texture.Compression.TargetProfile profile)
	{
		if ((texture.Compression == .None) || !profile.Bc)
			return false;
		if (!DdsFormats.IsBlockCompressed(dds.Format) || !DdsFitsUsage(dds.Format, texture.Usage))
			return false;

		// Mips wanted but not in the file: decode and generate them.
		let hasSize = (dds.Width > 1) || (dds.Height > 1);
		if (texture.GenerateMipmaps && (dds.MipLevels < 2) && hasSize)
			return false;
		return true;
	}

	private static Result<void, ErrorCode> BuildDds(TextureAsset texture,
		AssetBuildContext context, Span<uint8> raw)
	{
		let dds = scope DdsImage();
		if (Dds.LoadDds(raw, dds) case .Err(let loadError))
		{
			GlobalLog(.Error, "Texture: {} is not a readable DDS, being {}", texture.FileName.Value,
				(loadError == .NotSupported)
					? "a volume or a format outside the engine's set"
					: "truncated or malformed");
			return .Err(loadError);
		}
		if (dds.Cubemap || (dds.ArrayLayers != 1) || (texture.Shape != .Texture2D))
		{
			GlobalLog(.Error,
				"Texture: {} is a cubemap or array DDS, and only two dimensional DDS sources cook",
				texture.FileName.Value);
			return .Err(.NotSupported);
		}

		if (!DdsPassesThrough(texture, dds, TextureCompress.ProfileFor(context)))
		{
			let image = scope Image();
			if (DdsDecode.DecodeLevel(dds, 0, 0, image) case .Err(let decodeError))
				return .Err(decodeError);
			return BuildFromImage(texture, context, image);
		}

		// No mips asked for means level nought alone.
		let levels = texture.GenerateMipmaps ? dds.MipLevels : 1;
		var payload = 0;
		for (uint32 level = 0; level < levels; level++)
			payload += dds.LevelSize(level);

		let record = scope TextureResource();
		record.Width = dds.Width;
		record.Height = dds.Height;
		record.DepthOrArrayLayers = 1;
		record.MipLevels = levels;
		record.Format = DdsFormatToRhi(dds.Format, texture.ColorSpace == .Srgb);
		FillSampler(texture, record);

		if (context.Output.WriteObject(record) case .Err(let writeError))
			return .Err(writeError);
		return context.Output.WriteData(cPixelStreamName, .(dds.Data.Ptr, payload));
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
				TextureCompress.ProfileFor(context), ref record.Format, context.Jobs);
		}

		FillSampler(texture, record);
		if (context.Output.WriteObject(record) case .Err(let writeError))
			return .Err(writeError);
		return context.Output.WriteData(cPixelStreamName, pixels);
	}
}
