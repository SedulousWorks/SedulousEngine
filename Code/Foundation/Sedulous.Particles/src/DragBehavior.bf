using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Bleeds speed away. Linear rather than quadratic, and FLOORED at zero so a large drag over
/// a large step slows a particle to a stop rather than reversing it.
[Serializable]
class DragBehavior : ParticleBehavior
{
	public float Drag = 1.0f;

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

		let factor = Max(1.0f - Drag * context.DeltaTime, 0.0f);
		for (int32 i = 0; i < streams.AliveCount; i++)
			velocities[i] *= factor;
	}
}
