namespace Sedulous.UI;

/// Visual state of a control. Priority order for resolution:
/// Disabled > Pressed > Focused > Hover > Normal.
/// StateListDrawable uses this to pick the right drawable variant.
public enum ControlState
{
	Normal,
	Hover,
	Pressed,
	Focused,
	Disabled
}
