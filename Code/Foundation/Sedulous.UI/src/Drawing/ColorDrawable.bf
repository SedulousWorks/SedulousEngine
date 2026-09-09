using Sedulous.Core;

namespace Sedulous.UI;

/// Fills its bounds with a solid colour.
class ColorDrawable : Drawable
{
	public Color Color = .();

	public this() {}

	public this(Color color)
	{
		Color = color;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		// A fully transparent fill is not merely invisible, it is a wasted draw call, and a
		// theme leaves plenty of them lying around.
		if (Color.A > 0.0f)
			ctx.VG.FillRect(bounds, Color);
	}
}
