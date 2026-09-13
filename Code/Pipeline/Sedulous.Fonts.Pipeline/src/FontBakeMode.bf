namespace Sedulous.Fonts.Pipeline;

/// How a font asset bakes.
enum FontBakeMode : uint32
{
	/// A ramp of coverage rasterisations, one atlas per size.
	RasterRamp,
	/// A single distance field atlas, which samples at any size once the vector path is on.
	DistanceField,
}
