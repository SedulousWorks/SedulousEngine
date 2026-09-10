using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// One option in a mutually exclusive set, with a label beside it.
///
/// It only ever checks itself; nothing here unchecks. A radio button on its own cannot be
/// turned off by clicking it, which is the behaviour that separates it from a checkbox, and
/// the unchecking of its siblings is the group's job.
class RadioButton : View
{
	private const float CircleSize = 18.0f;
	private const float CircleTextSpacing = 8.0f;

	public Property<bool> IsChecked = new .(false) ~ delete _;
	public Property<String> Text = new .(new String()) ~ delete _;
	/// Null defers to the cascade's font size.
	public Property<float?> FontSize = new .() ~ delete _;
	/// Empty defers to the cascade's family.
	public Property<String> FontFamily = new .(new String()) ~ delete _;
	/// Null defers to the cascade's text colour.
	public Property<Color?> TextColor = new .() ~ delete _;
	public Event<delegate void(RadioButton, bool)> OnCheckedChanged ~ _.Dispose();

	public this()
	{
		Init();
	}

	public this(StringView text)
	{
		Init();
		Text.Value.Set(text); // reuses the empty String the property was built with
	}

	public ~this()
	{
		delete Text.Value;
		delete FontFamily.Value;
	}

	public void SetText(StringView text)
	{
		let replacement = new String(text);
		let previous = Text.Value;
		Text.Value = replacement;
		if (previous != replacement)
			delete previous;
		Invalidate();
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		// Already checked: nothing happens, and the event is left UNHANDLED so a click on the
		// current selection is not swallowed.
		if ((e.Button == .Left) && !IsChecked.Value)
		{
			IsChecked.Value = true;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if (((e.Key == .Space) || (e.Key == .Return)) && !IsChecked.Value)
		{
			IsChecked.Value = true;
			e.Handled = true;
		}
	}

	public override void OnActivate()
	{
		if (IsEffectivelyEnabled())
			IsChecked.Value = true;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var textWidth = 0.0f;
		var textHeight = 0.0f;
		let text = Text.Value;

		if (!text.IsEmpty && (Context != null) && (Context.FontService != null))
		{
			let family = scope String();
			ResolveStyleFontFamily(family, FontFamily.Value);
			if (let font = Context.FontService.GetFont(family, EffectiveFontSize))
			{
				textWidth = font.Font.MeasureString(text);
				textHeight = font.Font.Metrics.LineHeight;
			}
		}

		let circleSize = ResolvePartFloat("box", .Width, GetControlState(), CircleSize);
		let totalWidth = circleSize + ((textWidth > 0) ? CircleTextSpacing + textWidth : 0);
		let totalHeight = Max(circleSize, textHeight);

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(totalHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		var state = GetControlState();
		let circleSize = ResolvePartFloat("box", .Width, state, CircleSize);
		let cy = Height * 0.5f;
		let boxRect = Rectangle(0, cy - circleSize * 0.5f, circleSize, circleSize);

		if (IsChecked.Value)
			state |= .Checked;

		if (let boxDrawable = ResolvePartDrawable("box", .Background, state))
		{
			boxDrawable.Draw(ctx, boxRect, state);
			if (IsChecked.Value)
			{
				if (let mark = ResolvePartDrawable("mark", .Background, state))
					mark.Draw(ctx, boxRect);
			}
		}
		else if (IsChecked.Value)
		{
			DrawFallbackChecked(ctx, boxRect, cy);
		}
		else
		{
			DrawFallbackUnchecked(ctx, boxRect);
		}

		DrawText(ctx, circleSize + CircleTextSpacing);
	}

	private void DrawText(UIDrawContext ctx, float textX)
	{
		let text = Text.Value;
		if (text.IsEmpty || (ctx.FontService == null))
			return;

		let family = scope String();
		ResolveStyleFontFamily(family, FontFamily.Value);
		let font = ctx.FontService.GetFont(family, EffectiveFontSize);
		if (font == null)
			return;

		var textColor = (TextColor.Value != null)
			? TextColor.Value.Value
			: ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		if (!IsEffectivelyEnabled())
			textColor = Palette.ComputeDisabled(textColor);

		ctx.VG.DrawText(text, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
	}

	/// A built in look, so a radio button reads before any theme is loaded.
	private static void DrawFallbackUnchecked(UIDrawContext ctx, Rectangle boxRect)
	{
		ctx.VG.FillRect(boxRect, Color(30 / 255.0f, 32 / 255.0f, 42 / 255.0f, 1.0f));
		ctx.VG.StrokeRect(boxRect, Color(100 / 255.0f, 105 / 255.0f, 120 / 255.0f, 1.0f), 1.0f);
	}

	private static void DrawFallbackChecked(UIDrawContext ctx, Rectangle boxRect, float cy)
	{
		ctx.VG.FillRect(boxRect, Color(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f));

		let dotSize = boxRect.Width * 0.4f;
		let dotX = boxRect.X + (boxRect.Width - dotSize) * 0.5f;
		ctx.VG.FillRect(.(dotX, cy - dotSize * 0.5f, dotSize, dotSize), Color.White);
	}

	private float EffectiveFontSize =>
		(FontSize.Value != null) ? FontSize.Value.Value : ResolveStyleFloat(.FontSize, 16.0f);

	private void Init()
	{
		IsChecked.SetOwner(this, .Visual);
		Text.SetOwner(this);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this, .Visual);
		TextColor.SetOwner(this, .Visual);
		IsChecked.Changed.Add(new (val) => { OnCheckedChanged(this, val); });
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .Hand;
	}
}
