using System;

namespace Sedulous.Profiler;

/// Backend interface for processing profiler data.
/// Implementations can output to console, file, network, or visualization tools.
interface IProfilerBackend
{
	/// Called when a frame's profiling data is complete.
	void OnFrameComplete(ProfileFrame frame);

	/// Called when the profiler is shutting down.
	void OnShutdown();
}
