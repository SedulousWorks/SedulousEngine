using System;

namespace Sedulous.Profiler;

#if PROFILING || DEBUG || TEST
#define SEDULOUS_PROFILING
#endif

/// What ProfileScope hands to a using statement. Closing the block closes the scope.
///
/// Empty: the profiler keeps the open scope on its own per thread stack, so the token
/// carries nothing and costs nothing to pass around. When profiling is compiled out the
/// call that produces it is skipped along with this Dispose, so the whole using statement
/// disappears rather than becoming a pair of empty calls.
struct ProfileScopeToken : IDisposable
{
#if !SEDULOUS_PROFILING
	[SkipCall]
#endif
	public void Dispose()
	{
		ProfileScopeEnd();
	}
}
