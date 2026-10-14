using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Profiler;
using Sedulous.Profiler.Capture;

namespace Sedulous.Editor.App;

/// What the profiler tool drives: the process's profiler and capture recorder (a test's own),
/// and the folder captures go in.
class ProfilerToolSeams
{
	/// BORROWED, both.
	public Sedulous.Profiler.Profiler Profiler;
	public CaptureRecorder Recorder;
	public String Folder = new .() ~ delete _;
}

/// profiler_capture: a capture of the next few seconds of the running editor (its pages and any
/// Play-in-editor game, one process), written as files and answered as a summary an agent can
/// act on. Only the editor host serves it: a capture needs frames to run, and the headless host
/// runs none while a call waits. Re-entered each pump while the recorder runs, then reads the
/// written capture back as a source and summarises it.
static class EditorProfilerTools
{
	/// How many tools Register registers; a tripwire like cWindowToolCount.
	public const int cProfilerToolCount = 1;
	private const double cDefaultSeconds = 3.0;
	private const double cMaxSeconds = 30.0;
	private const int cTopCount = 10;

	/// One capture in flight, the call's state.
	private class CaptureWait
	{
		public double Seconds;
		/// The recorder's last capture before this one.
		public String Previous = new .() ~ delete _;
		public Stopwatch Clock = new .() ~ delete _;
	}

	private class Total
	{
		public String Name = new .() ~ delete _;
		public double Ms;
		public int Count;
	}

	private static void Add(List<Total> totals, StringView name, double ms)
	{
		for (let total in totals)
		{
			if (total.Name == name)
			{
				total.Ms += ms;
				total.Count++;
				return;
			}
		}
		let total = new Total();
		total.Name.Set(name);
		total.Ms = ms;
		total.Count = 1;
		totals.Add(total);
	}

	/// The longest by total first, the first cTopCount of them.
	private static JsonValue Top(List<Total> totals)
	{
		totals.Sort(scope (a, b) => b.Ms <=> a.Ms);
		let output = JsonValue.MakeArray();
		for (int i < Math.Min(totals.Count, cTopCount))
		{
			let row = JsonValue.MakeObject();
			row.Set("name", JsonValue.MakeString(totals[i].Name));
			row.Set("totalMs", JsonValue.MakeNumber(totals[i].Ms));
			row.Set("count", JsonValue.MakeNumber(totals[i].Count));
			output.Add(row);
		}
		return output;
	}

	/// What an agent reads first: frame times, where the time went (CPU scopes and GPU passes
	/// by total over the capture), and each counter's average. False when the file does not
	/// read back.
	public static bool Summarise(StringView path, JsonValue outResult, String outError)
	{
		let file = scope FileStream(path, .Read);
		let capture = scope ProfileCapture();
		if (!file.IsValid || !capture.Read(file) || !capture.HasFrames)
		{
			outError.AppendF("the capture at {} could not be read back", path);
			return false;
		}
		let toMs = 1000.0 / (double)Math.Max(capture.TickFrequency, 1);
		let frameMs = scope List<double>();
		let scopes = scope List<Total>();
		defer ClearAndDeleteItems(scopes);
		let passes = scope List<Total>();
		defer ClearAndDeleteItems(passes);
		let counters = capture.Counters;
		let counterSum = scope double[counters.Length];
		let counterFrames = scope int[counters.Length];
		for (var n = capture.OldestFrame; n <= capture.NewestFrame; n++)
		{
			let frame = capture.Frame(n);
			if (frame == null)
				continue;
			frameMs.Add((double)(frame.EndTick - frame.BeginTick) * toMs);
			for (let thread in frame.Threads)
			{
				for (let scopeEvent in thread.Scopes)
					Add(scopes, capture.NameOf(scopeEvent.Name), (double)(scopeEvent.EndTick - scopeEvent.BeginTick) * toMs);
			}
			for (let pass in frame.Gpu)
				Add(passes, capture.NameOf(pass.Name), (double)(pass.EndTick - pass.BeginTick) * toMs);
			for (let value in frame.Counters)
			{
				if (value.Counter < (uint32)counters.Length)
				{
					counterSum[value.Counter] += value.Value;
					counterFrames[value.Counter]++;
				}
			}
		}
		frameMs.Sort();

		outResult.Set("path", JsonValue.MakeString(path));
		let jsonPath = scope String(path);
		if (jsonPath.EndsWith(".aeprofile"))
			jsonPath.RemoveFromEnd(".aeprofile".Length);
		jsonPath.Append(".json");
		outResult.Set("chromeTrace", JsonValue.MakeString(jsonPath));
		outResult.Set("frames", JsonValue.MakeNumber(frameMs.Count));
		let times = JsonValue.MakeObject();
		if (!frameMs.IsEmpty)
		{
			times.Set("min", JsonValue.MakeNumber(frameMs[0]));
			times.Set("median", JsonValue.MakeNumber(frameMs[frameMs.Count / 2]));
			times.Set("max", JsonValue.MakeNumber(frameMs.Back));
		}
		outResult.Set("frameMs", times);
		outResult.Set("topScopes", Top(scopes));
		outResult.Set("topGpuPasses", Top(passes));
		let averages = JsonValue.MakeObject();
		for (int i < counters.Length)
		{
			if (counterFrames[i] > 0)
				averages.Set(counters[i].Name, JsonValue.MakeNumber(counterSum[i] / counterFrames[i]));
		}
		outResult.Set("counterAverages", averages);
		return true;
	}

