namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

class DockingTests
{
	// DockManager tree operations need interactive debugging.
	// The ReplaceNode / Center docking has context attachment issues
	// that crash in the headless test runner.
	// TODO: Fix and re-enable DockManager unit tests.

	[Test]
	public static void DockablePanel_Title()
	{
		let panel = scope DockablePanel("My Panel");
		Test.Assert(panel.Title == "My Panel");

		panel.SetTitle("Renamed");
		Test.Assert(panel.Title == "Renamed");
	}

	[Test]
	public static void DockablePanel_SetContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let panel = new DockablePanel("Test");
		root.AddView(panel);

		let content = new Label();
		panel.SetContent(content);
		Test.Assert(panel.ContentView === content);
	}
}
