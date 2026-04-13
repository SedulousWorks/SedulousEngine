namespace Sedulous.Particles;

using System;

/// Base class for particle simulation backends.
/// Concrete subclasses execute behaviors on particle streams using
/// either CPU loops (CPUSimulator) or GPU compute dispatches (GPUSimulator).
public abstract class ParticleSimulator
{
	/// Simulates all alive particles for one frame.
	/// Called by ParticleSystem after spawning.
	public abstract void Simulate(
		ParticleStreamContainer streams,
		Span<ParticleBehavior> behaviors,
		ref ParticleUpdateContext ctx);

	/// Removes dead particles after simulation.
	/// Returns the number of particles that died.
	public abstract int32 CompactDead(ParticleStreamContainer streams);
}
