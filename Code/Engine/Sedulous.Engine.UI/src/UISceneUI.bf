using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI;

/// One scene's UI tier: its own root, and the shared billboard layer under its canvases.
class UISceneUI
{
	/// BORROWED: the scene outlives this entry, which is removed when it dies.
	public Scene Scene = null;
	public RootView Root = null;
	/// BELOW the scene's canvases, and one batch for all of them.
	public ViewGroup BillboardLayer = null;
}
