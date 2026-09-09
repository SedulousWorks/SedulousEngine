using System;

namespace Sedulous.Particles;

/// A stream in system memory: one flat array of `capacity` elements.
class CPUStream<T> : ParticleStream where T : struct
{
	private T[] mData ~ delete _;

	public this(ParticleStreamId id, StreamElementType elementType, int32 capacity)
		: base(id, elementType, capacity)
	{
		mData = new T[capacity];
	}

	public override bool IsCPU => true;

	public ref T this[int32 index] => ref mData[index];

	public T* Ptr => mData.Ptr;

	/// The live prefix, which is what every behaviour walks.
	public Span<T> Slice(int32 count) => .(mData.Ptr, count);

	public override void SwapRemoveElement(int32 index, int32 aliveCount)
	{
		let last = aliveCount - 1;
		if (index < last)
			mData[index] = mData[last];
	}
}
