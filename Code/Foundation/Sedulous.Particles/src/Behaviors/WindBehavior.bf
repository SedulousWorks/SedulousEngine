namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Applies a constant directional wind force to particles.
public class WindBehavior : ParticleBehavior
{
	/// Wind direction and strength (vector magnitude = force).
	public Vector3 Force = .(1, 0, 0);

	/// Wind turbulence - randomized variation applied each frame.
	public float Turbulence = 0;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let velocities = streams.Velocities;
		if (velocities == null) return;

		var force = Force;
		if (Turbulence > 0 && ctx.Rng != null)
		{
			force = force + Vector3(
				(float)(ctx.Rng.NextDouble() * 2.0 - 1.0) * Turbulence,
				(float)(ctx.Rng.NextDouble() * 2.0 - 1.0) * Turbulence,
				(float)(ctx.Rng.NextDouble() * 2.0 - 1.0) * Turbulence
			);
		}

		let impulse = force * ctx.DeltaTime;
		for (int32 i = 0; i < streams.AliveCount; i++)
			velocities[i] = velocities[i] + impulse;
	}
}
