using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The MCP action bridge over a real registry: action_list with every declaration's state over
/// the active page, action_state for one, action_execute through the funnel (a toggle flips,
/// its state comes back), the refusals (an unknown id, disabled over the active page), and the
/// unattended scope: an action that opens a modal window runs with the GUI dispatcher refusing
/// it, answered as cancelled and reported, the interceptor that was there put back after, and a
/// window opened outside the scope opening as it always does.
class ActionToolsTests
{
	class TogglePage : EditorPage
	{
		public bool On = false;
		public override StringView Title => "toggling";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	/// The flow that asks before it acts ("Unsaved changes", OK or Cancel): dismissed, it acts
	/// not. Registered as project.close.
	class AskingFlow
	{
		public bool Accepted = false;
		public int Answers = 0;
		/// The last box the flow opened, a reference of ours: a refused one is held by nothing
		/// else.
		public MessageBox Last = null ~ _?.ReleaseRef();

		public void Register(EditorActionRegistry actions, SceneRoot over)
		{
			let d = new EditorActionDeclaration("project.close", "Close Project");
			d.Execute = new [=this, =over](page) => { Ask(over); };
			Test.Assert(actions.Register(d));
		}

		private void Ask(SceneRoot over)
		{
			let question = new MessageBox();
			if (Last != null)
				Last.ReleaseRef();
			Last = question;
			question.Configure("Unsaved changes", "Close anyway?", .OkCancel);
			question.SetOnResult(new [=this](result) =>
				{
					Answers++;
					Accepted = result == .Ok;
				});
			question.OpenModal(over);
		}
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

	private static JsonValue FindById(JsonValue actions, StringView id)
	{
		for (int i < actions.Count)
		{
			if (actions.At(i).Get("id").AsString() == id)
				return actions.At(i);
		}
		return null;
	}

	/// A GUI scene for the actions' dialogs, held by the caller: it releases it, and the GUI goes
	/// with it.
	private static SceneRoot NewRoot()
	{
		let gui = new GUIContext();
		let root = new SceneRoot(gui);
		gui.ReleaseRef(); // the root's keeps it
		root.Size = .(800.0f, 600.0f);
		return root;
	}

	[Test]
	public static void ListStateAndExecuteThroughTheFunnelUnattended()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let dispatcher = root.EventDispatcher;

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
			d.Shortcut = EditorShortcut.Of("ctrl-f");
			d.Enabled = new (page) => page != null;
			d.Checked = new (page) => (page != null) && ((TogglePage)page).On; // asked while disabled too
			d.Execute = new (page) =>
				{
					let toggling = (TogglePage)page;
					toggling.On = !toggling.On;
				};
			Test.Assert(actions.Register(d));
		}
		let flow = scope AskingFlow();
		flow.Register(actions, root);

