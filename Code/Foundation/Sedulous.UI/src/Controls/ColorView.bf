namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Solid color swatch view.
public class ColorView : View
{
	public Property<Color32> Color = new .(.White) ~ delete _;
	public Property<float> PreferredWidth = new .(0) ~ delete _;
	public Property<float> PreferredHeight = new .(0) ~ delete _;

	public this()
	{
		Color.SetOwner(this, .Visual);
		PreferredWidth.SetOwner(this);
		PreferredHeight.SetOwner(this);
	}

	public this(Color32 color) : this()
	{
		Color.SetSilent(color);
	}

	public this(Color32 color, float w, float h) : this()
	{
		Color.SetSilent(color);
		PreferredWidth.SetSilent(w);
		PreferredHeight.SetSilent(h);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = (PreferredWidth.Value > 0) ? PreferredWidth.Value : 0;
		let h = (PreferredHeight.Value > 0) ? PreferredHeight.Value : 0;
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color.Value);
	}
}
