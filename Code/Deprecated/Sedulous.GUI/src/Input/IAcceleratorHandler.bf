namespace Sedulous.GUI;

/// Interface for UI elements that can handle global accelerator key events.
/// Elements implementing this interface will receive Alt and Alt+letter key events
/// regardless of focus state, enabling menu bar accelerators and global shortcuts.
public interface IAcceleratorHandler
{
	/// Called when an accelerator-related key event occurs (Alt, Alt+letter).
	/// Returns true if the event was handled.
	bool HandleAccelerator(KeyCode key, KeyModifiers modifiers);
}
