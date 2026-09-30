using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The PIE tools over a real EditorContext whose Game tabs are headless IPieInstancePage
/// pages, opened by stand-ins for the editor's game.play and game.playNewInstance actions:
/// starting (the wait for the cook and the first frame), addressing by id, a second instance
/// beside the primary, stopping one while the other runs, the list, a faulted startup script
/// in the state, and the capture's frame-by-frame wait.
class PieMcpToolsTests
{
	/// A Game tab to the rest of the editor: the run as flags a test advances.
	class HeadlessPiePage : EditorPage, IPieInstancePage
	{
		private String mId = new .() ~ delete _;
		public bool Running = false;
		public bool Starting = false;
		public String Scene = new .() ~ delete _;
		public double Time = 0;
		public uint64 Frames = 0;
		public PieScriptState Script = .None;
		public String Fault = new .() ~ delete _;
		public ViewportCapture Capture = new .() ~ delete _;
		public int CaptureRequests = 0;
		/// Play fails the start at the cook's end instead of running.
		public bool FailStart = false;

		public this(StringView id)
		{
			mId.Set(id);
		}

		public override StringView Title => "Game";
		public override Result<void, ErrorCode> Save() => .Ok;

		public StringView PieId => mId;
		public void Play()
		{
			if (!Running)
				Starting = true;
		}
		public void Stop()
		{
			Running = false;
			Starting = false;
		}
		public bool IsRunning => Running;
		public bool IsStarting => Starting;
		public StringView SceneName => Scene;
		public double GameTime => Time;
		public uint64 FrameCount => Frames;
		public PieScriptState ScriptState => Script;
		public StringView ScriptFault => Fault;
		public void RequestViewportCapture(StringView path)
		{
			Capture.State = .Pending;
			Capture.Path.Set(path);
			CaptureRequests++;
		}
		public ViewportCapture LastViewportCapture => Capture;

		/// The cook went idle: the run starts (or fails to) in the scene.
		public void CookDone(StringView scene)
		{
			if (!Starting)
				return;
			Starting = false;
			if (FailStart)
				return;
			Running = true;
			Scene.Set(scene);
			Script = .Running;
		}

		/// One rendered frame of the run.
		public void Frame(double dt)
		{
			if (!Running)
				return;
			Frames++;
			Time += dt;
		}
	}

	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static LineState Pump(McpServer server, StringView tool, StringView argumentsJson, out Answer outAnswer)
	{
		outAnswer = null;
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		let state = server.HandleLine(line, reply);
		if (state != .Answered)
			return state;
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
		outAnswer = answer;
		return state;
	}

	private static Answer Call(McpServer server, StringView tool, StringView argumentsJson)
	{
		Answer answer;
		Test.Assert(Pump(server, tool, argumentsJson, out answer) == .Answered);
		return answer;
	}

	/// The editor's two play actions, as EditorApplication declares them: Play opens (or
	/// reveals) the primary tab, Play New Instance always opens another, and both need a
	/// project open.
	private static void RegisterPlayActions(EditorContext context, List<HeadlessPiePage> opened, bool* projectOpen)
	{
		{
			let d = new EditorActionDeclaration("game.play", "Play");
			d.Enabled = new (page) => *projectOpen;
			d.Execute = new [=context, =opened](page) =>
				{
					if (PieMcpTools.FindPie(context, "game-page") != null)
						return;
					let tab = new HeadlessPiePage("game-page");
					context.AdoptPage(tab);
					opened.Add(tab);
				};
			context.Actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("game.playNewInstance", "Play New Instance");
			d.Enabled = new (page) => *projectOpen;
			d.Execute = new [=context, =opened](page) =>
				{
					let tab = new HeadlessPiePage(scope $"game-page-{opened.Count}");
					context.AdoptPage(tab);
					opened.Add(tab);
				};
			context.Actions.Register(d);
		}
	}

