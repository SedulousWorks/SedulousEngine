namespace Sedulous.Particles;

using System;

/// Identifies a well-known particle stream by index.
/// Custom streams can use values >= Custom.
public enum ParticleStreamId : uint8
{
	Position = 0,
	Velocity = 1,
	StartVelocity = 2,
	Color = 3,
	Size = 4,
	Age = 5,
	Lifetime = 6,
	Rotation = 7,
	RotationSpeed = 8,

	/// First index available for custom streams.
	Custom = 32,

	/// Maximum number of streams.
	MaxStreams = 64
}

/// Type tag for stream element types.
public enum StreamElementType : uint8
{
	Float,
	Float2,
	Float3,
	Float4,
	Int32
}

/// Abstract base for a particle data stream.
/// Concrete subclasses are CPUStream<T> (system-memory array) and
/// GPUStream (storage buffer handle, placeholder for GPU simulation).
public abstract class ParticleStream
{
	/// Stream identifier.
	public ParticleStreamId Id { get; private set; }

	/// Element type tag.
	public StreamElementType ElementType { get; private set; }

	/// Maximum number of elements.
	public int32 Capacity { get; private set; }

	protected this(ParticleStreamId id, StreamElementType elementType, int32 capacity)
	{
		Id = id;
		ElementType = elementType;
		Capacity = capacity;
	}

	/// Whether this is a CPU-side stream (system memory).
	public abstract bool IsCPU { get; }

	/// Whether this is a GPU-side stream (storage buffer).
	public bool IsGPU => !IsCPU;
}
