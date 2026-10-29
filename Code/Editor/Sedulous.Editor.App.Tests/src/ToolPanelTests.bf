using System;
using Sedulous.GUI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App.Tests;

/// The registry (keyed by tool id, idempotent, first wins) and ViewportToolPanelHost are pure
/// logic, so they exercise headlessly: fake tools drive a ViewportToolManager, fake providers
/// build throwaway panels, and mount and clear callbacks record what the host asked the page
/// to show. The panel appears and disappears with the tool (mount told the tool it is for), an
/// unknown or panel-less tool shows nothing, and switching between two panelled tools clears
/// before mounting.
static class ToolPanelTests
{
	private static void AddTool(ViewportToolManager tools, StringView id) => tools.Add(new FakeTool(id));

	[Test]
	public static void RegistryIsIdempotentAndFirstWinsPerToolId()
	{
		let registry = scope ViewportToolPanelRegistry();
		let anim = scope FakeProvider("anim");
		let animAgain = scope FakeProvider("anim");
		let terrain = scope FakeProvider("terrain");

		registry.Register(anim);
		registry.Register(anim); // same provider: ignored
		Test.Assert(registry.Count == 1);

		registry.Register(animAgain); // a second provider for "anim": ignored, first wins
		Test.Assert(registry.Count == 1);
		Test.Assert(registry.FindByToolId("anim") === anim);

		registry.Register(terrain);
		Test.Assert(registry.Count == 2);
		Test.Assert(registry.FindByToolId("terrain") === terrain);
		Test.Assert(registry.FindByToolId("nope") == null);
		registry.Register(null); // tolerated
		Test.Assert(registry.Count == 2);
	}

	[Test]
	public static void PanelAppearsAndDisappearsWithItsTool()
	{
		let tools = scope ViewportToolManager();
		AddTool(tools, "select"); // first added is the default, no panel
		AddTool(tools, "anim");

		let registry = scope ViewportToolPanelRegistry();
		let animPanel = scope FakeProvider("anim");
		registry.Register(animPanel);

		int mounts = 0;
		int clears = 0;
		Node lastMounted = null;
		let mountedFor = scope String();
		let host = scope ViewportToolPanelHost(tools, registry, .(),
			new [&](v, tool) => { mounts++; lastMounted = v; mountedFor.Set(tool.Id); },
			new [&]() => { clears++; lastMounted = null; });

		// The default tool is active and has no panel, so the first Sync docks nothing.
		host.Sync();
		Test.Assert(host.CurrentToolId == "select");
		Test.Assert(host.CurrentPanel == null);
		Test.Assert(mounts == 0);

		// Switching to the panelled tool mounts the panel.
		Test.Assert(tools.ActivateById("anim"));
		host.Sync();
		Test.Assert(mounts == 1);
		Test.Assert(clears == 0, "nothing to clear: the tool left had no panel");
		Test.Assert(host.CurrentPanel != null);
		Test.Assert(lastMounted === host.CurrentPanel);
		Test.Assert(mountedFor == "anim", "the tool it is for, for its chrome");
		Test.Assert(animPanel.CreateCount == 1);

		// A Sync with no active-tool change is a no-op; the view is not rebuilt every frame.
		host.Sync();
		Test.Assert(mounts == 1);
		Test.Assert(animPanel.CreateCount == 1);

		// Back to the panel-less default: the panel is torn down.
		tools.ActivateDefault();
		host.Sync();
		Test.Assert(clears == 1);
		Test.Assert(host.CurrentPanel == null);
		Test.Assert(mounts == 1);
	}

	[Test]
	public static void UnknownOrPanelLessToolShowsNothing()
	{
		let tools = scope ViewportToolManager();
		AddTool(tools, "select");
		AddTool(tools, "anim");

		let registry = scope ViewportToolPanelRegistry(); // no providers at all

		int mounts = 0;
		int clears = 0;
		let host = scope ViewportToolPanelHost(tools, registry, .(),
			new [&](v, tool) => { mounts++; }, new [&]() => { clears++; });

		Test.Assert(tools.ActivateById("anim"));
		host.Sync(); // no provider for "anim": no panel, no crash
		Test.Assert(mounts == 0);
		Test.Assert(clears == 0);
		Test.Assert(host.CurrentPanel == null);
		Test.Assert(host.CurrentToolId == "anim");
	}

	[Test]
	public static void ProviderYieldingNoPanelMountsNothing()
	{
		let tools = scope ViewportToolManager();
		AddTool(tools, "select");
		AddTool(tools, "anim");

		let registry = scope ViewportToolPanelRegistry();
		let emptyPanel = scope FakeProvider("anim", true);
		registry.Register(emptyPanel);

		int mounts = 0;
		int clears = 0;
		let host = scope ViewportToolPanelHost(tools, registry, .(),
			new [&](v, tool) => { mounts++; }, new [&]() => { clears++; });

		Test.Assert(tools.ActivateById("anim"));
		host.Sync();
		Test.Assert(emptyPanel.CreateCount == 1, "asked");
		Test.Assert(mounts == 0, "but nothing to mount");
		Test.Assert(host.CurrentPanel == null);

		tools.ActivateDefault();
		host.Sync();
		Test.Assert(clears == 0, "nothing was mounted, so nothing to clear");
	}

	[Test]
	public static void SwitchingBetweenTwoPanelledToolsClearsThenMounts()
	{
		let tools = scope ViewportToolManager();
		AddTool(tools, "select");
		AddTool(tools, "a");
		AddTool(tools, "b");

		let registry = scope ViewportToolPanelRegistry();
		let panelA = scope FakeProvider("a");
		let panelB = scope FakeProvider("b");
		registry.Register(panelA);
		registry.Register(panelB);

		int mounts = 0;
		int clears = 0;
		let host = scope ViewportToolPanelHost(tools, registry, .(),
			new [&](v, tool) => { mounts++; }, new [&]() => { clears++; });

		Test.Assert(tools.ActivateById("a"));
		host.Sync();
		Test.Assert(mounts == 1);
		Test.Assert(clears == 0);

		Test.Assert(tools.ActivateById("b"));
		host.Sync();
		Test.Assert(clears == 1, "a's panel torn down first");
		Test.Assert(mounts == 2, "then b's mounted");
		Test.Assert(host.CurrentToolId == "b");
		Test.Assert(panelA.CreateCount == 1);
		Test.Assert(panelB.CreateCount == 1);
	}
}
