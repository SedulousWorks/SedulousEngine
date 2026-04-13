namespace Sedulous.Particles;

using System;

/// GPU-side particle stream — wraps a storage buffer handle.
/// Placeholder for GPU compute simulation. Data lives on GPU and is
/// never read back to CPU (except for async readback of bounding boxes, etc.).
public class GPUStream : ParticleStream
{
	// TODO: IBuffer handle for the GPU storage buffer.
	// Will be filled in when GPU simulation is implemented.

	public override bool IsCPU => false;

	public this(ParticleStreamId id, StreamElementType elementType, int32 capacity)
		: base(id, elementType, capacity)
	{
	}
}
