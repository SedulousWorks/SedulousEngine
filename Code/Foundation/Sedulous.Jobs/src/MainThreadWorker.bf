using System;

namespace Sedulous.Jobs;

using internal Sedulous.Jobs;

/// Worker that processes jobs on the main thread.
internal class MainThreadWorker : Worker
{
	public this(JobSystem jobSystem, StringView name)
		: base(jobSystem, name, .Persistent)
	{
	}

	public override void Update()
	{
		ProcessJobs();
	}
}
