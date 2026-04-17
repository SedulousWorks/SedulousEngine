namespace Sedulous.UI;

/// Tracks which phase the UIContext is currently in, so synchronous
/// tree mutations can assert when called during unsafe phases.
public enum UIPhase
{
	/// No phase running. Safe to mutate synchronously.
	Idle,
	/// Draining the MutationQueue.
	Draining,
	/// Routing input events through the tree.
	RoutingInput,
	/// Running the Measure/Layout pass.
	LayingOut,
	/// Walking the tree for Draw calls.
	Drawing
}