	[Test]
	public static void StartStateStopAndASecondInstanceBesideThePrimary()
	{
		let context = scope EditorContext();
		let opened = scope List<HeadlessPiePage>();
		bool projectOpen = false;
		RegisterPlayActions(context, opened, &projectOpen);
		let server = scope McpServer();
		PieMcpTools.Register(server, context);
		Test.Assert(server.ToolCount == PieMcpTools.cPieToolCount);
		Test.Assert(PieMcpTools.cPieToolCount == 5, "a tripwire: bump deliberately when a PIE tool comes or goes");

		// Nothing open: the state names the fix; no project, and the play action refuses.
		{
			let state = Call(server, "pie_state", "{}");
			defer delete state;
			Test.Assert(!state.Ok);
			Test.Assert(state.Error.StartsWith("no Game tab is open"), state.Error);
			let start = Call(server, "pie_start", "{}");
			defer delete start;
			Test.Assert(!start.Ok);
			Test.Assert(start.Error.StartsWith("the editor refused 'game.play'"), start.Error);
			Test.Assert(opened.IsEmpty);
		}
		projectOpen = true;

		// Start the primary: it waits on the cook, then on its first frame, then answers.
		Answer answer;
		Test.Assert(Pump(server, "pie_start", "{}", out answer) == .NotFinished);
		Test.Assert(opened.Count == 1);
		let primary = opened[0];
		Test.Assert(primary.IsStarting);
		Test.Assert(Pump(server, "pie_start", "{}", out answer) == .NotFinished, "the cook is still running");
		primary.CookDone("Level1");
		Test.Assert(Pump(server, "pie_start", "{}", out answer) == .NotFinished, "running, no frame yet");
		primary.Frame(0.016);
		Test.Assert(Pump(server, "pie_start", "{}", out answer) == .Answered);
		{
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("pie").AsString() == "game-page");
			Test.Assert(answer.Payload.Get("scene").AsString() == "Level1");
			Test.Assert(answer.Payload.Get("running").AsBool());
			Test.Assert(!answer.Payload.Get("alreadyRunning").AsBool());
			Test.Assert(answer.Payload.Get("script").Get("state").AsString() == "running");
		}
		// A second start of the running primary answers it as it is.
		{
			let again = Call(server, "pie_start", "{}");
			defer delete again;
			Test.Assert(again.Ok, again.Error);
			Test.Assert(again.Payload.Get("alreadyRunning").AsBool());
			Test.Assert(opened.Count == 1);
		}

