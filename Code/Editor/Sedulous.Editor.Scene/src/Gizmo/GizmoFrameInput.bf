using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// One frame of pointer and key state for the gizmo controller.
struct GizmoFrameInput
{
	public GizmoRay Ray = .();
	public Float3 CameraPosition = .Zero;
	public Float3 CameraForward = .(0, 0, -1);
	public float FovY = 1.0472f;
	public bool LeftPressed = false;
	public bool LeftDown = false;
	public bool LeftReleased = false;
	/// Held Ctrl.
	public bool Snap = false;
	/// W, E, R and X, as edges.
	public bool KeyTranslate = false;
	public bool KeyRotate = false;
	public bool KeyScale = false;
	public bool KeyToggleSpace = false;

	/// False while the pointer is off the viewport or editing is locked: the pose still
	/// syncs, nothing is hovered, and an in-flight drag closes out.
	public bool PointerValid = true;
}
