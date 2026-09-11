using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// Five panels in the layout an editor actually uses, over the runtime docking host.
///
/// Splitting and tabbing happen inside the tab, but dragging a panel OUT floats it into a real
/// OS window, which is the part no headless test reaches: the panel keeps its content, its
/// input and its theme in a window the docking system did not draw.
static class DockingTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(8, 8);
		tabView.AddTab("Docking", demo);

		let manager = new DockManager();
		manager.DockableWindowHost = app.DockHost;
		demo.AddView(manager, SandboxViews.Grow(1.0f));

		let scene = manager.AddPanel("Scene", MakeLabel("Scene viewport"));
		let inspector = manager.AddPanel("Inspector", MakeLabel("Inspector properties"));
		let hierarchy = manager.AddPanel("Hierarchy", MakeLabel("Scene hierarchy"));
		let console = manager.AddPanel("Console", MakeLabel("Console output"));
		let assets = manager.AddPanel("Assets", MakeLabel("Asset browser"));

		manager.DockPanel(scene, .Center);
		manager.DockPanel(hierarchy, .Left);
		manager.DockPanel(inspector, .Right);
		manager.DockPanel(console, .Bottom);
		// Into the console's own group rather than the root, which is what makes them TABS
		// beside each other instead of a second split.
		manager.DockPanelRelativeTo(assets, .Center, console.Parent);
	}

	private static Label MakeLabel(System.StringView text)
	{
		let label = new Label();
		label.SetText(text);
		return label;
	}
}
