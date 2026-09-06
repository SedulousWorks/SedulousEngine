namespace Sedulous.Image;

/// How the stored channel values are to be read.
///
/// This is not decoration: a GPU converts sRGB to linear when sampling, and getting it
/// wrong on a normal map or a mask corrupts the values rather than merely shifting the
/// look.
enum ImageColorSpace : uint32
{
	/// sRGB encoded, for photographs and interface art.
	case Srgb;
	/// Linear, for normal maps, masks and anything with a numeric meaning.
	case Linear;
}
