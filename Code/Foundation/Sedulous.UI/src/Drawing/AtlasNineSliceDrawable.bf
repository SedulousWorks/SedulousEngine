namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// 9-slice drawable that uses a sub-region of a shared atlas image.
/// Enables single-texture batching for all themed UI elements.
public class AtlasNineSliceDrawable : Drawable
{
	public IImageData AtlasImage;
	public RectangleF SourceRect; // pixel-space region in atlas
	public NineSlice Slices;
	public Thickness Expand;
	public Color Tint = .White;

	public this(IImageData atlas, RectangleF sourceRect, NineSlice slices,
		Color tint = .White, Thickness expand = .())
	{
		AtlasImage = atlas;
		SourceRect = sourceRect;
		Slices = slices;
		Expand = expand;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (AtlasImage == null) return;

		let drawBounds = RectangleF(
			bounds.X - Expand.Left,
			bounds.Y - Expand.Top,
			bounds.Width + Expand.TotalHorizontal,
			bounds.Height + Expand.TotalVertical);

		ctx.VG.DrawNineSlice(AtlasImage, drawBounds, SourceRect, Slices, Tint);
	}

	public override Thickness DrawablePadding
	{
		get => .(
			Math.Max(0, Slices.Left - Expand.Left),
			Math.Max(0, Slices.Top - Expand.Top),
			Math.Max(0, Slices.Right - Expand.Right),
			Math.Max(0, Slices.Bottom - Expand.Bottom));
	}

	public override Vector2? IntrinsicSize
	{
		get => .(
			SourceRect.Width - Expand.TotalHorizontal,
			SourceRect.Height - Expand.TotalVertical);
	}
}
