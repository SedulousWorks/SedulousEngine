using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Run;

namespace Sedulous.Engine.GUI;

/// A screen tier: a root outside any scene holding a screen stack (the shared tier the overlay
/// layer above it too), and the game's screen it lays out for. With run screens on, each run (an
/// editor Game tab's game) has one of its own.
class GuiScreenTier
{
	/// The run it belongs to, by id; nought for the shared tier.
	public RunId Run = 0;
	/// A HELD reference each; the stack is the root's child (its id "screens", what a script
	/// finds). Released in reverse, the stack before the root.
	public SceneRoot Root = null ~ _?.ReleaseRef();
	public ScreenStack Screens = null ~ _?.ReleaseRef();
	/// Its input, into the root's dispatcher (MakeBridge). OWNED; declared after the root, so it goes
	/// first.
	public GuiInputBridge Bridge = null ~ delete _;
	/// The game's render resolution (nought: none) and how it fits its target.
	public Float2 Resolution = .Zero;
	public FitMode Fit = .Letterbox;
	public ScreenOrientation Orientation = .Any;
	/// The target it last drew into, and the turn it took there: what the pointer maps against.
	public Float2 TargetSize = .Zero;
	public ContentRotation Turn = .None;
	/// The part of the target it was fitted into (empty: all of it).
	public Rectangle Area = .();

	public bool HasResolution => (Resolution.X > 0.0f) && (Resolution.Y > 0.0f);
}
