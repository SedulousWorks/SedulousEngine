using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Swings particles around an axis. The push falls off with distance, so the core spins fast
/// and the fringe drifts.
[Serializable]
class VortexBehavior : ParticleBehavior
{
	public float Strength = 1.0f;
	public Float3 Center = .(0, 0, 0);
	public Float3 Axis = .(0, 1, 0);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		let velocities = streams.Velocities;
		let positions = streams.Positions;
		if ((velocities == null) || (positions == null))
			return;

		let axis = (LengthSquared(Axis) > 1.0e-6f) ? Normalized(Axis) : Float3.UnitY;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let radial = positions[i] - Center;
			let tangent = Cross(axis, radial);
			// FLOORED, so a particle at the axis does not divide by nothing and fly off.
			let distance = Max(Length(radial), 0.1f);
			velocities[i] += tangent * (Strength * context.DeltaTime / distance);
		}
	}
}
