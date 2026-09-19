using Sedulous.Core;

namespace Sedulous.Particles;

/// Runs EVERY frame, over all live particles.
///
/// Velocity integration and ageing are not behaviours: the system does them as a fixed final
/// step, so a behaviour's writes to velocity always land before the position they move.
abstract class ParticleBehavior
{
	/// Engine side: which pipelines run it, not a knob.
	[Hidden]
	public abstract BehaviorSupport Support { get; }

	public abstract void DeclareStreams(ParticleStreamContainer streams);

	public abstract void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context);
}
