using System;
using Sedulous.Profiler;

namespace Sedulous.Engine.DefaultApp.Tests;

/// An application installs the global profiler when there is none and takes it down with
/// itself; one it found installed (an editor's, which its Play-in-editor game shares, and which
/// the editor's profiler_capture holds) outlives it.
class ProfilerOwnershipTests
{
	[Test]
	public static void AnApplicationTakesDownOnlyTheProfilerItInstalled()
	{
		ShutdownGlobalProfiler();
		{
			let host = scope StubHost();
			let app = scope DefaultApplication();
			app.OnStartup(host);
			Test.Assert(HasGlobalProfiler(), "none was installed: the application installs one");
			app.OnShutdown(host);
			Test.Assert(!HasGlobalProfiler(), "and takes it down");
		}

		let editors = new Sedulous.Profiler.Profiler();
		InitGlobalProfiler(editors, true);
		defer ShutdownGlobalProfiler();
		{
			let host = scope StubHost();
			let app = scope DefaultApplication();
			app.OnStartup(host);
			Test.Assert(GlobalProfiler() == editors, "the one installed is kept");
			app.OnShutdown(host);
			Test.Assert(GlobalProfiler() == editors, "and outlives the application");
		}
	}
}
