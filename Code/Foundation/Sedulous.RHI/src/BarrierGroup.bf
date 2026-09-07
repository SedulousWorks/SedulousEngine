using System;

namespace Sedulous.RHI;

/// Barriers submitted TOGETHER.
///
/// Together because a backend merges them into one pipeline barrier: issuing them
/// separately serialises what could have been a single stall.
struct BarrierGroup
{
	public Span<BufferBarrier> BufferBarriers = default;
	public Span<TextureBarrier> TextureBarriers = default;
	public Span<MemoryBarrier> MemoryBarriers = default;

	public this() {}
}
