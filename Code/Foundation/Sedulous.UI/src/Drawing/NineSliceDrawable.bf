namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.ImageData;

/// 9-slice image drawable with optional Expand for shadow/glow
/// extending beyond the logical bounds.
public class NineSliceDrawable : Drawable
{
	public IImageData Image;
	public NineSlice Slices;
	public Thickness Expand;  // extends drawing beyond bounds (shadow/glow)
	public Color Tint = .White;

	public this(IImageData image, NineSlice slices, Color tint = .White)
	{
		Image = image;
		Slices = slices;
		Tint = tint;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (Image == null) return;

		let drawBounds = RectangleF(
			bounds.X - Expand.Left,
			bounds.Y - Expand.Top,
			bounds.Width + Expand.TotalHorizontal,
			bounds.Height + Expand.TotalVertical);

		let srcRect = RectangleF(0, 0, Image.Width, Image.Height);
		ctx.VG.DrawNineSlice(Image, drawBounds, srcRect, Slices, Tint);
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
		get => (Image != null) ?
			Vector2(Image.Width - Expand.TotalHorizontal, Image.Height - Expand.TotalVertical) : null;
	}
}
