using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Integrates the rotation stream, with the curve SCALING the per particle rate rather than
/// setting the angle.
///
/// So an inactive curve still spins: the behaviour is what advances rotation at all, and a
/// system with a rotation initializer and no curve should turn at its authored speed.
[DisplayName("Rotation over Lifetime")]
[Serializable]
class RotationOverLifetimeBehavior : ParticleBehavior
{
	public ParticleCurveFloat Curve = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Rotation, .Float);
		streams.EnsureStream(.RotationSpeed, .Float);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		let rotations = streams.Rotations;
		let speeds = streams.RotationSpeeds;
		if ((rotations == null) || (speeds == null))
			return;

		let active = Curve.IsActive;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let scale = active ? Curve.Evaluate(streams.GetLifeRatio(i)) : 1.0f;
			rotations[i] += speeds[i] * scale * context.DeltaTime;
		}
	}
}
