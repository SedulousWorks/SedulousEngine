using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The trail ring buffers, and the compaction that has to move them with their particles.
class ParticleTrailTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// A moving trail system, recording every frame.
	private static void BuildTrailSystem(ParticleSystem system, int32 burst, int32 maxPoints)
	{
		system.RenderMode = .Trail;
		system.Trail.Enabled = true;
		system.Trail.MaxPoints = maxPoints;
		system.Trail.RecordInterval = 0.0f;
		system.Trail.MinVertexDistance = 0.0f;
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(100.0f, 100.0f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(5, 0, 0);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = burst;
		system.Emitter.BurstInterval = 0.0f;
	}

	[Test]
	public static void TheRingFillsAndCapsAtItsLength()
	{
		let system = scope ParticleSystem(100);
		BuildTrailSystem(system, 3, 4);
		Test.Assert(system.Trail.IsActive);

		system.Update(0.1f);
		Test.Assert(system.AliveCount == 3);
		Test.Assert(system.TrailMaxPoints == 4);
		Test.Assert(system.TrailStates[0].Count == 1);

		for (int i = 0; i < 10; i++)
			system.Update(0.1f);

		let states = system.TrailStates;
		Test.Assert(states.Length == 3);
		for (let state in states)
			Test.Assert(state.Count == 4);
	}

	[Test]
	public static void TheNewestPointIsTheParticlesPosition()
	{
		let system = scope ParticleSystem(100);
		BuildTrailSystem(system, 3, 4);
		for (int i = 0; i < 6; i++)
			system.Update(0.1f);

		let head = system.TrailStates[0].Head;
		Test.Assert(Near(system.TrailPoints[head].Position.X, system.Streams.Positions[0].X));
	}

	[Test]
	public static void TheRecordIntervalGatesHowOftenPointsAreAdded()
	{
		let system = scope ParticleSystem(100);
		BuildTrailSystem(system, 1, 16);
		system.Trail.RecordInterval = 0.5f;
		// A distance gate far out of reach, so only the interval can trigger a record.
		system.Trail.MinVertexDistance = 1.0e9f;

		for (int i = 0; i < 10; i++)
			system.Update(0.1f);

		Test.Assert(system.AliveCount == 1);
		// The first point plus roughly two interval points, not one per frame.
		let count = system.TrailStates[0].Count;
		Test.Assert((count >= 2) && (count <= 4));
	}

	[Test]
	public static void ADistantParticleRecordsBeforeItsIntervalIsUp()
	{
		let system = scope ParticleSystem(100);
		BuildTrailSystem(system, 1, 16);
		// The interval will never fire in this test; only the distance can.
		system.Trail.RecordInterval = 1.0e9f;
		system.Trail.MinVertexDistance = 0.1f;

		for (int i = 0; i < 10; i++)
			system.Update(0.1f);

		Test.Assert(system.TrailStates[0].Count > 1);
	}

	[Test]
	public static void CompactionKeepsTheTrailsAlignedAndDrainsCleanly()
	{
		let system = scope ParticleSystem(100);
		system.RenderMode = .Trail;
		system.Trail.Enabled = true;
		system.Trail.MaxPoints = 8;
		system.Trail.RecordInterval = 0.0f;
		system.Trail.MinVertexDistance = 0.0f;
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.25f, 0.25f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(2, 0, 0);
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 200.0f;

		for (int i = 0; i < 30; i++)
			system.Update(0.02f);

		let states = system.TrailStates;
		Test.Assert(states.Length == system.AliveCount);
		for (let state in states)
			Test.Assert((state.Count >= 0) && (state.Count <= 8));

		system.Emitter.IsEmitting = false;
		for (int i = 0; i < 30; i++)
			system.Update(0.02f);
		Test.Assert(system.AliveCount == 0);
	}
}
