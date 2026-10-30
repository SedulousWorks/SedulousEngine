using System;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.GUI; // GUI.Docking's controller and layout
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The layout tools over the editor's dock: layout_get's tree of splits (any number of children,
/// with their weights) and stacks, panel_dock putting one Game tab beside another (the networked
/// playtest's layout), a side's share, a tab back into a stack, a panel along the window's edge or
/// floating, a hidden panel docked again, and the refusals.
class EditorLayoutToolsTests
{
	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static Answer Call(McpServer server, StringView tool, StringView argumentsJson)
	{
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		Test.Assert(server.HandleLine(line, reply) == .Answered);
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		let answer = new Answer();
		if (result == null)
		{
			// Refused before the tool ran: the server checks the arguments against the schema.
			answer.Ok = false;
			answer.Error.Set(response.Get("error").Get("message").AsString());
			return answer;
		}
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	private static bool HoldsTab(JsonValue stack, StringView panel)
	{
		let tabs = stack.Get("tabs");
		for (int i < tabs.Count)
		{
			if (tabs.At(i).Get("panel").AsString() == panel)
				return true;
		}
		return false;
	}

	/// The stack of a layout_get tree that holds `panel`, named by its tabs' ids ("a,b"); empty
	/// when no stack holds it. Two panels share a stack when their names match.
	private static void GroupOf(JsonValue node, StringView panel, String outName)
	{
		if (node.Has("tabs"))
		{
			if (!HoldsTab(node, panel))
				return;
			let tabs = node.Get("tabs");
			for (int i < tabs.Count)
				outName.AppendF("{}{}", (i == 0) ? "" : ",", tabs.At(i).Get("panel").AsString());
			return;
		}
		if (node.Has("split"))
		{
			let children = node.Get("children");
			for (int i < children.Count)
			{
				GroupOf(children.At(i), panel, outName);
				if (!outName.IsEmpty)
					return;
			}
		}
	}

	private static bool SameGroup(JsonValue root, StringView a, StringView b)
	{
		let first = GroupOf(root, a, .. scope .());
		let second = GroupOf(root, b, .. scope .());
		return !first.IsEmpty && (first == second);
	}

	/// Two neighbours in a split: the stack holding `first` right before the stack holding
	/// `second`; their split's axis and `second`'s share of the two. False when there are none.
	private static bool PairOf(JsonValue node, StringView first, StringView second, String outAxis, out double outSecondShare)
	{
		outSecondShare = 0.0;
		if (!node.Has("split"))
			return false;
		let children = node.Get("children");
		let weights = node.Get("weights");
		for (int i = 0; i + 1 < children.Count; ++i)
		{
			let a = children.At(i);
			let b = children.At(i + 1);
			if (a.Has("tabs") && b.Has("tabs") && HoldsTab(a, first) && HoldsTab(b, second))
			{
				let wa = weights.At(i).AsNumber();
				let wb = weights.At(i + 1).AsNumber();
				outAxis.Set(node.Get("split").AsString());
				outSecondShare = wb / (wa + wb);
				return true;
			}
		}
		for (int i < children.Count)
		{
			if (PairOf(children.At(i), first, second, outAxis, out outSecondShare))
				return true;
		}
		return false;
	}

	private static bool Lists(JsonValue panels, StringView id)
	{
		for (int i < panels.Count)
		{
			if (panels.At(i).Get("panel").AsString() == id)
				return true;
		}
		return false;
	}

	private static bool Near(double value, double expected) => Math.Abs(value - expected) < 1e-4;

	/// The editor's dock (the bed's: Project in the documents' stack, Assets and Console under it)
	/// with two Game tabs among the documents, as Play and Play New Instance leave them, and the
	/// tools over its controller.
	private static void Rig(DockBed bed, McpServer server)
	{
		for (let id in StringView[?]("game-page", "game-page-1"))
		{
			let description = new DockPanelDescription();
			description.Id.Set(id);
			description.Title.Set("Game");
			description.Default.Central = true;
			description.Factory = new () => new Sedulous.GUI.Panel();
			Test.Assert(bed.Dock.Controller.Register(description));
			Test.Assert(bed.Dock.Controller.Show(id).Ok);
		}
		EditorLayoutTools.Register(server, bed.Dock.Controller);
	}

	[Test]
	public static void TwoGameTabsGoSideBySideThenBackIntoOneStack()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);
		Test.Assert(server.ToolCount == EditorLayoutTools.cLayoutToolCount);

		// Both tabs in the documents' stack, with the Project panel, under its registered title.
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let root = got.Payload.Get("root");
			Test.Assert(SameGroup(root, "game-page", "game-page-1"));
			Test.Assert(SameGroup(root, "welcome", "game-page"));
			Test.Assert(!GroupOf(root, "console", .. scope .()).IsEmpty);
			let documents = root.Get("children").At(0);
			Test.Assert(documents.Get("tabs").At(0).Get("panel").AsString() == EditorDock.cPanelProject);
			Test.Assert(documents.Get("tabs").At(0).Get("title").AsString() == "Project");
		}

		// The client to the right of the host: across, the host's stack then the client alone,
		// half each.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"game-page\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let tree = got.Payload.Get("root");
			Test.Assert(GroupOf(tree, "game-page-1", .. scope .()) == "game-page-1", "alone in its stack");
			Test.Assert(SameGroup(tree, "welcome", "game-page"), "the rest stay with the host");
			let axis = scope String();
			double share;
			Test.Assert(PairOf(tree, "game-page", "game-page-1", axis, out share));
			Test.Assert(axis == "horizontal");
			Test.Assert(Near(share, 0.5));
		}
		// The dock agrees: both are their stacks' active tabs, so both show.
		let layout = bed.Layout;
		let host = layout.StackOf("game-page");
		let client = layout.StackOf("game-page-1");
		Test.Assert(host != client);
		let clientStack = layout.FindNode(client);
		Test.Assert(clientStack.Panels[(int)clientStack.Active] == "game-page-1");

		// Back into the host's stack as a tab: the split goes.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"center\",\"relativeTo\":\"game-page\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(SameGroup(got.Payload.Get("root"), "game-page", "game-page-1"));
			Test.Assert(bed.Layout.StackOf("game-page") == bed.Layout.StackOf("game-page-1"));
		}
	}

	[Test]
	public static void ASidesShareIsTheMovedPanelsOnEitherSide()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);

		// Below the host, three tenths of the room it had.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"bottom\",\"relativeTo\":\"game-page\",\"share\":0.3}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let axis = scope String();
			double share;
			Test.Assert(PairOf(got.Payload.Get("root"), "game-page", "game-page-1", axis, out share));
			Test.Assert(axis == "vertical");
			Test.Assert(Near(share, 0.3));
		}
		// Left of the host, a quarter: now the moved panel is first.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"left\",\"relativeTo\":\"game-page\",\"share\":0.25}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let axis = scope String();
			double share;
			Test.Assert(PairOf(got.Payload.Get("root"), "game-page-1", "game-page", axis, out share));
			Test.Assert(axis == "horizontal");
			Test.Assert(Near(share, 0.75));
		}
	}

	[Test]
	public static void ASplitHoldsAnyNumberOfChildrenWithTheirWeights()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);

		// The default: the documents over the pane, 70 to 30, the pane Assets then Console.
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let root = got.Payload.Get("root");
			Test.Assert(root.Get("split").AsString() == "vertical");
			Test.Assert(root.Get("children").Count == 2);
			Test.Assert(Near(root.Get("weights").At(0).AsNumber(), 0.7));
			Test.Assert(Near(root.Get("weights").At(1).AsNumber(), 0.3));
			let pane = root.Get("children").At(1);
			Test.Assert(pane.Get("split").AsString() == "horizontal");
			Test.Assert(Near(pane.Get("weights").At(0).AsNumber(), 0.65));
		}
		// Along the window's bottom edge (no relativeTo), half by default: a third child of the
		// root's split, the others keeping their proportion.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"bottom\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let root = got.Payload.Get("root");
			Test.Assert(root.Get("split").AsString() == "vertical");
			let children = root.Get("children");
			let weights = root.Get("weights");
			Test.Assert(children.Count == 3);
			Test.Assert(weights.Count == 3);
			Test.Assert(GroupOf(children.At(2), "game-page-1", .. scope .()) == "game-page-1");
			Test.Assert(Near(weights.At(0).AsNumber(), 0.35));
			Test.Assert(Near(weights.At(1).AsNumber(), 0.15));
			Test.Assert(Near(weights.At(2).AsNumber(), 0.5));
		}
		// Along the left edge, a fifth: across the whole window, the old tree beside it.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page\",\"position\":\"left\",\"share\":0.2}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let root = got.Payload.Get("root");
			Test.Assert(root.Get("split").AsString() == "horizontal");
			Test.Assert(root.Get("children").Count == 2);
			Test.Assert(GroupOf(root.Get("children").At(0), "game-page", .. scope .()) == "game-page");
			Test.Assert(Near(root.Get("weights").At(0).AsNumber(), 0.2));
		}
	}

	[Test]
	public static void AStacksActiveIsItsChosenTab()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);
		// The middle of the documents' three tabs chosen: neither the first nor the last.
		Test.Assert(bed.Dock.Controller.Edit(scope (l) => l.Activate("game-page")).Ok);
		let got = Call(server, "layout_get", "{}");
		defer delete got;
		Test.Assert(got.Ok, got.Error);
		let documents = got.Payload.Get("root").Get("children").At(0);
		Test.Assert(GroupOf(documents, "game-page", .. scope .()) == "welcome,game-page,game-page-1");
		Test.Assert(documents.Get("active").AsString() == "game-page");
	}

	[Test]
	public static void AHiddenPanelIsListedAndDocksAgainOneFloats()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);
		Test.Assert(bed.Dock.Controller.Close(EditorDock.cPanelConsole).Ok); // a shared panel keeps its place, hidden
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Lists(got.Payload.Get("hidden"), "console"));
			Test.Assert(GroupOf(got.Payload.Get("root"), "console", .. scope .()).IsEmpty);
		}
		// Into Assets' stack as a tab.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"console\",\"position\":\"center\",\"relativeTo\":\"assets\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(!Lists(got.Payload.Get("hidden"), "console"));
			Test.Assert(SameGroup(got.Payload.Get("root"), "console", "assets"));
		}
		// Closed again, then along the window's top edge.
		Test.Assert(bed.Dock.Controller.Close(EditorDock.cPanelConsole).Ok);
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"console\",\"position\":\"top\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(!Lists(got.Payload.Get("hidden"), "console"));
			let root = got.Payload.Get("root");
			Test.Assert(root.Get("split").AsString() == "vertical");
			Test.Assert(GroupOf(root.Get("children").At(0), "console", .. scope .()) == "console");
		}
		// A Game tab into a window of its own: listed as floating, out of the main tree.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"float\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Lists(got.Payload.Get("floating"), "game-page-1"));
			Test.Assert(!Lists(got.Payload.Get("hidden"), "game-page-1"));
			Test.Assert(GroupOf(got.Payload.Get("root"), "game-page-1", .. scope .()).IsEmpty);
		}
		// Back as a tab with no relativeTo: the documents' stack.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"center\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("floating").Count == 0);
			Test.Assert(SameGroup(got.Payload.Get("root"), "game-page-1", "welcome"));
		}
	}

	[Test]
	public static void ARegisteredPanelNeverPlacedIsHiddenAndDocksBeside()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);
		// The dock's Profiler: registered, closed in the default layout until shown.
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let hidden = got.Payload.Get("hidden");
			Test.Assert(hidden.Count == 1);
			Test.Assert(hidden.At(0).Get("panel").AsString() == "profiler");
			Test.Assert(hidden.At(0).Get("title").AsString() == "Profiler");
		}
		// Beside the Console, a third of its room.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"profiler\",\"position\":\"right\",\"relativeTo\":\"console\",\"share\":0.3}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("hidden").Count == 0);
			let axis = scope String();
			double share;
			Test.Assert(PairOf(got.Payload.Get("root"), "console", "profiler", axis, out share));
			Test.Assert(axis == "horizontal");
			Test.Assert(Near(share, 0.3));
		}
	}

	[Test]
	public static void RefusalsNameWhatIsWrong()
	{
		let bed = scope DockBed();
		let server = scope McpServer();
		Rig(bed, server);
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-9\",\"position\":\"right\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("layout_get"), got.Error);
		}
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"middle\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			// The schema's list of positions refuses it before the tool sees it.
			Test.Assert(got.Error.Contains("'position' is not one of the allowed values"), got.Error);
		}
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"game-page-9\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("no panel 'game-page-9'"), got.Error);
		}
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page\",\"position\":\"right\",\"relativeTo\":\"game-page\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("itself"), got.Error);
		}
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"center\",\"relativeTo\":\"game-page\",\"share\":0.3}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("share"), got.Error);
		}
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"game-page\",\"share\":0.99}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("share"), got.Error);
		}
		Test.Assert(bed.Dock.Controller.Close(EditorDock.cPanelConsole).Ok);
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"console\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("not docked"), got.Error);
		}
		// What the layout refuses comes back with its reason: the documents' stack locked.
		let documents = bed.Layout.FindNode(bed.Layout.StackOf("game-page"));
		documents.Flags |= DockStackLocked;
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"game-page\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("'game-page-1' cannot go there: its stack is locked"), got.Error);
		}
		documents.Flags &= ~DockStackLocked;
		// Nothing moved.
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(SameGroup(got.Payload.Get("root"), "game-page", "game-page-1"));
		}
	}
}
