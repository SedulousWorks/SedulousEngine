using System;
using Sedulous.GUI;
using Sedulous.Render;
using Sedulous.RHI;

namespace Sedulous.Engine.GUI;

/// The GUI's GPU side: the VG shaders from the data mount, the pass renderer that draws both
/// tiers, and what PrepareOverlay recorded for the screen tier and for which view.
class GuiRenderState
{
	/// BORROWED: whoever owns graphics outlives the subsystem's render state.
	public IDevice Device = null;
	/// Owns the shader modules the renderer draws with: it goes after the renderer.
	public VgShaderLibrary Shaders = new .();
	/// Null when the shaders did not resolve.
	public GuiPassRenderer Renderer = null;
	/// What PrepareOverlay recorded: the shared tier, and the drawn run's under it.
	public GuiPassRenderer.Prepared Screen = .();
	public GuiPassRenderer.Prepared RunScreen = .();
	public bool HasRunScreen = false;
	public ScreenOverlayView ScreenView = .();
	public bool ScreenPrepared = false;
	// E3: the textures canvases and world panels draw into go here.

	public ~this()
	{
		// The renderer first (it waits for the GPU and lets its renderers go), then the modules
		// it drew with. No early return: the fields' own cleanups would be skipped.
		delete Renderer;
		delete Shaders;
	}
}
