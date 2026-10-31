using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// Draws a sub region of a shared atlas image, so a whole theme batches through one texture.
class AtlasImageDrawable : Drawable
{
	public ImageData AtlasImage = null;
	public Rectangle SourceRect = .();
	public Color Tint = Color.White;

	public this() {}

	public this(ImageData atlas, Rectangle sourceRect, Color tint = Color.White)
	{
		AtlasImage = atlas;
		SourceRect = sourceRect;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (AtlasImage != null)
			ctx.VG.DrawImage(AtlasImage, bounds, SourceRect, Tint);
	}

	public override Float2? IntrinsicSize => Float2(SourceRect.Width, SourceRect.Height);
}
