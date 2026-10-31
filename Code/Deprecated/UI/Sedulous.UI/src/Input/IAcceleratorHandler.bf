namespace Sedulous.UI;

/// Implemented by a view that wants Alt plus key accelerators.
///
/// Accelerators are searched top down through the tree, BYPASSING the usual focus based key
/// routing: a menu mnemonic has to work whether or not the menu has focus.
interface IAcceleratorHandler
{
	/// True when this handler consumed the accelerator.
	bool HandleAccelerator(KeyCode key, KeyModifiers modifiers);
}
