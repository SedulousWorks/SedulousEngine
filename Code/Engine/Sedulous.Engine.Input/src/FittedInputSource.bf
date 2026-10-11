using System;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Engine.Input;

/// The devices of another source with the MOUSE and the TOUCHES mapped into a fitted content
/// space: a game drawn at a fixed render resolution and fitted into its window reads its pointer
/// in render pixels, wherever the window puts the image, and a finger normalized over that image
/// (where its touch regions are). A turned present turns them back, so a game reads them in its
/// own frame. The keyboard, the pads and the event stream pass through.
///
/// Ungated, unlike an editor viewport's surface: it is the whole window's input, so a player
/// who never moves the mouse still has the keyboard. Over a letterbox bar the pointer maps
/// outside the render area rather than vanishing.
class FittedInputSource : IInputSourceProvider
{
	/// BORROWED: the source whose devices this presents.
	private IInputSourceProvider mInner;
	private FittedMouse mMouse = new .(this) ~ delete _;
	private FittedTouch mTouch = new .(this) ~ delete _;

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
	public ITouch Touch => (mInner.Touch != null) ? mTouch : null;
	public Span<InputEvent> Events => mInner.Events;

	/// A window point in render pixels, through the fit (its turn included) and without the
	/// bars' clamp.
	public Float2 ToContent(Float2 point) => Fit.ToContentUnclamped(point);
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
	/// Turned with the content as well as scaled: on a turned present, moving the mouse up the
	/// window moves right across the game.
	public float DeltaX => mSource.Fit.ToContentDelta(.(Raw.DeltaX, Raw.DeltaY)).X;
	public float DeltaY => mSource.Fit.ToContentDelta(.(Raw.DeltaX, Raw.DeltaY)).Y;
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

/// The inner touches through the fit: PointerX and PointerY in render pixels, X and Y normalized
/// over them.
class FittedTouch : ITouch
{
	/// BORROWED: the source it belongs to.
	private FittedInputSource mSource;

	public this(FittedInputSource source)
	{
		mSource = source;
	}

	public int32 TouchCount
	{
		get
		{
			let raw = mSource.Inner.Touch;
			return (raw != null) ? raw.TouchCount : 0;
		}
	}

	public bool HasTouch => TouchCount > 0;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		point = default;
		let raw = mSource.Inner.Touch;
		if (raw == null)
			return false;
		if (!raw.GetTouchPoint(index, let inner))
			return false;
		// Over a letterbox bar a finger maps outside the image (normalized below 0 or above 1)
		// rather than vanishing, as the mouse does.
		let content = mSource.ToContent(.(inner.PointerX, inner.PointerY));
		let src = mSource.Fit.SrcRect();
		point = inner;
		point.PointerX = content.X;
		point.PointerY = content.Y;
		point.X = (src.Width > 0.0f) ? (content.X - src.X) / src.Width : inner.X;
		point.Y = (src.Height > 0.0f) ? (content.Y - src.Y) / src.Height : inner.Y;
		return true;
	}
}
