namespace Sedulous.LegacyUI;

using Sedulous.Core.Mathematics;

/// Fills bounds with a solid color.
public class ColorDrawable : Drawable
{
	public Color32 Color;

	public this(Color32 color) { Color = color; }

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (Color.A > 0)
			ctx.VG.FillRect(bounds, Color);
	}
}
