namespace Sedulous.Physics;

/// Interface for receiving contact/collision events.
interface IContactListener
{
	/// Called when two bodies first begin touching.
	/// Return false to ignore the contact (bodies will pass through each other).
	bool OnContactAdded(BodyHandle body1, BodyHandle body2, ContactEvent event);

	/// Called each frame while two bodies remain in contact.
	void OnContactPersisted(BodyHandle body1, BodyHandle body2, ContactEvent event);

	/// Called when two bodies stop touching.
	void OnContactRemoved(BodyHandle body1, BodyHandle body2);
}
