namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Integrates velocity into position and advances particle age.
/// This is a core behavior that should be added to every system.
/// It runs after all force/acceleration behaviors have been applied.
public class VelocityIntegrationBehavior : ParticleBehavior
{
	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let positions = streams.Positions;
		let velocities = streams.Velocities;
		let ages = streams.Ages;
		if (positions == null || velocities == null || ages == null) return;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			positions[i] = positions[i] + velocities[i] * ctx.DeltaTime;
			ages[i] += ctx.DeltaTime;
		}
	}
}
