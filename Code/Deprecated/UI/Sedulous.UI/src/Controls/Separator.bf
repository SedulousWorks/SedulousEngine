using Sedulous.Core;

namespace Sedulous.UI;

/// A divider line, horizontal or vertical.
///
/// The `Orientation` property shadows the enum type inside this class, so the enum values are
/// reached through inference rather than by name.
class Separator : View
{
	public Property<Orientation> Orientation = new .(.Horizontal) ~ delete _;
	public Property<float> SeparatorThickness = new .(1.0f) ~ delete _;

	public this()
	{
		Orientation.SetOwner(this);
		SeparatorThickness.SetOwner(this);
	}

	public this(Orientation orientation) : this()
	{
		Orientation.SetSilent(orientation);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Fill the long axis when the parent bounded it, and fall back to a sane length when it
		// did not: the raw Max is FloatMax under an unbounded parent, which would measure a
		// separator as effectively infinite.
		if (Orientation.Value == .Horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(100.0f)),
				constraints.ConstrainHeight(SeparatorThickness.Value));
		else
			MeasuredSize = .(constraints.ConstrainWidth(SeparatorThickness.Value),
				constraints.ConstrainHeight(constraints.BoundedMaxHeight(100.0f)));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let color = ResolveStyleColor(.BorderColor, .(80.0f / 255.0f, 80.0f / 255.0f, 90.0f / 255.0f, 1.0f));
		ctx.VG.FillRect(.(0, 0, Width, Height), color);
	}
}
