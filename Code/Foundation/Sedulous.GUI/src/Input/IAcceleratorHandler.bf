namespace Sedulous.GUI;

/// Implement on a View to receive Alt+key accelerator events.
/// Accelerators are searched top-down through the tree, bypassing
/// normal focus-based key routing.
public interface IAcceleratorHandler
{
	/// Return true if this handler consumed the accelerator.
	bool HandleAccelerator(KeyCode key, KeyModifiers modifiers);
}
