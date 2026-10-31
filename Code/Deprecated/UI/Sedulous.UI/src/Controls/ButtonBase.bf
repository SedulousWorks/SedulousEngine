using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// What every button shares: the pressed state, the click, and an optional bound command.
///
/// A click needs BOTH a press and a release over the button, so pressing and dragging away
/// cancels it. That is the behaviour anyone expects and it costs a flag to get right.
abstract class ButtonBase : View
{
	/// BORROWED, and optional. A command that cannot execute disables the button.
	public ICommand Command = null;
	public Event<delegate void(ButtonBase)> OnClick ~ _.Dispose();

	private bool mIsPressed = false;

	protected this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	public bool IsPressed => mIsPressed;

	public override ControlState GetControlState()
	{
		var state = ControlState.Normal;

		if (!IsEffectivelyEnabled() || ((Command != null) && !Command.CanExecute()))
			state |= .Disabled;
		if (mIsPressed)
			state |= .Pressed;
		// Keyboard acquired only: a clicked button holds focus without a ring.
		if (IsFocusVisible())
			state |= .Focused;
		if (IsHovered())
			state |= .Hover;

		return state;
	}

	/// Fires the click and runs the bound command.
	public void FireClick()
	{
		if (!IsEffectivelyEnabled())
			return;
		if ((Command != null) && !Command.CanExecute())
			return;

		// PINNED: a click handler may destroy this button, a panel rebuilding itself being the
		// usual case. Without the pin, reading Command afterwards touches freed memory.
		AddRef();
		defer ReleaseRef();

		OnClick(this);

		if (Command != null)
			Command.Execute();
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		mIsPressed = true;
		InvalidateVisual(); // a press tint changes no geometry
		e.Handled = true;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if ((e.Button != .Left) || !mIsPressed)
			return;

		mIsPressed = false;
		InvalidateVisual();

		// Only a release still OVER the button is a click: dragging off cancels it.
		if (IsHovered())
			FireClick();

		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if ((e.Key != .Return) && (e.Key != .Space))
			return;

		FireClick();
		e.Handled = true;
	}

	public override void OnActivate() => FireClick();

	/// The button's chrome: the themed background where there is one, and a state tinted
	/// rounded rect where there is not, so a button is usable before any theme is loaded.
	protected void DrawButtonBackground(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		if (let background = ResolveStyleDrawable(.Background))
		{
			background.Draw(ctx, bounds, state);
			return;
		}

		let radius = ResolveStyleFloat(.CornerRadius, 4.0f);
		var fill = Color(55 / 255.0f, 58 / 255.0f, 70 / 255.0f, 1.0f);

		// Checked in priority order: disabled beats pressed beats focused beats hover, which is
		// the same precedence the state list drawables use.
		if (state.HasFlag(.Disabled))
			fill = Palette.ComputeDisabled(fill);
		else if (state.HasFlag(.Pressed))
			fill = Palette.ComputePressed(fill);
		else if (state.HasFlag(.Focused))
			fill = Palette.ComputeFocused(fill);
		else if (state.HasFlag(.Hover))
			fill = Palette.ComputeHover(fill);

		if (radius > 0)
			ctx.VG.FillRoundedRect(bounds, radius, fill);
		else
			ctx.VG.FillRect(bounds, fill);
	}
}
