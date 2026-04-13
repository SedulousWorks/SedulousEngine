namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Initializes particle color from a constant or random range.
public class ColorInitializer : ParticleInitializer
{
	/// Initial color range (component-wise lerp between min and max).
	public RangeColor Color = .Constant(.(1, 1, 1, 1));

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Color, .Float4);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		let t = (float)rng.NextDouble();
		streams.Colors[index] = Color.Evaluate(t);
	}
}
