using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.Terrain.Resource;

namespace Sedulous.Terrain.Pipeline;

/// Cooks painted or imported splat weights into their record and two streams.
class SplatmapAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(SplatmapAsset);

	/// The SERIALIZED cooked form rather than the runtime one, as the terrain and heightfield
	/// builders also do.
	public Type ProductType => typeof(SplatWeightsSource);

	/// Three, for the top weights model with its pair of rasters.
	public int32 Version => 3;

	/// An EDITABLE splatmap reads BOTH its sidecars, so the recipe hash has to chain their
	/// bytes: the envelope's hash does not cover a sidecar, and saving a paint stroke has to
	/// re-cook. An imported one chains its file, which the implicit file name already covers.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let splat = (SplatmapAsset)asset;
		if (splat.FileName.IsEmpty)
		{
			outDeps.AddSourceStream(SplatWeightsSource.WeightStream);
			outDeps.AddSourceStream(SplatWeightsSource.IndexStream);
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let splat = (SplatmapAsset)asset;
		if (context.Output == null)
			return .Err(.InvalidArgument);

		SplatWeights weights = null;
		defer { if (weights != null) delete weights; }

		if (!splat.FileName.IsEmpty)
		{
			if (BuildFromImage(splat, context, out weights) case .Err(let imageError))
				return .Err(imageError);
		}
		else
		{
			if (BuildFromSidecars(splat, context, out weights) case .Err(let sidecarError))
				return .Err(sidecarError);
		}

		if ((weights == null) || weights.IsEmpty)
			return .Err(.InvalidArgument);

		let cooked = scope SplatWeightsSource();
		SplatWeightsSource.FromWeights(weights, cooked);
		if (context.Output.WriteObject(cooked) case .Err(let writeError))
			return .Err(writeError);

		if (context.Output.WriteData(SplatWeightsSource.WeightStream,
			SplatWeightsSource.WeightBlob(weights)) case .Err(let weightError))
		{
			return .Err(weightError);
		}
		return context.Output.WriteData(SplatWeightsSource.IndexStream,
			SplatWeightsSource.IndexBlob(weights));
	}

	/// IMPORTED: the image is read as a fixed layer raster, red being the base's share and the
	/// rest the first three palette layers. That is the only reading of a flat image the top
	/// weights model can honestly make.
	private static Result<void, ErrorCode> BuildFromImage(SplatmapAsset splat,
		AssetBuildContext context, out SplatWeights outWeights)
	{
		outWeights = null;

		let bytes = scope List<uint8>();
		if (AssetSource.ReadBytes(context, splat.FileName.Value, bytes) case .Err(let readError))
			return .Err(readError);

		let image = scope Image();
		if (ImageIO.LoadImageFromMemory(bytes, image) case .Err(let decodeError))
			return .Err(decodeError);
		if (image.Format != .RGBA8)
			return .Err(.NotSupported); // weights are eight bit per channel

		outWeights = SplatBrush.FromFixedLayerRaster(image.PixelData, (int32)image.Width,
			(int32)image.Height);
		return .Ok;
	}

	/// EDITABLE: the rasters ride the source's sidecars.
	///
	/// BOTH present is the painted pair. NEITHER is a splatmap never painted, which is all
	/// base by construction and needs no seeding. ONE without the other is a broken source and
	/// fails the cook rather than inventing the missing half.
	private static Result<void, ErrorCode> BuildFromSidecars(SplatmapAsset splat,
		AssetBuildContext context, out SplatWeights outWeights)
	{
		outWeights = null;

		let width = (splat.Width > 0) ? splat.Width : 1;
		let height = (splat.Height > 0) ? splat.Height : 1;
		let expected = (int)width * (int)height * (int)SplatWeights.SlotCount;

		let weightBlob = scope List<uint8>();
		let indexBlob = scope List<uint8>();
		if (context.Source != null)
		{
			ReadStream(context.Source, SplatWeightsSource.WeightStream, weightBlob);
			ReadStream(context.Source, SplatWeightsSource.IndexStream, indexBlob);
		}

		if ((weightBlob.Count == expected) && (indexBlob.Count == expected))
		{
			outWeights = new SplatWeights(width, height);
			Internal.MemCpy(outWeights.Weights.Ptr, weightBlob.Ptr, expected);
			Internal.MemCpy(outWeights.Indices.Ptr, indexBlob.Ptr, expected);
			return .Ok;
		}
		if (weightBlob.IsEmpty && indexBlob.IsEmpty)
		{
			outWeights = new SplatWeights(width, height); // never painted, so all base
			return .Ok;
		}
		return .Err(.NotSupported); // one raster without the other, or a size that disagrees
	}

	private static void ReadStream(Instance instance, StringView name, List<uint8> outBlob)
	{
		let stream = instance.ReadData(name);
		if (stream == null)
			return;
		defer delete stream;

		let size = (int)stream.Size();
		if (size <= 0)
			return;

		outBlob.Count = size;
		if (stream.Read(.(outBlob.Ptr, size)) != size)
			outBlob.Clear();
	}
}
