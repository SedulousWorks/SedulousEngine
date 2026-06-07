namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Radio button - cannot be unchecked by click.
/// Use RadioGroup for mutual exclusion.
public class RadioButton : View
{
	private bool mIsChecked;
	private String mText ~ delete _;

	private static float CircleSize = 18;
	private static float CircleTextSpacing = 8;

	/// Whether this radio button is selected.
	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked == value) return;
			mIsChecked = value;
			Invalidate();
			OnCheckedChanged(this, mIsChecked);
		}
	}

	public StringView Text
	{
		get => (mText != null) ? StringView(mText) : StringView();
		set
		{
			if (mText == null) mText = new String(value);
			else mText.Set(value);
			Invalidate();
		}
	}

	/// Override font size for the label text.
	public float? FontSize;

	/// Override text color for the label text.
	public Color? TextColor;

	public Event<delegate void(RadioButton, bool)> OnCheckedChanged ~ _.Dispose();

	public this() { IsFocusable = true; IsTabStop = true; Cursor = .Hand; }
	public this(StringView text) : this() { mText = new String(text); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = FontSize ?? ResolveStyleFloat(.FontSize, 16);
		float textW = 0, textH = 0;

		if (mText != null && !mText.IsEmpty)
		{
			let font = Context?.FontService?.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(mText);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let totalW = CircleSize + ((textW > 0) ? CircleTextSpacing + textW : 0);
		let totalH = Math.Max(CircleSize, textH);

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let fontSize = FontSize ?? ResolveStyleFloat(.FontSize, 16);
		let r = CircleSize * 0.5f;
		let cy = Height * 0.5f;

		let boxRect = RectangleF(0, cy - r, CircleSize, CircleSize);

		// Draw the appropriate drawable for checked/unchecked state.
		if (mIsChecked)
		{
			let checkedDrawable = ResolveStyleDrawable(.CheckedBackground);
			if (checkedDrawable != null)
			{
				checkedDrawable.Draw(ctx, boxRect, GetControlState());
				// Draw radio dot icon on top of checked background
				let dotIcon = ResolveStyleDrawable(.RadioMarkIcon);
				if (dotIcon != null)
					dotIcon.Draw(ctx, boxRect);
			}
			else
				DrawFallbackChecked(ctx, boxRect, cy);
		}
		else
		{
			let boxDrawable = ResolveStyleDrawable(.BoxDrawable);
			if (boxDrawable != null)
				boxDrawable.Draw(ctx, boxRect, GetControlState());
			else
				DrawFallbackUnchecked(ctx, boxRect);
		}

		// Text
		if (mText != null && !mText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(fontSize);
			if (font != null)
			{
				var textColor = TextColor ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled)
					textColor = Palette.ComputeDisabled(textColor);

				let textX = CircleSize + CircleTextSpacing;
				ctx.VG.DrawText(mText, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
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
		if (e.Button == .Left && !mIsChecked)
		{
			IsChecked = true;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if ((e.Key == .Space || e.Key == .Return) && !mIsChecked)
		{
			IsChecked = true;
			e.Handled = true;
		}
	}
}
