namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Stateful button that toggles between checked and unchecked.
/// Content-bearing - set Content for custom content, or construct with text.
public class ToggleButton : ButtonBase
{
	/// Whether the toggle is checked.
	public Property<bool> IsChecked = new .(false) ~ delete _;

	/// Per-instance background for checked state (owned).
	public Drawable CheckedBackground ~ delete _;

	/// The content view (owned by this button).
	private View mContent ~ delete _;

	public View Content
	{
		get => mContent;
		set
		{
			if (mContent != null)
				delete mContent;
			mContent = value;
			Invalidate();
		}
	}

	public Event<delegate void(ToggleButton, bool)> OnCheckedChanged ~ _.Dispose();

	public this(StringView text) : base()
	{
		IsChecked.SetOwner(this, .Visual);
		mContent = new Label(text);

		IsChecked.Changed.Add(new (val) =>
			{
				OnCheckedChanged(this, val);
			});
	}

	public this() : base()
	{
		IsChecked.SetOwner(this, .Visual);

		IsChecked.Changed.Add(new (val) =>
			{
				OnCheckedChanged(this, val);
			});
	}

	public override ControlState GetControlState()
	{
		var state = ControlState.Normal;
		if (!IsEffectivelyEnabled) state |= .Disabled;
		if (IsPressed) state |= .Pressed;
		if (IsFocused) state |= .Focused;
		if (IsHovered) state |= .Hover;
		if (IsChecked.Value) state |= .Checked;
		return state;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = ResolveStyleThickness(.Padding, .(12, 8));
		let inner = constraints.Deflate(pad).Loosen();

		float cw = 0, ch = 0;
		if (mContent != null)
		{
			if (mContent.Context == null && Context != null)
				Context.AttachView(mContent);
			mContent.Measure(inner);
			cw = mContent.MeasuredSize.X;
			ch = mContent.MeasuredSize.Y;
		}

		MeasuredSize = .(constraints.ConstrainWidth(cw + pad.TotalHorizontal),
			constraints.ConstrainHeight(ch + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent == null) return;
		let pad = ResolveStyleThickness(.Padding, .(12, 8));
		let contentW = width - pad.TotalHorizontal;
		let contentH = height - pad.TotalVertical;
		let cx = pad.Left + (contentW - mContent.MeasuredSize.X) * 0.5f;
		let cy = pad.Top + (contentH - mContent.MeasuredSize.Y) * 0.5f;
		mContent.Layout(cx, cy, mContent.MeasuredSize.X, mContent.MeasuredSize.Y);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();
		let radius = ResolveStyleFloat(.CornerRadius, 4);

		// Background based on checked state
		let bg = IsChecked.Value ? (CheckedBackground ?? Background) : Background;
		if (bg != null)
		{
			bg.Draw(ctx, bounds, state);
		}
		else if (IsChecked.Value)
		{
			// Checked: try CheckedBackground from theme, fall back to accent color
			let checkedBg = ResolveStyleDrawable(.CheckedBackground);
			if (checkedBg != null)
				checkedBg.Draw(ctx, bounds, state);
			else
			{
				var color = ResolveStyleColor(.AccentColor, .(80, 150, 240, 255));
				if (state.HasFlag(.Disabled)) color = Palette.ComputeDisabled(color);
				else if (state.HasFlag(.Pressed)) color = Palette.ComputePressed(color);
				else if (state.HasFlag(.Hover)) color = Palette.ComputeHover(color);
				ctx.VG.FillRoundedRect(bounds, radius, color);
			}
		}
		else
		{
			DrawButtonBackground(ctx, bounds, state);
		}

		if (mContent != null)
		{
			ctx.VG.PushState();
			ctx.VG.Translate(mContent.Bounds.X, mContent.Bounds.Y);
			mContent.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	// Override mouse up to toggle instead of firing click
	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button == .Left && IsPressed)
		{
			if (IsHovered) IsChecked.Value = !IsChecked.Value;
		}
		base.OnMouseUp(e);
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key == .Space || e.Key == .Return)
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnActivate()
	{
		if (!IsEffectivelyEnabled) return;
		IsChecked.Value = !IsChecked.Value;
	}
}
