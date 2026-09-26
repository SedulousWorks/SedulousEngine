using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The MCP action bridge over a real registry: action_list with every declaration's state over
/// the active page, action_state for one, action_execute through the funnel (a toggle flips,
/// its state comes back), the refusals (an unknown id, disabled over the active page), and the
/// unattended scope: an action that opens a dialog runs with the dialog suppressed and reported.
class ActionToolsTests
{
	class TogglePage : EditorPage
	{
		public bool On = false;
		public override StringView Title => "toggling";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

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

	private static JsonValue FindById(JsonValue actions, StringView id)
	{
		for (int i < actions.Count)
		{
			if (actions.At(i).Get("id").AsString() == id)
				return actions.At(i);
		}
		return null;
	}

	[Test]
	public static void ListStateAndExecuteThroughTheFunnelUnattended()
	{
		let ui = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		root.ViewportSize = .(800, 600);
		ui.AddRootView(root);

		let context = scope EditorContext();
		let actions = context.Actions;
		int exits = 0;
		{
			let d = new EditorActionDeclaration("file.exit", "Exit", "Exit the editor", "File/Exit");
			d.Execute = new [&exits](page) => { exits++; };
			Test.Assert(actions.Register(d));
		}
		{
			let d = new EditorActionDeclaration("page.flip", "Flip");
			d.Kind = .Toggle;
			d.Shortcut = .(.F, .Ctrl);
			d.Enabled = new (page) => page != null;
			d.Checked = new (page) => (page != null) && ((TogglePage)page).On; // asked while disabled too
			d.Execute = new (page) =>
				{
					let toggling = (TogglePage)page;
					toggling.On = !toggling.On;
				};
			Test.Assert(actions.Register(d));
		}
		bool accepted = false;
		{
			let d = new EditorActionDeclaration("project.close", "Close Project");
			d.Execute = new [=ui, &accepted](page) =>
				{
					// The flow asks before it acts; dismissed, it acts not.
					let dialog = new Dialog("Unsaved changes");
					dialog.OnClosed.Add(new [&accepted](dlg, result) => { accepted = result == .OK; });
					dialog.Show(ui);
				};
			Test.Assert(actions.Register(d));
		}

		let server = scope McpServer();
		let seams = new ActionToolSeams();
		seams.Context = context;
		seams.Ui = ui;
		EditorActionTools.Register(server, seams);
		Test.Assert(server.ToolCount == EditorActionTools.cActionToolCount);

		// The list, with no page active: the page-bound toggle is disabled.
		{
			let listed = Call(server, "action_list", "{}");
			defer delete listed;
			Test.Assert(listed.Ok);
			Test.Assert(listed.Payload.Get("count").AsNumber() == 3);
			let flip = FindById(listed.Payload.Get("actions"), "page.flip");
			Test.Assert(flip != null);
			Test.Assert(flip.Get("kind").AsString() == "toggle");
			Test.Assert(flip.Get("shortcut").AsString() == "Ctrl+F");
			Test.Assert(!flip.Get("enabled").AsBool());
			Test.Assert(!flip.Get("checked").AsBool());
			let exit = FindById(listed.Payload.Get("actions"), "file.exit");
			Test.Assert(exit.Get("menuPath").AsString() == "File/Exit");
			Test.Assert(exit.Get("enabled").AsBool());
		}

		// Execute: the editor-wide action runs; the disabled one is refused with the reason.
		{
			let ran = Call(server, "action_execute", "{\"id\":\"file.exit\"}");
			defer delete ran;
			Test.Assert(ran.Ok);
			Test.Assert(ran.Payload.Get("executed").AsBool());
			Test.Assert(ran.Payload.Get("suppressedDialogs").Count == 0);
			Test.Assert(exits == 1);
		}
		{
			let refused = Call(server, "action_execute", "{\"id\":\"page.flip\"}");
			defer delete refused;
			Test.Assert(!refused.Ok);
			Test.Assert(refused.Error.StartsWith("action 'page.flip' is not enabled over the active page (no page is active)"), refused.Error);
		}
		{
			let unknown = Call(server, "action_execute", "{\"id\":\"nobody.home\"}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no action 'nobody.home'"));
			let stateUnknown = Call(server, "action_state", "{\"id\":\"nobody.home\"}");
			defer delete stateUnknown;
			Test.Assert(!stateUnknown.Ok);
		}

		// A page active: the toggle flips and reports its state after.
		let page = (TogglePage)context.AdoptPage(new TogglePage());
		{
			let state = Call(server, "action_state", "{\"id\":\"page.flip\"}");
			defer delete state;
			Test.Assert(state.Ok);
			Test.Assert(state.Payload.Get("enabled").AsBool());
			Test.Assert(!state.Payload.Get("checked").AsBool());
			let flipped = Call(server, "action_execute", "{\"id\":\"page.flip\"}");
			defer delete flipped;
			Test.Assert(flipped.Ok);
			Test.Assert(page.On);
			Test.Assert(flipped.Payload.Get("checked").AsBool());
			Test.Assert(flipped.Payload.Get("enabled").AsBool());
		}

		// Unattended: the dialog the action opens is suppressed and named; the flow saw a
		// dismissal, so nothing happened, and the scope put the interceptor back.
		{
			let closed = Call(server, "action_execute", "{\"id\":\"project.close\"}");
			defer delete closed;
			Test.Assert(closed.Ok);
			Test.Assert(closed.Payload.Get("suppressedDialogs").Count == 1);
			Test.Assert(closed.Payload.Get("suppressedDialogs").At(0).AsString() == "Unsaved changes");
			Test.Assert(closed.Payload.Has("note"));
			Test.Assert(!accepted);
			Test.Assert(ui.DialogInterceptor == null, "the scope restored it");
		}
		ui.MutationQueue.Drain();
	}
}
