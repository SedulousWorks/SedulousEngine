using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// Fills its bounds with a solid colour.
class ColorDrawable : Drawable
{
	public Color Color = .();
	/// A custom property (`--name`) the colour comes from where the drawn view has one; Color is
	/// its fallback.
	public String ColorVariable = new .() ~ delete _;

	public this() {}

	public this(Color color)
	{
		Color = color;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		// A fully transparent fill is not merely invisible, it is a wasted draw call, and a
		// theme leaves plenty of them lying around.
		let color = ctx.ColorOf(Color, ColorVariable);
		if (color.A > 0.0f)
			ctx.VG.FillRect(bounds, color);
	}
}
