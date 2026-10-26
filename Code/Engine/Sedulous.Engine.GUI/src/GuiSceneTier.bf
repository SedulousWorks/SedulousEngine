using System;
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
	// E3: its canvases' hosts, in the root, go here.
	// E4: its GuiInputBridge goes here (MakeBridge), owned.
}
