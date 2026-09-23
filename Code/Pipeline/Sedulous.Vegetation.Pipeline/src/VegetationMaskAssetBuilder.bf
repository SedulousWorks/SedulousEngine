using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Vegetation.Pipeline;

/// Cooks a vegetation mask into its metadata object plus one density stream.
class VegetationMaskAssetBuilder : IAssetBuilder
{
	/// The smallest raster anything here is allowed to have.
	private const int32 cMinSide = 1;

	public Type AssetType => typeof(VegetationMaskAsset);

	/// The SERIALIZED cooked form rather than the runtime product, the cook stamping this onto
	/// the instance and the runtime reconstructing by that name.
	public Type ProductType => typeof(VegetationMaskSource);

	public int32 Version => 1;

	/// An EMBEDDED mask, meaning one with no file name, reads its authored densities sidecar,
	/// so the recipe hash has to chain those bytes: the envelope hash does not cover a
	/// sidecar, and a paint save has to re-cook. An IMPORTED one chains the image file
	/// instead, which the implicit file name already covers.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let mask = (VegetationMaskAsset)asset;
		if (mask.FileName.IsEmpty)
			outDeps.AddSourceStream(VegetationMaskSource.DensityStream);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (VegetationMaskAsset)asset;

		if (!authored.FileName.IsEmpty)
			return BuildFromImage(authored, context);
		return BuildEmbedded(authored, context);
	}

	/// An IMPORTED mask: the image's own size is the raster's, and each channel becomes one
	/// density plane, so a four channel image authors four layers at once.
	private Result<void, ErrorCode> BuildFromImage(VegetationMaskAsset authored,
		AssetBuildContext context)
	{
		let bytes = scope List<uint8>();
		if (AssetSource.ReadBytes(context, authored.FileName.Value, bytes) case .Err(let readError))
			return .Err(readError);

		let image = scope Image();
		if (ImageIO.LoadImageFromMemory(bytes, image) case .Err(let decodeError))
			return .Err(decodeError);

		let width = (int32)image.Width;
		let height = (int32)image.Height;
		if ((width < cMinSide) || (height < cMinSide))
			return .Err(.InvalidArgument);

		// The loader hands back four channels; the asset says how many of them to keep.
		const uint32 cChannels = 4;
		let planes = Math.Clamp((authored.PlaneCount == 0) ? (uint32)1 : authored.PlaneCount,
			1, cChannels);

		let mask = scope VegetationMask(width, height, planes);
		let pixels = image.PixelData;
		let texels = (int)width * (int)height;
		if (pixels.Length < texels * (int)cChannels)
			return .Err(.InvalidArgument);

		for (uint32 plane = 0; plane < planes; plane++)
		{
			let dst = mask.Plane(plane);
			for (int i < texels)
				dst[i] = pixels[i * (int)cChannels + (int)plane];
		}

		return Write(mask, context);
	}

	/// An EMBEDDED mask: the authored sidecar is the truth, an empty file name being what
	/// marks it authoritative. A missing or mismatched blob leaves the planes empty, which is
	/// a mask created on a page and never painted.
	private Result<void, ErrorCode> BuildEmbedded(VegetationMaskAsset authored,
		AssetBuildContext context)
	{
		let width = Math.Max(authored.Width, cMinSide);
		let height = Math.Max(authored.Height, cMinSide);
		let planes = Math.Clamp((authored.PlaneCount == 0) ? (uint32)1 : authored.PlaneCount,
			1, VegetationMask.cMaxPlanes);

		let mask = scope VegetationMask(width, height, planes);
		if (context.Source != null)
		{
			let stream = context.Source.ReadData(VegetationMaskSource.DensityStream);
			if (stream != null)
			{
				defer delete stream;
				let streamSize = stream.Size();
				let planeBytes = (int64)width * (int64)height;
				let expected = planeBytes * (int64)planes;
				// A blob that is a whole number of planes but not this many is an author who
				// changed the plane COUNT after painting: keep the planes that still exist,
				// a fresh one starting empty and a dropped one simply gone. Anything else is
				// a dimension change, and there is no sensible way to carry a painting across
				// that, so the planes stay empty.
				let readable = (streamSize == expected)
					? streamSize
					: (((planeBytes > 0) && ((streamSize % planeBytes) == 0))
						? Math.Min(streamSize, expected)
						: 0);
				if (readable > 0)
				{
					let densities = mask.Densities;
					if (stream.Read(.(densities.Ptr, (int)readable)) != (int)readable)
					{
						// A partial read: an empty mask beats half a painting.
						for (int i < densities.Length)
							densities[i] = 0;
					}
				}
			}
		}

		return Write(mask, context);
	}

	private static Result<void, ErrorCode> Write(VegetationMask mask, AssetBuildContext context)
	{
		let cooked = scope VegetationMaskSource();
		VegetationMaskSource.FromMask(mask, cooked);
		if (context.Output.WriteObject(cooked) case .Err(let writeError))
			return .Err(writeError);

		return context.Output.WriteData(VegetationMaskSource.DensityStream,
			VegetationMaskSource.DensityBlob(mask));
	}
}
