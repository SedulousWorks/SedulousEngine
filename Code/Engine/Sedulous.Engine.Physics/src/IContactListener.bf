namespace Sedulous.Engine.Physics;

/// A consumer of resolved contacts.
///
/// Called once per drained contact per registered listener, at the physics tick. An
/// implementation MUST only ENQUEUE: it is called from inside the step's dispatch, so doing
/// real work here would run it while the world is mid tick.
interface IContactListener
{
	void OnContact(EntityContact contact);
}
