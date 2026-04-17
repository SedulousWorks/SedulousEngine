namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// iOS-style toggle switch with track and sliding knob.
public class ToggleSwitch : View
{
	private String mText ~ delete _;
	private bool mIsChecked;

	private Color? mTextColor;
	private float? mFontSize;

	public float TrackWidth = 44;
	public float TrackHeight = 24;
	public float KnobSize = 20;

	private const float TextSpacing = 8;

	public Event<delegate void(ToggleSwitch, bool)> OnCheckedChanged ~ _.Dispose();

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
		get => mTextColor ?? Context?.Theme?.GetColor("ToggleSwitch.Text") ?? .(220, 225, 235, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("ToggleSwitch.FontSize", 14) ?? 14;
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
		float textW = 0, textH = 0;
		if (mText != null && mText.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(FontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(mText);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let w = TrackWidth + ((textW > 0) ? TextSpacing + textW : 0);
		let h = Math.Max(TrackHeight, textH);
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let trackY = (Height - TrackHeight) * 0.5f;
		let trackRadius = TrackHeight * 0.5f;

		// Track color: interpolate between off and on.
		let offColor = ctx.Theme?.TryGetColor("ToggleSwitch.TrackOff") ?? ctx.Theme?.Palette.Surface ?? .(60, 62, 72, 255);
		let onColor = ctx.Theme?.TryGetColor("ToggleSwitch.TrackOn") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
		let trackColor = mIsChecked ? onColor : offColor;
		ctx.VG.FillRoundedRect(.(0, trackY, TrackWidth, TrackHeight), trackRadius, trackColor);

		// Track border.
		let borderColor = ctx.Theme?.GetColor("ToggleSwitch.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255);
		ctx.VG.StrokeRoundedRect(.(0, trackY, TrackWidth, TrackHeight), trackRadius, borderColor, 1);

		// Knob position.
		let knobPadding = (TrackHeight - KnobSize) * 0.5f;
		let knobMinX = knobPadding;
		let knobMaxX = TrackWidth - KnobSize - knobPadding;
		let knobX = mIsChecked ? knobMaxX : knobMinX;
		let knobY = trackY + knobPadding;
		let knobRadius = KnobSize * 0.5f;

		// Knob shadow.
		ctx.VG.FillCircle(.(knobX + knobRadius + 1, knobY + knobRadius + 1), knobRadius, .(0, 0, 0, 40));

		// Knob.
		var knobColor = ctx.Theme?.GetColor("ToggleSwitch.Knob", .(230, 230, 235, 255)) ?? .(230, 230, 235, 255);
		if (IsHovered) knobColor = Palette.ComputeHover(knobColor);
		ctx.VG.FillCircle(.(knobX + knobRadius, knobY + knobRadius), knobRadius, knobColor);

		// Focus ring around track.
		if (IsFocused)
			ctx.DrawFocusRing(.(0, trackY, TrackWidth, TrackHeight), trackRadius);

		// Text label.
		if (mText != null && mText.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let textX = TrackWidth + TextSpacing;
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
