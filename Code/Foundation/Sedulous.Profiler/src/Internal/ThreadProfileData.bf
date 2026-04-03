using System;
using System.Collections;
using System.Threading;
using System.Diagnostics;

namespace Sedulous.Profiler.Internal;

/// Per-thread profiling state.
class ThreadProfileData
{
	/// Thread ID this data belongs to.
	public readonly int32 ThreadId;
	/// Stack of active sample start times (for nested scopes).
	public List<int64> StartTimeStack = new .() ~ delete _;
	/// Stack of sample names (for nested scopes).
	public List<StringView> NameStack = new .() ~ delete _;
	/// Stack of parent indices (for nested scopes).
	public List<int32> ParentIndexStack = new .() ~ delete _;
	/// Current depth in the profiling hierarchy.
	public int32 CurrentDepth = 0;
	/// Index of the last sample added by this thread.
	public int32 LastSampleIndex = -1;

	public this(int32 threadId)
	{
		ThreadId = threadId;
	}

	/// Clears state for new frame.
	public void Clear()
	{
		StartTimeStack.Clear();
		NameStack.Clear();
		ParentIndexStack.Clear();
		CurrentDepth = 0;
		LastSampleIndex = -1;
	}

	/// Begin a new profiling scope.
	public void BeginScope(StringView name, int64 startTicks)
	{
		StartTimeStack.Add(startTicks);
		NameStack.Add(name);
		// Parent of this scope is the last sample we added (or -1 if none)
		ParentIndexStack.Add(LastSampleIndex);
		CurrentDepth++;
	}

	/// End the current profiling scope, returning scope info.
	public bool EndScope(out StringView name, out int64 startTicks, out int32 depth, out int32 parentIndex)
	{
		if (StartTimeStack.Count == 0)
		{
			name = default;
			startTicks = 0;
			depth = 0;
			parentIndex = -1;
			return false;
		}

		startTicks = StartTimeStack.PopBack();
		name = NameStack.PopBack();
		parentIndex = ParentIndexStack.PopBack();
		CurrentDepth--;
		depth = CurrentDepth;
		return true;
	}
}
