using System;
using System.Collections;

namespace Sedulous.Profiler;

/// One thread's profiling state: the scopes it has open, and the ones it has closed this
/// frame. Owned by the profiler's registry, not by the thread, so it survives the thread
/// and can be drained at frame end.
class ProfileThreadData
{
	public int32 Index;
	/// Scopes closed this frame, drained by EndFrame.
	public List<ProfileSample> Samples = new .() ~ delete _;
	/// Scopes currently open, innermost last.
	public List<ActiveScope> Stack = new .() ~ delete _;

	public struct ActiveScope
	{
		public StringView Name;
		public int64 StartTick;
		public int32 Depth;
	}
}
