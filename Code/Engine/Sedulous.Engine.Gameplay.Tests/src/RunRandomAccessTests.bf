using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// `Random` on a behaviour, a level and a game: their run's RunRandom, none outside a run.
class RunRandomAccessTests
{
	[Test]
	public static void ABehaviourAndALevelReachTheirRunsRandomNumbers()
	{
		let random = scope RunRandom();
		let run = scope RunBase("random");
		run.Register(random);
		let scene = scope Scene();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let level = scene.AddSystem<Gauntlet>();
		let entity = scene.CreateEntity("e");
		walkers.Add(entity);
		let walker = walkers.Get(entity);
		Test.Assert(walker != null);
		Test.Assert(walker.Random == null, "outside every run: none");
		Test.Assert(level.Random == null);

		scene.SetRun(run);
		Test.Assert(walker.Random === random, "the run's");
		Test.Assert(level.Random === random);
		scene.SetRun(null);
	}

	/// A game's is the GameInstance's own, which its scripts' Random draws from too.
	[Test]
	public static void AGamesIsItsInstances()
	{
		let instance = scope GameInstance();
		let game = scope ProbeGame();
		Test.Assert(game.Random == null, "before the launch: none");
		game.Bind(instance);
		Test.Assert(game.Random != null);
		Test.Assert(game.Random === instance.Get<RunRandom>());
	}
}
