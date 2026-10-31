using Sedulous.Core;

namespace Sedulous.UI;

/// An empty view that exists to take up room.
///
/// The properties are SpacerWidth/SpacerHeight rather than Width/Height because the latter are
/// the view's ARRANGED size, which the layout writes; these are the request.
class Spacer : View
{
	public Property<float> SpacerWidth = new .(0.0f) ~ delete _;
	public Property<float> SpacerHeight = new .(0.0f) ~ delete _;

	public this(float width = 0.0f, float height = 0.0f)
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
