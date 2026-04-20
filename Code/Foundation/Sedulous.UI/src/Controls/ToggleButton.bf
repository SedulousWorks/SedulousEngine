namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Button with on/off state. Uses accent color when checked.
public class ToggleButton : View
{
	private String mText ~ delete _;
	private bool mIsChecked;

	private Color? mTextColor;
	private float? mFontSize;
	private Thickness? mPadding;

	public Event<delegate void(ToggleButton, bool)> OnCheckedChanged ~ _.Dispose();

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
		get => mTextColor ?? Context?.Theme?.GetColor("ToggleButton.Text") ?? .(240, 240, 245, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("ToggleButton.FontSize", 16) ?? 16;
		set { mFontSize = value; InvalidateLayout(); }
	}

	public Thickness Padding
	{
		get => mPadding ?? Context?.Theme?.GetPadding("ToggleButton.Padding", .(12, 8)) ?? .(12, 8);
		set { mPadding = value; InvalidateLayout(); }
	}

	public bool IsPressed;

	public override ControlState GetControlState()
	{
		if (!IsEffectivelyEnabled) return .Disabled;
		if (IsPressed) return .Pressed;
		if (IsHovered) return .Hover;
		if (IsFocused) return .Focused;
		return .Normal;
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
		let padding = Padding;
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

		MeasuredSize = .(wSpec.Resolve(textW + padding.TotalHorizontal),
						 hSpec.Resolve(textH + padding.TotalVertical));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let radius = ctx.Theme?.GetDimension("ToggleButton.CornerRadius", 4) ?? 4;

		// Background - accent when checked, primary when not.
		let drawableKey = mIsChecked ? "ToggleButton.CheckedBackground" : "ToggleButton.Background";
		let state = GetControlState();
		if (!ctx.TryDrawDrawable(drawableKey, bounds, state))
		{
			Color bgColor;
			if (mIsChecked)
				bgColor = ctx.Theme?.TryGetColor("ToggleButton.CheckedBackground") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
			else
				bgColor = ctx.Theme?.TryGetColor("ToggleButton.Background") ?? ctx.Theme?.Palette.Surface ?? .(60, 65, 80, 255);

			if (!IsEffectivelyEnabled)
				bgColor = Palette.ComputeDisabled(bgColor);
			else if (IsHovered)
				bgColor = Palette.ComputeHover(bgColor);

			ctx.VG.FillRoundedRect(bounds, radius, bgColor);
		}

		// Border on unchecked state for visual distinction.
		if (!mIsChecked)
		{
			let borderColor = ctx.Theme?.TryGetColor("ToggleButton.Border") ?? ctx.Theme?.Palette.Border ?? .(80, 85, 100, 255);
			ctx.VG.StrokeRoundedRect(bounds, radius, borderColor, 1);
		}

		// Focus ring.
		if (IsFocused)
			ctx.DrawFocusRing(bounds, radius);

		// Text - may use different color when checked vs unchecked.
		if (mText != null && mText.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let padding = Padding;
				let contentBounds = RectangleF(padding.Left, padding.Top,
					Width - padding.TotalHorizontal, Height - padding.TotalVertical);
				var textColor = TextColor;
				if (mIsChecked)
				{
					let checkedText = ctx.Theme?.GetColor("ToggleButton.CheckedText");
					if (checkedText.HasValue) textColor = checkedText.Value;
				}
				let color = IsEffectivelyEnabled ? textColor : Palette.ComputeDisabled(textColor);
				ctx.VG.DrawText(mText, font, contentBounds, .Center, .Middle, color);
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