		let server = scope McpServer();
		let seams = new ActionToolSeams();
		seams.Context = context;
		seams.Dialogs = dispatcher;
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
			Test.Assert(!ran.Payload.Has("note"));
			Test.Assert(exits == 1);
		}
		{
			let refused = Call(server, "action_execute", "{\"id\":\"page.flip\"}");
			defer delete refused;
			Test.Assert(!refused.Ok);
			Test.Assert(refused.Error.StartsWith("action 'page.flip' is not enabled over the active page (no page is active)"), refused.Error);
		}
		// An unknown id is the tool's error, from either tool.
		{
			let unknown = Call(server, "action_execute", "{\"id\":\"nobody.home\"}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no action 'nobody.home'"), unknown.Error);
			let stateUnknown = Call(server, "action_state", "{\"id\":\"nobody.home\"}");
			defer delete stateUnknown;
			Test.Assert(!stateUnknown.Ok);
			Test.Assert(stateUnknown.Error.StartsWith("no action 'nobody.home'"), stateUnknown.Error);
		}

		// A page active: the toggle flips and reports its state after, and action_state says the
		// same.
		let page = (TogglePage)context.AdoptPage(new TogglePage());
		{
			let state = Call(server, "action_state", "{\"id\":\"page.flip\"}");
			defer delete state;
			Test.Assert(state.Ok);
			Test.Assert(state.Payload.Get("id").AsString() == "page.flip");
			Test.Assert(state.Payload.Get("enabled").AsBool());
			Test.Assert(!state.Payload.Get("checked").AsBool());
			let flipped = Call(server, "action_execute", "{\"id\":\"page.flip\"}");
			defer delete flipped;
			Test.Assert(flipped.Ok);
			Test.Assert(page.On);
			Test.Assert(flipped.Payload.Get("checked").AsBool());
			Test.Assert(flipped.Payload.Get("enabled").AsBool());
			let after = Call(server, "action_state", "{\"id\":\"page.flip\"}");
			defer delete after;
			Test.Assert(after.Ok);
			Test.Assert(after.Payload.Get("enabled").AsBool());
			Test.Assert(after.Payload.Get("checked").AsBool());
		}

		// Unattended: the dialog the action opens is refused and named; the flow heard a
		// cancel, so nothing happened; it was never shown, and the scope put the (empty)
		// interceptor slot back.
		{
			let closed = Call(server, "action_execute", "{\"id\":\"project.close\"}");
			defer delete closed;
			Test.Assert(closed.Ok);
			Test.Assert(closed.Payload.Get("suppressedDialogs").Count == 1);
			Test.Assert(closed.Payload.Get("suppressedDialogs").At(0).AsString() == "Unsaved changes");
			Test.Assert(closed.Payload.Has("note"));
			Test.Assert(flow.Answers == 1, "answered");
			Test.Assert(!flow.Accepted, "as cancelled");
			Test.Assert(!flow.Last.IsOpen);
			Test.Assert(dispatcher.PopupCount == 0, "never shown");
			let left = dispatcher.TakeModalInterceptor();
			Test.Assert(left == null, "the scope restored it");
			delete left;
		}
	}

	/// The scope puts back the interceptor that was there (it stands aside while the call runs:
	/// the call's refusal is the scope's own), and outside the scope a modal window opens as it
	/// always does.
	[Test]
	public static void TheScopePutsBackTheInterceptorThereAndOutsideItAWindowOpens()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let dispatcher = root.EventDispatcher;

		let context = scope EditorContext();
		let actions = context.Actions;
		let flow = scope AskingFlow();
		flow.Register(actions, root);

		let server = scope McpServer();
		let seams = new ActionToolSeams();
		seams.Context = context;
		seams.Dialogs = dispatcher;
		EditorActionTools.Register(server, seams);

		// Outside any scope: the question opens, modal, over the root.
		Test.Assert(actions.Execute("project.close") case .Ok);
		Test.Assert(flow.Last.IsOpen);
		Test.Assert(flow.Last.IsModal);
		Test.Assert(dispatcher.PopupCount == 1);
		Test.Assert(flow.Answers == 0, "waiting for the user");
		flow.Last.Close();
		Test.Assert(dispatcher.PopupCount == 0);

		// Another interceptor there, one that lets every window open.
		int priorAsked = 0;
		delegate bool(Node window) prior = new [&priorAsked] (window) =>
			{
				priorAsked++;
				return true;
			};
		dispatcher.SetModalInterceptor(prior);

		{
			let closed = Call(server, "action_execute", "{\"id\":\"project.close\"}");
			defer delete closed;
			Test.Assert(closed.Ok);
			Test.Assert(closed.Payload.Get("suppressedDialogs").Count == 1);
			Test.Assert(closed.Payload.Get("suppressedDialogs").At(0).AsString() == "Unsaved changes");
		}
		Test.Assert(priorAsked == 0, "the scope's own refused it");
		Test.Assert(!flow.Last.IsOpen);
		Test.Assert(dispatcher.PopupCount == 0);
		Test.Assert(flow.Answers == 1);
		Test.Assert(!flow.Accepted);

		// After the call the one that was there answers again: asked, it lets the window open.
		Test.Assert(actions.Execute("project.close") case .Ok);
		Test.Assert(priorAsked == 1);
		Test.Assert(flow.Last.IsOpen);
		Test.Assert(dispatcher.PopupCount == 1);
		flow.Last.Close();

		let taken = dispatcher.TakeModalInterceptor();
		Test.Assert(taken === prior, "the same one, put back");
		delete taken;
	}

	/// An unattended scope over no dispatcher records nothing and still frees its list: the
	/// destructor once returned early there, which in Beef skips the fields' deletes
	/// (asan-test.py shows it).
	[Test]
	public static void AnUnattendedScopeWithoutAContextFreesItsList()
	{
		let unattended = scope UnattendedDialogs(null);
		Test.Assert(unattended.Suppressed.IsEmpty);
	}
}
