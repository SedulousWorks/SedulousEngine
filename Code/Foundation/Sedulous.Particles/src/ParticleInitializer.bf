using Sedulous.Core;

namespace Sedulous.Particles;

/// Runs ONCE, on one freshly spawned particle.
///
/// Concrete initializers carry [Serializable], which is what gives them a type id and lets a
/// cooked effect rebuild them without naming their types.
abstract class ParticleInitializer
{
	/// Engine side: which pipelines run it, not a knob.
	[Hidden]
	public abstract BehaviorSupport Support { get; }

	/// Asks for the streams this module reads or writes. Idempotent, so several modules may
	/// want the same channel.
	public abstract void DeclareStreams(ParticleStreamContainer streams);

	public abstract void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context);
}
