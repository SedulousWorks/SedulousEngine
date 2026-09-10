namespace Sedulous.UI;

/// One popup the layer is showing, and everything it needs to close correctly.
struct PopupEntry
{
	/// OWNED: the layer holds the popup's reference while it is open.
	public View Popup = null;
	/// BORROWED: told when this popup closes.
	public IPopupOwner Owner = null;
	/// Clicking outside dismisses it.
	public bool CloseOnClickOutside = false;
	/// Blocks input to everything underneath.
	public bool IsModal = false;
	/// Whether the layer is the popup's PRIMARY owner, so closing destroys it.
	///
	/// RECORDED ONLY: ShowPopup always consumes the caller's reference and ClosePopup always
	/// releases it, whatever this says. A caller that keeps its own reference AddRefs before
	/// showing, which is what TooltipManager and the modal backdrop do. Raptor drives the
	/// lifetime from this flag instead; here it survives as description, not mechanism.
	public bool OwnsView = true;
	/// Whether this popup took focus when it opened, and so restores on close.
	public bool PushedFocus = false;
	/// The focus this popup displaced. Held HERE rather than in a manager wide stack, so each
	/// popup restores only what IT saved: closing out of order can never cross restore.
	public SavedFocus SavedFocusEntry = .();
	/// In the layer's own coordinates.
	public float X = 0.0f;
	public float Y = 0.0f;

	public this() {}
}
