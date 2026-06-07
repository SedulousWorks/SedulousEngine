namespace Sedulous.GUI;

/// Phase of event propagation through the view tree.
/// Events flow: Capture (root -> target) -> Target -> Bubble (target -> root).
public enum EventPhase
{
	/// Event traveling from root toward the target.
	/// Parents see the event before children. Setting Handled stops
	/// the event from reaching the target.
	Capture,
	/// Event firing on the target view itself.
	Target,
	/// Event traveling from target back toward root.
	/// Parents see the event after children. Setting Handled stops
	/// further bubbling.
	Bubble
}
