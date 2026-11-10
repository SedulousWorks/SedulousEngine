using System;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// Contacts to behaviours: what the scene's physics pushes reaches both sides at the end of
/// the next tick, a collision with its geometry and a trigger with the other alone, to the
/// classes that override the callback, skipping what is gone or not ticking.
class BehaviourContactTests
{
	private const float cDt = 1.0f / 60.0f;

	/// What the physics step hands its listeners, driven directly.
	private static EntityContact Contact(Scene scene, ContactKind kind, EntityHandle a, EntityHandle b, float speed = 0.0f)
	{
		var contact = EntityContact();
		contact.Kind = kind;
		contact.Scene = scene;
		contact.A = a;
		contact.B = b;
		contact.Point = .(0.0f, 0.5f, 0.0f);
		contact.Normal = .(0.0f, 1.0f, 0.0f);
		contact.Speed = speed;
		return contact;
	}

	/// A collision is queued, not delivered inside the physics step, and reaches both sides
	/// at the end of the next tick: after the updates, before the late tick, each side seeing
	/// the other, with the point, normal and speed.
	[Test]
	public static void ACollisionReachesBothSidesAtTheEndOfTheTick()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let bumpers = scene.AddSystem<BehaviourManager<Bumper>>();
		let crate = scene.CreateEntity("crate");
		let floor = scene.CreateEntity("floor");
		walkers.Add(crate);
		bumpers.Add(crate);
		bumpers.Add(floor);
		scene.Update(cDt);

		LifecycleLog.Text.Clear();
		system.OnContact(Contact(scene, .Begin, crate, floor, 2.5f));
		Test.Assert(LifecycleLog.Text.IsEmpty, "queued, not delivered inside the caller");
		Test.Assert(system.PendingContactCount == 2, "one entry per side");

		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:crate.Update B:crate.Begin(floor) B:floor.Begin(crate) W:crate.Late ", LifecycleLog.Text);
		Test.Assert(system.PendingContactCount == 0);
		for (let bumper in bumpers.Instances)
		{
			Test.Assert(Math.Abs(bumper.LastSpeed - 2.5f) < 1e-6f, "the speed crossed");
			Test.Assert(Math.Abs(bumper.LastPoint.Y - 0.5f) < 1e-6f, "the point crossed");
			Test.Assert(Math.Abs(bumper.LastNormal.Y - 1.0f) < 1e-6f, "the normal crossed");
		}

