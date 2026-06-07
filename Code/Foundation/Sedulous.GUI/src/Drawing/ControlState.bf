namespace Sedulous.GUI;

/// Visual state of a control as bit flags. Multiple flags can be
/// combined (e.g., .Checked | .Hover for a hovered checked checkbox).
///
/// StateListDrawable uses these for drawable lookup with fallback:
/// try exact match first, then strip flags until a match is found.
///
/// .sss selectors match compound states: CheckBox:checked:hover { ... }
/// requires both flags to be present.
public enum ControlState
{
	Normal        = 0,
	Hover         = 1,
	Pressed       = 2,
	Focused       = 4,
	Disabled      = 8,
	Checked       = 16,
	Indeterminate = 32,
}