	/// OWNERSHIP of the seams transfers to the tool.
	public static void Register(McpServer server, ProfilerToolSeams seams)
	{
		let schema = scope SchemaBuilder();
		schema.Number("seconds", "How long to capture (default 3, at most 30).");
		server.RegisterTool("profiler_capture",
			"Capture the next few seconds of the running editor (its pages and any Play-in-editor game) with the profiler, and answer a summary: frame times (min, median, max), the CPU scopes and GPU passes that took longest over the capture, and each counter's average (draws, passes, GPU memory). The capture is written as a .aeprofile (the profile stream) and Chrome trace JSON beside it (Perfetto, chrome://tracing); both paths are in the answer. The call lasts the capture plus a few frames.",
			schema.Build(), .Creates,
			new (call, arguments, outResult, outError) => CaptureCall(seams, call, arguments, outResult, outError), seams);
	}

	private static ToolOutcome CaptureCall(ProfilerToolSeams seams, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (let wait = call.State as CaptureWait)
		{
			// Re-entered: this call, one pump later.
			if (seams.Recorder.Capturing)
			{
				if (wait.Clock.Elapsed.TotalSeconds > wait.Seconds * 4.0 + 30.0)
				{
					outError.Append("the capture did not finish (the editor stopped running frames?)");
					return .Failed;
				}
				return .NotFinished;
			}
			if (seams.Recorder.LastCapture == wait.Previous)
			{
				outError.Append("the capture could not be written (log_read says why)");
				return .Failed;
			}
			return Summarise(seams.Recorder.LastCapture, outResult, outError) ? .Answered : .Failed;
		}
#if SHIPPING
		outError.Append("the profiler is compiled out of this build (ShippingRelease)");
		return .Failed;
#else
		if (seams.Recorder.Capturing)
		{
			outError.Append("a capture is already running; call again when it has finished");
			return .Failed;
		}
		var seconds = cDefaultSeconds;
		if ((arguments != null) && (arguments.Get("seconds") != null))
			seconds = arguments.Get("seconds").AsNumber(cDefaultSeconds);
		seconds = Math.Clamp(seconds, 0.0, cMaxSeconds);
		let wait = new CaptureWait();
		wait.Seconds = seconds;
		wait.Previous.Set(seams.Recorder.LastCapture);
		wait.Clock.Start();
		if (!seams.Recorder.Start(seams.Profiler, seconds, seams.Folder))
		{
			delete wait;
			outError.Append("the capture could not start");
			return .Failed;
		}
		call.State = wait;
		return .NotFinished;
#endif
	}
}
