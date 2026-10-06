using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// Static capsules from a scene's sources (a forest's trunks): solid bodies owned by no entity,
/// found by their group, and built late for a source that was not ready at the start.
class PhysicsStaticCapsuleTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	/// A stand-in for vegetation: a fixed set of trunks, ready or not as the test says.
	class TrunkSource : SceneSystem, IStaticColliderSource
	{
		public List<StaticCapsule> Trunks = new .() ~ delete _;
		public bool Ready = true;
		public int Asks = 0;

		public override IStaticColliderSource AsStaticColliderSource => this;

		public bool CollectStaticCapsules(Scene scene, List<StaticCapsule> outCapsules)
		{
			Asks++;
			if (!Ready)
				return false;
			outCapsules.AddRange(Trunks);
			return true;
		}

		public void Add(Float3 foot, float radius, float height, uint8 group)
		{
			var trunk = StaticCapsule();
			trunk.Foot = foot;
			trunk.Radius = radius;
			trunk.Height = height;
			trunk.Group = group;
			Trunks.Add(trunk);
		}
	}

	/// A character driven at a trunk stops against it; the trunk is found in its group (no
	/// entity, the capsule's centre) and not beside it or in another group.
	[Test]
	public static void ATrunkStopsACharacterAndIsFoundByItsGroup()
	{
		let play = scope PhysicsPlayScene();
		let trunks = play.Scene.AddSystem<TrunkSource>();
		trunks.Add(.(4.0f, 0.0f, 0.0f), 0.3f, 4.0f, 5);
		play.AddFloor();
		let hero = play.Scene.CreateEntity("hero");
		play.Scene.SetLocalPosition(hero, .(0.0f, 0.9f, 0.0f));
		play.Characters.Add(hero);
		play.Start();
		Test.Assert(play.Physics.BodyCount == 2, "the floor and the trunk");

		play.Step(30);
		play.Characters.Get(hero).MoveVelocity = .(3.0f, 0.0f, 0.0f);
		play.Step(120);
		play.Settle();
		let x = play.Scene.GetWorldPosition(hero).X;
		Test.Assert((x > 2.5f) && (x < 4.0f - 0.3f - 0.3f), scope $"the character stopped at the trunk, at {x}");

		let found = play.Physics.NearestOverlap(.(4.0f, 1.0f, 0.5f), 0.5f, 1u << 5);
		Test.Assert(found.Hit, "the trunk, in its group");
		Test.Assert(found.Entity == .Invalid, "owned by no entity");
		Test.Assert(Near(found.Position.X, 4.0f, 0.01f) && Near(found.Position.Y, 2.0f, 0.01f),
			"the capsule's centre: half its height above its foot");
		Test.Assert(!play.Physics.NearestOverlap(.(4.0f, 1.0f, 2.0f), 0.5f, 1u << 5).Hit, "beside it: nothing");
		Test.Assert(!play.Physics.NearestOverlap(.(4.0f, 1.0f, 0.5f), 0.5f, 1u << 6).Hit, "another group: nothing");
		let listed = scope List<EntityHandle>();
		play.Physics.OverlapSphere(.(4.0f, 1.0f, 0.5f), 0.5f, listed, 1u << 5);
		Test.Assert(listed.IsEmpty, "the entity list holds entities only");
	}

	/// A short trunk is a sphere sitting on its foot; a zero radius is no body at all.
	[Test]
	public static void AShortTrunkIsASphereOnItsFootAndANoughtRadiusIsNothing()
	{
		let play = scope PhysicsPlayScene();
		let trunks = play.Scene.AddSystem<TrunkSource>();
		trunks.Add(.(0.0f, 0.0f, 0.0f), 0.5f, 0.6f, 1);
		trunks.Add(.(10.0f, 0.0f, 0.0f), 0.0f, 3.0f, 1);
		play.Start();
		Test.Assert(play.Physics.BodyCount == 1);
		let found = play.Physics.NearestOverlap(.(0.0f, 0.5f, 0.0f), 0.1f, 1u << 1);
		Test.Assert(found.Hit && Near(found.Position.Y, 0.5f, 0.01f), "the sphere's centre is a radius above the foot");
	}

	/// A source not ready at the start is asked again each step; once ready, it is solid and
	/// asked no more. A stop drops the bodies and the wait.
	[Test]
	public static void ASourceNotReadyAtTheStartIsSolidOnceItIs()
	{
		let play = scope PhysicsPlayScene();
		let trunks = play.Scene.AddSystem<TrunkSource>();
		trunks.Add(.(0.0f, 0.0f, 0.0f), 0.3f, 4.0f, 2);
		trunks.Ready = false;
		play.Start();
		Test.Assert((trunks.Asks == 1) && (play.Physics.BodyCount == 0));

		play.Step(3);
		Test.Assert((trunks.Asks == 4) && (play.Physics.BodyCount == 0), "asked again each step");
		trunks.Ready = true;
		play.Step();
		Test.Assert(play.Physics.BodyCount == 1);
		Test.Assert(play.Physics.NearestOverlap(.(0.0f, 2.0f, 0.0f), 0.5f, 1u << 2).Hit);
		play.Step(3);
		Test.Assert(trunks.Asks == 5, "a ready source is not asked again");

		play.Scene.Stop();
		Test.Assert(play.Physics.BodyCount == 0);
	}
}
