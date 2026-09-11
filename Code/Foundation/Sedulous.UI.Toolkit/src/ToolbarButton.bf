using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A toolbar button carrying text, an icon, or both.
///
/// The icon is a DRAW DELEGATE rather than a drawable, because a toolbar icon is usually a few
/// vector strokes a caller already knows how to draw and giving it a drawable would mean
/// building one per button.
///
/// It fires on mouse DOWN, not on a press and release pair, which is what a toolbar wants: the
/// action happens the moment the button is hit.
class ToolbarButton : ToolbarItem
{
	public Event<delegate void(ToolbarButton)> OnClick ~ _.Dispose();

	/// Empty means no text.
	protected String mText = new .() ~ delete _;
	/// OWNED. Null means no icon.
	protected delegate void(UIDrawContext, Rectangle) mIconDraw ~ delete _;

	public this()
	{
		IsFocusable = true;
		Cursor = .Hand;
	}

	public StringView Text => mText;

	public void SetText(StringView text)
	{
		mText.Set(text);
		Invalidate();
	}

	/// CONSUMES the delegate, replacing any previous icon. Drawn in the icon area before text.
	public void SetIcon(delegate void(UIDrawContext, Rectangle) iconDraw)
	{
		delete mIconDraw;
		mIconDraw = iconDraw;
		Invalidate();
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		// The hover fill is DERIVED from the parent toolbar's own background rather than named
		// here, so a retheme moves the button with the bar it sits on.
		if (IsHovered())
		{
			var backgroundColor = Color.Rgb(50, 52, 62);
			let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);

			if (let toolbar = Parent as Toolbar)
			{
				let background = toolbar.ResolveStyleDrawable(.Background);
				if (let rounded = background as RoundedRectDrawable)
					backgroundColor = rounded.FillColor;
				else if (let solid = background as ColorDrawable)
					backgroundColor = solid.Color;
			}

			let hover = Palette.ComputeHover(backgroundColor);
			if (cornerRadius > 0.0f)
				ctx.VG.FillRoundedRect(bounds, cornerRadius, hover);
			else
				ctx.VG.FillRect(bounds, hover);
		}

		var x = 8.0f;

		if (mIconDraw != null)
		{
			mIconDraw(ctx, Rectangle(x, (Height - 16.0f) * 0.5f, 16.0f, 16.0f));
			x += 16.0f;
		}

		if (!mText.IsEmpty && (ctx.FontService != null))
		{
			if (mIconDraw != null)
				x += 4.0f;

			var fontSize = 13.0f;
			if (let toolbar = Parent as Toolbar)
				fontSize = toolbar.ResolveStyleFloat(.FontSize, fontSize);

			if (let font = ctx.FontService.GetFont(fontSize))
			{
				let textColor = ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235));
				ctx.VG.DrawText(mText, font, Rectangle(x, 0, Width - x - 8.0f, Height),
					.Left, .Middle, textColor);
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		OnClick(this);
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if ((e.Key == .Space) || (e.Key == .Return))
		{
			OnClick(this);
			e.Handled = true;
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var width = 8.0f; // left padding
		var textHeight = 14.0f;

		if (mIconDraw != null)
			width += 16.0f;

		if (!mText.IsEmpty)
		{
			if (mIconDraw != null)
				width += 4.0f; // the gap between icon and text

			if ((Context != null) && (Context.FontService != null))
			{
				if (let font = Context.FontService.GetFont(13.0f))
				{
					width += font.Font.MeasureString(mText);
					textHeight = font.Font.Metrics.LineHeight;
				}
			}
		}

		width += 8.0f; // right padding
		MeasuredSize = .(constraints.ConstrainWidth(width),
			constraints.ConstrainHeight(textHeight + 8.0f));
	}
}
