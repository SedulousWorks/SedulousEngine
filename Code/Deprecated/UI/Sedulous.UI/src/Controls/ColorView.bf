using Sedulous.Core;

namespace Sedulous.UI;

/// A solid colour swatch.
///
/// The `Color` property shadows the Color type inside this class, so the type is spelled out
/// wherever it is still needed.
class ColorView : View
{
	public Property<Sedulous.Core.Color> Color = new .(Sedulous.Core.Color.White) ~ delete _;
	public Property<float> PreferredWidth = new .(0.0f) ~ delete _;
	public Property<float> PreferredHeight = new .(0.0f) ~ delete _;

	public this()
	{
		Color.SetOwner(this, .Visual);
		PreferredWidth.SetOwner(this);
		PreferredHeight.SetOwner(this);
	}

	public this(Sedulous.Core.Color color) : this()
	{
		Color.SetSilent(color);
	}

	public this(Sedulous.Core.Color color, float w, float h) : this()
	{
		Color.SetSilent(color);
		PreferredWidth.SetSilent(w);
		PreferredHeight.SetSilent(h);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = PreferredWidth.Value > 0 ? PreferredWidth.Value : 0.0f;
		let h = PreferredHeight.Value > 0 ? PreferredHeight.Value : 0.0f;
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color.Value);
	}
}
