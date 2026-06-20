namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Draws an image stretched to fill bounds.
public class ImageDrawable : Drawable
{
	public IImageData Image;
	public Color Tint = .White;

	public this(IImageData image, Color tint = .White)
	{
		Image = image;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (Image != null)
			ctx.VG.DrawImage(Image, bounds, .(0, 0, Image.Width, Image.Height), Tint);
	}

	public override Vector2? IntrinsicSize
	{
		get => (Image != null) ? Vector2(Image.Width, Image.Height) : null;
	}
}
