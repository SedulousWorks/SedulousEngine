namespace Sedulous.UI;

/// What a focus taking popup remembers so it can give focus back when it closes.
///
/// The POPUP stores this rather than a manager holding a stack, so each popup restores only
/// what IT saved: closing popups out of order can then never cross restore another's focus.
struct SavedFocus
{
	public ViewId Id = .();
	public FocusSource Source = .Programmatic;

	public this() {}
}
