using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Gives a particle its starting size, in world units across.
[Serializable]
class SizeInitializer : ParticleInitializer
{
	public RangeFloat2 Size = .Constant(.(0.1f, 0.1f));

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Size, .Float2);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		streams.Sizes[index] = Size.Evaluate(context.Rng.NextFloat());
	}
}
