using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// What a physics component held leaves the world when the component goes, its entity
/// destroyed or the component taken off, rather than staying as an invisible collider until the
/// scene stops.
class PhysicsLifetimeTests
{
	[Test]
	public static void ADestroyedEntitysBodyAndARemovedComponentsBodyLeaveTheWorld()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let doomed = play.AddBox(5.0f);
		let stripped = play.AddBox(8.0f);
		play.Start();
		play.Step(2);
		Test.Assert(play.Physics.World != null);
		Test.Assert(play.Physics.World.BodyCount == 3);

		play.Scene.DestroyEntity(doomed);
		play.Step(2);
		Test.Assert(play.Physics.World.BodyCount == 2);

		play.Bodies.RemoveComponent(stripped);
		play.Step(2);
		// The floor only.
		Test.Assert(play.Physics.World.BodyCount == 1);
	}

	/// The joint's target goes: the joint drops in the same reconcile, before the target's body.
	[Test]
	public static void AJointLetsGoBeforeItsTargetsBodyLeaves()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let left = play.AddBox(0.5f);
		let right = play.AddBox(0.5f);
		play.Scene.SetLocalPosition(left, .(4.0f, 0.5f, 0.0f));
		play.Scene.SetLocalPosition(right, .(5.2f, 0.5f, 0.0f));
		{
			let joint = play.Joints.Add(right);
			joint.Kind = .Fixed;
			joint.TargetEntity = .(play.Scene.GetEntityId(left));
		}
		play.Start();
		play.Step(10);
		Test.Assert(play.Physics.World.BodyCount == 3);
		Test.Assert(play.Joints.Get(right).Joint.IsValid);

		play.Scene.DestroyEntity(left);
		play.Step(10);
		Test.Assert(play.Physics.World.BodyCount == 2);
		Test.Assert(!play.Joints.Get(right).Joint.IsValid);
	}

	/// A joint whose own entity's body is taken off has nothing to hold by: it goes with the body
	/// though its target stays, and does not come back.
	[Test]
	public static void AJointWhoseOwnBodyIsTakenOffGoes()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let left = play.AddBox(0.5f);
		let right = play.AddBox(0.5f);
		play.Scene.SetLocalPosition(left, .(4.0f, 0.5f, 0.0f));
		play.Scene.SetLocalPosition(right, .(5.2f, 0.5f, 0.0f));
		{
			let joint = play.Joints.Add(right);
			joint.Kind = .Fixed;
			joint.TargetEntity = .(play.Scene.GetEntityId(left));
		}
		play.Start();
		play.Step(10);
		Test.Assert(play.Joints.Get(right).Joint.IsValid);

		play.Bodies.RemoveComponent(right);
		play.Step(1);
		Test.Assert(!play.Joints.Get(right).Joint.IsValid);
		Test.Assert(play.Physics.World.BodyCount == 2);

		play.Step(10);
		Test.Assert(!play.Joints.Get(right).Joint.IsValid);
		Test.Assert(play.Bodies.Get(left).Body.IsValid);
	}

	/// A joint with no named target holds the nearest ANCESTOR's body. Taking that body off drops
	/// the joint before the body leaves, and the next reconcile builds it again against what is
	/// left: here, the world.
	[Test]
	public static void AJointLetsGoOfAnAncestorBodyTakenOffAndHoldsTheWorld()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let holder = play.AddBox(4.0f, .Kinematic);
		let hanging = play.AddBox(0.0f);
		play.Scene.SetParent(hanging, holder);
		play.Scene.SetLocalPosition(hanging, .(0.0f, -1.5f, 0.0f));
		{
			let joint = play.Joints.Add(hanging);
			joint.Kind = .Fixed;
		}
		play.Start();
		play.Step(10);
		Test.Assert(play.Physics.World.BodyCount == 3);
		let held = play.Joints.Get(hanging).Joint;
		Test.Assert(held.IsValid);
		Test.Assert(play.Physics.World.JointHolds(held, play.Bodies.Get(holder).Body));

		let holderBody = play.Bodies.Get(holder).Body;
		play.Bodies.RemoveComponent(holder);
		play.Step(1);
		Test.Assert(play.Physics.World.BodyCount == 2);
		Test.Assert(!play.Joints.Get(hanging).Joint.IsValid);

		// Built again on the next step, to the world this time.
		play.Step(1);
		let rebuilt = play.Joints.Get(hanging).Joint;
		Test.Assert(rebuilt.IsValid);
		Test.Assert(!play.Physics.World.JointHolds(rebuilt, holderBody));
		Test.Assert(play.Physics.World.JointHolds(rebuilt, play.Bodies.Get(hanging).Body));

		// It holds the hanging box where it was rather than letting it fall.
		play.Step(60);
		play.Settle();
		Test.Assert(PhysicsPlayScene.Near(play.Scene.GetWorldPosition(hanging).Y, 2.5f, 0.05f));
	}

	/// A character goes with its entity; the world steps on.
	[Test]
	public static void ADestroyedEntitysCharacterLeavesTheWorld()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let hero = play.Scene.CreateEntity("hero");
		play.Scene.SetLocalPosition(hero, .(-3.0f, 0.9f, 0.0f));
		play.Characters.Add(hero);
		play.Start();
		play.Step(10);

		let character = play.Characters.Get(hero).Character;
		Test.Assert(character.IsValid);
		// The world answers the origin for a character it does not have.
		Test.Assert(PhysicsPlayScene.Near(play.Physics.World.CharacterPosition(character).X, -3.0f, 0.05f));

		play.Scene.DestroyEntity(hero);
		play.Step(10);
		Test.Assert(PhysicsPlayScene.Near(play.Physics.World.CharacterPosition(character).X, 0.0f));
		Test.Assert(play.Physics.World.BodyCount == 1);
	}

	/// What a component removed in the last frame before a stop held goes with that run's world:
	/// it is not dropped in the next play's world, where its id may name another body.
	[Test]
	public static void ABodyReleasedBeforeTheStopIsNotDroppedInTheNextPlay()
	{
		let play = scope PhysicsPlayScene();
		let floor = play.AddFloor();
		let @box = play.AddBox(5.0f);
		play.Start();
		play.Step(2);

		// Released, then stopped before a reconcile took it.
		play.Bodies.RemoveComponent(floor);
		play.Scene.Stop();

		play.Start();
		play.Step(2);
		Test.Assert(play.Physics.World.BodyCount == 1);
		Test.Assert(play.Bodies.Get(@box).Body.IsValid);
	}
}
