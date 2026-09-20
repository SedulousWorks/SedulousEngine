using System;
using Sedulous.Image;
using Sedulous.UI;

namespace Sedulous.Editor.Core;

/// A thumbnail drawable that OWNS its pixels: the image lives exactly as long as the
/// drawable, so the service's map can drop entries freely while the UI still holds refs.
/// A renderer cache keyed on the image's instance id then never sees the pixels go before
/// the drawable does.
class OwnedThumbnailDrawable : ImageDrawable
{
	private Image mPixels ~ delete _;

	/// TAKES OWNERSHIP of `pixels`.
	public this(Image pixels) : base(pixels)
	{
		mPixels = pixels;
	}
}
