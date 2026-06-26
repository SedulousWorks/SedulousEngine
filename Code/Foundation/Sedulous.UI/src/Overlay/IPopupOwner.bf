namespace Sedulous.UI;

/// Implement to receive notification when a popup you opened is closed.
/// In practice every owner is also a View; OwnerView exposes that so
/// PopupLayer can walk parent chains (used to cascade-close popups when
/// an owner's subtree is being torn down).
public interface IPopupOwner
{
	void OnPopupClosed(View popup);
	View OwnerView { get; }
}
