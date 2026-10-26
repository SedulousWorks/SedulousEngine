using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Engine.GUI;

/// The mouse as a world panel (or a fitted screen tier) sees it: at the point the pointer falls
/// in its pixels; its buttons, wheel and the rest the real one's, which it BORROWS.
class GuiPanelMouse : IMouse
{
	private IMouse mMouse;
	private Float2 mAt;

	public this(IMouse mouse, Float2 at)
	{
		mMouse = mouse;
		mAt = at;
	}

	public float X => mAt.X;
	public float Y => mAt.Y;
	public float GlobalX => mMouse.GlobalX;
	public float GlobalY => mMouse.GlobalY;
	public float DeltaX => mMouse.DeltaX;
	public float DeltaY => mMouse.DeltaY;
	public float ScrollX => mMouse.ScrollX;
	public float ScrollY => mMouse.ScrollY;

	public bool IsButtonDown(MouseButton button) => mMouse.IsButtonDown(button);
	public bool IsButtonPressed(MouseButton button) => mMouse.IsButtonPressed(button);
	public bool IsButtonReleased(MouseButton button) => mMouse.IsButtonReleased(button);

	public bool RelativeMode => mMouse.RelativeMode;
	public void SetRelativeMode(bool enabled) => mMouse.SetRelativeMode(enabled);
	public bool CursorVisible => mMouse.CursorVisible;
	public void SetCursorVisible(bool visible) => mMouse.SetCursorVisible(visible);
	public void SetCursor(CursorType cursor) => mMouse.SetCursor(cursor);
	public void SetGlobalCapture(bool enabled) => mMouse.SetGlobalCapture(enabled);
}
