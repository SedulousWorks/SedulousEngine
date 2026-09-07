namespace Sedulous.Fonts.Resource;

/// How a cooked atlas payload is encoded. Uniform across one resource's entries.
enum FontResourcePixels : uint32
{
	/// Single channel coverage, expanded to RGBA8 when the product is built.
	Coverage = 0,
	/// RGBA8 distance field channels, LINEAR: the values are geometry, not colour, so
	/// nothing may gamma decode them.
	DistanceField = 1
}
