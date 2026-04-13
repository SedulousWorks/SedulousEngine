namespace Sedulous.Particles;

using System;

/// GPU simulation backend — dispatches compute shaders on storage buffers.
/// Placeholder for future GPU compute particle simulation.
public class GPUSimulator : ParticleSimulator
{
	public override void Simulate(
		ParticleStreamContainer streams,
		Span<ParticleBehavior> behaviors,
		ref ParticleUpdateContext ctx)
	{
		// TODO: For each behavior that supports GPU, dispatch its compute shader.
		// For behaviors that are CPU-only, fall back to CPU execution on readback data.
		// For now, this is a stub — GPU simulation will be implemented per-behavior.
	}

	public override int32 CompactDead(ParticleStreamContainer streams)
	{
		// TODO: GPU compaction via parallel prefix sum + scatter.
		// For now, fall back to CPU compaction.
		return streams.CompactDead();
	}
}
