using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Scene;
using Sedulous.Engine.Physics;

namespace Sedulous.Engine.Physics.Tests;

/// What one side of a contact was told: the entity, the other side, and a collision's geometry.
struct RecordedContact
{
	public ContactKind Kind;
	public Scene Scene;
	/// The entity the event was posted to.
	public EntityHandle A;
	/// The other side.
	public EntityHandle B;
	public Float3 Point;
	public Float3 Normal;
	public float Speed;
}

/// Records the contact events physics posts to its scene, one per side of each contact.
class RecordingContactSink : IEntityEventSink
{
	public List<RecordedContact> Contacts = new .() ~ delete _;

	public void OnEntityEvent(Scene scene, EntityEvent entityEvent)
	{
		RecordedContact contact = default;
		if (entityEvent.Name == PhysicsEntityEvents.ContactBegin)
			contact.Kind = .Begin;
		else if (entityEvent.Name == PhysicsEntityEvents.ContactEnd)
			contact.Kind = .End;
		else if (entityEvent.Name == PhysicsEntityEvents.TriggerEnter)
			contact.Kind = .TriggerEnter;
		else if (entityEvent.Name == PhysicsEntityEvents.TriggerExit)
			contact.Kind = .TriggerExit;
		else
			return;
		contact.Scene = scene;
		contact.A = entityEvent.Target;
		contact.B = entityEvent.Args[0].Entity;
		if (entityEvent.Args.Length == 4)
		{
			contact.Point = entityEvent.Args[1].Float3;
			contact.Normal = entityEvent.Args[2].Float3;
			contact.Speed = (float)entityEvent.Args[3].Float;
		}
		Contacts.Add(contact);
	}
}
