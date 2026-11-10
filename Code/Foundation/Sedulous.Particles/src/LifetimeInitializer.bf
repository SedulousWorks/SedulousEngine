using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Sets how long a particle lives, and starts its age at nothing.
[DisplayName("Lifetime")]
[Serializable]
class LifetimeInitializer : ParticleInitializer
{
	public RangeFloat Lifetime = .(1.0f, 1.0f);

	public override BehaviorSupport Support => .Both;

	// Age and Lifetime are core streams.
	public override void DeclareStreams(ParticleStreamContainer streams) {}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		// FLOORED, because a zero lifetime divides through every life ratio and makes a
		// particle that is dead before it is drawn.
		streams.Lifetimes[index] = Max(Lifetime.Evaluate(context.Rng.NextFloat()), 0.01f);
		streams.Ages[index] = 0.0f;
	}
}
