using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// One scene's GUI: a root of its own, drawn wherever the scene renders, with the layer its
/// billboards are in under its canvases.
class GuiSceneTier
{
	/// BORROWED: the scene outlives its tier, which goes as it is destroyed.
	public Scene Scene = null;
	/// A HELD reference each, released in reverse: the billboards' layer, then the root.
	public SceneRoot Root = null ~ _?.ReleaseRef();
	/// Under every canvas; it paints nothing, so it takes no pointer.
	public UIWidget Billboards = null ~ _?.ReleaseRef();
	/// Its canvases' hosts, in the root, in no order: a HELD reference each, beside the root's
	/// and the component's own.
	public List<GuiCanvasHost> Canvases = new .() ~ { for (let host in _) host.ReleaseRef(); delete _; };
	/// Its input, into the root's dispatcher (MakeBridge). OWNED; declared last, so it goes first.
	public GuiInputBridge Bridge = null ~ delete _;
}
