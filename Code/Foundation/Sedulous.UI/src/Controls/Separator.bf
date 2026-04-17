namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Thin line (horizontal or vertical) for visual separation.
/// Color defaults to theme's "Separator.Color".
public class Separator : View
{
	public Orientation Orientation = .Horizontal;
	public float SeparatorThickness = 1;

	private Color? mColor;

	public Color Color
	{
		get => mColor ?? Context?.Theme?.GetColor("Separator.Color") ?? .(80, 80, 90, 255);
		set => mColor = value;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (Orientation == .Horizontal)
			MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(SeparatorThickness));
		else
			MeasuredSize = .(wSpec.Resolve(SeparatorThickness), hSpec.Resolve(0));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color);
	}
}
