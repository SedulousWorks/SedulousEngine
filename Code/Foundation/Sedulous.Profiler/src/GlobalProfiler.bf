using System;
using Sedulous.Core;

namespace Sedulous.Profiler;

#if !SHIPPING
#define SEDULOUS_PROFILING
#endif

/// The process wide profiler, and the frontend that instrumentation actually calls.
///
/// The same exception the logger makes: threading a profiler through every subsystem that
/// might want to time something costs more than it buys. Ownership still flows down, and
/// code must tolerate its absence, since a unit test or a headless tool never installs
/// one.
///
/// Instrumentation lands here rather than in a macro. Beef has no macros, and does not need
/// them: [SkipCall] removes the call at the CALL SITE, arguments and all, so an
/// uninstrumented build pays nothing at all rather than paying for a check.
///
/// Profiling is compiled into every build but the shipping one (the ShippingRelease config,
/// which defines SHIPPING and builds the export templates): Release keeps it, since Release is
/// where timings mean something. In shipping these compile to nothing.
///
/// A scope is bracketed with using, which is Beef's answer to the RAII helper:
///
///     using (ProfileScope("Render"))
///     {
///         ...
///     }
///
/// That form is free too: a skipped call still type checks as a value, so when profiling
/// is compiled out the factory, the argument and the Dispose all go, and the using
/// statement is gone with them.
///
/// Nothing is recorded until the profiler is ARMED (Profiler.Arm), and a name is copied into
/// the profiler's table, so a name made at run time is as good as a literal.
static
{
	private static Profiler sGlobalProfiler;
	private static bool sOwnsGlobalProfiler;

	/// The job system's hooks: every job a JobSystem runs shows as a "Job" scope on its
	/// worker's lane, under which its own scopes nest.
	private static JobHooks sJobHooks = new .(
		() => (sGlobalProfiler != null) && sGlobalProfiler.BeginScope("Job"),
		() => { if (sGlobalProfiler != null) sGlobalProfiler.EndScope(); }) ~ delete _;

	/// Installs the global profiler, replacing and, if owned, deleting any previous one; every
	/// job system's jobs show in it from then on.
	public static void InitGlobalProfiler(Profiler profiler, bool owns = false)
	{
		ShutdownGlobalProfiler();
		sGlobalProfiler = profiler;
		sOwnsGlobalProfiler = owns;
		if (profiler != null)
			JobHooks.Set(sJobHooks);
	}

	public static void ShutdownGlobalProfiler()
	{
		if (JobHooks.Current == sJobHooks)
			JobHooks.Set(null);
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

	/// Opens a scope that the token closes; it closes only what it opened, so arming or
	/// disarming inside it leaves the thread's nesting balanced.
#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public static ProfileScopeToken ProfileScope(StringView name)
	{
		return .((sGlobalProfiler != null) && sGlobalProfiler.BeginScope(name));
	}
}
