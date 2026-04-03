using System;
using System.Threading;

namespace Sedulous.Profiler.Tests;

class ProfilerTests
{
	[Test]
	public static void TestProfilerInitialization()
	{
		Profiler.Initialize();
		Test.Assert(Profiler.Enabled);

		Profiler.Shutdown();
		Test.Assert(!Profiler.Enabled);
	}

	[Test]
	public static void TestBasicProfiling()
	{
		Profiler.Initialize();
		defer Profiler.Shutdown();

		Profiler.BeginFrame();

		Profiler.BeginScope("TestScope");
		// Simulate some work
		Thread.Sleep(1);
		Profiler.EndScope();

		Profiler.EndFrame();

		let frame = Profiler.GetCompletedFrame();
		Test.Assert(frame != null);
		Test.Assert(frame.SampleCount == 1);
		Test.Assert(frame.Samples[0].Name == "TestScope");
		Test.Assert(frame.Samples[0].Depth == 0);
	}

	[Test]
	public static void TestNestedScopes()
	{
		Profiler.Initialize();
		defer Profiler.Shutdown();

		Profiler.BeginFrame();

		Profiler.BeginScope("Outer");
		Profiler.BeginScope("Inner");
		Profiler.EndScope();
		Profiler.EndScope();

		Profiler.EndFrame();

		let frame = Profiler.GetCompletedFrame();
		Test.Assert(frame.SampleCount == 2);

		// Inner should have depth 1, Outer depth 0
		// Order in samples list: Inner first (completed first), then Outer
		var innerFound = false;
		var outerFound = false;
		for (let sample in frame.Samples)
		{
			if (sample.Name == "Inner")
			{
				Test.Assert(sample.Depth == 1);
				innerFound = true;
			}
			else if (sample.Name == "Outer")
			{
				Test.Assert(sample.Depth == 0);
				outerFound = true;
			}
		}
		Test.Assert(innerFound && outerFound);
	}

	[Test]
	public static void TestProfileScope()
	{
		Profiler.Initialize();
		defer Profiler.Shutdown();

		Profiler.BeginFrame();

		{
			using (ProfileScope("ScopedTest"))
			{
				// Work
			}
		}

		Profiler.EndFrame();

		let frame = Profiler.GetCompletedFrame();
		Test.Assert(frame.SampleCount == 1);
		Test.Assert(frame.Samples[0].Name == "ScopedTest");
	}

	[Test]
	public static void TestProfilerBeginAPI()
	{
		Profiler.Initialize();
		defer Profiler.Shutdown();

		Profiler.BeginFrame();

		// Test the new Profiler.Begin() API that returns a scope
		using (Profiler.Begin("BeginAPITest"))
		{
			// Nested scope using same API
			using (Profiler.Begin("NestedBegin"))
			{
				// Work
			}
		}

		Profiler.EndFrame();

		let frame = Profiler.GetCompletedFrame();
		Test.Assert(frame.SampleCount == 2);

		// Verify both scopes were recorded
		var outerFound = false;
		var innerFound = false;
		for (let sample in frame.Samples)
		{
			if (sample.Name == "BeginAPITest")
				outerFound = true;
			else if (sample.Name == "NestedBegin")
				innerFound = true;
		}
		Test.Assert(outerFound && innerFound);
	}

	[Test]
	public static void TestDisabledProfiling()
	{
		Profiler.Initialize();
		Profiler.Enabled = false;
		defer { Profiler.Enabled = true; Profiler.Shutdown(); }

		Profiler.BeginFrame();
		Profiler.BeginScope("ShouldNotRecord");
		Profiler.EndScope();
		Profiler.EndFrame();

		// When disabled, GetCompletedFrame may still return the last frame
		// but we shouldn't have any new samples
	}

	[Test]
	public static void TestFrameNumber()
	{
		Profiler.Initialize();
		defer Profiler.Shutdown();

		let startFrame = Profiler.FrameNumber;

		Profiler.BeginFrame();
		Profiler.EndFrame();

		Test.Assert(Profiler.FrameNumber == startFrame + 1);

		Profiler.BeginFrame();
		Profiler.EndFrame();

		Test.Assert(Profiler.FrameNumber == startFrame + 2);
	}
}
