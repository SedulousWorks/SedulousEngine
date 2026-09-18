using Sedulous.Core;

namespace Sedulous.Input;

/// Which physical thing a binding reads.
///
/// The tag on a flat record: only the fields its source uses mean anything, and the rest
/// stay at their defaults. Flat because it then serializes compactly and an editor can show
/// it as a grid rather than a tree of variants.
[Scriptable(.AllPublic)]
enum BindingSource : uint8
{
	/// Code is a KeyCode, with an optional required modifier mask.
	Key,
	/// Code is a MouseButton.
	MouseButton,
	/// A rate, so NEVER time scaled: slowing time must not slow the pointer.
	MouseAxis,
	/// A rate in two dimensions.
	MouseDelta,
	/// Code is a GamepadButton; device -1 means any pad.
	GamepadButton,
	/// Code is a GamepadAxis, with a dead zone, an inversion and a scale.
	GamepadAxis,
	/// A stick, with a CIRCULAR dead zone rather than a per axis one.
	GamepadStick,
	/// Two dimensions from four digital keys, as WASD.
	Composite2D,
	/// Any touch inside a normalised screen region.
	TouchButton,
	/// A FLOATING virtual stick: the touch that starts inside the region anchors there, and
	/// the deflection from that anchor is the value. Anchoring where the thumb lands rather
	/// than where the art sits is what makes one usable without looking.
	TouchStick
}
