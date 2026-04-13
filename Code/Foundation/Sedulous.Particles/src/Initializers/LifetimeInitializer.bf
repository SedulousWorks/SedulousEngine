namespace Sedulous.Particles;

using System;

/// Initializes particle lifetime with optional variance.
public class LifetimeInitializer : ParticleInitializer
{
	/// Base lifetime in seconds.
	public RangeFloat Lifetime = .(1.0f, 1.0f);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		// Age and Lifetime are core streams, always allocated
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		let t = (float)rng.NextDouble();
		streams.Lifetimes[index] = Math.Max(Lifetime.Evaluate(t), 0.01f);
		streams.Ages[index] = 0;
	}
}
