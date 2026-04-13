namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Initializes particle velocity from a base velocity plus emission shape direction.
public class VelocityInitializer : ParticleInitializer
{
	/// Base initial velocity.
	public Vector3 BaseVelocity = .(0, 1, 0);

	/// Per-axis randomness added to velocity.
	public Vector3 Randomness = .Zero;

	/// Speed applied along the emission shape's outward direction.
	public float ShapeDirectionSpeed = 0;

	/// Factor for inheriting emitter movement velocity.
	public float VelocityInheritance = 0;

	/// Emission shape (shared with PositionInitializer to get the same direction).
	public EmissionShape Shape = .Point();

	/// Emitter velocity (set by system before initialization).
	public Vector3 EmitterVelocity = .Zero;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
		streams.EnsureStream(.StartVelocity, .Float3);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		Vector3 shapePos;
		Vector3 shapeDir;
		Shape.Sample(rng, out shapePos, out shapeDir);

		var velocity = BaseVelocity;

		if (Randomness.X != 0 || Randomness.Y != 0 || Randomness.Z != 0)
		{
			velocity = velocity + Vector3(
				(float)(rng.NextDouble() * 2.0 - 1.0) * Randomness.X,
				(float)(rng.NextDouble() * 2.0 - 1.0) * Randomness.Y,
				(float)(rng.NextDouble() * 2.0 - 1.0) * Randomness.Z
			);
		}

		if (ShapeDirectionSpeed > 0)
			velocity = velocity + shapeDir * ShapeDirectionSpeed;

		if (VelocityInheritance > 0)
			velocity = velocity + EmitterVelocity * VelocityInheritance;

		streams.Velocities[index] = velocity;
		streams.StartVelocities[index] = velocity;
	}
}
