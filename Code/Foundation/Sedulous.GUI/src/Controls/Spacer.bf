namespace Sedulous.GUI;

/// Empty view for explicit spacing. In UI2, mostly replaced by
/// FlexLayout.Spacing and JustifyContent, but kept for explicit
/// gaps in non-flex containers.
public class Spacer : View
{
	public float SpacerWidth;
	public float SpacerHeight;

	public this(float width = 0, float height = 0)
	{
		SpacerWidth = width;
		SpacerHeight = height;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(SpacerWidth),
			constraints.ConstrainHeight(SpacerHeight));
	}
}
