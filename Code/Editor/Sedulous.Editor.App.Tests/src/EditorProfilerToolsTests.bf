using System;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Profiler;
using Sedulous.Profiler.Capture;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// profiler_capture over a test's own profiler and recorder: it waits for the capture, then
/// answers a summary of the file written, and says why when it cannot.
class EditorProfilerToolsTests
{
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
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"profiler_capture\",\"arguments\":{}}}}}", argumentsJson);
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

	private static ProfilerToolSeams SeamsFor(Sedulous.Profiler.Profiler profiler, CaptureRecorder recorder, StringView folder)
	{
		let seams = new ProfilerToolSeams();
		seams.Profiler = profiler;
		seams.Recorder = recorder;
		seams.Folder.Set(folder);
		return seams;
	}

	/// One frame of the host: a scope, a counter, the frame's end and the recorder advanced.
	private static void RunFrame(Sedulous.Profiler.Profiler profiler, CaptureRecorder recorder, uint32 counter, double value)
	{
		profiler.BeginFrame();
		if (profiler.BeginScope("Work"))
			profiler.EndScope();
		profiler.SetCounter(counter, value);
		profiler.EndFrame();
		recorder.OnFrameEnd(profiler);
	}

	/// Re-entered a frame at a time until it answers.
	private static LineState PumpThroughFrames(McpServer server, StringView args, Sedulous.Profiler.Profiler profiler,
		CaptureRecorder recorder, uint32 counter, double value, out Answer outAnswer)
	{
		outAnswer = null;
		var state = LineState.NotFinished;
		for (uint32 frame < 20)
		{
			RunFrame(profiler, recorder, counter, value);
			state = Pump(server, args, out outAnswer);
			if (state != .NotFinished)
				break;
		}
		return state;
	}

	[Test]
	public static void RegisteredOnce()
	{
		let profiler = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		let server = scope McpServer();
		EditorProfilerTools.Register(server, SeamsFor(profiler, recorder, "scratch_profiler_tool"));
		Test.Assert(server.ToolCount == EditorProfilerTools.cProfilerToolCount);
	}

	[Test]
	public static void WaitsForTheCaptureThenAnswersItsSummary()
	{
		let profiler = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		recorder.SetApplication("ToolProbe");
		let draws = profiler.RegisterCounter("Draws", .Count);
		let server = scope McpServer();
		EditorProfilerTools.Register(server, SeamsFor(profiler, recorder, "scratch_profiler_tool"));

		let args = "{\"seconds\":0}";
		Test.Assert(Pump(server, args, let first) == .NotFinished);
		delete first;
		Test.Assert(recorder.Capturing);
		Test.Assert(profiler.Armed);

		Test.Assert(PumpThroughFrames(server, args, profiler, recorder, draws, 10.0, let got) == .Answered);
		defer delete got;
		Test.Assert(got.Ok, got.Error);
		Test.Assert(!profiler.Armed);
		let payload = got.Payload;
		Test.Assert(payload.Get("path").AsString() == recorder.LastCapture);
		Test.Assert(payload.Get("path").AsString().Contains("ToolProbe-"));
		Test.Assert(payload.Get("chromeTrace").AsString().EndsWith(".json"));
		Test.Assert(FileExists(payload.Get("chromeTrace").AsString()));
		Test.Assert(payload.Get("frames").AsNumber() >= 1.0);
		let times = payload.Get("frameMs");
		Test.Assert(times.Get("min").AsNumber(-1.0) >= 0.0);
		Test.Assert(times.Get("median").AsNumber() <= times.Get("max").AsNumber());
		let scopes = payload.Get("topScopes");
		Test.Assert(scopes.Count == 1);
		Test.Assert(scopes.At(0).Get("name").AsString() == "Work");
		Test.Assert(scopes.At(0).Get("count").AsNumber() == payload.Get("frames").AsNumber());
		Test.Assert(payload.Get("topGpuPasses").Count == 0);
		Test.Assert(payload.Get("counterAverages").Get("Draws").AsNumber() == 10.0);
	}

	[Test]
	public static void NamesACaptureAlreadyRunningAndOneThatCouldNotBeWritten()
	{
		let profiler = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		let draws = profiler.RegisterCounter("Draws", .Count);
		let server = scope McpServer();
		// A folder under a file cannot be made, so the capture cannot be written.
		Test.Assert(CreateDirectory("scratch_profiler_tool"));
		{
			let blocker = scope FileStream("scratch_profiler_tool/blocker", .Write);
			Test.Assert(blocker.IsValid);
		}
		EditorProfilerTools.Register(server, SeamsFor(profiler, recorder, "scratch_profiler_tool/blocker/inside"));

		// The key (or a player's flag) got there first.
		Test.Assert(recorder.Start(profiler, 0.0, "scratch_profiler_tool"));
		Test.Assert(Pump(server, "{}", let busy) == .Answered);
		defer delete busy;
		Test.Assert(!busy.Ok);
		Test.Assert(busy.Error.Contains("already running", true), busy.Error);
		for (uint32 frame < 20)
		{
			if (!recorder.Capturing)
				break;
			RunFrame(profiler, recorder, draws, 0.0);
		}
		Test.Assert(!recorder.Capturing);

		Test.Assert(Pump(server, "{\"seconds\":0}", let started) == .NotFinished);
		delete started;
		Test.Assert(PumpThroughFrames(server, "{\"seconds\":0}", profiler, recorder, draws, 0.0, let failed) == .Answered);
		defer delete failed;
		Test.Assert(!failed.Ok);
		Test.Assert(failed.Error.Contains("could not be written", true), failed.Error);
	}
}
