namespace Sedulous.Particles;

using System;

/// CPU-side particle stream - a typed system-memory array.
/// This is the primary stream type for CPU simulation.
public class CPUStream<T> : ParticleStream where T : struct
{
	/// Raw data array.
	public T[] Data ~ delete _;

	public override bool IsCPU => true;

	public this(ParticleStreamId id, StreamElementType elementType, int32 capacity)
		: base(id, elementType, capacity)
	{
		Data = new T[capacity];
	}

	/// Direct indexer for read/write access.
	public ref T this[int32 index] => ref Data[index];

	/// Gets a span over the alive portion.
	public Span<T> Slice(int32 count) => .(Data, 0, count);

	/// Swap element at index with the last alive element (for compaction).
	public void SwapRemove(int32 index, int32 aliveCount)
	{
		let last = aliveCount - 1;
		if (index < last)
			Data[index] = Data[last];
	}
}
