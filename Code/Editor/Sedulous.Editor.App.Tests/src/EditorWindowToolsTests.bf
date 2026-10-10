using System;
using System.Collections;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// editor_screenshot over fake windows: the main window to a PNG, every window with "all",
/// re-entered until the capture lands, and why it could not when it cannot.
class EditorWindowToolsTests
{
	/// What the application would be: its windows, and a capture the test moves along by hand.
	private class FakeWindows
	{
		public List<uint32> Windows = new .() ~ delete _;
		public List<WindowShot> Shots = new .() ~ DeleteContainerAndItems!(_);
		public int Requests = 0;

		/// The seams over this fake; the tool owns them.
		public WindowToolSeams Seams()
		{
			let seams = new WindowToolSeams();
			seams.Windows = new (outWindows) => { outWindows.AddRange(Windows); };
			seams.Request = new (requested) =>
				{
					Requests++;
					ClearAndDeleteItems!(Shots);
					for (let r in requested)
					{
						let shot = new WindowShot();
						shot.Window = r.Window;
						shot.Main = r.Main;
						shot.Path.Set(r.Path);
						Shots.Add(shot);
					}
				};
			seams.Shots = new (outShots) => { outShots.AddRange(Shots); };
			return seams;
		}

		public void Land(WindowCaptureState state)
		{
			for (let shot in Shots)
			{
				shot.State = state;
				shot.Width = 1600;
				shot.Height = 900;
			}
		}
	}

	private class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static LineState Pump(McpServer server, StringView argumentsJson, out Answer outAnswer)
	{
		outAnswer = null;
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"editor_screenshot\",\"arguments\":{}}}}}", argumentsJson);
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

	private static bool Pending(McpServer server, StringView argumentsJson)
	{
		let state = Pump(server, argumentsJson, let answer);
		delete answer;
		return state == .NotFinished;
	}

	/// The main window to a PNG, waiting for its frame; with no path, a new file under the
	/// screenshots folder each time.
	[Test]
	public static void TheMainWindowToAPngWaitingForItsFrame()
	{
		let fake = scope FakeWindows();
		fake.Windows.Add(7); // the main window
		fake.Windows.Add(9); // a floating panel
		let server = scope McpServer();
		EditorWindowTools.Register(server, fake.Seams());
		Test.Assert(server.ToolCount == EditorWindowTools.cWindowToolCount);

		// The first pump asks for the main window alone, to the path given.
		let args = "{\"path\":\"/tmp/editor.png\"}";
		Test.Assert(Pending(server, args));
		Test.Assert(fake.Shots.Count == 1);
		Test.Assert((fake.Shots[0].Window == 7) && fake.Shots[0].Main && (fake.Shots[0].Path == "/tmp/editor.png"));

		// Re-entered until it lands; the same request, not a new one.
		Test.Assert(Pending(server, args));
		Test.Assert(fake.Requests == 1);
		fake.Land(.Written);
		Test.Assert(Pump(server, args, let got) == .Answered);
		defer delete got;
		Test.Assert(got.Ok, got.Error);
		Test.Assert(got.Payload.Get("path").AsString() == "/tmp/editor.png");
		let shots = got.Payload.Get("shots");
		Test.Assert(shots.Count == 1);
		Test.Assert(shots.At(0).Get("window").AsNumber() == 7);
		Test.Assert(shots.At(0).Get("main").AsBool());
		Test.Assert((shots.At(0).Get("width").AsNumber() == 1600) && (shots.At(0).Get("height").AsNumber() == 900));

		// With no path, a new file under the screenshots folder, a new one each time.
		Test.Assert(Pending(server, "{}"));
		let first = scope String(fake.Shots[0].Path);
		Test.Assert(first.EndsWith(".png") && first.Contains("screenshots") && first.Contains("editor-"), first);
		fake.Land(.Written);
		Test.Assert(Pump(server, "{}", let firstAnswer) == .Answered);
		defer delete firstAnswer;
		Test.Assert(firstAnswer.Ok, firstAnswer.Error);
		Test.Assert(Pending(server, "{}"));
		Test.Assert(fake.Shots[0].Path != first);
		fake.Land(.Written);
		Test.Assert(Pump(server, "{}", let secondAnswer) == .Answered);
		defer delete secondAnswer;
		Test.Assert(secondAnswer.Ok, secondAnswer.Error);
	}

	/// Every window with "all", each further one beside the first.
	[Test]
	public static void EveryWindowWithAllEachFurtherOneBesideTheFirst()
	{
		let fake = scope FakeWindows();
		fake.Windows.Add(7);
		fake.Windows.Add(9);
		fake.Windows.Add(12);
		let server = scope McpServer();
		EditorWindowTools.Register(server, fake.Seams());

		let args = "{\"window\":\"all\",\"path\":\"/tmp/all.png\"}";
		Test.Assert(Pending(server, args));
		Test.Assert(fake.Shots.Count == 3);
		Test.Assert((fake.Shots[0].Path == "/tmp/all.png") && fake.Shots[0].Main);
		Test.Assert((fake.Shots[1].Path == "/tmp/all-window9.png") && !fake.Shots[1].Main);
		Test.Assert(fake.Shots[2].Path == "/tmp/all-window12.png");

		// Not done while one window has yet to draw.
		fake.Shots[0].State = .Written;
		Test.Assert(Pending(server, args));
		fake.Land(.Written);
		Test.Assert(Pump(server, args, let got) == .Answered);
		defer delete got;
		Test.Assert(got.Ok, got.Error);
		Test.Assert(got.Payload.Get("shots").Count == 3);
		Test.Assert(got.Payload.Get("path").AsString() == "/tmp/all.png");
	}

	/// Says why when it cannot capture: no window that can draw, a failed capture, no frame
	/// in time.
	[Test]
	public static void SaysWhyWhenItCannotCapture()
	{
		let fake = scope FakeWindows();
		let server = scope McpServer();
		EditorWindowTools.Register(server, fake.Seams());

		// No window that can draw (the editor minimised).
		Test.Assert(Pump(server, "{}", let none) == .Answered);
		defer delete none;
		Test.Assert(!none.Ok && none.Error.StartsWith("the editor has no window"), none.Error);
		Test.Assert(fake.Requests == 0);

		// A failed capture names the window and the log.
		fake.Windows.Add(7);
		Test.Assert(Pending(server, "{}"));
		fake.Land(.Failed);
		Test.Assert(Pump(server, "{}", let failed) == .Answered);
		defer delete failed;
		Test.Assert(!failed.Ok && failed.Error.StartsWith("the capture of window 7 failed"), failed.Error);

		// No frame in time: it gives up rather than waiting forever.
		Test.Assert(Pending(server, "{}"));
		Answer late = null;
		for (int pump < 1000)
		{
			if (Pump(server, "{}", out late) == .Answered)
				break;
		}
		defer delete late;
		Test.Assert((late != null) && !late.Ok, "an answer came");
		Test.Assert(late.Error.StartsWith("the editor drew no frame in ten seconds"), late.Error);
	}
}
