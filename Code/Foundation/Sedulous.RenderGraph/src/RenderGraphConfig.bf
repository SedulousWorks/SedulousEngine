namespace Sedulous.RenderGraph;

/// How the graph itself is set up.
struct RenderGraphConfig
{
	/// The multi buffering slots, which is what the transient pools and the profiler's
	/// query sets are sized for. Two or three in practice.
	public int32 FrameBufferCount = 2;

	public this() {}

	public this(int32 frameBufferCount)
	{
		FrameBufferCount = frameBufferCount;
	}
}
