namespace Sedulous.Physics;

/// Interface for receiving body activation/deactivation events.
interface IBodyActivationListener
{
	/// Called when a body wakes up from sleeping.
	void OnBodyActivated(BodyHandle body);

	/// Called when a body goes to sleep.
	void OnBodyDeactivated(BodyHandle body);
}
