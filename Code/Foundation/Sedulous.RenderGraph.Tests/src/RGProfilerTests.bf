using System;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The GPU profiler, which is optional and has to be harmless when it is off.
class RGProfilerTests
{
	/// An uninitialised profiler answers zero and records nothing, so a caller that never
	/// turned it on can still ask.
	[Test]
	public static void AnUninitialisedProfilerIsInert()
	{
		let profiler = scope GraphProfiler();

		Test.Assert(!profiler.IsInitialized);
		Test.Assert(profiler.GetPassTimeMs(0) == 0.0f);
		Test.Assert(profiler.GetPassTimeMs(-1) == 0.0f);
		Test.Assert(profiler.GetPassTimeMs(1000) == 0.0f);

		let report = scope String();
		profiler.ReadResults(4, report);
		Test.Assert(report.IsEmpty, "nothing was measured, so there is nothing to say");
	}

	/// A graph with no device cannot profile, and asking for it is not an error.
	[Test]
	public static void AGraphWithNoDeviceCannotProfile()
	{
		let graph = scope RenderGraph(null);
		graph.EnableGpuProfiling();
		Test.Assert(graph.GpuProfiler == null);
	}

	/// With a device it comes up, and turning it on twice is the same as once.
	[Test]
	public static void EnablingProfilingIsIdempotent()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		let graph = scope RenderGraph(device);
		graph.EnableGpuProfiling();
		let first = graph.GpuProfiler;

		graph.EnableGpuProfiling();
		Test.Assert(graph.GpuProfiler == first);
	}

	/// The CPU report is empty when nothing was profiled, and says so rather than being
	/// blank.
	[Test]
	public static void TheCpuReportHasATotalEvenWithNoPasses()
	{
		let graph = scope RenderGraph(null);

		let report = scope String();
		graph.AppendCpuPassReport(report);
		Test.Assert(report.Contains("TOTAL (pass record)"));
	}
}
