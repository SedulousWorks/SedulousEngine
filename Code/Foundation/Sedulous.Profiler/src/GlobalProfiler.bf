using System;

namespace Sedulous.Profiler;

#if PROFILING || DEBUG || TEST
#define SEDULOUS_PROFILING
#endif

/// The process wide profiler, and the frontend that instrumentation actually calls.
///
/// The same exception the logger makes: threading a profiler through every subsystem that
/// might want to time something costs more than it buys. Ownership still flows down, and
/// code must tolerate its absence, since a unit test or a headless tool never installs
/// one.
///
/// This is where Raptor's PROFILE_SCOPE macros land. Beef has no macros, and does not need
/// them: [SkipCall] removes the call at the CALL SITE, arguments and all, so an
/// uninstrumented build pays nothing at all rather than paying for a check.
///
/// Profiling is compiled in for a debug or test build, and for any build that defines
/// PROFILING; a release build without it compiles these to nothing. PROFILING exists
/// because the build worth profiling is usually the optimised one.
///
/// A scope is bracketed with defer, which is Beef's answer to the RAII helper:
///
///     ProfileScopeBegin("Render");
///     defer ProfileScopeEnd();
///
/// Names must be literals or otherwise outlive the frame: samples borrow them.
static
{
	private static Profiler sGlobalProfiler;
	private static bool sOwnsGlobalProfiler;

	/// Installs the global profiler, replacing and, if owned, deleting any previous one.
	public static void InitGlobalProfiler(Profiler profiler, bool owns = false)
	{
		ShutdownGlobalProfiler();
		sGlobalProfiler = profiler;
		sOwnsGlobalProfiler = owns;
	}

	public static void ShutdownGlobalProfiler()
	{
		if (sOwnsGlobalProfiler && (sGlobalProfiler != null))
			delete sGlobalProfiler;
		sGlobalProfiler = null;
		sOwnsGlobalProfiler = false;
	}

	public static bool HasGlobalProfiler() => sGlobalProfiler != null;

	public static Profiler GlobalProfiler() => sGlobalProfiler;

#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public static void ProfileFrameBegin()
	{
		if (sGlobalProfiler != null)
			sGlobalProfiler.BeginFrame();
	}

#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public static void ProfileFrameEnd()
	{
		if (sGlobalProfiler != null)
			sGlobalProfiler.EndFrame();
	}

#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public static void ProfileScopeBegin(StringView name)
	{
		if (sGlobalProfiler != null)
			sGlobalProfiler.BeginScope(name);
	}

#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public static void ProfileScopeEnd()
	{
		if (sGlobalProfiler != null)
			sGlobalProfiler.EndScope();
	}
}