		LifecycleLog.Text.Clear();
		system.OnContact(Contact(scene, .End, crate, floor));
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:crate.Update B:crate.End(floor) B:floor.End(crate) W:crate.Late ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:crate.Update W:crate.Late ", "delivered once");
	}

	/// A trigger reaches the trigger callbacks with the other alone, every hearing behaviour
	/// of each side in registration order; a class overriding only the entry hears no
	/// collision and no exit.
	[Test]
	public static void ATriggerReachesTheTriggerCallbacks()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let bumpers = scene.AddSystem<BehaviourManager<Bumper>>();
		let sensors = scene.AddSystem<BehaviourManager<Sensor>>();
		let volume = scene.CreateEntity("volume");
		let faller = scene.CreateEntity("faller");
		bumpers.Add(volume);
		sensors.Add(volume);
		bumpers.Add(faller);
		scene.Update(cDt);

		system.OnContact(Contact(scene, .TriggerEnter, volume, faller));
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "B:volume.Enter(faller) S:volume.Enter(faller) B:faller.Enter(volume) ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		system.OnContact(Contact(scene, .Begin, volume, faller, 1.0f));
		system.OnContact(Contact(scene, .TriggerExit, faller, volume));
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "B:volume.Begin(faller) B:faller.Begin(volume) B:faller.Exit(volume) B:volume.Exit(faller) ", LifecycleLog.Text);
	}

	/// Only a class that overrides a contact callback is on the contact list, each with the
	/// callbacks it overrides; with no such class, a contact is not even queued.
	[Test]
	public static void OnlyAClassOverridingAContactCallbackHearsContacts()
	{
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let markers = scene.AddSystem<BehaviourManager<Marker>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		walkers.Add(a);
		markers.Add(b);
		scene.Update(cDt);

		Test.Assert(walkers.Contacts == .None);
		Test.Assert(markers.Contacts == .None);
		Test.Assert(system.ContactCount == 0);
		system.OnContact(Contact(scene, .Begin, a, b));
		Test.Assert(system.PendingContactCount == 0, "nothing hears contacts: nothing queued");

		let bumpers = scene.AddSystem<BehaviourManager<Bumper>>();
		let sensors = scene.AddSystem<BehaviourManager<Sensor>>();
		Test.Assert(system.ContactCount == 2, "the bumper and the sensor");
		Test.Assert(bumpers.Contacts == (ContactCallbacks.ContactBegin | .ContactEnd | .TriggerEnter | .TriggerExit));
		Test.Assert(sensors.Contacts == .TriggerEnter);
		Test.Assert(!bumpers.TicksUpdate, "a contact callback is not a tick");
	}

	/// At delivery, an entity destroyed since the contact, a disabled behaviour and an inactive
	/// entity hear nothing; a side that maps to no entity is never queued, and the live side
	/// still hears the other, gone or not.
	[Test]
	public static void WhatIsGoneOrNotTickingHearsNothing()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let bumpers = scene.AddSystem<BehaviourManager<Bumper>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");
		let d = scene.CreateEntity("d");
		let e = scene.CreateEntity("e");
		bumpers.Add(a);
		bumpers.Add(b);
		bumpers.Add(c);
		bumpers.Add(d);
		bumpers.Add(e);
		scene.Update(cDt);

		system.OnContact(Contact(scene, .Begin, a, b));
		system.OnContact(Contact(scene, .Begin, c, d));
		system.OnContact(Contact(scene, .End, e, EntityHandle.Invalid));
		Test.Assert(system.PendingContactCount == 5, "the unassigned side is not queued");

		// Outside Update a destroy is at once.
		scene.DestroyEntity(b);
		bumpers.Get(c).Enabled = false;
		scene.SetActive(d, false);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "B:a.Begin(-) B:e.End(-) ", LifecycleLog.Text);
	}

	/// A contact of another scene is not this one's to queue, and a stopped scene drops what
	/// it had queued.
	[Test]
	public static void AnotherScenesContactAndAStoppedScenesQueueAreDropped()
	{
		let scene = scope Scene();
		let other = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let bumpers = scene.AddSystem<BehaviourManager<Bumper>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		bumpers.Add(a);
		bumpers.Add(b);

		system.OnContact(Contact(other, .Begin, a, b));
		Test.Assert(system.PendingContactCount == 0);

		scene.Start();
		system.OnContact(Contact(scene, .Begin, a, b));
		Test.Assert(system.PendingContactCount == 2);
		scene.Stop();
		Test.Assert(system.PendingContactCount == 0);
	}

	/// The scene's physics takes the system as a listener of its own contacts whichever of the
	/// two is added first, and lets it go when the system goes.
	[Test]
	public static void TheScenesPhysicsHearsTheSystemInEitherOrder()
	{
		{
			let scene = scope Scene();
			let physics = scene.AddSystem<PhysicsSceneSystem>();
			scene.AddSystem<BehaviourSystem>();
			Test.Assert(physics.SceneContactListenerCount == 1, "the system finds the physics");
			scene.RemoveSystem<BehaviourSystem>();
			Test.Assert(physics.SceneContactListenerCount == 0, "and leaves it as it goes");
		}
		{
			let scene = scope Scene();
			scene.AddSystem<BehaviourSystem>();
			let physics = scene.AddSystem<PhysicsSceneSystem>();
			Test.Assert(physics.SceneContactListenerCount == 1, "the physics finds the system");
		}
	}
}
