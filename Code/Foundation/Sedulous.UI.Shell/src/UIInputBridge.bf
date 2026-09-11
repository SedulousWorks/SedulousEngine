using System;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.UI.Shell;

/// The platform's input, driven into a UIContext.
///
/// This is the ONLY place that knows both the shell and the UI. The core exposes an input
/// manager taking physical pixels and nothing else, which is what keeps it platform agnostic;
/// everything platform shaped lives here.
///
/// It also drives the window's text input from FOCUS: a field taking keyboard focus starts the
/// platform's composition, and losing it stops it. Nothing else knows when that should happen,
/// because only the UI knows what is focused.
///
/// The context and the window are both BORROWED.
class UIInputBridge
{
	private UIContext mContext;
	/// The window whose text input follows focus. Null disables that entirely.
	private IWindow mTextInputTarget = null;
	/// The last pointer position, because a wheel event carries a DELTA rather than a place.
	private float mLastX = 0.0f;
	private float mLastY = 0.0f;

	public this(UIContext context)
	{
		mContext = context;
	}

	/// The window whose platform text input follows UI focus. Null disables it.
	public void SetTextInputTarget(IWindow window)
	{
		mTextInputTarget = window;
	}

	/// Brings the window's text input into line with what is focused.
	///
	/// Called after every dispatch, because a click or a Tab can move focus and the platform
	/// has to be told: an IME left running over a button swallows keystrokes.
	public void SyncTextInput()
	{
		if ((mTextInputTarget == null) || (mContext == null))
			return;

		let wants = mContext.WantsTextInput();
		if (wants && !mTextInputTarget.IsTextInputActive)
			mTextInputTarget.StartTextInput();
		else if (!wants && mTextInputTarget.IsTextInputActive)
			mTextInputTarget.StopTextInput();
	}

	/// Routes one platform event. False when it is not the UI's business - a gamepad or a
	/// touch, which reach the UI by other paths if at all.
	public bool Dispatch(InputEvent e)
	{
		if (mContext == null)
			return false;

		let input = mContext.GetInputManager();
		var routed = true;

		switch (e.Kind)
		{
		case .MouseMove:
			RememberPosition(e.X, e.Y);
			input.ProcessMouseMove(e.X, e.Y);
		case .MouseButtonDown:
			RememberPosition(e.X, e.Y);
			input.ProcessMouseDown(ShellInputMapping.ToUIButton(e.Button), e.X, e.Y, mContext.TotalTime);
		case .MouseButtonUp:
			RememberPosition(e.X, e.Y);
			input.ProcessMouseUp(ShellInputMapping.ToUIButton(e.Button), e.X, e.Y);
		case .MouseWheel:
			// A wheel event's X and Y are the SCROLL, not a position, so the pointer's last
			// known place is what says which view is being scrolled.
			input.ProcessMouseWheel(mLastX, mLastY, e.X, e.Y,
				ShellInputMapping.ToUIModifiers(e.Modifiers));
		case .KeyDown:
			input.ProcessKeyDown(ShellInputMapping.ToUIKey(e.Key),
				ShellInputMapping.ToUIModifiers(e.Modifiers), false, mContext.TotalTime);
		case .KeyUp:
			input.ProcessKeyUp(ShellInputMapping.ToUIKey(e.Key),
				ShellInputMapping.ToUIModifiers(e.Modifiers), mContext.TotalTime);
		case .TextInput:
			DispatchText(input, e);
		default:
			routed = false;
		}

		SyncTextInput();
		return routed;
	}

	/// One event may carry SEVERAL characters, and each arrives at the focused control on its
	/// own: a composed sequence is still typing.
	private void DispatchText(InputManager input, InputEvent e)
	{
		// COPIED first: the text is a fixed array inside a by-value parameter, and a view over
		// it would be pointing at a temporary.
		var copy = e;
		let text = StringView(&copy.Text[0]);
		for (let character in text.DecodedChars)
			input.ProcessTextInput(character);
	}

	/// Polls a gated input surface: hover from the cursor, clicks from the press and release
	/// edges, and the wheel. Keys and text still arrive through Dispatch.
	///
	/// The surface's mouse is already in content space, having been gated and transformed by
	/// whatever owns it, so nothing here converts coordinates.
	public void PumpFromSurface(InputSurface surface)
	{
		if (mContext == null)
			return;

		let mouse = surface.Mouse;
		if (mouse == null)
			return;

		let input = mContext.GetInputManager();
		PumpMouse(input, mouse, mouse.X, mouse.Y);

		let scrollX = mouse.ScrollX;
		let scrollY = mouse.ScrollY;
		if ((scrollX != 0.0f) || (scrollY != 0.0f))
		{
			// The LIVE modifiers, so Shift and wheel scrolls sideways.
			let keyboard = surface.Keyboard;
			let modifiers = (keyboard != null)
				? ShellInputMapping.ToUIModifiers(keyboard.Modifiers)
				: Sedulous.UI.KeyModifiers.None;

			input.ProcessMouseWheel(mouse.X, mouse.Y, scrollX, scrollY, modifiers);
		}

		SyncTextInput();
	}

	/// Feeds the mouse at EXPLICIT coordinates rather than wherever the surface's cursor is.
	///
	/// For cross-window dragging: while a floating window is dragged the desktop cursor sits
	/// over THAT window, but the drag has to be delivered to another one, at coordinates
	/// relative to it, or its drop targets never see it. The button state still comes from the
	/// real mouse, so the held drag and the release that drops it both register.
	///
	/// No wheel: a drag in progress is not a scroll.
	public void PumpMouseAt(float x, float y, IMouse mouse)
	{
		if ((mContext == null) || (mouse == null))
			return;

		PumpMouse(mContext.GetInputManager(), mouse, x, y);
		SyncTextInput();
	}

	private void PumpMouse(InputManager input, IMouse mouse, float x, float y)
	{
		RememberPosition(x, y);
		input.ProcessMouseMove(x, y);

		for (let button in Sedulous.Shell.MouseButton[](.Left, .Middle, .Right))
		{
			if (mouse.IsButtonPressed(button))
				input.ProcessMouseDown(ShellInputMapping.ToUIButton(button), x, y, mContext.TotalTime);

			if (mouse.IsButtonReleased(button))
				input.ProcessMouseUp(ShellInputMapping.ToUIButton(button), x, y);
		}
	}

	/// Pushes the hovered view's cursor to the operating system.
	///
	/// A borderless window has no window manager drawing resize grips for it, so a floating
	/// dock panel's edges only look draggable if the application sets the cursor itself.
	public void SyncCursor(IMouse mouse)
	{
		if (mContext == null)
			return;

		mouse.SetCursor(ShellInputMapping.ToShellCursor(mContext.GetInputManager().CurrentCursor));
	}

	private void RememberPosition(float x, float y)
	{
		mLastX = x;
		mLastY = y;
	}
}
