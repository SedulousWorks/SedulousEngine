namespace Sedulous.Particles;

/// A stream's identity, element type and capacity, plus a type erased swap remove so the
/// container can compact without knowing what it holds.
abstract class ParticleStream
{
	private ParticleStreamId mId;
	private StreamElementType mElementType;
	private int32 mCapacity;

	public this(ParticleStreamId id, StreamElementType elementType, int32 capacity)
	{
		mId = id;
		mElementType = elementType;
		mCapacity = capacity;
	}

	public ParticleStreamId Id => mId;
	public StreamElementType ElementType => mElementType;
	public int32 Capacity => mCapacity;

	public abstract bool IsCPU { get; }
	public bool IsGPU => !IsCPU;

	/// Moves the last live element over `index`. The CALLER shrinks the alive count.
	public abstract void SwapRemoveElement(int32 index, int32 aliveCount);
}
