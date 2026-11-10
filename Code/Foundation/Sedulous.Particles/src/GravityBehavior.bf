using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A constant acceleration. The multiplier scales Earth gravity, so one is what a falling
/// thing does and a fraction is what dust does.
[DisplayName("Gravity")]
[Serializable]
class GravityBehavior : ParticleBehavior
{
	public float Multiplier = 1.0f;
	public Float3 Direction = .(0, -1, 0);

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

		let delta = Direction * (9.81f * Multiplier * context.DeltaTime);
		for (int32 i = 0; i < streams.AliveCount; i++)
			velocities[i] += delta;
	}
}
