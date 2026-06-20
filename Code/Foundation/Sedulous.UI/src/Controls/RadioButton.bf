namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Radio button - cannot be unchecked by click.
/// Use RadioGroup for mutual exclusion.
public class RadioButton : View
{
	private static float CircleSize = 18;
	private static float CircleTextSpacing = 8;

	/// Whether this radio button is selected.
	public Property<bool> IsChecked = new .(false) ~ delete _;

	/// Text label next to the radio button.
	public Property<String> Text = new .(null) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Override font size for the label text.
	public Property<float?> FontSize = new .(null) ~ delete _;

	/// Per-instance font family override. When set (and non-empty), overrides the style-resolved FontFamily.
	public Property<String> FontFamily = new .(null, .Visual) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Override text color for the label text.
	public Property<Color?> TextColor = new .(null, .Visual) ~ delete _;

	public Event<delegate void(RadioButton, bool)> OnCheckedChanged ~ _.Dispose();

	public this()
	{
		IsChecked.SetOwner(this, .Visual);
		Text.SetOwner(this);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this, .Visual);
		TextColor.SetOwner(this, .Visual);

		IsChecked.Changed.Add(new (val) => { OnCheckedChanged(this, val); });

		IsFocusable = true; IsTabStop = true; Cursor = .Hand;
	}
	public this(StringView text) : this() { Text.SetSilent(new String(text)); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 16);
		float textW = 0, textH = 0;

		if (Text.Value != null && !Text.Value.IsEmpty)
		{
			let font = Context?.FontService?.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text.Value);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let totalW = CircleSize + ((textW > 0) ? CircleTextSpacing + textW : 0);
		let totalH = Math.Max(CircleSize, textH);

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 16);
		let r = CircleSize * 0.5f;
		let cy = Height * 0.5f;

		let boxRect = RectangleF(0, cy - r, CircleSize, CircleSize);

		// Draw box with checked state for cascade selection
		var state = GetControlState();
		if (IsChecked.Value) state |= .Checked;
		let boxDrawable = ResolvePartDrawable("box", .Background, state);
		if (boxDrawable != null)
		{
			boxDrawable.Draw(ctx, boxRect, state);
			if (IsChecked.Value)
			{
				let dotIcon = ResolvePartDrawable("mark", .Background, state);
				if (dotIcon != null)
					dotIcon.Draw(ctx, boxRect);
			}
		}
		else if (IsChecked.Value)
			DrawFallbackChecked(ctx, boxRect, cy);
		else
			DrawFallbackUnchecked(ctx, boxRect);

		// Text
		if (Text.Value != null && !Text.Value.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
			if (font != null)
			{
				var textColor = TextColor.Value ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled)
					textColor = Palette.ComputeDisabled(textColor);

				let textX = CircleSize + CircleTextSpacing;
				ctx.VG.DrawText(Text.Value, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
			}
		}
	}

	/// Fallback unchecked when no theme is set.
	private void DrawFallbackUnchecked(UIDrawContext ctx, RectangleF boxRect)
	{
		ctx.VG.FillRect(boxRect, .(30, 32, 42, 255));
		ctx.VG.StrokeRect(boxRect, .(100, 105, 120, 255), 1);
	}

	/// Fallback checked when no theme is set.
	private void DrawFallbackChecked(UIDrawContext ctx, RectangleF boxRect, float cy)
	{
		ctx.VG.FillRect(boxRect, .(80, 150, 240, 255));
		let dotSize = CircleSize * 0.4f;
		let dotX = (CircleSize - dotSize) * 0.5f;
		ctx.VG.FillRect(.(dotX, cy - dotSize * 0.5f, dotSize, dotSize), .(255, 255, 255, 255));
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Button == .Left && !IsChecked.Value)
		{
			IsChecked.Value = true;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if ((e.Key == .Space || e.Key == .Return) && !IsChecked.Value)
		{
			IsChecked.Value = true;
			e.Handled = true;
		}
	}

	public override void OnActivate()
	{
		if (!IsEffectivelyEnabled) return;
		IsChecked.Value = true;
	}
}
