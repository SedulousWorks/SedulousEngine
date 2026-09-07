using System;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// What a cached font is looked up by: where it came from, and the size it was baked at.
///
/// The size is part of the key because a coverage atlas is baked for ONE size; the same
/// file at two sizes is two different bakes.
struct FontCacheKey : IHashable
{
	public String Path;
	public float PixelHeight;

	public this() { Path = null; PixelHeight = 0; }
	public this(String path, float pixelHeight) { Path = path; PixelHeight = pixelHeight; }

	/// Sizes compare with a tolerance: they arrive from layout arithmetic, and two routes
	/// to the same size can differ in the last bit and would otherwise bake twice.
	public bool Equals(FontCacheKey other)
	{
		if ((Path == null) != (other.Path == null))
			return false;
		if ((Path != null) && (Path != other.Path))
			return false;
		return Abs(PixelHeight - other.PixelHeight) < 0.001f;
	}

	/// Quantised to hundredths, which is coarser than the 0.001 the comparison allows. Two
	/// keys that straddle a hundredth boundary therefore compare equal but hash apart, and
	/// the cache bakes twice rather than returning the wrong font. Harmless at the discrete
	/// sizes a font cache actually sees, and the failure direction is the safe one.
	public int GetHashCode()
	{
		let heightBucket = (int)(int64)(PixelHeight * 100.0f);
		let pathHash = (Path != null) ? Path.GetHashCode() : 0;
		return pathHash * 31 + heightBucket;
	}

	[Commutable]
	public static bool operator==(FontCacheKey a, FontCacheKey b) => a.Equals(b);
}
