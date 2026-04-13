namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Initializes particle size from a constant or random range.
public class SizeInitializer : ParticleInitializer
{
	/// Initial size range.
	public RangeVector2 Size = .Constant(.(0.1f, 0.1f));

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Size, .Float2);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		let t = (float)rng.NextDouble();
		streams.Sizes[index] = Size.Evaluate(t);
	}
}
