using System;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Engine.Input;

/// The devices of another source with the MOUSE mapped into a fitted content space: a game
/// drawn at a fixed render resolution and fitted into its window reads its pointer in
/// render pixels, wherever the window puts the image. The keyboard, the pads, the touches and
/// the event stream pass through.
///
/// Ungated, unlike an editor viewport's surface: it is the whole window's input, so a player
/// who never moves the mouse still has the keyboard. Over a letterbox bar the pointer maps
/// outside the render area rather than vanishing.
class FittedInputSource : IInputSourceProvider
{
	/// BORROWED: the source whose devices this presents.
	private IInputSourceProvider mInner;
	private FittedMouse mMouse = new .(this) ~ delete _;

	/// The window region (the region) and the render resolution (the content) with the fit.
	/// The owner keeps the region current as the window resizes.
	public ContentFit Fit = .();

	public this(IInputSourceProvider inner)
	{
		mInner = inner;
	}

	public IInputSourceProvider Inner => mInner;

	public IKeyboard Keyboard => mInner.Keyboard;
	public IMouse Mouse => (mInner.Mouse != null) ? mMouse : null;
	public int32 GamepadCount => mInner.GamepadCount;
	public IGamepad GetGamepad(int32 index) => mInner.GetGamepad(index);
	public ITouch Touch => mInner.Touch;
	public Span<InputEvent> Events => mInner.Events;

	/// A window point in render pixels, through the fit and without the bars' clamp.
	public Float2 ToContent(Float2 point)
	{
		let dst = Fit.DstRect();
		let src = Fit.SrcRect();
		if ((dst.Width <= 0.0f) || (dst.Height <= 0.0f))
			return point;
		return .(src.X + (point.X - dst.X) / dst.Width * src.Width,
			src.Y + (point.Y - dst.Y) / dst.Height * src.Height);
	}
}

/// The inner mouse, its position and motion in the fitted content space.
class FittedMouse : IMouse
{
	/// BORROWED: the source it belongs to.
	private FittedInputSource mSource;

	public this(FittedInputSource source)
	{
		mSource = source;
	}

	private IMouse Raw => mSource.Inner.Mouse;

	public float X => mSource.ToContent(.(Raw.X, Raw.Y)).X;
	public float Y => mSource.ToContent(.(Raw.X, Raw.Y)).Y;
	public float GlobalX => Raw.GlobalX;
	public float GlobalY => Raw.GlobalY;
	/// Motion in render pixels too, so a look speed does not change with the window's size.
	public float DeltaX => Raw.DeltaX * mSource.Fit.Scale().X;
	public float DeltaY => Raw.DeltaY * mSource.Fit.Scale().Y;
	public float ScrollX => Raw.ScrollX;
	public float ScrollY => Raw.ScrollY;
	public bool IsButtonDown(MouseButton button) => Raw.IsButtonDown(button);
	public bool IsButtonPressed(MouseButton button) => Raw.IsButtonPressed(button);
	public bool IsButtonReleased(MouseButton button) => Raw.IsButtonReleased(button);
	public bool RelativeMode => Raw.RelativeMode;
	public void SetRelativeMode(bool enabled) => Raw.SetRelativeMode(enabled);
	public bool CursorVisible => Raw.CursorVisible;
	public void SetCursorVisible(bool visible) => Raw.SetCursorVisible(visible);
	public void SetCursor(CursorType cursor) => Raw.SetCursor(cursor);
	public void SetGlobalCapture(bool enabled) => Raw.SetGlobalCapture(enabled);
}
