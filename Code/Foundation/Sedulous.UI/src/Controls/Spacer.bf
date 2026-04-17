namespace Sedulous.UI;

/// Empty view that takes a fixed size. Useful for spacing in layouts.
public class Spacer : View
{
	public float SpacerWidth;
	public float SpacerHeight;

	public this(float width = 0, float height = 0)
	{
		SpacerWidth = width;
		SpacerHeight = height;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(SpacerWidth), hSpec.Resolve(SpacerHeight));
	}
}
