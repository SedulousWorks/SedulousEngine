using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// What a world shares and what it says when a budget is met.
class PhysicsBudgetTests
{
	/// CreateBody returned an invalid id with nothing said: a level past the budget lost bodies
	/// silently. It is said once, naming the setting.
	[Test]
	public static void AWorldPastItsBodyBudgetSaysSoOnce()
	{
		let log = scope RingLogger(32, .Error);
		bool previousOwned = false;
		let previous = DetachGlobalLogger(out previousOwned);
		InitGlobalLogger(log);
		{
			let settings = scope PhysicsWorldSettings();
			settings.MaxBodies = 4;
			let world = scope PhysicsWorld(settings);
			for (int i < 4)
				Test.Assert(world.CreateBody(BoxAt!((float)i * 2.0f)).IsValid);
			Test.Assert(!world.CreateBody(BoxAt!(20.0f)).IsValid);
			Test.Assert(!world.CreateBody(BoxAt!(22.0f)).IsValid);
			world.Step(1.0f / 60.0f); // the world steps on with what it holds
		}
		bool logOwned = false;
		DetachGlobalLogger(out logOwned);
		InitGlobalLogger(previous, previousOwned);

		Test.Assert(log.Count == 1, scope $"{log.Count} errors");
		let line = log.GetMessage(0, .. scope String());
		Test.Assert(line.Contains("MaxBodies"), line);
	}

	/// Each world made its own pool of a thread per core; two scenes ran two pools. They share
	/// one, held while any world is, and each steps as before.
	[Test]
	public static void WorldsShareOneWorkerPoolEachSteppingAsBefore()
	{
		let before = PhysicsJobPool.Users;
		{
			let first = scope PhysicsWorld();
			let second = scope PhysicsWorld();
			Test.Assert(PhysicsJobPool.Users == before + 2, "both worlds hold the one pool");
			first.CreateBody(FloorDesc!());
			second.CreateBody(FloorDesc!());
			let a = first.CreateBody(BoxAt!(3.0f));
			let b = second.CreateBody(BoxAt!(3.0f));
			for (int i < 120)
			{
				first.Step(1.0f / 60.0f);
				second.Step(1.0f / 60.0f);
			}
			first.GetBodyTransform(a, let pa, ?);
			second.GetBodyTransform(b, let pb, ?);
			Test.Assert(Near(pa.Y, 0.5f, 0.03f), scope $"first at {pa.Y}");
			Test.Assert(Near(pb.Y, 0.5f, 0.03f), scope $"second at {pb.Y}");
		}
		Test.Assert(PhysicsJobPool.Users == before, "gone with the last world");
	}
}
