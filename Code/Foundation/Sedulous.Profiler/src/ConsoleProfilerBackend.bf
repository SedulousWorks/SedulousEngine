using System;

namespace Sedulous.Profiler;

/// Simple backend that prints profiling data to the console.
class ConsoleProfilerBackend : IProfilerBackend
{
	private bool mVerbose;

	/// Create a console backend.
	/// If verbose is true, prints every sample. Otherwise just frame summary.
	public this(bool verbose = false)
	{
		mVerbose = verbose;
	}

	public void OnFrameComplete(ProfileFrame frame)
	{
		Console.WriteLine($"Frame {frame.FrameNumber}: {frame.FrameDurationMs:F2}ms ({frame.SampleCount} samples)");

		if (mVerbose && frame.SampleCount > 0)
		{
			for (let sample in frame.Samples)
			{
				let indent = scope String();
				for (int i = 0; i < sample.Depth; i++)
					indent.Append("  ");
				Console.WriteLine($"  {indent}{sample.Name}: {sample.DurationMs:F3}ms");
			}
		}
	}

	public void OnShutdown()
	{
		Console.WriteLine("Profiler shutdown");
	}
}
