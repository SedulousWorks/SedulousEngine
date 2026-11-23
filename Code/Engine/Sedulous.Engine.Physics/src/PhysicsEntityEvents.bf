using System;

namespace Sedulous.Engine.Physics;

/// The entity events physics posts to its scene (Scene.PostEntityEvent), one to each side of a
/// contact, which an entity's behaviors hear as on<Name>. A collision's arguments are the other
/// entity, the point, the normal and the speed (a float); a trigger's, the other entity alone. The
/// other entity is unassigned when its body no longer maps to a live entity (an end after the body
/// was destroyed).
static class PhysicsEntityEvents
{
	public const String ContactBegin = "contactBegin";
	public const String ContactEnd = "contactEnd";
	public const String TriggerEnter = "triggerEnter";
	public const String TriggerExit = "triggerExit";
}
