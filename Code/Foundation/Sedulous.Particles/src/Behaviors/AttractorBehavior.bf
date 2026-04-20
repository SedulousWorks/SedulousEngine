namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Pulls (or repels) particles toward a point.
public class AttractorBehavior : ParticleBehavior
{
	/// Force strength (positive = attract, negative = repel).
	public float Strength = 1.0f;

	/// Attractor position in world space.
	public Vector3 Position = .Zero;

	/// Attractor radius - force falls off outside this distance.
	/// Set to 0 for no falloff.
	public float Radius = 0;

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

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let toAttractor = Position - positions[i];
			let dist = toAttractor.Length();

			if (dist > 0.001f)
			{
				var strength = Strength;
				if (Radius > 0 && dist > Radius)
					strength *= Radius / dist;

				let dir = toAttractor / dist;
				velocities[i] = velocities[i] + dir * strength * ctx.DeltaTime;
			}
		}
	}
}
