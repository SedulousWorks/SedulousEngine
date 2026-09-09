using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The effect and its instance: systems, sub emitter routing, and local space.
class ParticleEffectTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void SystemsCanBeAddedAndRemoved()
	{
		let effect = scope ParticleEffect();
		effect.AddSystem(100);
		effect.AddSystem(100);
		Test.Assert(effect.SystemCount == 2);
		effect.RemoveSystem(0);
		Test.Assert(effect.SystemCount == 1);
		effect.Clear();
		Test.Assert(effect.SystemCount == 0);
	}

	[Test]
	public static void ParentDeathSpawnsIntoTheChild()
	{
		let effect = scope ParticleEffect("fireworks");

		// Short lived rockets, which die and so produce death events.
		let rockets = effect.AddSystem(100);
		rockets.AddInitializer<LifetimeInitializer>().Lifetime = .(0.05f, 0.05f);
		rockets.Emitter.Mode = .Burst;
		rockets.Emitter.BurstCount = 4;
		rockets.Emitter.BurstInterval = 0.0f;

		// Sparks, which emit nothing of their own.
		let sparks = effect.AddSystem(1000);
		sparks.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.0f);
		sparks.Emitter.IsEmitting = false;

		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		link.ChildSystemIndex = 1;
		link.SpawnCount = 10;
		link.Probability = 1.0f;
		effect.AddSubEmitterLink(link);

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.016f);
		Test.Assert(rockets.AliveCount == 4);
		Test.Assert(sparks.AliveCount == 0);

		// The rockets age out, and each death spawns ten sparks.
		instance.Update(0.1f);
		Test.Assert(rockets.AliveCount == 0);
		Test.Assert(sparks.AliveCount == 40);
	}

	[Test]
	public static void SpawnAtAddsVelocityAndModulatesColour()
	{
		let effect = scope ParticleEffect("inherit");
		let child = effect.AddSystem(100);
		child.AddInitializer<VelocityInitializer>().BaseVelocity = .(1, 0, 0);
		child.AddInitializer<ColorInitializer>().Color = .Constant(.(1, 1, 1, 1));
		child.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);

		child.SpawnAt(1, .(0, 0, 0), .(0, 5, 0), .(1, 0, 0, 1));
		Test.Assert(child.AliveCount == 1);

		let velocity = child.Streams.Velocities[0];
		// The base is kept and the inherited part is ADDED to it.
		Test.Assert(Near(velocity.X, 1.0f));
		Test.Assert(Near(velocity.Y, 5.0f));

		let color = child.Streams.Colors[0];
		// White MODULATED by red.
		Test.Assert(Near(color.X, 1.0f));
		Test.Assert(Near(color.Y, 0.0f));
		Test.Assert(Near(color.Z, 0.0f));
	}

	[Test]
	public static void ALocalSpaceSystemSpawnsAtItsOwnOrigin()
	{
		let effect = scope ParticleEffect("local");
		let system = effect.AddSystem(100);
		system.SimulationSpace = .Local;
		system.AddInitializer<PositionInitializer>();
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 8;

		let instance = scope ParticleEffectInstance(effect);
		// A long way from the origin, which a world space system would spawn at.
		instance.Position = .(100, 0, 0);
		instance.Update(0.016f);

		Test.Assert(system.AliveCount == 8);
		Test.Assert(Length(system.Streams.Positions[0]) < 1.0f);
	}

	[Test]
	public static void StopDrainsAndPlayResumes()
	{
		let effect = scope ParticleEffect("drain");
		let system = effect.AddSystem(1000);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.1f, 0.1f);
		system.Emitter.SpawnRate = 200.0f;

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.05f);
		Test.Assert(system.AliveCount > 0);
		Test.Assert(!instance.IsFinished);

		instance.Stop();
		for (int i = 0; i < 30; i++)
			instance.Update(0.02f);
		// Emission stopped AND the live particles finished their lives.
		Test.Assert(instance.IsFinished);

		instance.Play();
		instance.Update(0.05f);
		Test.Assert(system.AliveCount > 0);
	}

	[Test]
	public static void ALinkNeverRoutesASystemIntoItself()
	{
		let effect = scope ParticleEffect("selfloop");
		let system = effect.AddSystem(1000);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.05f, 0.05f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 4;
		system.Emitter.BurstInterval = 0.0f;

		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		// Pointed at the only system there is, which is its own parent.
		link.ChildSystemIndex = 0;
		link.SpawnCount = 10;
		effect.AddSubEmitterLink(link);

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.016f);
		instance.Update(0.1f);
		// The deaths route nowhere, so the system drains instead of feeding itself forever.
		Test.Assert(system.AliveCount == 0);
	}
}
