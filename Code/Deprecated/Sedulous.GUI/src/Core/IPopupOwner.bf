namespace Sedulous.GUI;

/// Interface for controls that own popups and need to be notified when popups close.
public interface IPopupOwner
{
	/// Called when a popup owned by this element is closed.
	/// This is called for all close reasons: click-outside, programmatic close, etc.
	void OnPopupClosed(UIElement popup);
}
