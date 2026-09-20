namespace Sedulous.Editor.Scene;

/// A gizmo handle: an axis, the plane perpendicular to one, or the view aligned centre.
enum GizmoAxis : uint8
{
	None,
	X,
	Y,
	Z,
	PlaneX,
	PlaneY,
	PlaneZ,
	View
}
