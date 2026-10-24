using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// Drawable: image content drawn into a destination Rect via DrawContext (an Image widget's
// picture, a menu item's or a button's icon); a node's look is its box, not a drawable. Derived
// from eepp's Drawable (include/eepp/graphics/drawable.hpp): keeps the color/alpha tint state,
// but replaces eepp's global draw with the DrawContext seam. Reference counted: each holder (a
// widget showing it, a style that made it) keeps a reference, and whoever made one releases its
// own.

abstract class Drawable : RefCounted
{
	protected Color mColor = .White;

	/// Draws into a destination rect.
	public abstract void Draw(DrawContext ctx, Rect dest);

	/// Draws it multiplied by `tint` (an Image's image-color); one that cannot tint draws as it is.
	public virtual void DrawTinted(DrawContext ctx, Rect dest, Color tint)
	{
		Draw(ctx, dest);
	}

	/// Natural size (icons/images); null = no intrinsic size.
	public virtual Float2? IntrinsicSize => null;

	/// Tint / opacity (eepp Drawable color state).
	public Color Color
	{
		get => mColor;
		set => mColor = value;
	}

	public float Alpha
	{
		get => mColor.A;
		set => mColor.A = value;
	}
}
