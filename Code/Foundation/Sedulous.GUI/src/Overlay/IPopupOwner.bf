namespace Sedulous.GUI;

/// Implement to receive notification when a popup you opened is closed.
public interface IPopupOwner
{
	void OnPopupClosed(View popup);
}
