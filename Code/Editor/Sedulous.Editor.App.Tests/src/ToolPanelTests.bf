using System;
using Sedulous.GUI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App.Tests;

/// The registry (keyed by tool id, idempotent, first wins) and ViewportToolPanelHost are pure
/// logic, so they exercise headlessly: fake tools drive a ViewportToolManager, fake providers
/// build throwaway panels, and mount and clear callbacks record what the host asked the page
/// to show. The panel appears and disappears with the tool (mount told the tool it is for), an
/// unknown or panel-less tool shows nothing, and switching between two panelled tools clears
/// before mounting. Under the editor's sheet, a row of pictures (a terrain's layers) holds its
/// pictures.
static class ToolPanelTests
{
	private static void AddTool(ViewportToolManager tools, StringView id) => tools.Add(new FakeTool(id));

	/// Under the editor's sheet a row of pictures is as tall as they are, and many wrap: eight
	/// 40-pixel layers do not fit one line of a 240-wide panel.
	[Test]
	public static void UnderTheEditorsSheetARowOfPicturesIsAsTallAsTheyAreAndManyWrap()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(800.0f, 600.0f);
		let body = new ToolPanelBody();
		body.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(240.0f); });
		let baseChoice = scope ToolPanelChoice();
		baseChoice.Icon.Set("Editor/Icons/texture.svg");
		baseChoice.Picture = new () => null; // no picture yet: its icon stands in
		body.AddPicture("Base", baseChoice);
		let layers = scope ToolPanelChoice[8];
		for (int i < layers.Count)
		{
			layers[i] = scope:: ToolPanelChoice();
			layers[i].Icon.Set("Editor/Icons/texture.svg");
			layers[i].Picture = new () => null;
		}
		body.AddChoices("Layer", layers, new () => 0, new (index) => { });
		root.AddChild(body);
		body.ReleaseRef(); // the root's keeps it
		let sheet = scope EditorSheet();
		sheet.Apply(root);

		// The rows in order: Base's heading and picture, then Layer's heading and pictures.
		Test.Assert(body.ChildCount == 4);
		let row = body.GetChildAt(3);
		let layerRow = row.ScreenBounds;
		Test.Assert(row.ChildCount == 8);
		float firstTop = 0.0f;
		bool wrapped = false;
		for (int i < row.ChildCount)
		{
			let slot = row.GetChildAt(i).ScreenBounds;
			Test.Assert(slot.Y >= layerRow.Y - 0.5f, "within its row, not over its edges");
			Test.Assert(slot.Y + slot.Height <= layerRow.Y + layerRow.Height + 0.5f);
			Test.Assert(slot.X + slot.Width <= layerRow.X + layerRow.Width + 0.5f, "and within the panel's width");
			Test.Assert(slot.Height >= 40.0f, scope $"a picture big enough to tell apart ({slot.Height})");
			if (i == 0)
				firstTop = slot.Y;
			else if (slot.Y > firstTop + 1.0f)
				wrapped = true;
		}
		Test.Assert(wrapped, "eight do not fit on one line of a 240 wide panel");
		let baseSlot = body.GetChildAt(1).GetChildAt(0).ScreenBounds;
		Test.Assert(Math.Abs(baseSlot.Height - row.GetChildAt(0).ScreenBounds.Height) < 0.5f, "the base as big as a layer");
	}

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
