using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Profiler;
using Sedulous.Profiler.Capture;

namespace Sedulous.Profiler.Capture.Tests;

/// The capture recorder: arms the profiler for the time asked, waits for the last frames' GPU
/// passes, then writes a profile stream file and Chrome trace JSON beside it, and lets the
/// profiler go.
class CaptureRecorderTests
{
	[Test]
	public static void ACaptureBecomesAStreamFileAndAChromeTraceThenLetsGo()
	{
		let p = scope Profiler();
		let recorder = scope CaptureRecorder();
		recorder.SetApplication("Probe");
		recorder.SetBuild("Linux64", "test");
		Test.Assert(recorder.LastCapture.IsEmpty);
		Test.Assert(recorder.Start(p, 0.0, "scratch_profile_captures/nested"));
		Test.Assert(p.Armed);
		Test.Assert(!recorder.Start(p, 1.0, "scratch_profile_captures"), "one at a time");

		uint32 frames = 0;
		bool written = false;
		while (!written && (frames < 20))
		{
			p.BeginFrame();
			Test.Assert(p.BeginScope("Work"));
			p.EndScope();
			p.EndFrame();
			written = recorder.OnFrameEnd(p);
			frames++;
		}
		Test.Assert(written);
		Test.Assert(frames == CaptureRecorder.GpuGraceFrames, scope $"{frames} frames: the time was up at once, then the grace");
		Test.Assert(!p.Armed);
		Test.Assert(!recorder.Capturing);
		Test.Assert(!recorder.LastCapture.IsEmpty);
		Test.Assert(recorder.LastCapture.EndsWith(".aeprofile"));

		// The stream reads back as a capture of the recorded frames, named and built as set.
		{
			let file = scope FileStream(recorder.LastCapture, .Read);
			Test.Assert(file.IsValid);
			let capture = scope ProfileCapture();
			Test.Assert(capture.Read(file));
			Test.Assert(capture.Header.Application == "Probe");
			Test.Assert(capture.Header.Platform == "Linux64");
			Test.Assert(capture.Header.Build == "test");
			Test.Assert(capture.FrameCount >= 1);
			Test.Assert(capture.OldestFrame == 0, "from the frame it started on");
			Test.Assert(capture.NameOf(capture.Frame(capture.OldestFrame).Threads[0].Scopes[0].Name) == "Work");
		}

		// The Chrome trace beside it.
		let jsonPath = scope String(recorder.LastCapture);
		jsonPath.RemoveFromEnd(".aeprofile".Length);
		jsonPath.Append(".json");
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(jsonPath, bytes) case .Ok);
		let trace = JsonValue.Parse(StringView((char8*)bytes.Ptr, bytes.Count));
		defer delete trace;
		Test.Assert(trace.Get("traceEvents").IsArray);
	}

	/// The editor's panel saves what it recorded this way, as the recorder writes a capture.
	[Test]
	public static void AnySourcesFramesARecordingsTooAsTheStreamAndTheChromeTrace()
	{
		let p = scope Profiler();
		p.Arm();
		let live = scope LiveProfileSource(p);
		let recording = scope ProfileRecording();
		recording.Begin(live);
		for (uint32 f < 3)
		{
			p.BeginFrame();
			Test.Assert(p.BeginScope("Panel"));
			p.EndScope();
			p.EndFrame();
		}
		recording.Pull(live, 0);
		Test.Assert(CreateDirectory("scratch_capture_files"));
		let header = scope StreamHeader();
		header.TickFrequency = recording.TickFrequency;
		header.Application.Set("Editor");
		let path = CaptureRecorder.WriteCaptureFiles(recording, recording.OldestFrame, recording.NewestFrame,
			"scratch_capture_files/saved", header, .. scope .());
		Test.Assert(path == "scratch_capture_files/saved.aeprofile", path);
		{
			let file = scope FileStream(path, .Read);
			Test.Assert(file.IsValid);
			let capture = scope ProfileCapture();
			Test.Assert(capture.Read(file));
			Test.Assert(capture.FrameCount == 3);
			Test.Assert(capture.Header.Application == "Editor");
		}
		Test.Assert(FileExists("scratch_capture_files/saved.json"));

		// A folder that is not there: nothing written, an empty answer.
		Test.Assert(CaptureRecorder.WriteCaptureFiles(recording, 0, 0, "scratch_no_such_folder/x/saved", header, .. scope .()).IsEmpty);
	}
}
