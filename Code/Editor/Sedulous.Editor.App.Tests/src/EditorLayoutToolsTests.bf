using System;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The layout tools over a headless editor shell's dock: layout_get's tree of splits and tab
/// groups, panel_dock putting one Game tab beside another (the networked playtest's layout), a
/// side's share, a tab back into a group, a hidden tool panel docked again, and the refusals.
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
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	private static bool HoldsTab(JsonValue group, StringView panel)
	{
		let tabs = group.Get("tabs");
		for (int i < tabs.Count)
		{
			if (tabs.At(i).Get("panel").AsString() == panel)
				return true;
		}
		return false;
	}

	/// The tab group of a layout_get tree that holds `panel`, named by its tabs' ids ("a,b");
	/// empty when no group holds it. Two panels share a group when their names match.
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
			GroupOf(node.Get("first"), panel, outName);
			if (outName.IsEmpty)
				GroupOf(node.Get("second"), panel, outName);
		}
	}

	private static bool SameGroup(JsonValue root, StringView a, StringView b)
	{
		let first = GroupOf(root, a, .. scope .());
		let second = GroupOf(root, b, .. scope .());
		return !first.IsEmpty && (first == second);
	}

	/// The split whose first side is the group holding `first` and whose second is the group
	/// holding `second`; null when there is none. BORROWED from the tree.
	private static JsonValue SplitOver(JsonValue node, StringView first, StringView second)
	{
		if (!node.Has("split"))
			return null;
		let a = node.Get("first");
		let b = node.Get("second");
		if (a.Has("tabs") && b.Has("tabs") && HoldsTab(a, first) && HoldsTab(b, second))
			return node;
		return SplitOver(a, first, second) ?? SplitOver(b, first, second);
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

	/// A headless shell with two Game tabs among the documents, as Play and Play New Instance
	/// leave them.
	private static void Rig(EditorShell shell, EditorContext context, McpServer server)
	{
		shell.Build(context, null, 1280, 720);
		shell.AddPagePanel("Game", new Label("host")).SetPersistenceId("game-page");
		shell.AddPagePanel("Game", new Label("client")).SetPersistenceId("game-page-1");
		EditorLayoutTools.Register(server, shell.Docks);
	}

	[Test]
	public static void TwoGameTabsGoSideBySideThenBackIntoOneGroup()
	{
		let context = scope EditorContext();
		let shell = scope EditorShell();
		let server = scope McpServer();
		Rig(shell, context, server);
		Test.Assert(server.ToolCount == EditorLayoutTools.cLayoutToolCount);

		// Both tabs in the document group, with the Project panel.
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let root = got.Payload.Get("root");
			Test.Assert(SameGroup(root, "game-page", "game-page-1"));
			Test.Assert(SameGroup(root, "welcome", "game-page"));
			Test.Assert(!GroupOf(root, "console", .. scope .()).IsEmpty);
		}

		// The client to the right of the host: a horizontal split, the host's group left, the
		// client alone right, half each.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"game-page\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let tree = got.Payload.Get("root");
			Test.Assert(GroupOf(tree, "game-page-1", .. scope .()) == "game-page-1", "alone in its group");
			Test.Assert(SameGroup(tree, "welcome", "game-page"), "the rest stay with the host");
			let split = SplitOver(tree, "game-page", "game-page-1");
			Test.Assert(split != null);
			Test.Assert(split.Get("split").AsString() == "horizontal");
			Test.Assert(Math.Abs(split.Get("share").AsNumber() - 0.5) < 1e-4);
		}
		// The dock agrees: both are their groups' selected tabs, so both render.
		let hostPanel = shell.Docks.FindPanelById("game-page");
		let clientPanel = shell.Docks.FindPanelById("game-page-1");
		Test.Assert((clientPanel.Parent as DockTabGroup).SelectedPanel == clientPanel);
		Test.Assert(hostPanel.Parent != clientPanel.Parent);

		// Back into the host's group as a tab: the split goes.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"center\",\"relativeTo\":\"game-page\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(SameGroup(got.Payload.Get("root"), "game-page", "game-page-1"));
			Test.Assert(hostPanel.Parent == clientPanel.Parent);
		}
	}

	[Test]
	public static void ASidesShareIsTheMovedPanelsOnEitherSide()
	{
		let context = scope EditorContext();
		let shell = scope EditorShell();
		let server = scope McpServer();
		Rig(shell, context, server);

		// Below the host, a third of the height: the host's group is first, so its share is 0.7.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"bottom\",\"relativeTo\":\"game-page\",\"share\":0.3}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let split = SplitOver(got.Payload.Get("root"), "game-page", "game-page-1");
			Test.Assert(split != null);
			Test.Assert(split.Get("split").AsString() == "vertical");
			Test.Assert(Math.Abs(split.Get("share").AsNumber() - 0.7) < 1e-4);
		}
		// Left of the host, a quarter: now the moved panel is first.
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"left\",\"relativeTo\":\"game-page\",\"share\":0.25}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let split = SplitOver(got.Payload.Get("root"), "game-page-1", "game-page");
			Test.Assert(split != null);
			Test.Assert(Math.Abs(split.Get("share").AsNumber() - 0.25) < 1e-4);
		}
	}

	[Test]
	public static void AHiddenToolPanelIsListedAndDocksAgain()
	{
		let context = scope EditorContext();
		let shell = scope EditorShell();
		let server = scope McpServer();
		Rig(shell, context, server);
		shell.Docks.ClosePanel(shell.ProfilerTab); // a tool panel hides on close
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Lists(got.Payload.Get("hidden"), "profiler"));
			Test.Assert(GroupOf(got.Payload.Get("root"), "profiler", .. scope .()).IsEmpty);
		}
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"profiler\",\"position\":\"center\",\"relativeTo\":\"console\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(!Lists(got.Payload.Get("hidden"), "profiler"));
			Test.Assert(SameGroup(got.Payload.Get("root"), "profiler", "console"));
		}
	}

	[Test]
	public static void RefusalsNameWhatIsWrong()
	{
		let context = scope EditorContext();
		let shell = scope EditorShell();
		let server = scope McpServer();
		Rig(shell, context, server);
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-9\",\"position\":\"right\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("layout_get"), got.Error);
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
		shell.Docks.ClosePanel(shell.ProfilerTab);
		{
			let got = Call(server, "panel_dock", "{\"panel\":\"game-page-1\",\"position\":\"right\",\"relativeTo\":\"profiler\"}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.Contains("not docked"), got.Error);
		}
		// Nothing moved.
		{
			let got = Call(server, "layout_get", "{}");
			defer delete got;
			Test.Assert(SameGroup(got.Payload.Get("root"), "game-page", "game-page-1"));
		}
	}
}
