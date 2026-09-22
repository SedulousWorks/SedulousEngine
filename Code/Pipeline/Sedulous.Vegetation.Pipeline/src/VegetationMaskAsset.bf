using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Vegetation.Pipeline;

/// A painted vegetation mask over a terrain's footprint.
///
/// A file name means an image, one plane per channel, resampled to nothing: the image's own
/// size is the mask's. WITHOUT one the mask is authored in place, and the density sidecar is
/// the truth, which is what a Paint Vegetation stroke saves.
[Category("Terrain")]
[DisplayName("Vegetation Mask")]
[Serializable]
class VegetationMaskAsset : Asset
{
	/// The raster's width in texels.
	public int32 Width = 512;
	/// The raster's height in texels.
	public int32 Height = 512;
	/// How many density planes it carries, one per layer that paints against it.
	[DisplayName("Plane Count")]
	public uint32 PlaneCount = 1;
}
