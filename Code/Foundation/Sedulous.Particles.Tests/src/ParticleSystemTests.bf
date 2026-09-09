using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The per frame loop: emission, integration, ageing, the budget, level of detail and
/// determinism.
class ParticleSystemTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// An upward fountain: continuous emission, a two second life, and gravity.
	private static void BuildFountain(ParticleSystem system, float rate = 100.0f)
	{
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(2.0f, 2.0f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0, 5, 0);
		system.AddInitializer<SizeInitializer>();
		system.AddInitializer<ColorInitializer>();
		system.AddBehavior<GravityBehavior>();
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = rate;
	}

	[Test]
	public static void ContinuousEmissionSpawnsIntegratesAndAgesOut()
	{
		let system = scope ParticleSystem(10000);
		BuildFountain(system, 100.0f);

		// A tenth of a second at a hundred a second.
		system.Update(0.1f);
		Test.Assert((system.AliveCount >= 9) && (system.AliveCount <= 11));
		// The velocity carried them up, so position was integrated.
		Test.Assert(system.Streams.Positions[0].Y > 0.0f);

		system.Emitter.IsEmitting = false;
		for (int i = 0; i < 300; i++)
			system.Update(0.016f);
		Test.Assert(system.AliveCount == 0);
	}

	[Test]
	public static void TheBudgetIsAHardCap()
	{
		let system = scope ParticleSystem(50);
		BuildFountain(system, 100000.0f);
		for (int i = 0; i < 10; i++)
			system.Update(0.1f);
		Test.Assert(system.AliveCount <= 50);
	}

	[Test]
	public static void ModulesCanBeAddedAndRemoved()
	{
		let system = scope ParticleSystem(100);
		BuildFountain(system);
		Test.Assert(system.InitializerCount == 4);
		Test.Assert(system.BehaviorCount == 1);

		system.RemoveInitializer(0);
		Test.Assert(system.InitializerCount == 3);
		system.RemoveBehavior(0);
		Test.Assert(system.BehaviorCount == 0);
		// Out of range is a no-op, not a crash.
		system.RemoveInitializer(99);
		Test.Assert(system.InitializerCount == 3);
	}

	[Test]
	public static void ReorderingPreservesIdentityAndRespectsBounds()
	{
		let system = scope ParticleSystem(100);
		let gravity = system.AddBehavior<GravityBehavior>();
		let drag = system.AddBehavior<DragBehavior>();
		let wind = system.AddBehavior<WindBehavior>();
		Test.Assert(system.GetBehavior(0) == gravity);
		Test.Assert(system.GetBehavior(2) == wind);

		system.MoveBehavior(2, 0);
		Test.Assert(system.GetBehavior(0) == wind);
		Test.Assert(system.GetBehavior(1) == gravity);
		Test.Assert(system.GetBehavior(2) == drag);

		system.MoveBehavior(0, 2);
		Test.Assert(system.GetBehavior(2) == wind);
		Test.Assert(system.GetBehavior(0) == gravity);

		system.MoveBehavior(0, 5);
		Test.Assert(system.GetBehavior(0) == gravity);
		Test.Assert(system.BehaviorCount == 3);
	}

	[Test]
	public static void ResizingTheBudgetRedeclaresTheStreams()
	{
		let system = scope ParticleSystem(50);
		BuildFountain(system, 500.0f);
		Test.Assert(system.MaxParticles == 50);
		for (int32 i = 0; i < 30; i++)
			system.Step(1.0f / 60.0f);
		Test.Assert(system.AliveCount == 50);

		system.SetMaxParticles(2000);
		Test.Assert(system.MaxParticles == 2000);
		// The resize restarts the alive set: the old streams are gone.
		Test.Assert(system.AliveCount == 0);

		for (int32 i = 0; i < 60; i++)
			system.Step(1.0f / 60.0f);
		Test.Assert(system.AliveCount > 50);

		// The same value changes nothing and does not restart it.
		system.SetMaxParticles(2000);
		Test.Assert(system.MaxParticles == 2000);
		Test.Assert(system.AliveCount > 50);
	}

	[Test]
	public static void ABurstWithNoIntervalFiresOnce()
	{
		let system = scope ParticleSystem(1000);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 20;
		system.Emitter.BurstInterval = 0.0f;

		system.Update(0.016f);
		Test.Assert(system.AliveCount == 20);
		system.Update(0.016f);
		Test.Assert(system.AliveCount == 20);
	}

	[Test]
	public static void AOneShotDurationStopsAndALoopingOneRearms()
	{
		let oneShot = scope ParticleEmitter();
		oneShot.Mode = .Continuous;
		oneShot.SpawnRate = 100.0f;
		oneShot.Duration = 0.1f;
		oneShot.Looping = false;
		Test.Assert(oneShot.CalculateSpawnCount(0.05f) == 5);
		Test.Assert(oneShot.CalculateSpawnCount(0.10f) == 0);

		let looping = scope ParticleEmitter();
		looping.Mode = .Continuous;
		looping.SpawnRate = 100.0f;
		looping.Duration = 0.1f;
		looping.Looping = true;
		Test.Assert(looping.CalculateSpawnCount(0.05f) == 5);
		Test.Assert(looping.CalculateSpawnCount(0.10f) > 0);
	}

	[Test]
	public static void TheSameSeedGivesTheSameParticles()
	{
		let a = scope ParticleSystem(1000, 42);
		let b = scope ParticleSystem(1000, 42);
		BuildFountain(a, 200.0f);
		BuildFountain(b, 200.0f);
		for (int i = 0; i < 20; i++)
		{
			a.Update(0.02f);
			b.Update(0.02f);
		}

		Test.Assert(a.AliveCount == b.AliveCount);
		Test.Assert(a.AliveCount > 0);
		for (int32 i = 0; i < a.AliveCount; i++)
		{
			Test.Assert(Near(a.Streams.Positions[i].X, b.Streams.Positions[i].X));
			Test.Assert(Near(a.Streams.Positions[i].Y, b.Streams.Positions[i].Y));
		}
	}

	[Test]
	public static void ResetReplaysFromTheSeed()
	{
		let system = scope ParticleSystem(100, 12345);
		system.AddInitializer<PositionInitializer>().Shape = .Sphere(3.0f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 16;

		system.Update(0.016f);
		Test.Assert(system.AliveCount == 16);
		let first = system.Streams.Positions[3];

		system.Reset();
		system.Update(0.016f);
		Test.Assert(Near(Length(system.Streams.Positions[3] - first), 0.0f));
	}

	[Test]
	public static void BeyondTheCullDistanceNothingSpawns()
	{
		let system = scope ParticleSystem(1000);
		BuildFountain(system, 100.0f);
		system.LodStartDistance = 10.0f;
		system.LodCullDistance = 20.0f;
		system.Position = .(0, 0, 0);

		system.Update(0.1f, .(100, 0, 0));
		Test.Assert(Near(system.LodRateMultiplier, 0.0f));
		Test.Assert(system.AliveCount == 0);
		Test.Assert(system.IsLodCulled);
	}

	[Test]
	public static void PrewarmPopulatesTheFirstFrame()
	{
		let system = scope ParticleSystem(500);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(10.0f, 10.0f);
		system.Emitter.SpawnRate = 100.0f;
		// A second of simulation before the first visible frame.
		system.PrewarmTime = 1.0f;

		system.Update(0.016f);
		Test.Assert(system.AliveCount > 50);
	}

	[Test]
	public static void ACpuOnlyBehaviourKeepsTheSystemOnTheCpu()
	{
		let system = scope ParticleSystem(4096);
		system.DesiredMode = .Auto;
		system.AddBehavior<GravityBehavior>();
		system.ResolveSimulationMode();
		Test.Assert(system.ResolvedMode == .GPU);

		system.AddBehavior<TurbulenceBehavior>();
		system.ResolveSimulationMode();
		Test.Assert(system.ResolvedMode == .CPU);
	}

	[Test]
	public static void ASmallSystemStaysOnTheCpuWhateverItSupports()
	{
		let system = scope ParticleSystem(64);
		system.DesiredMode = .Auto;
		system.AddBehavior<GravityBehavior>();
		system.ResolveSimulationMode();
		// The dispatch would cost more than the work.
		Test.Assert(system.ResolvedMode == .CPU);
	}
}
