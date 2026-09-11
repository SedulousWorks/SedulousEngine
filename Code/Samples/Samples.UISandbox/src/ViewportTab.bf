using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;

namespace Samples.UISandbox;

/// A 3D viewport hosted in a DOCKABLE panel.
///
/// The panel is the point: drag its tab out and the viewport floats into its own OS window, and
/// the cube keeps rendering and keeps its input gating there. That is the whole stack at once,
/// the renderer, the docking host and the input router agreeing about which window a view is in.
static class ViewportTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let body = SandboxViews.VFlex(6.0f);
		body.Padding = .(8, 8);

		let help = new Label();
		help.SetText("""
			A 3D spinning cube in a dockable UI panel. Hover and hold the right button to look, WASD and QE to move, wheel to zoom; the input is GATED to the viewport, so moving off stops the camera while the cube keeps spinning.
			Drag the Viewport panel's tab out to float it into its own OS window: the cube keeps rendering there, re-bound to that window's renderer.
			""");
		body.AddView(help, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap()));

		// Its OWN dock manager, sharing the application's window host with the docking tab, so
		// floating one does not disturb the other.
		let manager = new DockManager();
		manager.DockableWindowHost = app.DockHost;
		body.AddView(manager, SandboxViews.Grow(1.0f));

		let viewport = new ViewportView();
		// Letterboxed, so the cube keeps its aspect and the bars show where the fit region is.
		viewport.FitMode = .Letterbox;
		app.SetViewport(viewport);

		let viewportPanel = manager.AddPanel("Viewport", viewport);

		let inspector = new Label();
		inspector.SetText("Drag the Viewport tab out to float it into an OS window.");
		let inspectorPanel = manager.AddPanel("Inspector", inspector);

		manager.DockPanel(viewportPanel, .Center);
		manager.DockPanel(inspectorPanel, .Right);

		// Opened on, so the 3D content and its gating are the first thing seen.
		let index = tabView.AddTab("Viewport (3D)", body);
		tabView.SetSelectedIndex(index);
	}
}
