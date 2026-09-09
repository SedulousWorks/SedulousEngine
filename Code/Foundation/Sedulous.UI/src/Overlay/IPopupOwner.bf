namespace Sedulous.UI;

/// Implemented by whatever opened a popup, to hear when it closes.
///
/// In practice every owner is also a view, and OwnerView exposes that so the popup layer can
/// walk parent chains and cascade closed popups when an owner's subtree is torn down.
interface IPopupOwner
{
	void OnPopupClosed(View popup);

	/// The owning view, or null.
	View OwnerView { get; }
}
