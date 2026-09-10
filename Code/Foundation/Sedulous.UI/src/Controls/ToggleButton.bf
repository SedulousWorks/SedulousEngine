using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A button that stays down: checked or unchecked, with a view for its face.
///
/// Built from text, the face is a Label. As with ContentButton the face is NOT a child, so the
/// whole button is one click target, and the reference to it is owned by hand.
class ToggleButton : ButtonBase
{
	public Property<bool> IsChecked = new .(false) ~ delete _;
	public Event<delegate void(ToggleButton, bool)> OnCheckedChanged ~ _.Dispose();

	private View mContent = null;

	public this()
	{
		Wire();
	}

	public this(StringView text)
	{
		Wire();
		mContent = new Label(text);
	}

	public ~this()
	{
		ReleaseContent();
	}

	/// Borrowed; may be null.
	public View Content => mContent;

	/// CONSUMES the caller's reference, and releases the one held before.
	public void SetContent(View content)
	{
		if (mContent == content)
		{
			content?.ReleaseRef();
			return;
		}

		ReleaseContent();
		mContent = content;
		Invalidate();
	}

	/// Attached to the context by hand during measure, so detached by hand before release.
	private void ReleaseContent()
	{
		if (mContent == null)
			return;

		if (mContent.Context != null)
			mContent.Context.DetachView(mContent);
		mContent.ReleaseRef();
		mContent = null;
	}

	/// Adds Checked to the base states. A bound command does NOT disable a toggle the way it
	/// disables a push button: a toggle's job is to carry state, and it carries it whether or
	/// not anything can act on it right now.
	public override ControlState GetControlState()
	{
		var state = ControlState.Normal;

		if (!IsEffectivelyEnabled())
			state |= .Disabled;
		if (IsPressed)
			state |= .Pressed;
		// Keyboard acquired only: a clicked toggle holds focus without a ring.
		if (IsFocusVisible())
			state |= .Focused;
		if (IsHovered())
			state |= .Hover;
		if (IsChecked.Value)
			state |= .Checked;

		return state;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		// The toggle happens BEFORE the base, which is what fires OnClick: a handler reading
		// IsChecked sees the value the click produced, not the one it replaced.
		if ((e.Button == .Left) && IsPressed && IsHovered())
			IsChecked.Value = !IsChecked.Value;

		base.OnMouseUp(e);
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if ((e.Key != .Space) && (e.Key != .Return))
			return;

		IsChecked.Value = !IsChecked.Value;
		e.Handled = true;
	}

	public override void OnActivate()
	{
		if (IsEffectivelyEnabled())
			IsChecked.Value = !IsChecked.Value;
	}

	protected override Thickness DefaultStylePadding() => .(12, 8);

	/// CONTENT only: the base handles the chrome.
	protected override Float2 OnMeasureContent(BoxConstraints contentConstraints)
	{
		if (mContent == null)
			return .Zero;

		if ((mContent.Context == null) && (Context != null))
			Context.AttachView(mContent);

		SyncContentFont();
		mContent.Measure(contentConstraints.Loosen());
		return mContent.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent == null)
			return;

		let chrome = ResolveBoxMetrics().Chrome;
		let contentWidth = width - chrome.TotalHorizontal;
		let contentHeight = height - chrome.TotalVertical;
		let size = mContent.MeasuredSize;

		mContent.Layout(chrome.Left + (contentWidth - size.X) * 0.5f,
			chrome.Top + (contentHeight - size.Y) * 0.5f, size.X, size.Y);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let state = GetControlState();

		if (IsChecked.Value)
			DrawCheckedBackground(ctx, bounds, state);
		else
			DrawButtonBackground(ctx, bounds, state);

		if (mContent != null)
		{
			ctx.VG.PushState();
			ctx.VG.Translate(mContent.Bounds.X, mContent.Bounds.Y);
			mContent.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	/// Checked chrome, in falling order of what the theme declared: a dedicated checked
	/// background, the plain one, and finally the accent colour so a checked toggle still
	/// reads as checked before any theme is loaded.
	private void DrawCheckedBackground(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		if (let checkedBackground = ResolveStyleDrawable(.CheckedBackground))
		{
			checkedBackground.Draw(ctx, bounds, state);
			return;
		}

		if (let background = ResolveStyleDrawable(.Background))
		{
			background.Draw(ctx, bounds, state);
			return;
		}

		let radius = ResolveStyleFloat(.CornerRadius, 4.0f);
		var color = ResolveStyleColor(.AccentColor, Color(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f));

		if (state.HasFlag(.Disabled))
			color = Palette.ComputeDisabled(color);
		else if (state.HasFlag(.Pressed))
			color = Palette.ComputePressed(color);
		else if (state.HasFlag(.Hover))
			color = Palette.ComputeHover(color);

		ctx.VG.FillRoundedRect(bounds, radius, color);
	}

	/// A Label resolves its font size against itself, which would pick up the global View
	/// default rather than the button's, and a toggle would then not match the push button
	/// beside it. Pushing the resolved size down fixes that.
	///
	/// A no-op for content that is not a Label, and guarded so it does not re-invalidate on
	/// every measure.
	private void SyncContentFont()
	{
		if (let label = mContent as Label)
		{
			let fontSize = ResolveStyleFloat(.FontSize, 16.0f);
			if ((label.FontSize.Value == null) || (label.FontSize.Value.Value != fontSize))
				label.FontSize.Value = fontSize;
		}
	}

	private void Wire()
	{
		IsChecked.SetOwner(this, .Visual);
		IsChecked.Changed.Add(new (val) => { OnCheckedChanged(this, val); });
	}
}
