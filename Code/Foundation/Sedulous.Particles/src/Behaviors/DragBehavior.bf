namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Applies velocity damping (drag) to particles.
public class DragBehavior : ParticleBehavior
{
	/// Drag coefficient. Higher values slow particles faster.
	public float Drag = 1.0f;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let velocities = streams.Velocities;
		if (velocities == null) return;

		let factor = Math.Max(1.0f - Drag * ctx.DeltaTime, 0.0f);
		for (int32 i = 0; i < streams.AliveCount; i++)
			velocities[i] = velocities[i] * factor;
	}
}
