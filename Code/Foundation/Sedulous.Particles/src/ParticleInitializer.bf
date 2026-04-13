using System;
namespace Sedulous.Particles;

/// Base class for particle initializers.
/// Initializers run once when a particle is spawned, setting its initial values.
public abstract class ParticleInitializer
{
	/// Which simulation backends this initializer supports.
	public abstract BehaviorSupport Support { get; }

	/// Called once when the initializer is attached to a system.
	/// Declare required streams here via streams.EnsureStream() calls.
	public abstract void DeclareStreams(ParticleStreamContainer streams);

	/// Called once per newly spawned particle to set initial values.
	/// `index` is the particle's slot in the stream arrays.
	public abstract void Initialize(ParticleStreamContainer streams, int32 index, Random rng);
}