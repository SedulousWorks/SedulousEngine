namespace Sedulous.UI;

/// Implement on a View to receive Alt+key accelerator events searched
/// top-down through the tree (bypasses focus routing).
public interface IAcceleratorHandler
{
	/// Return true if this handler consumed the accelerator.
	bool HandleAccelerator(KeyCode key, KeyModifiers modifiers);
}
