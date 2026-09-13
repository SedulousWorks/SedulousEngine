using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// What a real collision delivers, and the impulse queue that lets a thing be launched before
/// its body exists.
class PhysicsContactTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	/// A collision reaches a listener with BOTH sides resolved and its geometry intact.
	[Test]
	public static void ACollisionReachesAListenerWithResolvedEntitiesAndGeometry()
	{
		let play = scope PhysicsPlayScene();
		let floor = play.AddFloor();
		// Close enough to land almost at once.
		let @box = play.AddBox(1.4f);
		play.Start();

		let recorder = scope RecordingContactListener();
		let listeners = scope List<IContactListener>();
		listeners.Add(recorder);
		play.Physics.SetContactListeners(listeners);

		var sawBegin = false;
		for (int i = 0; (i < 120) && !sawBegin; i++)
		{
			play.Step(1);
			for (let contact in recorder.Contacts)
			{
				if (contact.Kind != .Begin)
					continue;

				if (((contact.A == @box) && (contact.B == floor))
					|| ((contact.A == floor) && (contact.B == @box)))
				{
					sawBegin = true;
					Test.Assert(contact.Scene === play.Scene);
					// An APPROACH speed, so never negative.
					Test.Assert(contact.Speed >= 0.0f);
					// And a unit normal.
					Test.Assert(Near(Length(contact.Normal), 1.0f, 0.02f));
				}
			}
		}

		Test.Assert(sawBegin);
	}

	/// An impulse applied before the body exists QUEUES, and the assembly flushes it.
	///
	/// A body added after the scene started is built on the next step, so launching it in the
	/// same frame would otherwise be dropped and the thing would simply fall.
	[Test]
	public static void AnImpulseBeforeTheBodyExistsIsQueuedAndFlushed()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		// The world and the floor exist: this is the running game's state.
		play.Start();

		let @box = play.AddBox(5.0f);
		play.Scene.UpdateTransforms();

		play.Physics.ApplyImpulse(@box, .(0.0f, 0.0f, 5000.0f));

		// The assembly builds the body and flushes what was queued.
		play.Step(1);

		let body = play.Bodies.Get(@box);
		Test.Assert(body != null);
		Test.Assert(body.Body.IsValid);
		Test.Assert(play.Physics.World.LinearVelocity(body.Body).Z > 0.0f);
	}

	/// The queue belongs to the RUN. It must not survive a stop, must not survive
	/// deactivation, and must not grow without bound on a body that never appears.
	[Test]
	public static void TheImpulseQueueIsRunScopedAndCannotAccumulate()
	{
		// Stopping clears what was queued in the last frame before it.
		{
			let play = scope PhysicsPlayScene();
			play.AddFloor();
			let @box = play.AddBox(5.0f);
			play.Start();

			play.Scene.SetActive(@box, false);
			// The reconcile destroys the body.
			play.Step(1);

			play.Physics.ApplyImpulse(@box, .(0.0f, 0.0f, 500.0f));
			play.Scene.Stop();
			Test.Assert(play.Bodies.Get(@box).PendingImpulse.Z == 0.0f);
		}

		// And an impulse queued while the entity is inactive is dropped every reconcile, so
		// coming back does not launch a sum accumulated across the dark window.
		{
			let play = scope PhysicsPlayScene();
			play.AddFloor();
			let @box = play.AddBox(2.0f);
			play.Start();

			play.Scene.SetActive(@box, false);
			// The body is destroyed, and the queue clears with it.
			play.Step(1);

			// A script spamming the call at a disabled entity.
			for (int i < 60)
			{
				play.Physics.ApplyImpulse(@box, .(0.0f, 0.0f, 5000.0f));
				play.Step(1);
			}

			Test.Assert(play.Bodies.Get(@box).PendingImpulse.Z == 0.0f);

			// The activation edge builds the body, with no accumulated launch behind it.
			play.Scene.SetActive(@box, true);
			play.Step(1);

			let body = play.Bodies.Get(@box);
			Test.Assert(body.Body.IsValid);
			Test.Assert(play.Physics.World.LinearVelocity(body.Body).Z < 1.0f);
		}
	}
}
