using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A box that ticks, with a label beside it.
///
/// A View rather than a ToggleButton: a checkbox has no button chrome, and its box is a styled
/// part rather than a background, so it shares nothing useful with the button base.
class CheckBox : View
{
	public Property<bool> IsChecked = new .(false) ~ delete _;
	public Property<String> Text = new .(new String()) ~ delete _;
	/// Null defers to the cascade's font size.
	public Property<float?> FontSize = new .() ~ delete _;
	/// Empty defers to the cascade's family.
	public Property<String> FontFamily = new .(new String()) ~ delete _;
	/// Null defers to the cascade's text colour.
	public Property<Color?> TextColor = new .() ~ delete _;
	public Event<delegate void(CheckBox, bool)> OnCheckedChanged ~ _.Dispose();

	public this()
	{
		Init();
	}

	public this(StringView text)
	{
		Init();
		Text.Value.Set(text); // reuses the empty String the property was built with
	}

	public this(StringView text, bool isChecked)
	{
		Init();
		Text.Value.Set(text); // reuses the empty String the property was built with
		IsChecked.SetSilent(isChecked);
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
		// The property compares CONTENT and keeps the old string for equal text, so which
		// of the two is the stale one is decided by identity: a per frame SetText with an
		// unchanged label leaked a string a frame.
		if (Text.Value === replacement)
			delete previous;
		else
			delete replacement;
		Invalidate();
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if (e.Button == .Left)
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if ((e.Key == .Space) || (e.Key == .Return))
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnActivate()
	{
		if (IsEffectivelyEnabled())
			IsChecked.Value = !IsChecked.Value;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let boxSize = ResolvePartFloat("box", .Width, GetControlState(), 18.0f);
		let spacing = ResolveStyleFloat(.Spacing, 6.0f);
		let fontSize = EffectiveFontSize;

		var textWidth = 0.0f;
		var textHeight = 0.0f;
		let text = Text.Value;

		if (!text.IsEmpty && (Context != null) && (Context.FontService != null))
		{
			let family = scope String();
			ResolveStyleFontFamily(family, FontFamily.Value);
			if (let font = Context.FontService.GetFont(family, fontSize))
			{
				textWidth = font.Font.MeasureString(text);
				textHeight = font.Font.Metrics.LineHeight;
			}
		}

		// The spacing only exists when there is text to separate the box from.
		let totalWidth = boxSize + ((textWidth > 0) ? spacing + textWidth : 0);
		let totalHeight = Max(boxSize, textHeight);

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(totalHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		var state = GetControlState();
		if (IsChecked.Value)
			state |= .Checked;

		let boxSize = ResolvePartFloat("box", .Width, state, 18.0f);
		let spacing = ResolveStyleFloat(.Spacing, 6.0f);

		// The box is centred on the line, so a tall label does not leave it sitting at the top.
		let boxRect = Rectangle(0, (Height - boxSize) * 0.5f, boxSize, boxSize);

		if (let boxDrawable = ResolvePartDrawable("box", .Background, state))
		{
			boxDrawable.Draw(ctx, boxRect, state);
			if (IsChecked.Value)
			{
				if (let checkmark = ResolvePartDrawable("checkmark", .Background, state))
					checkmark.Draw(ctx, boxRect);
			}
		}
		else if (IsChecked.Value)
		{
			DrawFallbackChecked(ctx, boxRect, boxSize);
		}
		else
		{
			DrawFallbackUnchecked(ctx, boxRect);
		}

		DrawText(ctx, boxSize + spacing);
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

	/// A built in box, so a checkbox is usable before any theme is loaded.
	private static void DrawFallbackUnchecked(UIDrawContext ctx, Rectangle boxRect)
	{
		ctx.VG.FillRect(boxRect, Color(30 / 255.0f, 32 / 255.0f, 42 / 255.0f, 1.0f));
		ctx.VG.StrokeRect(boxRect, Color(100 / 255.0f, 105 / 255.0f, 120 / 255.0f, 1.0f), 1.0f);
	}

	private static void DrawFallbackChecked(UIDrawContext ctx, Rectangle boxRect, float boxSize)
	{
		ctx.VG.FillRect(boxRect, Color(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f));

		let cx = boxRect.X + boxSize * 0.5f;
		let cy = boxRect.Y + boxSize * 0.5f;
		let s = boxSize * 0.3f;
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(cx - s, cy);
		ctx.VG.LineTo(cx - s * 0.3f, cy + s * 0.7f);
		ctx.VG.LineTo(cx + s, cy - s * 0.5f);
		ctx.VG.Stroke(Color.White, 2.0f);
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
