using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Pulls particles toward a point, or pushes them away when the strength is negative.
[Serializable]
class AttractorBehavior : ParticleBehavior
{
	public float Strength = 1.0f;
	public Float3 Position = .(0, 0, 0);
	/// Beyond this the pull falls off with distance. Zero means no falloff at all.
	public float Radius = 0.0f;

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

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let delta = Position - positions[i];
			let distance = Length(delta);
			// A particle sitting ON the attractor has no direction to be pulled in.
			if (distance < 1.0e-4f)
				continue;

			var strength = Strength;
			if ((Radius > 0.0f) && (distance > Radius))
				strength *= Radius / distance;
			velocities[i] += (delta / distance) * (strength * context.DeltaTime);
		}
	}
}
