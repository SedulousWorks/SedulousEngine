using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Pushes particles straight out from the emitter, which is what an explosion does.
[Serializable]
class RadialForceBehavior : ParticleBehavior
{
	public float Strength = 1.0f;

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
			let delta = positions[i] - context.EmitterPosition;
			// A particle exactly at the emitter has no outward to push along.
			if (LengthSquared(delta) < 1.0e-8f)
				continue;
			velocities[i] += Normalized(delta) * (Strength * context.DeltaTime);
		}
	}
}
