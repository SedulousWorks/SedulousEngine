namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Abstract base for all button types. Provides click event, pressed state,
/// ICommand binding, focus/keyboard handling, and button chrome drawing.
/// Subclasses define how content is stored and drawn.
///
/// Background is set via the inline-style API:
/// `btn.SetStyle(.Background, new ColorDrawable(...))`. Theme rules
/// on the context StyleSheet contribute when no inline override is
/// set. Both paths flow through `ResolveStyleDrawable(.Background)`.
public abstract class ButtonBase : View
{
	private bool mIsPressed;

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
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
		{
			bg.Draw(ctx, bounds, state);
		}
		else
		{
			let radius = ResolveStyleFloat(.CornerRadius, 4);
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

	public override void OnActivate()
	{
		FireClick();
	}
}
