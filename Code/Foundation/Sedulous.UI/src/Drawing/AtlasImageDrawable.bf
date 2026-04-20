namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Draws a sub-region of a shared atlas image. Enables single-texture
/// batching for all themed UI elements.
public class AtlasImageDrawable : Drawable
{
	public IImageData AtlasImage;
	public RectangleF SourceRect; // pixel-space region in atlas
	public Color Tint = .White;

	public this(IImageData atlas, RectangleF sourceRect, Color tint = .White)
	{
		AtlasImage = atlas;
		SourceRect = sourceRect;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (AtlasImage != null)
			ctx.VG.DrawImage(AtlasImage, bounds, SourceRect, Tint);
	}

	public override Vector2? IntrinsicSize => .(SourceRect.Width, SourceRect.Height);
}
