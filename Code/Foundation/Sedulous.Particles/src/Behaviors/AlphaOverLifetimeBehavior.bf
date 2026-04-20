namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Multiplies particle alpha over its lifetime using a float curve.
/// Applied on top of the existing color alpha - does not replace it.
public class AlphaOverLifetimeBehavior : ParticleBehavior
{
	/// Alpha multiplier curve evaluated at normalized particle age [0, 1].
	public ParticleCurveFloat Curve;

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
			let alphaMul = Curve.Evaluate(t);
			var color = colors[i];
			color.W *= alphaMul;
			colors[i] = color;
		}
	}
}
