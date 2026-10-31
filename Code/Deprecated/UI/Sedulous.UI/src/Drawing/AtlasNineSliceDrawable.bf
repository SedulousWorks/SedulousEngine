using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// A nine slice over a sub region of a shared atlas image.
class AtlasNineSliceDrawable : Drawable
{
	public ImageData AtlasImage = null;
	public Rectangle SourceRect = .();
	public NineSlice Slices = .();
	public Thickness Expand = .();
	public Color Tint = Color.White;

	public this() {}

	public this(ImageData atlas, Rectangle sourceRect, NineSlice slices,
		Color tint = Color.White, Thickness expand = .())
	{
		AtlasImage = atlas;
		SourceRect = sourceRect;
		Slices = slices;
		Expand = expand;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (AtlasImage == null)
			return;

		let drawBounds = Rectangle(bounds.X - Expand.Left, bounds.Y - Expand.Top,
			bounds.Width + Expand.TotalHorizontal, bounds.Height + Expand.TotalVertical);
		ctx.VG.DrawNineSlice(AtlasImage, drawBounds, SourceRect, Slices, Tint);
	}

	public override Thickness DrawablePadding => .(
		Max(0.0f, Slices.Left - Expand.Left), Max(0.0f, Slices.Top - Expand.Top),
		Max(0.0f, Slices.Right - Expand.Right), Max(0.0f, Slices.Bottom - Expand.Bottom));

	public override Float2? IntrinsicSize => Float2(
		SourceRect.Width - Expand.TotalHorizontal, SourceRect.Height - Expand.TotalVertical);
}
