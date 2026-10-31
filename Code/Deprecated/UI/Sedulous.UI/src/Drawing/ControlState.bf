namespace Sedulous.UI;

/// A control's visual state, as combinable flags: Checked and Hover at once, say.
///
/// StateListDrawable looks drawables up by these with a fallback, and style sheet selectors
/// match compound states.
enum ControlState : uint32
{
	Normal = 0,
	Hover = 1,
	Pressed = 2,
	Focused = 4,
	Disabled = 8,
	Checked = 16,
	Indeterminate = 32
}
