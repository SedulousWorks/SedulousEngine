namespace Sedulous.UI;

/// Where a drag gesture has got to.
enum DragState
{
	case Idle;
	/// The mouse went down on a drag source; whether it is a drag or a click is not yet known.
	case Potential;
	/// Past the threshold: the adorner is up and drop targets are being asked.
	case Active;
}
