namespace Sedulous.GUI;

/// Bit flags representing the interactive state of a view.
/// Multiple flags can be combined (e.g. .Checked | .Hover).
/// Used by StateListDrawable for visual state lookup and by
/// .sss selectors for state matching (e.g. CheckBox:checked:hover).
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
