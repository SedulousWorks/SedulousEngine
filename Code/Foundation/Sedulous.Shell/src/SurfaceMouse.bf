using Sedulous.Core;

namespace Sedulous.Shell;

/// The surface's mouse: the raw one transformed into content space and gated by whether
/// the surface is hovered or captured.
///
/// It implements IMouse, so code written against the shell's mouse works unchanged when
/// handed this instead. That substitutability is the whole point of the surface layer.
class SurfaceMouse : IMouse
{
	private InputSurface mSurface;

	public this(InputSurface surface) { mSurface = surface; }

	/// Content space, already transformed by the surface's fit.
	public float X => mSurface.ContentMouse.X;
	public float Y => mSurface.ContentMouse.Y;

	/// Desktop space, so surface independent: it passes through untransformed.
	public float GlobalX => mSurface.Raw.Mouse.GlobalX;
	public float GlobalY => mSurface.Raw.Mouse.GlobalY;

	public float DeltaX => mSurface.ContentDelta.X;
	public float DeltaY => mSurface.ContentDelta.Y;

	// Gated on MouseActive rather than Hovered: a drag that leaves the rect keeps
	// reporting, because the press captured the pointer.
	public float ScrollX => mSurface.MouseActive ? mSurface.Raw.Mouse.ScrollX : 0.0f;
	public float ScrollY => mSurface.MouseActive ? mSurface.Raw.Mouse.ScrollY : 0.0f;

	public bool IsButtonDown(MouseButton button)
		=> mSurface.MouseActive && mSurface.Raw.Mouse.IsButtonDown(button);
	public bool IsButtonPressed(MouseButton button)
		=> mSurface.MouseActive && mSurface.Raw.Mouse.IsButtonPressed(button);
	public bool IsButtonReleased(MouseButton button)
		=> mSurface.MouseActive && mSurface.Raw.Mouse.IsButtonReleased(button);

	// Cursor and capture control are NOT gated: they act on the real device, and a
	// surface asking for a resize cursor means it.
	public bool RelativeMode => mSurface.Raw.Mouse.RelativeMode;
	public void SetRelativeMode(bool enabled) => mSurface.Raw.Mouse.SetRelativeMode(enabled);
	public bool CursorVisible => mSurface.Raw.Mouse.CursorVisible;
	public void SetCursorVisible(bool visible) => mSurface.Raw.Mouse.SetCursorVisible(visible);
	public void SetCursor(CursorType cursor) => mSurface.Raw.Mouse.SetCursor(cursor);
	public void SetGlobalCapture(bool enabled) => mSurface.Raw.Mouse.SetGlobalCapture(enabled);
}
