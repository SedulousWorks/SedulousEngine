using System;
using Sedulous.Image;

namespace Sedulous.Editor.Fonts;

/// What a preview bake produced: the atlas as displayable RGBA8, or null when the source
/// was missing, unparseable, or the atlas too small.
class FontBakeOutcome
{
	public OwnedImageData Image = null ~ delete _;
	public int Glyphs = 0;
	public float Size = 0.0f;
	public uint64 Generation = 0;

	/// Hands the image over; the caller owns it afterwards.
	public OwnedImageData TakeImage()
	{
		let image = Image;
		Image = null;
		return image;
	}
}
