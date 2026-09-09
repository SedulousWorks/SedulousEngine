using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Spins a billboard: a starting angle and a rate, both in radians.
[Serializable]
class RotationInitializer : ParticleInitializer
{
	/// A full turn by default, so a sheet of sprites does not all face the same way.
	public RangeFloat Rotation = .(0.0f, 6.2831853f);
	public RangeFloat RotationSpeed = .(-2.0f, 2.0f);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Rotation, .Float);
		streams.EnsureStream(.RotationSpeed, .Float);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		streams.Rotations[index] = Rotation.Evaluate(context.Rng.NextFloat());
		streams.RotationSpeeds[index] = RotationSpeed.Evaluate(context.Rng.NextFloat());
	}
}
