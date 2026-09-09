using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A steady push with an optional per particle jitter, which is what keeps a wind from
/// moving every particle identically.
[Serializable]
class WindBehavior : ParticleBehavior
{
	public Float3 Force = .(1, 0, 0);
	public float Turbulence = 0.0f;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		let velocities = streams.Velocities;
		if (velocities == null)
			return;

		var rng = context.Rng;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let jitter = Float3(rng.NextFloat(-Turbulence, Turbulence),
				rng.NextFloat(-Turbulence, Turbulence),
				rng.NextFloat(-Turbulence, Turbulence));
			velocities[i] += (Force + jitter) * context.DeltaTime;
		}
	}
}
