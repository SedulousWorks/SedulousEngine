namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Fills bounds with a solid color.
public class ColorDrawable : Drawable
{
	public Color Color;

	public this(Color color) { Color = color; }

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (Color.A > 0)
			ctx.VG.FillRect(bounds, Color);
	}
}
