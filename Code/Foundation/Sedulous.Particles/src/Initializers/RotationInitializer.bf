namespace Sedulous.Particles;

using System;

/// Initializes particle rotation angle and rotation speed.
public class RotationInitializer : ParticleInitializer
{
	/// Initial rotation range in radians.
	public RangeFloat Rotation = .(0, Math.PI_f * 2.0f);

	/// Initial rotation speed range in radians/sec.
	public RangeFloat RotationSpeed = .(-2.0f, 2.0f);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Rotation, .Float);
		streams.EnsureStream(.RotationSpeed, .Float);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		streams.Rotations[index] = Rotation.Evaluate((float)rng.NextDouble());
		streams.RotationSpeeds[index] = RotationSpeed.Evaluate((float)rng.NextDouble());
	}
}
