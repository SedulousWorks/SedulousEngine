namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Applies gravitational acceleration to particle velocity.
public class GravityBehavior : ParticleBehavior
{
	/// Gravity multiplier (1.0 = Earth gravity at 9.81 m/s²).
	public float Multiplier = 1.0f;

	/// Gravity direction (default: negative Y).
	public Vector3 Direction = .(0, -1, 0);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let velocities = streams.Velocities;
		if (velocities == null) return;

		let gravity = Direction * (9.81f * Multiplier * ctx.DeltaTime);
		for (int32 i = 0; i < streams.AliveCount; i++)
			velocities[i] = velocities[i] + gravity;
	}
}