		// A new instance gets its own tab and id.
		Test.Assert(Pump(server, "pie_start", "{\"newInstance\":true}", out answer) == .NotFinished);
		Test.Assert(opened.Count == 2);
		let client = opened[1];
		Test.Assert(client.PieId == "game-page-1");
		client.CookDone("Lobby");
		client.Frame(0.016);
		Test.Assert(Pump(server, "pie_start", "{\"newInstance\":true}", out answer) == .Answered);
		{
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("pie").AsString() == "game-page-1");
			Test.Assert(answer.Payload.Get("scene").AsString() == "Lobby");
		}

		// State by id; the list has both.
		primary.Frame(0.5);
		{
			let state = Call(server, "pie_state", "{\"pie\":\"game-page\"}");
			defer delete state;
			Test.Assert(state.Ok, state.Error);
			Test.Assert(state.Payload.Get("frames").AsNumber() == 2);
			Test.Assert(Math.Abs(state.Payload.Get("gameTime").AsNumber() - 0.516) < 1e-9);
			let list = Call(server, "pie_list", "{}");
			defer delete list;
			Test.Assert(list.Ok, list.Error);
			Test.Assert(list.Payload.Get("count").AsNumber() == 2);
			Test.Assert(list.Payload.Get("instances").At(1).Get("pie").AsString() == "game-page-1");
			let unknown = Call(server, "pie_state", "{\"pie\":\"game-page-9\"}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no PIE instance 'game-page-9'"), unknown.Error);
		}

		// A faulted startup script shows in its instance's state, with the reason.
		client.Script = .Faulted;
		client.Fault.Set("faulted in update: Lobby.sc:12 index out of range");
		{
			let state = Call(server, "pie_state", "{\"pie\":\"game-page-1\"}");
			defer delete state;
			Test.Assert(state.Payload.Get("script").Get("state").AsString() == "faulted");
			Test.Assert(state.Payload.Get("script").Get("fault").AsString() == "faulted in update: Lobby.sc:12 index out of range");
		}

		// Stopping the client leaves the primary running; `all` stops the rest.
		{
			let stop = Call(server, "pie_stop", "{\"pie\":\"game-page-1\"}");
			defer delete stop;
			Test.Assert(stop.Ok, stop.Error);
			Test.Assert(stop.Payload.Get("stopped").Count == 1);
			Test.Assert(!client.IsRunning);
			Test.Assert(primary.IsRunning);
			let all = Call(server, "pie_stop", "{\"all\":true}");
			defer delete all;
			Test.Assert(all.Payload.Get("stopped").Count == 1);
			Test.Assert(all.Payload.Get("stopped").At(0).AsString() == "game-page");
			Test.Assert(!primary.IsRunning);
		}

		// A run that fails to start is an error, not a wait.
		primary.FailStart = true;
		Test.Assert(Pump(server, "pie_start", "{}", out answer) == .NotFinished);
		primary.CookDone("Level1");
		Test.Assert(Pump(server, "pie_start", "{}", out answer) == .Answered);
		defer delete answer;
		Test.Assert(!answer.Ok);
		Test.Assert(answer.Error.StartsWith("PIE instance 'game-page' did not start"), answer.Error);
	}

	[Test]
	public static void TheScreenshotWaitsForTheInstancesFrame()
	{
		let context = scope EditorContext();
		let primary = (HeadlessPiePage)context.AdoptPage(new HeadlessPiePage("game-page"));
		let client = (HeadlessPiePage)context.AdoptPage(new HeadlessPiePage("game-page-1"));
		let server = scope McpServer();
		PieMcpTools.Register(server, context);

		// A stopped instance renders nothing worth a picture.
		{
			let got = Call(server, "pie_screenshot", "{}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("PIE instance 'game-page' is not running"), got.Error);
		}

		primary.Running = true;
		client.Running = true;
		context.SetActivePage(primary);
		let args = "{\"pie\":\"game-page-1\",\"path\":\"/tmp/client.png\"}";
		Answer answer;
		Test.Assert(Pump(server, "pie_screenshot", args, out answer) == .NotFinished);
		Test.Assert(context.ActivePage == client, "brought to front");
		Test.Assert(client.CaptureRequests == 1);
		Test.Assert(primary.CaptureRequests == 0);
		Test.Assert(Pump(server, "pie_screenshot", args, out answer) == .NotFinished, "not yet rendered");
		Test.Assert(client.CaptureRequests == 1, "the same request, not a new one");
		client.Capture.State = .Written;
		client.Capture.Width = 1280;
		client.Capture.Height = 800;
		Test.Assert(Pump(server, "pie_screenshot", args, out answer) == .Answered);
		{
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("pie").AsString() == "game-page-1");
			Test.Assert(answer.Payload.Get("path").AsString() == "/tmp/client.png");
			Test.Assert(answer.Payload.Get("width").AsNumber() == 1280);
		}

		// An instance stopped mid-capture ends the wait with an error.
		Test.Assert(Pump(server, "pie_screenshot", args, out answer) == .NotFinished);
		client.Running = false;
		Test.Assert(Pump(server, "pie_screenshot", args, out answer) == .Answered);
		defer delete answer;
		Test.Assert(!answer.Ok);
		Test.Assert(answer.Error.StartsWith("PIE instance 'game-page-1' stopped before"), answer.Error);
	}
}
