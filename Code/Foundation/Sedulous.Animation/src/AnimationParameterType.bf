namespace Sedulous.Animation;

enum AnimationParameterType
{
	case Float;
	case Int;
	case Bool;
	/// A bool that CONSUMES itself: set it, and the update that sees it clears it, so one
	/// press fires one transition rather than every frame the button is down.
	case Trigger;
}
