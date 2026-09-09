using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Terrain.Resource;

/// The cooked splat weights METADATA: the raster's dimensions, and nothing else.
///
/// The two pixel blobs ride sidecar streams rather than sitting in here, the way an image's
/// pixels do.
/// Version one, matching the cooked layout Raptor stamps.
[Serializable(1)]
class SplatWeightsSource
{
	/// The sidecar carrying the WEIGHT raster.
	public const String WeightStream = "pixels";
	/// The sidecar carrying the palette INDEX raster. Both are required: a cooked instance
	/// missing either cannot be rebuilt.
	public const String IndexStream = "indices";

	public int32 Width = 0;
	public int32 Height = 0;

	public static void FromWeights(SplatWeights weights, SplatWeightsSource outSource)
	{
		outSource.Width = weights.Width;
		outSource.Height = weights.Height;
	}

	/// BORROWED from the raster, which has to outlive the write.
	public static Span<uint8> WeightBlob(SplatWeights weights) => weights.Weights;
	public static Span<uint8> IndexBlob(SplatWeights weights) => weights.Indices;

	/// Builds the runtime raster from this metadata and the two sidecars. Inconsistent data,
	/// meaning bad dimensions or a blob that does not match them, yields an EMPTY raster
	/// rather than a malformed one.
	///
	/// THE CALLER OWNS what comes back.
	public SplatWeights Build(Span<uint8> indexBlob, Span<uint8> weightBlob)
	{
		if ((Width <= 0) || (Height <= 0))
			return new SplatWeights();

		let expected = (int)Width * (int)Height * (int)SplatWeights.SlotCount;
		if ((indexBlob.Length != expected) || (weightBlob.Length != expected))
			return new SplatWeights();

		let weights = new SplatWeights(Width, Height);
		Internal.MemCpy(weights.Indices.Ptr, indexBlob.Ptr, expected);
		Internal.MemCpy(weights.Weights.Ptr, weightBlob.Ptr, expected);
		return weights;
	}
}
