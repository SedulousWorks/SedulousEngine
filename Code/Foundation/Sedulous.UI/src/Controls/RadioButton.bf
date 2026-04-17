namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Radio button with circle indicator and text label.
/// Use inside a RadioGroup for mutual exclusion.
public class RadioButton : View
{
	private String mText ~ delete _;
	private bool mIsChecked;

	private Color? mTextColor;
	private float? mFontSize;

	private const float CircleSize = 16;
	private const float CircleTextSpacing = 8;

	public Event<delegate void(RadioButton, bool)> OnCheckedChanged ~ _.Dispose();

	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked != value)
			{
				mIsChecked = value;
				InvalidateVisual();
				OnCheckedChanged(this, value);
			}
		}
	}

	public Color TextColor
	{
		get => mTextColor ?? Context?.Theme?.GetColor("RadioButton.Text") ?? .(220, 225, 235, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("RadioButton.FontSize", 16) ?? 16;
		set { mFontSize = value; InvalidateLayout(); }
	}

	public this()
	{
		IsFocusable = true;
		Cursor = .Hand;
	}

	public void SetText(StringView text)
	{
		if (mText == null) mText = new String(text);
		else mText.Set(text);
		InvalidateLayout();
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let fontSize = FontSize;
		float textW = 0, textH = fontSize;

		if (mText != null && mText.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(mText);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let w = CircleSize + ((mText != null && mText.Length > 0) ? CircleTextSpacing + textW : 0);
		let h = Math.Max(CircleSize, textH);
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let centerX = CircleSize * 0.5f;
		let centerY = Height * 0.5f;
		let radius = CircleSize * 0.5f;

		// Circle background.
		let circleBg = ctx.Theme?.GetColor("RadioButton.CircleBackground", .(30, 32, 42, 255)) ?? .(30, 32, 42, 255);
		let circleBorder = ctx.Theme?.GetColor("RadioButton.CircleBorder", .(100, 105, 120, 255)) ?? .(100, 105, 120, 255);

		let borderColor = IsHovered ? Palette.Lighten(circleBorder, 0.3f) : circleBorder;
		ctx.VG.FillCircle(.(centerX, centerY), radius, circleBg);
		ctx.VG.StrokeCircle(.(centerX, centerY), radius, borderColor, 1.5f);

		// Inner dot when checked.
		if (mIsChecked)
		{
			let dotColor = ctx.Theme?.TryGetColor("RadioButton.DotColor") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
			let dc = IsEffectivelyEnabled ? dotColor : Palette.ComputeDisabled(dotColor);
			ctx.VG.FillCircle(.(centerX, centerY), radius - 4, dc);
		}

		// Focus ring.
		if (IsFocused)
			ctx.VG.StrokeCircle(.(centerX, centerY), radius + 3, ctx.Theme?.GetColor("Focus.Ring", .(100, 160, 255, 180)) ?? .(100, 160, 255, 180), 2);

		// Text label.
		if (mText != null && mText.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let textX = CircleSize + CircleTextSpacing;
				let color = IsEffectivelyEnabled ? TextColor : Palette.ComputeDisabled(TextColor);
				ctx.VG.DrawText(mText, font, .(textX, 0, Width - textX, Height), .Left, .Middle, color);
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;
		// Radio buttons can only be checked, not unchecked by click.
		if (!mIsChecked)
			IsChecked = true;
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return)
		{
			if (!mIsChecked) IsChecked = true;
			e.Handled = true;
		}
	}
}
