namespace Sedulous.Fonts;

/// How an atlas stores its glyphs.
enum AtlasMode : uint8
{
	/// Eight bit coverage: the classic rasterised alpha, baked at one size and blurry away
	/// from it.
	case Coverage;
	/// A signed distance field, which stays crisp at any scale because the field is
	/// interpolated rather than the pixels.
	case DistanceField;
}
