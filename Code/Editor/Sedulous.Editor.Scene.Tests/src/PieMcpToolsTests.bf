using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Input;
using Sedulous.Script;
using Sedulous.Shell;

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
			DeleteAndNullify!(Scripted);
		}
		public bool IsRunning => Running;
		public bool IsStarting => Starting;
		public StringView SceneName => Scene;
		public double RunTime => Time;
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

		/// The run's scene, and a game script with one property, `score`.
		public Sedulous.Scene.Scene Level = new .("Level1") ~ delete _;
		public double Score = 0;
		public Sedulous.Scene.Scene RunningScene => Running ? Level : null;
		public bool GetScriptProperty(StringView name, ref ScriptValue value)
		{
			if (!Running || (name != "score"))
				return false;
			value = .FromFloat(Score);
			return true;
		}

		/// The scripted input a run installed, advanced by Frame as the page's OnUpdate does.
		public ScriptedInputSource Scripted ~ delete _;
		public double ScriptStart = 0;
		public bool ScriptEnding = false;
		public int ScriptsBegun = 0;
		public void BeginScriptedInput(ScriptedInputSource source)
		{
			delete Scripted;
			Scripted = source;
			ScriptStart = Time;
			ScriptEnding = false;
			ScriptsBegun++;
		}
		public void EndScriptedInput() { if (Scripted != null) ScriptEnding = true; }
		public bool IsScripted => Scripted != null;

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

		/// One rendered frame of the run: the clock, then the page's advance of the script
		/// (an ended script goes, as the page's release frame then restore do).
		public void Frame(double dt)
		{
			if (!Running)
				return;
			Frames++;
			Time += dt;
			if (Scripted != null)
			{
				if (ScriptEnding)
					DeleteAndNullify!(Scripted);
				else
					Scripted.Advance(Time - ScriptStart);
			}
		}
	}

	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static LineState Pump(McpServer server, StringView tool, StringView argumentsJson, out Answer outAnswer) =>
		Pump(server, 0, tool, argumentsJson, out outAnswer);

	/// One entry of the call the transport knows as `callId` (nought: known by its line).
	private static LineState Pump(McpServer server, uint64 callId, StringView tool, StringView argumentsJson, out Answer outAnswer)
	{
		outAnswer = null;
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		let state = server.HandleLine(line, reply, callId);
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
		Test.Assert(PieMcpTools.cPieToolCount == 6, "a tripwire: bump deliberately when a PIE tool comes or goes");

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
			Test.Assert(Math.Abs(state.Payload.Get("runTime").AsNumber() - 0.516) < 1e-9);
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

	/// A primary start and a new instance's run at once, re-entered in turn, and each answers
	/// with its own tab.
	[Test]
	public static void APrimaryStartAndANewInstancesInterleave()
	{
		let context = scope EditorContext();
		let opened = scope List<HeadlessPiePage>();
		bool projectOpen = true;
		RegisterPlayActions(context, opened, &projectOpen);
		let server = scope McpServer();
		PieMcpTools.Register(server, context);

		Answer primaryAnswer = null;
		Answer clientAnswer = null;
		Test.Assert(Pump(server, "pie_start", "{}", out primaryAnswer) == .NotFinished);
		Test.Assert(Pump(server, "pie_start", "{\"newInstance\":true}", out clientAnswer) == .NotFinished);
		Test.Assert(opened.Count == 2, "both tabs opened, neither start mistaken for the other's re-entry");
		for (let tab in opened)
		{
			tab.CookDone("Level1");
			tab.Frame(0.016);
		}
		Test.Assert(Pump(server, "pie_start", "{\"newInstance\":true}", out clientAnswer) == .Answered);
		defer delete clientAnswer;
		Test.Assert(Pump(server, "pie_start", "{}", out primaryAnswer) == .Answered);
		defer delete primaryAnswer;
		Test.Assert(primaryAnswer.Payload.Get("pie").AsString() == "game-page");
		Test.Assert(clientAnswer.Payload.Get("pie").AsString() == "game-page-1");
	}

	/// Two agents make the same call at once: each call keeps its own wait, where its arguments
	/// alone would have made the second the first's re-entry.
	[Test]
	public static void IdenticalCallsInFlightEachKeepTheirOwnWait()
	{
		let context = scope EditorContext();
		let opened = scope List<HeadlessPiePage>();
		bool projectOpen = true;
		RegisterPlayActions(context, opened, &projectOpen);
		let server = scope McpServer();
		PieMcpTools.Register(server, context);

		// Two new instances asked for with the same arguments: two tabs, one each.
		Answer first = null;
		Answer second = null;
		let args = "{\"newInstance\":true}";
		Test.Assert(Pump(server, 1, "pie_start", args, out first) == .NotFinished);
		Test.Assert(Pump(server, 2, "pie_start", args, out second) == .NotFinished);
		Test.Assert(opened.Count == 2, "the second start opened a tab of its own");
		for (let tab in opened)
			tab.CookDone("Level1");

		// Only the front tab renders: the one behind waits its turn, then comes to front.
		context.SetActivePage(opened[1]);
		Test.Assert(Pump(server, 1, "pie_start", args, out first) == .NotFinished);
		Test.Assert(context.ActivePage == opened[1], "the front tab's first frame is still to come");
		opened[1].Frame(0.016);
		Test.Assert(Pump(server, 1, "pie_start", args, out first) == .NotFinished);
		Test.Assert(context.ActivePage == opened[0], "its turn: to front");
		opened[0].Frame(0.016);
		Test.Assert(Pump(server, 2, "pie_start", args, out second) == .Answered);
		defer delete second;
		Test.Assert(Pump(server, 1, "pie_start", args, out first) == .Answered);
		defer delete first;
		Test.Assert(first.Payload.Get("pie").AsString() == "game-page-0");
		Test.Assert(second.Payload.Get("pie").AsString() == "game-page-1");

		// Two screenshots of one tab: the tab holds one request, so a call whose request was
		// replaced asks again once the replacing one is done, and each gets its own file.
		let tab = opened[0];
		Answer a = null;
		Answer b = null;
		let argsA = "{\"pie\":\"game-page-0\",\"path\":\"/tmp/a.png\"}";
		let argsB = "{\"pie\":\"game-page-0\",\"path\":\"/tmp/b.png\"}";
		Test.Assert(Pump(server, 3, "pie_screenshot", argsA, out a) == .NotFinished);
		Test.Assert(Pump(server, 4, "pie_screenshot", argsB, out b) == .NotFinished);
		Test.Assert(tab.Capture.Path == "/tmp/b.png", "b replaced a");
		Test.Assert(Pump(server, 3, "pie_screenshot", argsA, out a) == .NotFinished);
		Test.Assert(tab.CaptureRequests == 2, "a waits while b's is pending");
		tab.Capture.State = .Written;
		Test.Assert(Pump(server, 3, "pie_screenshot", argsA, out a) == .NotFinished, "b's file is not a's");
		Test.Assert((tab.Capture.Path == "/tmp/a.png") && (tab.Capture.State == .Pending), "a asked again");
		Test.Assert(Pump(server, 4, "pie_screenshot", argsB, out b) == .NotFinished, "a's request is not b's");
		tab.Capture.State = .Written;
		Test.Assert(Pump(server, 3, "pie_screenshot", argsA, out a) == .Answered);
		defer delete a;
		Test.Assert(a.Payload.Get("path").AsString() == "/tmp/a.png");
		Test.Assert(Pump(server, 4, "pie_screenshot", argsB, out b) == .NotFinished);
		Test.Assert(tab.Capture.Path == "/tmp/b.png", "b asked again");
		tab.Capture.State = .Written;
		Test.Assert(Pump(server, 4, "pie_screenshot", argsB, out b) == .Answered);
		defer delete b;
		Test.Assert(b.Payload.Get("path").AsString() == "/tmp/b.png");
		Test.Assert(server.CallsInFlight == 0);
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

	/// A stand-in game frame: the page's frame (its clock and its script), then the "game":
	/// the player walks +x at one unit a second while D is held, and a requested capture lands.
	private static void PlayFrame(HeadlessPiePage page, double dt)
	{
		page.Frame(dt);
		if (!page.Running)
			return;
		let player = page.Level.FindEntityByName("Player");
		if ((page.Scripted != null) && page.Scripted.Keyboard.IsKeyDown(.D) && page.Level.IsValid(player))
		{
			var t = page.Level.GetLocalTransform(player);
			t.Position.X += (float)dt;
			page.Level.SetLocalTransform(player, t);
		}
		if (page.Capture.State == .Pending)
		{
			page.Capture.State = .Written;
			page.Capture.Width = 640;
			page.Capture.Height = 360;
		}
	}

	private static HeadlessPiePage RunningPie(EditorContext context, StringView id)
	{
		let page = (HeadlessPiePage)context.AdoptPage(new HeadlessPiePage(id));
		page.Running = true;
		page.Scene.Set("Level1");
		page.Level.CreateEntity("Player");
		return page;
	}

	[Test]
	public static void ARunPlaysItsTimelineSamplesShootsAndEnds()
	{
		let context = scope EditorContext();
		let host = RunningPie(context, "game-page");
		let server = scope McpServer();
		PieMcpTools.Register(server, context);
		Answer answer;

		// Refusals change nothing: no script is installed.
		{
			let noKey = Call(server, "pie_run", "{\"duration\":1,\"input\":[{\"at\":0,\"key\":\"Hyper\"}]}");
			defer delete noKey;
			Test.Assert(!noKey.Ok);
			Test.Assert(noKey.Error.StartsWith("input[0]: no key 'Hyper'"), noKey.Error);
			let late = Call(server, "pie_run", "{\"duration\":1,\"input\":[{\"at\":2,\"key\":\"D\"}]}");
			defer delete late;
			Test.Assert(late.Error.StartsWith("input[0]: `at` 2 is after the run's end"), late.Error);
			let noField = Call(server, "pie_run", "{\"duration\":1,\"probes\":[{\"entity\":\"Player\",\"fields\":[\"light.intensity\"]}]}");
			defer delete noField;
			Test.Assert(noField.Error.StartsWith("entity 'Player' has no field 'light.intensity'"), noField.Error);
			let noEntity = Call(server, "pie_run", "{\"duration\":1,\"probes\":[{\"entity\":\"Ghost\"}]}");
			defer delete noEntity;
			Test.Assert(noEntity.Error.StartsWith("no entity 'Ghost' in PIE instance 'game-page''s scene 'Level1'"), noEntity.Error);
			let noDuration = Call(server, "pie_run", "{\"duration\":0}");
			defer delete noDuration;
			Test.Assert(noDuration.Error.StartsWith("`duration` takes run seconds"), noDuration.Error);
			Test.Assert(host.ScriptsBegun == 0);
		}

		// Hold D for a second of a two second run, sampling the player and the score every half
		// second, with a screenshot at one second.
		let args = "{\"duration\":2,\"input\":[{\"at\":0,\"key\":\"D\"},{\"at\":1,\"key\":\"D\",\"down\":false}],\"probes\":[{\"entity\":\"Player\",\"fields\":[\"position.x\"]},{\"script\":\"score\"}],\"every\":0.5,\"screenshots\":[1],\"screenshotDir\":\"/tmp\"}";
		Test.Assert(Pump(server, "pie_run", args, out answer) == .NotFinished);
		Test.Assert(host.IsScripted && (host.ScriptsBegun == 1));
		host.Score = 7;
		int pumps = 0;
		while (Pump(server, "pie_run", args, out answer) == .NotFinished)
		{
			PlayFrame(host, 0.05);
			Test.Assert(++pumps < 200, "the run ends");
		}
		{
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			let result = answer.Payload;
			Test.Assert(result.Get("endedBy").AsString() == "duration");
			Test.Assert(result.Get("runTime").AsNumber() >= 2.0);
			Test.Assert(result.Get("inputs").AsNumber() == 2);
			let samples = result.Get("samples");
			// 0, 0.5, 1, 1.5, 2 each read on the frame that reached it, then no extra final row.
			Test.Assert(samples.Count == 5, scope $"{samples.Count} samples");
			double last = -1;
			for (int i < samples.Count)
			{
				let t = samples.At(i).Get("t").AsNumber();
				Test.Assert(t > last);
				Test.Assert(t >= i * 0.5 - 1e-9, "a row is read once its time is reached");
				last = t;
			}
			// Walked while D was held (a second, give or take a frame), then stood.
			let x = samples.At(samples.Count - 1).Get("values").Get("Player.position.x").AsNumber();
			Test.Assert(Math.Abs(x - 1.0) <= 0.1, scope $"x {x}");
			Test.Assert(samples.At(4).Get("values").Get("script.score").AsNumber() == 7);
			let shots = result.Get("screenshots");
			Test.Assert(shots.Count == 1);
			Test.Assert(shots.At(0).Get("at").AsNumber() == 1);
			Test.Assert(shots.At(0).Get("path").AsString().StartsWith("/tmp/game-page-"));
			Test.Assert(shots.At(0).Get("width").AsNumber() == 640);
			Test.Assert(result.Get("until").IsNull);
			Test.Assert(result.Get("state").Get("running").AsBool());
		}
		// The script ends: its release, then the viewport's input back.
		Test.Assert(host.ScriptEnding);
		PlayFrame(host, 0.05);
		Test.Assert(!host.IsScripted);
	}

	[Test]
	public static void UntilEndsARunAndAStopEndsItToo()
	{
		let context = scope EditorContext();
		let host = RunningPie(context, "game-page");
		let server = scope McpServer();
		PieMcpTools.Register(server, context);
		Answer answer;

		let args = "{\"duration\":10,\"input\":[{\"at\":0,\"key\":\"d\"}],\"until\":{\"entity\":\"Player\",\"field\":\"position.x\",\"op\":\">=\",\"value\":1.5}}";
		while (Pump(server, "pie_run", args, out answer) == .NotFinished)
			PlayFrame(host, 0.1);
		{
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("endedBy").AsString() == "until");
			let hit = answer.Payload.Get("until");
			Test.Assert(hit.Get("probe").AsString() == "Player.position.x");
			Test.Assert(hit.Get("value").AsNumber() >= 1.5);
			Test.Assert(answer.Payload.Get("runTime").AsNumber() < 2.0);
			Test.Assert(answer.Payload.Get("samples").Count == 0, "no probes, no rows");
		}
		{
			let badOp = Call(server, "pie_run", "{\"duration\":1,\"until\":{\"script\":\"score\",\"op\":\"~\",\"value\":1}}");
			defer delete badOp;
			Test.Assert(badOp.Error.StartsWith("`until.op` takes"), badOp.Error);
		}

		// A stop mid-run answers what it had, and says so.
		PlayFrame(host, 0.1); // the ended script goes
		let long = "{\"duration\":30,\"input\":[{\"at\":0,\"key\":\"D\"}],\"probes\":[{\"entity\":\"Player\",\"fields\":[\"position.x\"]}]}";
		Test.Assert(Pump(server, "pie_run", long, out answer) == .NotFinished);
		PlayFrame(host, 0.1);
		Test.Assert(Pump(server, "pie_run", long, out answer) == .NotFinished);
		host.Stop();
		Test.Assert(Pump(server, "pie_run", long, out answer) == .Answered);
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		Test.Assert(answer.Payload.Get("endedBy").AsString() == "stopped");
		Test.Assert(answer.Payload.Get("samples").Count == 1);
		Test.Assert(!answer.Payload.Get("state").Get("running").AsBool());
	}

	/// A second run on a busy instance is refused, not taken for the first's re-entry; a run
	/// whose caller went away ends, and the tab's input goes back to the user.
	[Test]
	public static void ASecondRunIsRefusedAndAnAbandonedRunHandsInputBack()
	{
		let context = scope EditorContext();
		let host = RunningPie(context, "game-page");
		let server = scope McpServer();
		PieMcpTools.Register(server, context);
		let args = "{\"duration\":5,\"input\":[{\"at\":0,\"key\":\"D\"}]}";
		Answer answer = null;
		Test.Assert(Pump(server, 1, "pie_run", args, out answer) == .NotFinished);
		PlayFrame(host, 0.1);
		Test.Assert(Pump(server, 2, "pie_run", args, out answer) == .Answered);
		{
			defer delete answer;
			Test.Assert(!answer.Ok);
			Test.Assert(answer.Error.StartsWith("PIE instance 'game-page' is already in a pie_run"), answer.Error);
		}
		Test.Assert(Pump(server, 1, "pie_run", args, out answer) == .NotFinished, "the first run goes on");
		Test.Assert(host.IsScripted && !host.ScriptEnding);

		server.AbandonCall(1);
		Test.Assert(server.CallsInFlight == 0);
		Test.Assert(host.ScriptEnding, "the abandoned run let the tab's input go");
		PlayFrame(host, 0.1);
		Test.Assert(!host.IsScripted);

		// The instance is free for the next run.
		Test.Assert(Pump(server, 3, "pie_run", args, out answer) == .NotFinished);
		Test.Assert(host.ScriptsBegun == 2);
		server.AbandonCall(3);
	}

	[Test]
	public static void TwoInstancesRunSideBySideAndOnlyTheScriptedOneMoves()
	{
		let context = scope EditorContext();
		let host = RunningPie(context, "game-page");
		let client = RunningPie(context, "game-page-1");
		let server = scope McpServer();
		PieMcpTools.Register(server, context);
		SceneMcpTools.Register(server, context);
		Answer hostAnswer = null;
		Answer clientAnswer = null;

		// The host walks; the client runs a timeline with nothing in it, over the same seconds.
		let hostArgs = "{\"pie\":\"game-page\",\"duration\":1,\"input\":[{\"at\":0,\"key\":\"D\"}],\"probes\":[{\"entity\":\"Player\",\"fields\":[\"position.x\"]}]}";
		let clientArgs = "{\"pie\":\"game-page-1\",\"duration\":1,\"probes\":[{\"entity\":\"Player\",\"fields\":[\"position.x\"]}]}";
		var hostState = LineState.NotFinished;
		var clientState = LineState.NotFinished;
		while ((hostState == .NotFinished) || (clientState == .NotFinished))
		{
			if (hostState == .NotFinished)
				hostState = Pump(server, "pie_run", hostArgs, out hostAnswer);
			if (clientState == .NotFinished)
				clientState = Pump(server, "pie_run", clientArgs, out clientAnswer);
			PlayFrame(host, 0.1);
			PlayFrame(client, 0.1);
		}
		defer delete hostAnswer;
		defer delete clientAnswer;
		Test.Assert(hostAnswer.Ok && clientAnswer.Ok);
		Test.Assert(hostAnswer.Payload.Get("pie").AsString() == "game-page");
		Test.Assert(clientAnswer.Payload.Get("pie").AsString() == "game-page-1");
		let hostSamples = hostAnswer.Payload.Get("samples");
		let clientSamples = clientAnswer.Payload.Get("samples");
		Test.Assert(hostSamples.At(hostSamples.Count - 1).Get("values").Get("Player.position.x").AsNumber() > 0.8);
		Test.Assert(clientSamples.At(clientSamples.Count - 1).Get("values").Get("Player.position.x").AsNumber() == 0);

		// entity_inspect reads a running game's scene by `pie`.
		{
			let got = Call(server, "entity_inspect", "{\"pie\":\"game-page\",\"entity\":\"Player\"}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("pie").AsString() == "game-page");
			Test.Assert(got.Payload.Get("scene").AsString() == "Level1");
			Test.Assert(got.Payload.Get("entity").Get("name").AsString() == "Player");
			let missing = Call(server, "entity_inspect", "{\"pie\":\"game-page-1\",\"entity\":\"Ghost\"}");
			defer delete missing;
			Test.Assert(!missing.Ok);
			Test.Assert(missing.Error.StartsWith("no entity 'Ghost'"), missing.Error);
			client.Stop();
			let stopped = Call(server, "entity_inspect", "{\"pie\":\"game-page-1\",\"entity\":\"Player\"}");
			defer delete stopped;
			Test.Assert(stopped.Error.StartsWith("PIE instance 'game-page-1' is not running a scene"), stopped.Error);
		}
	}
}
