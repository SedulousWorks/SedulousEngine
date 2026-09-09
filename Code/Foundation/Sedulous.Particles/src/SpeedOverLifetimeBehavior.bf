using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Rescales speed to a curve MULTIPLE of the particle's starting speed, keeping whatever
/// direction the forces have left it pointing.
///
/// Measured against the start velocity rather than the current one, so this does not compound
/// with itself frame over frame the way scaling the live speed would.
[Serializable]
class SpeedOverLifetimeBehavior : ParticleBehavior
{
	public ParticleCurveFloat Curve = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
		streams.EnsureStream(.StartVelocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		if (!Curve.IsActive)
			return;

		let velocities = streams.Velocities;
		let starts = streams.StartVelocities;
		if ((velocities == null) || (starts == null))
			return;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let velocity = velocities[i];
			let length = Length(velocity);
			// A stopped particle has no direction to rescale along, and would divide by
			// nothing.
			if (length < 1.0e-6f)
				continue;
			let target = Length(starts[i]) * Curve.Evaluate(streams.GetLifeRatio(i));
			velocities[i] = (velocity / length) * target;
		}
	}
}
