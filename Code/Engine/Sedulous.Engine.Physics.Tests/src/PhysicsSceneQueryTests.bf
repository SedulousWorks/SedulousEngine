using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// The scene level queries: what a ray or a swept sphere meets, what overlaps a point, and
/// how heavy the world is. Raptor keeps these on a ScenePhysics facade; ours are on the
/// system itself, and these are its four cases.
static class PhysicsSceneQueryTests
{
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) <= epsilon;

	private static EntityHandle AddStaticBox(PhysicsPlayScene play, Float3 at, uint8 group)
	{
		let e = play.Scene.CreateEntity("b");
		play.Scene.SetLocalPosition(e, at);
		let b = play.Bodies.Add(e);
		b.Motion = .Static;
		b.Layer = .Static;
		b.HalfExtents = .(0.5f, 0.5f, 0.5f);
		b.CollisionGroup = group;
		return e;
	}

	[Test]
	public static void RayCastAnswersAnExplicitHitWithNoStoredState()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let @box = play.AddBox(0.5f); // resting on the floor, top face at y = 1
		play.Start();
		play.Step(10);

		// Straight down from y = 5: the box top at y = 1 is four units away.
		let hit = play.Physics.RayCast(.(0, 5, 0), .(0, -1, 0), 20.0f);
		Test.Assert(hit.Hit, "the ray struck the box");
		Test.Assert(Near(hit.Distance, 4.0f, 0.08f), scope $"distance {hit.Distance}");
		Test.Assert(Near(hit.Position.Y, 1.0f, 0.02f), "the hit sits on the top face");
		Test.Assert(Near(hit.Normal.Y, 1.0f, 0.01f), "the top face's normal points up");
		Test.Assert(hit.Entity == @box, "the hit resolves to the box's entity");
		Test.Assert(play.Physics.BodyCount == 2, "floor and box");

		// A miss is explicit rather than stale: no hit, distance -1, no entity.
		let miss = play.Physics.RayCast(.(0, 100, 0), .(0, 1, 0), 1.0f);
		Test.Assert(!miss.Hit);
		Test.Assert(Near(miss.Distance, -1.0f, 0.0f));
		Test.Assert(miss.Entity == .Invalid);
	}

	[Test]
	public static void SphereCastSweepsAVolumeAndHitsEarlierThanARay()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let @box = play.AddBox(0.5f);
		play.Start();
		play.Step(10);

		// A sphere of radius 0.5 touches the top face when its centre reaches y = 1.5, so the
		// sweep from y = 5 stops at 3.5 where a point ray needs the full 4.
		let swept = play.Physics.SphereCast(.(0, 5, 0), .(0, -1, 0), 20.0f, 0.5f);
		Test.Assert(swept.Hit);
		Test.Assert(swept.Entity == @box);
		Test.Assert(Near(swept.Distance, 3.5f, 0.1f), scope $"swept distance {swept.Distance}");

		let ray = play.Physics.RayCast(.(0, 5, 0), .(0, -1, 0), 20.0f);
		Test.Assert(swept.Distance < ray.Distance, "the volume meets the box before the point does");

		Test.Assert(!play.Physics.SphereCast(.(0, 100, 0), .(0, 1, 0), 1.0f, 0.5f).Hit,
			"a clear sweep misses");
	}

	[Test]
	public static void NearestOverlapPicksTheClosestBodyAndHonoursTheGroupMask()
	{
		let play = scope PhysicsPlayScene();
		let nearBox = AddStaticBox(play, .(2, 0, 0), 3);
		AddStaticBox(play, .(6, 0, 0), 3); // farther, same group
		play.Start();
		play.Step(1);

		// A sphere big enough for both: the nearer body origin wins, and Distance is to it.
		let h = play.Physics.NearestOverlap(.(0, 0, 0), 8.0f);
		Test.Assert(h.Hit);
		Test.Assert(h.Entity == nearBox, "the nearer of the two");
		Test.Assert(Near(h.Position.X, 2.0f, 0.01f), "Position is the body's origin");
		Test.Assert(Near(h.Distance, 2.0f, 0.02f));

		// Exclude group 3 and nothing remains; both boxes are group 3.
		Test.Assert(!play.Physics.NearestOverlap(.(0, 0, 0), 8.0f, ~(1u << 3)).Hit,
			"the group mask filters both out");
		// A sphere reaching neither.
		Test.Assert(!play.Physics.NearestOverlap(.(0, 0, 0), 1.0f).Hit);
	}

	[Test]
	public static void OverlapSphereAnswersTheFullSet()
	{
		let play = scope PhysicsPlayScene();
		let a = AddStaticBox(play, .(2, 0, 0), 3);
		let b = AddStaticBox(play, .(6, 0, 0), 3);
		play.Start();
		play.Step(1);

		let all = scope List<EntityHandle>();
		play.Physics.OverlapSphere(.(0, 0, 0), 8.0f, all);
		Test.Assert(all.Count == 2, scope $"got {all.Count}");
		// Both present; the order is the broadphase's and not promised.
		Test.Assert(all.Contains(a) && all.Contains(b), "both entities, each live");

		// A mask excluding their group answers an empty set, and the list is CLEARED first.
		play.Physics.OverlapSphere(.(0, 0, 0), 8.0f, all, ~(1u << 3));
		Test.Assert(all.Count == 0, "filtered to nothing, and the previous answer did not linger");
	}
}
