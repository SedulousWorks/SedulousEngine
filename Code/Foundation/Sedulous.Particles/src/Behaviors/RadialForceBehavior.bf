namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Pushes particles radially away from (or toward) the emitter origin.
public class RadialForceBehavior : ParticleBehavior
{
	/// Force strength (positive = outward, negative = inward).
	public float Strength = 1.0f;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let positions = streams.Positions;
		let velocities = streams.Velocities;
		if (positions == null || velocities == null) return;

		let strengthDt = Strength * ctx.DeltaTime;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let fromEmitter = positions[i] - ctx.EmitterPosition;
			let dist = fromEmitter.Length();
			if (dist > 0.001f)
			{
				let dir = fromEmitter / dist;
				velocities[i] = velocities[i] + dir * strengthDt;
			}
		}
	}
}
