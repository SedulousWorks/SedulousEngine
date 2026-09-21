using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Editor.ViewportTools;

/// One frame of viewport input, built by the host: the page owns camera policy, so it masks
/// buttons and nulls the keyboard while the camera owns the mouse. A plain struct, so tests
/// script whole gestures without a viewport.
struct ViewportToolInput
{
	public ViewportRay Ray = .();
	public Float3 CameraPosition = .Zero;
	public Float3 CameraForward = .(0.0f, 0.0f, -1.0f);
	public float FovY = 1.0472f;

	/// False when the pointer is not over the viewport this frame: a tool keeps its
	/// selection-tracking visuals in sync but clears hover, ignores buttons, and finishes or
	/// aborts an in-flight gesture.
	public bool PointerValid = true;

	/// The pointer in view pixels (y down, row nought at the top) and the view's size: what a
	/// GPU pick needs. Meaningful only while PointerValid and the size is non-zero.
	public int32 PointerX = 0;
	public int32 PointerY = 0;
	public uint32 ViewportWidth = 0;
	public uint32 ViewportHeight = 0;

	/// Strictly "the pointer is over the viewport" (PointerValid also admits focused but not
	/// hovered, so hotkeys keep working); click-initiated gestures require this one.
	public bool PointerOver = true;

	public bool LeftPressed = false;
	public bool LeftDown = false;
	public bool LeftReleased = false;
	public bool Ctrl = false;
	public bool Shift = false;
	/// Vertical scroll this frame, for brush resize and the like.
	public float WheelDelta = 0.0f;
	/// A continuous brush scales its per-dab delta by this.
	public float DeltaSeconds = 0.0f;

	/// True while edits are refused (Simulate mode): tools may hover and inspect, the host
	/// still picks selection, but no tool may open a command or mutate anything.
	public bool EditingLocked = false;

	/// Null while the camera owns input; tools read key edges for their hotkeys and must
	/// tolerate null every frame.
	public IKeyboard Keyboard = null;
}
