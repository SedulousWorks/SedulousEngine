namespace Sedulous.GUI;

/// Entry tracking a single popup in the PopupLayer.
public class PopupEntry
{
	/// The popup view.
	public View Popup;

	/// Notified when this popup is closed.
	public IPopupOwner Owner;

	/// Whether clicking outside this popup dismisses it.
	public bool CloseOnClickOutside;

	/// Whether this popup is modal (blocks input to underlying content).
	public bool IsModal;

	/// Whether PopupLayer owns the view (true = delete on close; false = detach only).
	public bool OwnsView;

	/// Position in PopupLayer coordinates.
	public float X, Y;
}
