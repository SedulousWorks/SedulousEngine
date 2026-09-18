using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Gives a particle its starting velocity, and records it: the start velocity is what a
/// speed-over-lifetime curve scales, so it has to survive whatever the forces do.
[DisplayName("Velocity")]
[Serializable]
class VelocityInitializer : ParticleInitializer
{
	public Float3 BaseVelocity = .(0, 1, 0);
	/// Per axis half widths of a uniform jitter.
	public Float3 Randomness = .(0, 0, 0);
	/// How fast the particle leaves along the shape's OWN outward direction, which is what
	/// makes a cone a cone rather than a disc of parallel particles.
	public float ShapeDirectionSpeed = 0.0f;
	/// How much of the emitter's velocity the particle carries away.
	public float VelocityInheritance = 0.0f;
	/// Sampled only for its direction. Usually a copy of the position initializer's shape.
	public EmissionShape Shape = .Point();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
		streams.EnsureStream(.StartVelocity, .Float3);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		Float3 position;
		Float3 direction;
		Shape.Sample(ref *context.Rng, out position, out direction);

		var rng = context.Rng;
		let jitter = Float3(rng.NextFloat(-Randomness.X, Randomness.X),
			rng.NextFloat(-Randomness.Y, Randomness.Y),
			rng.NextFloat(-Randomness.Z, Randomness.Z));

		let velocity = BaseVelocity + jitter + direction * ShapeDirectionSpeed
			+ context.EmitterVelocity * VelocityInheritance;
		streams.Velocities[index] = velocity;
		streams.StartVelocities[index] = velocity;
	}
}
