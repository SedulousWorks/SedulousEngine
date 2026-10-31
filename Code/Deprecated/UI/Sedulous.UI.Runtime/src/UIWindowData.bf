using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.UI.Runtime;

/// One window's UI payload, carried on the render window itself.
///
/// The graphics host reserves a slot on each render window for exactly this, so the UI's
/// per-window state travels with the window rather than being tracked in a parallel map that
/// could fall out of step with it.
///
/// It OWNS the window's vector context, renderer, input surface and quality targets, and SHARES
/// its root view with the UI context.
class UIWindowData : IRenderWindowData
{
	public RootView Root = null ~ _?.ReleaseRef();
	public VGContext VG = new .() ~ delete _;
	public VGRenderer Renderer = new .() ~ delete _;
	public InputSurface Surface = null ~ delete _;

	/// The quality targets: a multisampled colour target resolved into the backbuffer, and a
	/// stencil attachment for the fill pipelines (stencil-then-cover is what makes holes,
	/// self-intersection and even-odd fills come out right). Off means the plain single sampled
	/// pass.
	public VGPassTargets Targets = new .() ~ delete _;

	/// Encoded: this window's UI blends encoded values, drawing through the backbuffer's UNORM
	/// view in DrawFormat (its twin); otherwise linear light in the backbuffer's own format.
	public bool Encoded = false;
	public TextureFormat DrawFormat = .Undefined;
}
