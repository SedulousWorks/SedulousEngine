namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Scales particle speed over its lifetime using a float curve.
/// The curve value multiplies the initial speed (from StartVelocity).
public class SpeedOverLifetimeBehavior : ParticleBehavior
{
	/// Speed multiplier curve evaluated at normalized particle age [0, 1].
	public ParticleCurveFloat Curve;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
		streams.EnsureStream(.StartVelocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		if (!Curve.IsActive) return;
		let velocities = streams.Velocities;
		let startVelocities = streams.StartVelocities;
		if (velocities == null || startVelocities == null) return;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let t = streams.GetLifeRatio(i);
			let speedMul = Curve.Evaluate(t);
			let currentSpeed = velocities[i].Length();
			if (currentSpeed > 0.0001f)
			{
				let desiredSpeed = startVelocities[i].Length() * speedMul;
				velocities[i] = velocities[i] * (desiredSpeed / currentSpeed);
			}
		}
	}
}
