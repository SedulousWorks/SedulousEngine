using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameInstance.Tests;

/// The run's random numbers: a service of every GameInstance, kept through a session and its
/// pauses, back to the default seed as the session stops, so the next session draws the same.
class RunRandomTests
{
	[Test]
	public static void ASessionsStopRestartsTheRunsRandomNumbers()
	{
		let fresh = scope RunRandom();
		let first = fresh.NextU32();
		let second = fresh.NextU32();

		let instance = scope GameInstance();
		let random = instance.Get<RunRandom>();
		Test.Assert(random != null, "every run has its own");
		Test.Assert(RunServices.Get<RunRandom>(instance) === random);
		let other = scope GameInstance();
		Test.Assert(other.Get<RunRandom>() !== random, "one per run");

		instance.Start();
		Test.Assert(random.NextU32() == first, "a fresh run draws the default sequence");
		instance.SetPaused(true);
		instance.SetPaused(false);
		Test.Assert(random.NextU32() == second, "a pause leaves it where it was");
		random.Seed(42);
		random.Value();
		instance.Stop();
		Test.Assert(random.NextU32() == first, "the session's stop restarts it");

		// A seed set between sessions (a replay's) holds into the next one.
		random.Seed(42);
		let seeded = scope RunRandom();
		seeded.Seed(42);
		instance.Start();
		Test.Assert(random.NextU32() == seeded.NextU32(), "the start does not restart it");
		instance.Stop();
	}
}
