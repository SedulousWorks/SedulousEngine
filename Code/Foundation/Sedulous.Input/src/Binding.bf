using Sedulous.Core;

namespace Sedulous.Input;

/// One physical binding: a tag, and the fields that tag gives meaning to.
///
/// FLAT rather than a union or a hierarchy. Only the fields its source uses are read, the
/// rest sit at defaults that cost almost nothing on disk, and an editor can render the
/// whole thing as one grid row instead of a shape that changes per source.
[Scriptable(.AllPublic)]
struct Binding
{
	public BindingSource Source = .Key;

	/// A KeyCode, MouseButton, MouseAxisCode, GamepadButton, GamepadAxis or StickCode,
	/// depending on Source.
	public uint32 Code = 0;

	/// Key only: the modifier mask a press must carry. Zero requires none.
	public uint32 Modifiers = 0;

	/// The gamepad index, or -1 for any connected pad.
	public int32 Device = -1;

	/// Analog sources. CIRCULAR for a stick, so a diagonal is not easier to reach than a
	/// cardinal.
	public float DeadZone = 0.15f;

	/// The response scale. A key bound to an axis uses -1 for the negative direction, which
	/// is how one axis is built out of two keys.
	public float Scale = 1.0f;

	/// Flips the value. For a stick, flips Y.
	public bool Invert = false;

	/// Composite2D: clamp a diagonal to length one, so a diagonal is not faster.
	public bool Normalize = true;

	/// Composite2D: the four keys.
	public uint32 NegX = 0;
	public uint32 PosX = 0;
	public uint32 NegY = 0;
	public uint32 PosY = 0;

	/// Touch sources: the region that activates them, in NORMALISED window coordinates,
	/// because that is what a finger position arrives as and a region in pixels would mean
	/// something different on every screen.
	public float RegionX = 0.0f;
	public float RegionY = 0.0f;
	public float RegionW = 1.0f;
	public float RegionH = 1.0f;

	/// How far a touch stick deflects for a full reading, also normalised.
	public float StickRadius = 0.15f;

	public this() {}
}
