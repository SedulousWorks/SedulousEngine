namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Modifies particle size over its lifetime using a Vector2 curve.
public class SizeOverLifetimeBehavior : ParticleBehavior
{
	/// Size curve evaluated at normalized particle age [0, 1].
	public ParticleCurveVector2 Curve;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Size, .Float2);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		if (!Curve.IsActive) return;
		let sizes = streams.Sizes;
		if (sizes == null) return;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let t = streams.GetLifeRatio(i);
			sizes[i] = Curve.Evaluate(t);
		}
	}
}
