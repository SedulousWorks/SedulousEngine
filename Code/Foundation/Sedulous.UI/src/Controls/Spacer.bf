namespace Sedulous.UI;

/// Empty view for explicit spacing. In UI2, mostly replaced by
/// FlexLayout.Spacing and JustifyContent, but kept for explicit
/// gaps in non-flex containers.
public class Spacer : View
{
	public Property<float> SpacerWidth = new .(0) ~ delete _;
	public Property<float> SpacerHeight = new .(0) ~ delete _;

	public this(float width = 0, float height = 0)
	{
		SpacerWidth.SetOwner(this);
		SpacerHeight.SetOwner(this);

		SpacerWidth.SetSilent(width);
		SpacerHeight.SetSilent(height);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(SpacerWidth.Value),
			constraints.ConstrainHeight(SpacerHeight.Value));
	}
}
