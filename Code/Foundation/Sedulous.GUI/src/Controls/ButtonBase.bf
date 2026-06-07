namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Abstract base for all button types. Provides click event, pressed state,
/// ICommand binding, focus/keyboard handling, and button chrome drawing.
/// Subclasses define how content is stored and drawn.
public abstract class ButtonBase : View
{
	private bool mIsPressed;

	/// Per-instance background override (owned by this view).
	public Drawable Background ~ delete _;

	/// Optional command binding. Executed on click if CanExecute() is true.
	public ICommand Command;

	/// Click event.
	public Event<delegate void(ButtonBase)> OnClick ~ _.Dispose();

	/// Whether the button is currently pressed (visual state).
	public bool IsPressed => mIsPressed;

	protected this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	public override ControlState GetControlState()
	{
		var state = ControlState.Normal;
		if (!IsEffectivelyEnabled || (Command != null && !Command.CanExecute()))
			state |= .Disabled;
		if (mIsPressed) state |= .Pressed;
		if (IsFocused) state |= .Focused;
		if (IsHovered) state |= .Hover;
		return state;
	}

	/// Fire the click event and execute command if bound.
	public void FireClick()
	{
		if (!IsEffectivelyEnabled) return;
		if (Command != null && !Command.CanExecute()) return;

		OnClick(this);
		Command?.Execute();
	}

	// === Drawing helpers for subclasses ===

	protected void DrawButtonBackground(UIDrawContext ctx, RectangleF bounds, ControlState state)
	{
		let radius = ResolveStyleFloat(.CornerRadius, 4);

		if (Background != null)
		{
			Background.Draw(ctx, bounds, state);
		}
		else
		{
			let themeBg = ResolveStyleDrawable(.Background);
			if (themeBg != null)
				themeBg.Draw(ctx, bounds, state);
			else
				DrawDefaultBackground(ctx, bounds, state, radius);
		}
	}

	private void DrawDefaultBackground(UIDrawContext ctx, RectangleF bounds, ControlState state, float radius)
	{
		Color bg = .(55, 58, 70, 255);
		if (state.HasFlag(.Disabled))       bg = Palette.ComputeDisabled(bg);
		else if (state.HasFlag(.Pressed))   bg = Palette.ComputePressed(bg);
		else if (state.HasFlag(.Focused))   bg = Palette.ComputeFocused(bg);
		else if (state.HasFlag(.Hover))     bg = Palette.ComputeHover(bg);

		if (radius > 0)
			ctx.VG.FillRoundedRect(bounds, radius, bg);
		else
			ctx.VG.FillRect(bounds, bg);
	}

	// === Input handling ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left)
		{
			mIsPressed = true;
			Invalidate();
			e.Handled = true;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button == .Left && mIsPressed)
		{
			mIsPressed = false;
			Invalidate();

			// Fire click if mouse is still over this button
			if (IsHovered)
				FireClick();

			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key == .Return || e.Key == .Space)
		{
			FireClick();
			e.Handled = true;
		}
	}
}
