using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Places a particle by sampling the emission shape.
[DisplayName("Position")]
[Serializable]
class PositionInitializer : ParticleInitializer
{
	public EmissionShape Shape = .Point();
	/// Local space leaves the sample where the shape put it, so the whole system moves with
	/// its emitter. World space offsets by the emitter once, at spawn, and the particle then
	/// stays where it was born.
	public bool LocalSpace = false;

	public override BehaviorSupport Support => .Both;

	// Position is a core stream, so there is nothing to ask for.
	public override void DeclareStreams(ParticleStreamContainer streams) {}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		Float3 position;
		Float3 direction;
		Shape.Sample(ref *context.Rng, out position, out direction);
		streams.Positions[index] = LocalSpace ? position : (context.EmitterPosition + position);
	}
}
