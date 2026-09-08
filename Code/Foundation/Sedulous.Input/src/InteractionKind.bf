namespace Sedulous.Input;

/// The shape a BUTTON action's press takes.
///
/// A small state machine per action, so a game does not write the same press timing logic
/// for every ability it has.
enum InteractionKind : uint8
{
	/// Plain press and release edges.
	None,
	/// The press fires only once it has been held long enough.
	Hold,
	/// A single frame pulse at RELEASE, and only if the press was short enough.
	Tap,
	/// A single frame pulse on the second press, if it lands soon enough after the first.
	DoubleTap
}
