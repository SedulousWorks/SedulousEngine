using System;

namespace Sedulous.RenderGraph;

/// One pass's CPU RECORD cost for a frame.
///
/// The graph's execute is often CPU bound while the GPU sits idle, so the question of which
/// pass is slow to record is a different one from which pass is slow to run.
struct PassCpuTime
{
	/// BORROWED from the pass, which outlives the report but not the next frame's reset.
	public StringView Name = default;
	public int64 Ticks = 0;

	public this() {}

	public this(StringView name, int64 ticks)
	{
		Name = name;
		Ticks = ticks;
	}
}
