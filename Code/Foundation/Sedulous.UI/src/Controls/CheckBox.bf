namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Toggle control with check box indicator and text label.
public class CheckBox : View
{
	private String mText ~ delete _;
	private bool mIsChecked;

	private Color? mTextColor;
	private float? mFontSize;

	private const float BoxSize = 16;
	private const float BoxTextSpacing = 8;

	public Event<delegate void(CheckBox, bool)> OnCheckedChanged ~ _.Dispose();

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
		get => mTextColor ?? Context?.Theme?.GetColor("CheckBox.Text") ?? .(220, 225, 235, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("CheckBox.FontSize", 16) ?? 16;
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

		let w = BoxSize + ((mText != null && mText.Length > 0) ? BoxTextSpacing + textW : 0);
		let h = Math.Max(BoxSize, textH);
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let boxY = (Height - BoxSize) * 0.5f;

		// Box background.
		let boxBg = ctx.Theme?.GetColor("CheckBox.BoxBackground", .(30, 32, 42, 255)) ?? .(30, 32, 42, 255);
		let boxBorder = ctx.Theme?.GetColor("CheckBox.BoxBorder", .(100, 105, 120, 255)) ?? .(100, 105, 120, 255);
		let radius = ctx.Theme?.GetDimension("CheckBox.CornerRadius", 3) ?? 3;

		let borderColor = IsHovered ? Palette.Lighten(boxBorder, 0.3f) : boxBorder;
		ctx.VG.FillRoundedRect(.(0, boxY, BoxSize, BoxSize), radius, boxBg);
		ctx.VG.StrokeRoundedRect(.(0, boxY, BoxSize, BoxSize), radius, borderColor, 1.5f);

		// Check mark — VG-drawn checkmark.
		if (mIsChecked)
		{
			let checkColor = ctx.Theme?.TryGetColor("CheckBox.CheckColor") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
			let cc = IsEffectivelyEnabled ? checkColor : Palette.ComputeDisabled(checkColor);
			// Draw a checkmark path.
			let cx = BoxSize * 0.5f;
			let cy = boxY + BoxSize * 0.5f;
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(cx - 4, cy);
			ctx.VG.LineTo(cx - 1, cy + 3);
			ctx.VG.LineTo(cx + 4, cy - 3);
			ctx.VG.Stroke(cc, 2.0f);
		}

		// Focus ring.
		if (IsFocused)
			ctx.DrawFocusRing(.(0, boxY, BoxSize, BoxSize), radius);

		// Text label.
		if (mText != null && mText.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let textX = BoxSize + BoxTextSpacing;
				let color = IsEffectivelyEnabled ? TextColor : Palette.ComputeDisabled(TextColor);
				ctx.VG.DrawText(mText, font, .(textX, 0, Width - textX, Height), .Left, .Middle, color);
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;
		IsChecked = !mIsChecked;
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return)
		{
			IsChecked = !mIsChecked;
			e.Handled = true;
		}
	}
}
