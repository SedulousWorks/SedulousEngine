namespace Sedulous.UI;

/// How the current focus was acquired.
///
/// Focus is RETAINED whatever the source: typing, list arrow navigation and tab continuity
/// all key off the focused view. But a control draws its focus ring only for KEYBOARD
/// acquired focus, so a button clicked with the pointer holds focus without lighting up.
/// That is the `:focus-visible` split.
enum FocusSource : uint8
{
	Programmatic,
	Pointer,
	Keyboard
}
