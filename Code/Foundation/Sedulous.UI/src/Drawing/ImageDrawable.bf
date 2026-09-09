using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// Draws an image stretched to fill the bounds.
///
/// The image is BORROWED: it belongs to the theme or atlas that loaded it, not to the
/// drawable, so many drawables can name the same one.
class ImageDrawable : Drawable
{
	public ImageData Image = null;
	public Color Tint = Color.White;

	public this() {}

	public this(ImageData image, Color tint = Color.White)
	{
		Image = image;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (Image == null)
			return;
		ctx.VG.DrawImage(Image, bounds, .(0.0f, 0.0f, (float)Image.Width, (float)Image.Height),
			Tint);
	}

	public override Float2? IntrinsicSize
	{
		get
		{
			if (Image == null)
				return null;
			return Float2((float)Image.Width, (float)Image.Height);
		}
	}
}
