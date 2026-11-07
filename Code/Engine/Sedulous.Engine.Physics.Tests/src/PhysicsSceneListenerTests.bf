using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// A system of the scene that hears its contacts, registering itself with the scene's physics
/// as a gameplay system does: one added after the physics finds it, one added before is found.
class ListeningSystem : SceneSystem, IContactListener
{
	public List<EntityContact> Contacts = new .() ~ delete _;

	public override void OnSceneCreate(Scene scene)
	{
		if (let physics = scene.GetSystem<PhysicsSceneSystem>())
			physics.AddSceneContactListener(this);
	}

	public ~this()
	{
		if (Scene != null)
		{
			if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
				physics.RemoveSceneContactListener(this);
		}
	}

	public void OnContact(EntityContact contact)
	{
		Contacts.Add(contact);
	}
}

/// A scene's own contact listeners: they hear its contacts with no subsystem, whichever of
/// them and the physics is added first, and stop as they go.
class PhysicsSceneListenerTests
{
	/// Steps until the box lands on the floor, true when `listener` heard that Begin.
	private static bool HeardTheLanding(PhysicsPlayScene play, ListeningSystem listener, EntityHandle floor, EntityHandle body)
	{
		for (int i < 120)
		{
			play.Step(1);
			for (let contact in listener.Contacts)
			{
				if ((contact.Kind == .Begin) && (contact.Scene === play.Scene)
					&& (((contact.A == body) && (contact.B == floor)) || ((contact.A == floor) && (contact.B == body))))
					return true;
			}
		}
		return false;
	}

	/// A listener added after the physics registers itself and hears the collision, without
	/// the subsystem's list; removed, it is let go and the steps go on.
	[Test]
	public static void ASceneListenerHearsItsScenesContacts()
	{
		let play = scope PhysicsPlayScene();
		let floor = play.AddFloor();
		let @box = play.AddBox(1.4f);
		let listener = play.Scene.AddSystem<ListeningSystem>();
		Test.Assert(play.Physics.SceneContactListenerCount == 1);
		play.Start();

		Test.Assert(HeardTheLanding(play, listener, floor, @box), "the scene listener heard the landing");

		play.Scene.RemoveSystem<ListeningSystem>();
		Test.Assert(play.Physics.SceneContactListenerCount == 0, "let go as it goes");
		play.Step(30);
	}

	/// The physics finds a listener the scene had before it, and a duplicate is ignored.
	[Test]
	public static void ThePhysicsFindsAListenerAddedBeforeIt()
	{
		let scene = scope Scene("listener-first");
		let listener = scene.AddSystem<ListeningSystem>();
		PhysicsScene.AddPhysicsSceneManagers(scene);
		let physics = scene.GetSystem<PhysicsSceneSystem>();
		Test.Assert(physics.SceneContactListenerCount == 1);
		physics.AddSceneContactListener(listener);
		Test.Assert(physics.SceneContactListenerCount == 1, "a duplicate is ignored");
	}
}
