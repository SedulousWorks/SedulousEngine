namespace Sedulous.Particles;

using System;

/// Scales particle rotation speed over its lifetime using a float curve.
public class RotationOverLifetimeBehavior : ParticleBehavior
{
	/// Rotation speed multiplier curve evaluated at normalized particle age [0, 1].
	public ParticleCurveFloat Curve;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Rotation, .Float);
		streams.EnsureStream(.RotationSpeed, .Float);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let rotations = streams.Rotations;
		let rotSpeeds = streams.RotationSpeeds;
		if (rotations == null || rotSpeeds == null) return;

		if (!Curve.IsActive)
		{
			for (int32 i = 0; i < streams.AliveCount; i++)
				rotations[i] += rotSpeeds[i] * ctx.DeltaTime;
		}
		else
		{
			for (int32 i = 0; i < streams.AliveCount; i++)
			{
				let t = streams.GetLifeRatio(i);
				let speedMul = Curve.Evaluate(t);
				rotations[i] += rotSpeeds[i] * speedMul * ctx.DeltaTime;
			}
		}
	}
}
