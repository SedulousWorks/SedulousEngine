using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// The scene to world bridge: components become bodies when the scene starts, the fixed step
/// simulates them, and the render frame reads interpolated poses.
class PhysicsSceneTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	[Test]
	public static void ComponentsBuildBodiesAtStartAndDynamicsLand()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let @box = play.AddBox(5.0f);
		play.Start();

		Test.Assert(play.Physics.World != null);
		Test.Assert(play.Physics.World.BodyCount == 2);

		play.Step(240);
		play.Settle();

		// Resting on the floor, its own half extent above the surface.
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, 0.5f, 0.05f));

		// Stopping tears the world down and clears the handles with it.
		play.Scene.Stop();
		Test.Assert(play.Physics.World == null);
		Test.Assert(!play.Bodies.Get(@box).Body.IsValid);
	}

	/// The interpolation reads the double buffer: nought is the previous pose, one the
	/// current, and a half is exactly between them.
	[Test]
	public static void InterpolationBlendsBetweenTheLastTwoFixedPoses()
	{
		let play = scope PhysicsPlayScene();
		// Free fall, with no floor to land on.
		let @box = play.AddBox(10.0f);
		play.Start();
		// Long enough to be moving properly.
		play.Step(30);

		let body = play.Bodies.Get(@box);
		Test.Assert(body != null);

		let previous = body.PrevPosition.Y;
		let current = body.CurrPosition.Y;
		Test.Assert(previous > current);

		play.Settle(0.0f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, previous));

		play.Settle(1.0f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, current));

		play.Settle(0.5f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, (previous + current) * 0.5f));
	}

	/// A KINEMATIC body follows the scene, and what rests on it is carried along by friction
	/// rather than left behind.
	[Test]
	public static void KinematicBodiesFollowTheSceneAndCarryWhatRestsOnThem()
	{
		let play = scope PhysicsPlayScene();
		let platform = play.AddBox(0.0f, .Kinematic);
		let rider = play.AddBox(1.5f);
		play.Start();

		// Land the rider first.
		play.Step(120);

		// Then slide the platform two units over two seconds.
		for (int i < 120)
		{
			var transform = play.Scene.GetLocalTransform(platform);
			transform.Position.X += 2.0f / 120.0f;
			play.Scene.SetLocalTransform(platform, transform);
			play.Scene.UpdateTransforms();
			play.Step(1);
		}

		play.Settle();

		let position = play.Scene.GetWorldPosition(rider);
		// Dragged along.
		Test.Assert(position.X > 1.0f);
		// And still on top: the platform's upper face plus the rider's half extent.
		Test.Assert(Near(position.Y, 1.0f, 0.1f));
	}

	/// A descendant's collider folds into its ancestor's body as a compound, at the offset it
	/// had when the scene started.
	[Test]
	public static void DescendantCollidersCompoundIntoTheAncestorBody()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let body = play.AddBox(0.5f, .Static);
		let arm = play.Scene.CreateEntity("arm");
		play.Scene.SetParent(arm, body);
		play.Scene.SetLocalPosition(arm, .(2.0f, 0.0f, 0.0f));
		play.Colliders.Add(arm).HalfExtents = .(0.5f, 0.5f, 0.5f);

		play.Start();

		// The arm is only reachable if the compound actually carries its shape.
		Test.Assert(play.Physics.World.RayCast(.(2.0f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f,
			let hit));
		Test.Assert(Near(hit.Position.Y, 1.0f, 0.05f));
	}

	/// A trigger raises an ENTER whose sides resolve back to the entities that own them.
	[Test]
	public static void TriggersRaiseEventsResolvedToEntities()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let volume = play.AddBox(2.0f, .Kinematic);
		let sensor = play.Bodies.Get(volume);
		sensor.IsTrigger = true;
		sensor.HalfExtents = .(1.0f, 1.0f, 1.0f);

		let faller = play.AddBox(6.0f);
		play.Start();

		let recorder = scope RecordingContactListener();
		let listeners = scope List<IContactListener>();
		listeners.Add(recorder);
		play.Physics.SetContactListeners(listeners);

		var entered = false;
		for (int i = 0; (i < 240) && !entered; i++)
		{
			play.Step(1);
			for (let contact in recorder.Contacts)
			{
				if (contact.Kind != .TriggerEnter)
					continue;

				if (((contact.A == volume) && (contact.B == faller))
					|| ((contact.A == faller) && (contact.B == volume)))
					entered = true;
			}
		}

		Test.Assert(entered);
	}
}
