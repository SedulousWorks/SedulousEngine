using System;

namespace Sedulous.Profiler;

#if !SHIPPING
#define SEDULOUS_PROFILING
#endif

/// What ProfileScope hands to a using statement. Closing the block closes the scope, if it
/// opened one: a scope begun while the profiler was unarmed opened nothing, and closing it
/// after an Arm inside must not close the thread's enclosing scope instead.
///
/// When profiling is compiled out the call that produces it is skipped along with this
/// Dispose, so the whole using statement disappears.
struct ProfileScopeToken : IDisposable
{
	private bool mBegan;

	public this(bool began)
	{
		mBegan = began;
	}

#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public void Dispose()
	{
		if (mBegan && HasGlobalProfiler())
			GlobalProfiler().EndScope();
	}
}
