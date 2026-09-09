using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The behaviours, run directly against a container so the effect around them is not part of
/// what is being tested.
class ParticleModuleTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// One live particle, halfway through its life, with velocity and colour allocated.
	private static ParticleStreamContainer OneMidLifeParticle()
	{
		let streams = new ParticleStreamContainer(8);
		streams.EnsureStream(.Velocity, .Float3);
		streams.EnsureStream(.Color, .Float4);
		streams.AliveCount = 1;
		streams.Velocities[0] = .(0, 0, 0);
		streams.Colors[0] = .(1, 1, 1, 1);
		streams.Ages[0] = 0.5f;
		streams.Lifetimes[0] = 1.0f;
		return streams;
	}

	private static ParticleUpdateContext Context(ref Sedulous.Core.Random rng, float deltaTime)
	{
		var context = ParticleUpdateContext();
		context.DeltaTime = deltaTime;
		context.Rng = &rng;
		return context;
	}

	[Test]
	public static void GravityPullsVelocityDown()
	{
		let streams = scope:: ParticleStreamContainer(8);
		streams.EnsureStream(.Velocity, .Float3);
		streams.AliveCount = 1;
		streams.Velocities[0] = .(0, 0, 0);

		var rng = Sedulous.Core.Random(1);
		var context = Context(ref rng, 0.5f);
		let gravity = scope GravityBehavior();
		gravity.Update(streams, ref context);
		Test.Assert(streams.Velocities[0].Y < 0.0f);
	}

	[Test]
	public static void DragCannotReverseAParticle()
	{
		let streams = scope ParticleStreamContainer(8);
		streams.EnsureStream(.Velocity, .Float3);
		streams.AliveCount = 1;
		streams.Velocities[0] = .(10, 0, 0);

		var rng = Sedulous.Core.Random(1);
		// A drag and a step whose product is far past one: the factor floors at nothing
		// rather than going negative.
		var context = Context(ref rng, 1.0f);
		let drag = scope DragBehavior();
		drag.Drag = 5.0f;
		drag.Update(streams, ref context);
		Test.Assert(Near(streams.Velocities[0].X, 0.0f));
	}

	[Test]
	public static void AlphaOverLifetimeSetsTheEnvelopeRatherThanScalingIt()
	{
		let streams = OneMidLifeParticle();
		defer delete streams;

		var rng = Sedulous.Core.Random(1);
		var context = Context(ref rng, 0.016f);
		let alpha = scope AlphaOverLifetimeBehavior();
		alpha.Curve = ParticleCurveFloat.Linear(1.0f, 0.0f);

		alpha.Update(streams, ref context);
		let first = streams.Colors[0].W;
		// Running it again at the SAME life ratio must give the same answer. A scaling
		// implementation would compound to nothing within a few frames.
		alpha.Update(streams, ref context);
		alpha.Update(streams, ref context);
		Test.Assert(Near(first, 0.5f));
		Test.Assert(Near(streams.Colors[0].W, first));
	}

	[Test]
	public static void AnInactiveCurveLeavesTheStreamAlone()
	{
		let streams = OneMidLifeParticle();
		defer delete streams;

		var rng = Sedulous.Core.Random(1);
		var context = Context(ref rng, 0.016f);
		let color = scope ColorOverLifetimeBehavior();
		color.Update(streams, ref context);
		Test.Assert(Near(streams.Colors[0].X, 1.0f));
		Test.Assert(Near(streams.Colors[0].W, 1.0f));
	}

	[Test]
	public static void RotationStillTurnsWithoutACurve()
	{
		let streams = scope ParticleStreamContainer(8);
		streams.EnsureStream(.Rotation, .Float);
		streams.EnsureStream(.RotationSpeed, .Float);
		streams.AliveCount = 1;
		streams.Rotations[0] = 0.0f;
		streams.RotationSpeeds[0] = 2.0f;
		streams.Ages[0] = 0.0f;
		streams.Lifetimes[0] = 1.0f;

		var rng = Sedulous.Core.Random(1);
		var context = Context(ref rng, 0.5f);
		let rotation = scope RotationOverLifetimeBehavior();
		// No curve: the rate applies unscaled, because this behaviour is what integrates
		// rotation at all.
		rotation.Update(streams, ref context);
		Test.Assert(Near(streams.Rotations[0], 1.0f));
	}

	[Test]
	public static void SpeedOverLifetimeMeasuresAgainstTheStartVelocity()
	{
		let streams = scope ParticleStreamContainer(8);
		streams.EnsureStream(.Velocity, .Float3);
		streams.EnsureStream(.StartVelocity, .Float3);
		streams.AliveCount = 1;
		streams.Velocities[0] = .(4, 0, 0);
		streams.StartVelocities[0] = .(10, 0, 0);
		streams.Ages[0] = 1.0f;
		streams.Lifetimes[0] = 1.0f;

		var rng = Sedulous.Core.Random(1);
		var context = Context(ref rng, 0.016f);
		let speed = scope SpeedOverLifetimeBehavior();
		speed.Curve = ParticleCurveFloat.Constant(0.5f);
		speed.Update(streams, ref context);
		// Half of TEN, the start speed, not half of four.
		Test.Assert(Near(streams.Velocities[0].X, 5.0f));
	}

	[Test]
	public static void AnAttractorIgnoresAParticleSittingOnIt()
	{
		let streams = scope ParticleStreamContainer(8);
		streams.EnsureStream(.Velocity, .Float3);
		streams.AliveCount = 1;
		streams.Positions[0] = .(0, 0, 0);
		streams.Velocities[0] = .(0, 0, 0);

		var rng = Sedulous.Core.Random(1);
		var context = Context(ref rng, 0.5f);
		let attractor = scope AttractorBehavior();
		attractor.Position = .(0, 0, 0);
		attractor.Update(streams, ref context);
		// No direction to pull along, so nothing happens rather than a division by nothing.
		Test.Assert(Near(Length(streams.Velocities[0]), 0.0f));
	}
}
