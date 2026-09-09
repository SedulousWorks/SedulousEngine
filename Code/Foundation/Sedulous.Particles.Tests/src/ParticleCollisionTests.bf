using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The analytic collision behaviour: planes, spheres and boxes.
class ParticleCollisionTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// One system holding a single particle with a ten second life, plus a collision
	/// behaviour the caller configures.
	private static CollisionBehavior BuildOneParticle(ParticleSystem system, int32 count = 1)
	{
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(10.0f, 10.0f);
		let collision = system.AddBehavior<CollisionBehavior>();
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = count;
		system.Emitter.BurstInterval = 0.0f;
		return collision;
	}

	[Test]
	public static void AParticleBouncesOffTheGroundPlane()
	{
		let system = scope ParticleSystem(10);
		let collision = BuildOneParticle(system);
		collision.Planes[0] = .(.(0, 1, 0), 0.0f);
		collision.Bounce = 0.5f;
		collision.Friction = 0.0f;

		system.Update(0.016f);
		Test.Assert(system.AliveCount == 1);

		// Driven below the plane and heading further down.
		system.Streams.Positions[0] = .(0, -1, 0);
		system.Streams.Velocities[0] = .(0, -2, 0);
		system.Update(0.016f);

		// Reflected and halved by the restitution.
		Test.Assert(Near(system.Streams.Velocities[0].Y, 1.0f));
		Test.Assert(system.Streams.Positions[0].Y >= -0.001f);
	}

	[Test]
	public static void AParticleAlreadyLeavingIsNotPulledBack()
	{
		let system = scope ParticleSystem(10);
		let collision = BuildOneParticle(system);
		collision.Planes[0] = .(.(0, 1, 0), 0.0f);
		collision.Bounce = 1.0f;
		collision.Friction = 0.0f;

		system.Update(0.016f);
		system.Streams.Positions[0] = .(0, -1, 0);
		// Penetrating, but already on its way out.
		system.Streams.Velocities[0] = .(0, 3, 0);
		system.Update(0.016f);

		// Pushed to the surface, but the velocity is left alone: reflecting it here is what
		// makes a resting particle jitter.
		Test.Assert(system.Streams.Velocities[0].Y > 0.0f);
	}

	[Test]
	public static void SphereAndBoxObstaclesPushOutAndReflect()
	{
		let system = scope ParticleSystem(10);
		let collision = BuildOneParticle(system, 2);
		collision.PlaneCount = 0;
		collision.Spheres[0] = .(.(0, 0, 0), 1.0f);
		collision.SphereCount = 1;
		collision.Boxes[0] = .(.(5, 0, 0), .(1, 1, 1));
		collision.BoxCount = 1;
		collision.Bounce = 1.0f;
		collision.Friction = 0.0f;

		system.Update(0.016f);
		Test.Assert(system.AliveCount == 2);

		// Inside the sphere, heading toward its centre.
		system.Streams.Positions[0] = .(0.5f, 0, 0);
		system.Streams.Velocities[0] = .(-1, 0, 0);
		// Just inside the box's top face, falling.
		system.Streams.Positions[1] = .(5.0f, 0.5f, 0);
		system.Streams.Velocities[1] = .(0, -1, 0);
		system.Update(0.016f);

		Test.Assert(system.Streams.Positions[0].X >= 0.99f);
		Test.Assert(Near(system.Streams.Velocities[0].X, 1.0f));
		Test.Assert(system.Streams.Positions[1].Y >= 0.99f);
		Test.Assert(Near(system.Streams.Velocities[1].Y, 1.0f));
	}

	[Test]
	public static void LifetimeLossAgesAParticleTowardDeath()
	{
		let system = scope ParticleSystem(10);
		let collision = BuildOneParticle(system);
		collision.Planes[0] = .(.(0, 1, 0), 0.0f);
		collision.LifetimeLoss = 0.5f;

		system.Update(0.016f);
		system.Streams.Positions[0] = .(0, -1, 0);
		system.Streams.Velocities[0] = .(0, -2, 0);
		let before = system.Streams.Ages[0];
		system.Update(0.016f);

		// Half of what was LEFT, so the loss is a fraction of the remaining life rather than
		// of the whole.
		Test.Assert(system.Streams.Ages[0] > before + 4.0f);
	}
}
