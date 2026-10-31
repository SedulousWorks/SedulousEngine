using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// A nine slice image, optionally EXPANDED beyond its logical bounds.
///
/// Expand is what lets a shadow or glow bleed outside the view it decorates while the layout
/// still measures the view at its logical size: the expansion is subtracted back out of both
/// the padding and the intrinsic size.
class NineSliceDrawable : Drawable
{
	public ImageData Image = null;
	public NineSlice Slices = .();
	public Thickness Expand = .();
	public Color Tint = Color.White;

	public this() {}

	public this(ImageData image, NineSlice slices, Color tint = Color.White)
	{
		Image = image;
		Slices = slices;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (Image == null)
			return;

		let drawBounds = Rectangle(bounds.X - Expand.Left, bounds.Y - Expand.Top,
			bounds.Width + Expand.TotalHorizontal, bounds.Height + Expand.TotalVertical);
		let source = Rectangle(0.0f, 0.0f, (float)Image.Width, (float)Image.Height);
		ctx.VG.DrawNineSlice(Image, drawBounds, source, Slices, Tint);
	}

	public override Thickness DrawablePadding => .(
		Max(0.0f, Slices.Left - Expand.Left), Max(0.0f, Slices.Top - Expand.Top),
		Max(0.0f, Slices.Right - Expand.Right), Max(0.0f, Slices.Bottom - Expand.Bottom));

	public override Float2? IntrinsicSize
	{
		get
		{
			if (Image == null)
				return null;
			return Float2((float)Image.Width - Expand.TotalHorizontal,
				(float)Image.Height - Expand.TotalVertical);
		}
	}
}
