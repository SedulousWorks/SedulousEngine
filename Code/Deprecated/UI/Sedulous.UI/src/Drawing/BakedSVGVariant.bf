using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// One pre baked bitmap of an SVG, at one square size.
struct BakedSVGVariant
{
	/// BORROWED: the baker owns the atlas and must outlive every drawable using it.
	public ImageData Atlas = null;
	/// The texel region within that atlas.
	public Rectangle SourceRect = .();
	/// The square size, in DEVICE pixels, that this was baked at.
	public float SizePx = 0.0f;

	public this() {}

	public this(ImageData atlas, Rectangle sourceRect, float sizePx)
	{
		Atlas = atlas;
		SourceRect = sourceRect;
		SizePx = sizePx;
	}
}
