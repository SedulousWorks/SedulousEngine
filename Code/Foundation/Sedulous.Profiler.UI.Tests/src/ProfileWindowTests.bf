using System;
using System.Collections;
using Sedulous.Profiler;
using Sedulous.Profiler.UI;

namespace Sedulous.Profiler.UI.Tests;

/// What the views show, computed from a source of known frames: frame times and their
/// statistics, the longest scopes and passes, and the counters as text.
class ProfileWindowTests
{
	public static bool Near(double a, double b) => Math.Abs(a - b) <= 1e-4 * Math.Max(1.0, Math.Abs(b));

	[Test]
	public static void TheNewestFramesTimesAndStatistics()
	{
		let source = scope KnownSource();
		Test.Assert(ProfileWindow.LastFrames(source, 10).Empty);
		let forward = source.Name("forward");
		for (let ms in int64[4](10, 20, 30, 40))
		{
			let frame = source.AddFrame(ms);
			if (ms != 40) // the newest frame's GPU passes have not arrived
			{
				KnownSource.AddPass(frame, forward, 1, 1 + ms / 2);
				KnownSource.AddPass(frame, forward, 2, 3); // inside the first: the span is unchanged
			}
		}

		let range = ProfileWindow.LastFrames(source, 3);
		Test.Assert(!range.Empty);
		Test.Assert((range.First == 1) && (range.Last == 3));
		Test.Assert(ProfileWindow.LastFrames(source, 100).First == 0, "no further back than the source holds");

		let times = scope List<FrameTime>();
		ProfileWindow.CollectFrameTimes(source, range, times);
		Test.Assert(times.Count == 3);
		Test.Assert(times[0].Frame == 1);
		Test.Assert(Near(times[0].CpuMs, 20.0));
		Test.Assert(times[0].HasGpu);
		Test.Assert(Near(times[0].GpuMs, 10.0));
		Test.Assert(Near(times[2].CpuMs, 40.0));
		Test.Assert(!times[2].HasGpu);

		let stats = ProfileWindow.StatsOf(times);
		Test.Assert(stats.Cpu.Count == 3);
		Test.Assert(Near(stats.Cpu.Min, 20.0));
		Test.Assert(Near(stats.Cpu.Median, 30.0));
		Test.Assert(Near(stats.Cpu.Max, 40.0));
		Test.Assert(Near(stats.Cpu.Mean, 30.0));
		Test.Assert(stats.Gpu.Count == 2, "only the frames whose passes arrived");
		Test.Assert(Near(stats.Gpu.Max, 15.0));
	}

	[Test]
	public static void ScopesRankByTheirOwnTimePassesByTheirs()
	{
		let source = scope KnownSource();
		let update = source.Name("Update");
		let physics = source.Name("Physics");
		let audio = source.Name("Audio");
		let render = source.Name("Render");
		let shadows = source.Name("shadows");
		let forward = source.Name("forward");
		for (int f < 2)
		{
			let frame = source.AddFrame(16);
			// In the order they end: Update (0..10) holds Physics (1..6) and Audio (6..7, 7..8).
			KnownSource.AddScope(frame, physics, 1, 1, 6);
			KnownSource.AddScope(frame, audio, 1, 6, 7);
			KnownSource.AddScope(frame, audio, 1, 7, 8);
			KnownSource.AddScope(frame, update, 0, 0, 10);
			KnownSource.AddScope(frame, render, 0, 10, 14);
			KnownSource.AddPass(frame, shadows, 0, 2);
			KnownSource.AddPass(frame, forward, 2, 9);
		}

		let top = scope List<TopEntry>();
		ProfileWindow.CollectTop(source, ProfileWindow.LastFrames(source, 2), .Scopes, 3, top);
		Test.Assert(top.Count == 3, "four names, the three longest kept");
		Test.Assert((top[0].Name == physics) && Near(top[0].MsPerFrame, 5.0));
		Test.Assert((top[1].Name == render) && Near(top[1].MsPerFrame, 4.0));
		Test.Assert((top[2].Name == update) && Near(top[2].MsPerFrame, 3.0), "10 ms less its children's 7");

		ProfileWindow.CollectTop(source, ProfileWindow.LastFrames(source, 2), .Scopes, 10, top);
		Test.Assert(top.Count == 4);
		Test.Assert((top[3].Name == audio) && Near(top[3].MsPerFrame, 2.0) && Near(top[3].CallsPerFrame, 2.0));

		ProfileWindow.CollectTop(source, ProfileWindow.LastFrames(source, 2), .GpuPasses, 10, top);
		Test.Assert(top.Count == 2);
		Test.Assert((top[0].Name == forward) && Near(top[0].MsPerFrame, 7.0));
		Test.Assert(top[1].Name == shadows);
	}

	private static bool Formats(double value, CounterUnit unit, StringView expected)
	{
		let text = ProfileWindow.FormatCounter(value, unit, .. scope .());
		if (text != expected)
			Console.WriteLine(scope $"{value} as {unit}: '{text}', not '{expected}'");
		return text == expected;
	}

	[Test]
	public static void CountersNewestValuesAndMeansAsTextInTheirUnit()
	{
		let source = scope KnownSource();
		let draws = source.Counter("Draws", .Count);
		let memory = source.Counter("Texture memory", .Bytes);
		source.Counter("Never set", .Count);
		for (let v in double[3](10.0, 20.0, 60.0))
		{
			let frame = source.AddFrame(16);
			frame.Counters.Add(.(draws, v));
			frame.Counters.Add(.(memory, v * 1024.0 * 1024.0));
		}
		let readings = scope List<CounterReading>();
		ProfileWindow.CollectCounters(source, ProfileWindow.LastFrames(source, 10), readings);
		Test.Assert(readings.Count == 3);
		Test.Assert(readings[0].Present);
		Test.Assert(Near(readings[0].Latest, 60.0));
		Test.Assert(Near(readings[0].Mean, 30.0));
		Test.Assert(Near(readings[1].Latest, 60.0 * 1024.0 * 1024.0));
		Test.Assert(!readings[2].Present);

		Test.Assert(Formats(183.4, .Count, "183"));
		Test.Assert(Formats(512.0, .Bytes, "0.5 KiB"));
		Test.Assert(Formats(3.0 * 1024 * 1024, .Bytes, "3.0 MiB"));
		Test.Assert(Formats(6.0 * 1024 * 1024 * 1024, .Bytes, "6.00 GiB"));
		Test.Assert(Formats(1.5, .Milliseconds, "1.50 ms"));
		Test.Assert(Formats(42.34, .Percent, "42.3%"));
	}
}
