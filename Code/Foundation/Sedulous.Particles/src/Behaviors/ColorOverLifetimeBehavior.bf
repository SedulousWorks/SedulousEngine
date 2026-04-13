namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Modifies particle color over its lifetime using a color curve.
public class ColorOverLifetimeBehavior : ParticleBehavior
{
	/// Color curve evaluated at normalized particle age [0, 1].
	public ParticleCurveColor Curve;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Color, .Float4);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		if (!Curve.IsActive) return;
		let colors = streams.Colors;
		if (colors == null) return;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let t = streams.GetLifeRatio(i);
			colors[i] = Curve.Evaluate(t);
		}
	}
}
