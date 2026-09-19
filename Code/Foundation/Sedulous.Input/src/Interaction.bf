using Sedulous.Core;

namespace Sedulous.Input;

/// A button action's press shaping, and the time it is measured against.
[Scriptable(.AllPublic)]
struct Interaction
{
	public InteractionKind Kind = .None;
	/// The hold duration, the tap ceiling, or the double tap window, depending on Kind.
	public float Seconds = 0.3f;

	public this() {}
}
