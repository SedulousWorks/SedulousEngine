namespace UISandbox;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

/// Demo page: Docking system with multiple panels.
/// This page IS the dock manager — it fills the entire tab content.
class DockingPage : DemoPage
{
	private DockManager mDockManager;

	public this(DemoContext demo) : base(demo)
	{
		// Instead of using the default scrollable layout, replace with a DockManager
		// that fills the page. Remove the default mLayout from the ScrollView.
		RemoveView(mLayout, true);
		mLayout = null;

		// Disable scrolling — the dock manager fills the page.
		VScrollPolicy = .Never;
		HScrollPolicy = .Never;

		mDockManager = new DockManager();
		mDockManager.FloatingWindowHost = demo.FloatingWindowHost;
		AddView(mDockManager, new Sedulous.UI.LayoutParams() {
			Width = Sedulous.UI.LayoutParams.MatchParent,
			Height = Sedulous.UI.LayoutParams.MatchParent
		});

		// Add initial panels.
		let panel1 = mDockManager.AddPanel("Scene", CreateContent("Scene View\n\nThis is the main viewport."));
		mDockManager.DockPanel(panel1, .Center);

		let panel2 = mDockManager.AddPanel("Inspector", CreateContent("Inspector\n\nProperties panel."));
		mDockManager.DockPanelRelativeTo(panel2, .Right, panel1);

		let panel3 = mDockManager.AddPanel("Hierarchy", CreateContent("Hierarchy\n\nScene tree."));
		mDockManager.DockPanelRelativeTo(panel3, .Left, panel1);

		let panel4 = mDockManager.AddPanel("Console", CreateContent("Console\n\nLog output."));
		mDockManager.DockPanelRelativeTo(panel4, .Bottom, panel1);

		let panel5 = mDockManager.AddPanel("Assets", CreateContent("Assets\n\nAsset browser."));
		mDockManager.DockPanelRelativeTo(panel5, .Center, panel4);
	}

	private View CreateContent(StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.FontSize = 12;
		label.VAlign = .Top;
		label.HAlign = .Left;
		return label;
	}
}
