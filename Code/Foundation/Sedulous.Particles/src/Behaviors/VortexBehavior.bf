namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Applies a rotational vortex force around an axis.
public class VortexBehavior : ParticleBehavior
{
	/// Rotational strength (radians/sec at unit distance).
	public float Strength = 1.0f;

	/// Vortex center offset from emitter.
	public Vector3 Center = .Zero;

	/// Vortex axis (default: Y-up).
	public Vector3 Axis = .(0, 1, 0);

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

		let axis = Vector3.Normalize(Axis);
		let strengthDt = Strength * ctx.DeltaTime;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let toParticle = positions[i] - Center;
			let projDist = Vector3.Dot(toParticle, axis);
			let inPlane = toParticle - axis * projDist;
			let dist = inPlane.Length();

			if (dist > 0.001f)
			{
				let radial = inPlane / dist;
				let tangent = Vector3.Cross(axis, radial);
				let force = tangent * strengthDt / Math.Max(dist, 0.1f);
				velocities[i] = velocities[i] + force;
			}
		}
	}
}
