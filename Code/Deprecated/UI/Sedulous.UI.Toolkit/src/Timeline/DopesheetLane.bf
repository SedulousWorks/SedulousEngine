using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// One row of a dopesheet: a height, a label for the gutter, and the TIMES of the keys on it.
///
/// The times are the whole model. What a key MEANS, which track and which channel, stays with
/// the host, so the widget can draw a dopesheet for anything with keys on a clock.
class DopesheetLane
{
	public float Height = 22.0f;
	/// Shown in the left gutter when there is one: "Transform.Position", say.
	public String Label = new .() ~ delete _;
	/// Seconds, SORTED by the host. The widget draws and hit tests in this order and never
	/// reorders them.
	public List<float> KeyTimes = new .() ~ delete _;

	public this() {}

	public this(StringView label, float height = 22.0f)
	{
		Label.Set(label);
		Height = height;
	}
}
