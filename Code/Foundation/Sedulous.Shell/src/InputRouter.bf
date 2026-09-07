using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.Shell;

/// The single owner of hover, focus and capture across a set of surfaces.
///
/// One owner rather than each surface deciding for itself, because the answers are
/// EXCLUSIVE: exactly one surface is hovered, one focused, one holds the pointer while a
/// button is down. Surfaces deciding independently is how two viewports both conclude they
/// are hovered and both react to the same click.
///
/// Run once a frame, after the shell has pumped OS events.
class InputRouter
{
	/// Frames capture may persist with no button down before the leak is reported.
	/// Roughly half a second at sixty frames a second: long enough not to fire on a frame
	/// where the release is still in flight, short enough to catch a stuck drag.
	private const uint32 cCaptureLeakFrames = 30;

	private IInputManager mRaw;
	private List<InputSurface> mSurfaces = new .() ~ delete _;

	private InputSurface mHovered;
	private InputSurface mFocused;
	private InputSurface mCaptured;

	private bool mFocusFollowsHover;
	private bool mExternalMouseCapture;
	private bool mExternalKeyboardCapture;

	private uint32 mCaptureNoButtonFrames;
	private bool mCaptureLeakLogged;

	public this(IInputManager raw) { mRaw = raw; }

	public void AddSurface(InputSurface surface)
	{
		if (surface != null)
			mSurfaces.Add(surface);
	}

	public void RemoveSurface(InputSurface surface)
	{
		mSurfaces.Remove(surface);

		// A removed surface must not stay focused or capturing: the router would keep
		// routing to an object the caller is about to delete.
		if (mFocused === surface)
			mFocused = null;
		if (mCaptured === surface)
			mCaptured = null;
		if (mHovered === surface)
			mHovered = null;
	}

	/// When on, hovering a surface also focuses it, so the keyboard follows the pointer.
	/// Off by default, where focus changes on a click.
	public void SetFocusFollowsHover(bool on) => mFocusFollowsHover = on;

	/// Lets an external overlay swallow input for a frame.
	///
	/// While set, NO surface is hovered or focused, so a viewport camera ignores the wheel
	/// and the keys the overlay is using. Set each frame before Update.
	public void SetExternalCapture(bool mouse, bool keyboard)
	{
		mExternalMouseCapture = mouse;
		mExternalKeyboardCapture = keyboard;
	}

	public InputSurface Hovered => mHovered;
	public InputSurface Focused => mFocused;
	public InputSurface Captured => mCaptured;

	/// Resolves the gate for every surface and pushes it.
	public void Update()
	{
		let rawMouse = mRaw.Mouse;
		let position = Float2(rawMouse.X, rawMouse.Y);
		let delta = Float2(rawMouse.DeltaX, rawMouse.DeltaY);
		let hoverWindow = mRaw.HoverWindow;

		ResolveHover(position, hoverWindow);

		let anyDown = rawMouse.IsButtonDown(.Left) || rawMouse.IsButtonDown(.Right)
			|| rawMouse.IsButtonDown(.Middle);
		let anyPressed = rawMouse.IsButtonPressed(.Left) || rawMouse.IsButtonPressed(.Right)
			|| rawMouse.IsButtonPressed(.Middle);

		ResolveCapture(anyDown, anyPressed);
		ResolveFocus(anyPressed);

		let target = (mCaptured != null) ? mCaptured : mHovered;
		PushGates(position, delta, hoverWindow, target);
	}

	/// The surface under the pointer. Last match wins, so the most recently added is
	/// treated as topmost.
	private void ResolveHover(Float2 position, uint32 hoverWindow)
	{
		mHovered = null;
		if (mExternalMouseCapture)
			return;

		for (let surface in mSurfaces)
		{
			// Window first: a surface in another window cannot be under this pointer,
			// however well its rectangle happens to line up.
			if (surface.Window != hoverWindow)
				continue;
			if (surface.Fit.DstRect().Contains(position))
				mHovered = surface;
		}
	}

	/// A held button pins the pointer to the surface the press STARTED on, so a drag that
	/// leaves the rectangle keeps reporting to it.
	private void ResolveCapture(bool anyDown, bool anyPressed)
	{
		let before = mCaptured;

		if ((mCaptured != null) && (!anyDown || mExternalMouseCapture))
			mCaptured = null;

		if (!mExternalMouseCapture && (mCaptured == null) && (mHovered != null) && anyPressed)
			mCaptured = mHovered;

		if (mCaptured !== before)
		{
			mCaptureNoButtonFrames = 0;
			mCaptureLeakLogged = false;
		}

		// A watchdog, because a capture that never releases is a real and miserable bug:
		// the viewport keeps eating the mouse and nothing says why. Capture should have
		// been released above, so reaching here with no button down means something else
		// is pinning it.
		if ((mCaptured != null) && !anyDown)
		{
			mCaptureNoButtonFrames++;
			if ((mCaptureNoButtonFrames >= cCaptureLeakFrames) && !mCaptureLeakLogged)
			{
				GlobalLog(.Error,
					"Input: viewport capture STUCK, held {} frames with no mouse button down, so a button up was probably missed",
					mCaptureNoButtonFrames);
				mCaptureLeakLogged = true;
			}
		}
		else
		{
			mCaptureNoButtonFrames = 0;
		}
	}

	private void ResolveFocus(bool anyPressed)
	{
		if (mExternalKeyboardCapture)
		{
			// An overlay text field has the keyboard, so typing must not also drive a
			// viewport.
			mFocused = null;
		}
		else if (mFocusFollowsHover)
		{
			// Only on a hover: keeping the last focus means the keyboard survives the
			// pointer briefly leaving every surface.
			if (mHovered != null)
				mFocused = mHovered;
		}
		else if (anyPressed && (mHovered != null))
		{
			mFocused = mHovered;
		}
	}

	private void PushGates(Float2 position, Float2 delta, uint32 hoverWindow, InputSurface target)
	{
		for (let surface in mSurfaces)
		{
			// The last content position is KEPT when the pointer is not over this surface,
			// so a camera reading it mid drag does not see the value jump to the origin.
			var content = surface.ContentMouse;
			if (surface.Window == hoverWindow)
			{
				if (surface.Fit.ToContent(position, let mapped))
					content = mapped;
			}

			// Only the target gets a delta. Every other surface reads zero, so a drag moves
			// one viewport rather than all of them.
			var contentDelta = Float2.Zero;
			if (surface === target)
			{
				let scale = surface.Fit.Scale();
				contentDelta = .(delta.X * scale.X, delta.Y * scale.Y);
			}

			surface.ApplyGate(surface === mHovered, surface === mFocused, surface === mCaptured,
				content, contentDelta);
		}
	}
}
