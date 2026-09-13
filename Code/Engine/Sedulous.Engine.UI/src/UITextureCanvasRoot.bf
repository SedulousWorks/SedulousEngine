using Sedulous.UI;

namespace Sedulous.Engine.UI;

/// A render texture canvas's standalone root, held here so it can be UNREGISTERED from the
/// context when its component vanishes.
///
/// The context stores roots WITHOUT owning them, and a component manager has no destroy hook,
/// so this registry is what notices a root has been orphaned. Holding the reference also
/// keeps a just orphaned root alive until the sweep gets to it.
class UITextureCanvasRoot
{
	public RootView Root = null;
	public bool Seen = false;
}
