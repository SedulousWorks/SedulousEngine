using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Vegetation.Resource;

/// The cooked mask METADATA: the raster's dimensions and its plane count, nothing else.
///
/// The density planes ride ONE sidecar stream, plane major, the way the splat rasters do.
/// Version one.
[Serializable(1)]
class VegetationMaskSource
{
	/// The sidecar carrying every plane, plane major.
	public const String DensityStream = "densities";

	public int32 Width = 0;
	public int32 Height = 0;
	public uint32 PlaneCount = 1;

	public static void FromMask(VegetationMask mask, VegetationMaskSource outSource)
	{
		outSource.Width = mask.Width;
		outSource.Height = mask.Height;
		outSource.PlaneCount = mask.PlaneCount;
	}

	/// BORROWED from the mask, which has to outlive the write.
	public static Span<uint8> DensityBlob(VegetationMask mask) => mask.Densities;

	/// Builds the runtime mask from this metadata and the sidecar. Inconsistent data, meaning
	/// bad dimensions or a blob that does not match them, yields an EMPTY mask rather than a
	/// malformed one.
	///
	/// THE CALLER OWNS what comes back.
	public VegetationMask Build(Span<uint8> densityBlob)
	{
		if ((Width <= 0) || (Height <= 0))
			return new VegetationMask();

		let planes = (PlaneCount == 0) ? (uint32)1 : Math.Min(PlaneCount, VegetationMask.cMaxPlanes);
		let expected = (int)Width * (int)Height * (int)planes;
		if (densityBlob.Length != expected)
			return new VegetationMask();

		let mask = new VegetationMask(Width, Height, planes);
		Internal.MemCpy(mask.Densities.Ptr, densityBlob.Ptr, expected);
		return mask;
	}
}
