namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Solid color swatch view.
public class ColorView : View
{
	public Color Color = .White;
	public float PreferredWidth;
	public float PreferredHeight;

	public this() { }
	public this(Color color) { Color = color; }
	public this(Color color, float w, float h) { Color = color; PreferredWidth = w; PreferredHeight = h; }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = (PreferredWidth > 0) ? PreferredWidth : 0;
		let h = (PreferredHeight > 0) ? PreferredHeight : 0;
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color);
	}
}
