using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Gives a particle its starting colour.
[Serializable]
class ColorInitializer : ParticleInitializer
{
	public RangeColor Color = .Constant(.(1, 1, 1, 1));

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Color, .Float4);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		streams.Colors[index] = Color.Evaluate(context.Rng.NextFloat());
	}
}
