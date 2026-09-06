using System;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Tests;

/// The frontend instrumentation calls, and the mechanism that lets an uninstrumented
/// build pay nothing for it.
class GlobalProfilerTests
{
	[Test]
	public static void WithNoProfilerInstalledTheFrontendIsHarmless()
	{
		ShutdownGlobalProfiler();
		Test.Assert(!HasGlobalProfiler());

		// The whole point: a unit test or a headless tool never installs one, and the
		// instrumentation scattered through the engine still has to be callable.
		ProfileFrameBegin();
		ProfileScopeBegin("Nowhere");
		ProfileScopeEnd();
		ProfileFrameEnd();
	}

	[Test]
	public static void TheFrontendRecordsIntoTheInstalledProfiler()
	{
		let profiler = scope Profiler();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();

		Test.Assert(HasGlobalProfiler());
		Test.Assert(GlobalProfiler() == profiler);

		ProfileFrameBegin();
		{
			ProfileScopeBegin("Outer");
			defer ProfileScopeEnd();

			ProfileScopeBegin("Inner");
			ProfileScopeEnd();
		}
		ProfileFrameEnd();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 2, scope $"got {frame.Samples.Count}");
		Test.Assert(DepthOf(frame, "Outer") == 0);
		Test.Assert(DepthOf(frame, "Inner") == 1, "defer closed the outer scope after the inner one");
	}

	/// Installing replaces, and owning deletes. Not owning leaves the caller's profiler
	/// alone, which is what the scope allocated ones above depend on.
	[Test]
	public static void InstallingReplacesAndOwnershipDecidesTheDelete()
	{
		let borrowed = scope Profiler();
		InitGlobalProfiler(borrowed);

		// Owned, and installed over the borrowed one: the borrowed one is not touched.
		InitGlobalProfiler(new Profiler(), true);
		Test.Assert(GlobalProfiler() != borrowed);

		// Deletes the owned one rather than leaking it.
		ShutdownGlobalProfiler();
		Test.Assert(!HasGlobalProfiler());
		Test.Assert(GlobalProfiler() == null);

		// The borrowed one survived, since it was never owned.
		borrowed.BeginFrame();
		borrowed.EndFrame();
	}

	private static int32 DepthOf(ProfileFrame frame, StringView name)
	{
		for (let sample in frame.Samples)
		{
			if (sample.Name == name)
				return sample.Depth;
		}
		return -1;
	}
}
