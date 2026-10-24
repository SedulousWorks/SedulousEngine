using System;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.GUI;

// ImageDrawable: draws an image stretched to fill the destination rect, with a tint. Derived from
// eepp's Texture/TextureRegion drawing (batched textured quad); maps to VG's DrawImage. The image
// is owned elsewhere (theme/atlas/resource provider) and borrowed here.

class ImageDrawable : Drawable
{
	/// Borrowed; it must outlive the drawable.
	public ImageData Image = null;
	public Color Tint = .White;

	public this() { }

	public this(ImageData image, Color tint = .White)
	{
		Image = image;
		Tint = tint;
	}

	public override void Draw(DrawContext ctx, Rect dest)
	{
		if (Image == null)
			return;
		ctx.VG.DrawImage(Image, dest.ToRectangle(), .(0.0f, 0.0f, (float)Image.Width, (float)Image.Height), Tint);
	}

	public override void DrawTinted(DrawContext ctx, Rect dest, Color tint)
	{
		if (Image == null)
			return;
		Color t = .(Tint.R * tint.R, Tint.G * tint.G, Tint.B * tint.B, Tint.A * tint.A);
		ctx.VG.DrawImage(Image, dest.ToRectangle(), .(0.0f, 0.0f, (float)Image.Width, (float)Image.Height), t);
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
