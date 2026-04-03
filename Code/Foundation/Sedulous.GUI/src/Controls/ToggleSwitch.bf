using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// An iOS-style toggle switch control.
public class ToggleSwitch : ToggleButton
{
	private float mTrackWidth = 44;
	private float mTrackHeight = 24;
	private float mKnobSize = 20;
	private float mAnimationProgress = 0; // 0 = off position, 1 = on position
	private ImageBrush? mTrackImage;
	private ImageBrush? mKnobImage;

	/// Creates a new ToggleSwitch.
	public this() : base()
	{
		// Toggle switch doesn't need content by default
	}

	/// Creates a new ToggleSwitch with text content.
	public this(StringView text) : base(text)
	{
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for toggle switch dimensions.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mTrackWidth = theme?.ToggleSwitchTrackWidth ?? 44;
		mTrackHeight = theme?.ToggleSwitchTrackHeight ?? 24;
		mKnobSize = theme?.ToggleSwitchKnobSize ?? 20;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ToggleSwitch";

	/// The width of the track (default 44).
	public float TrackWidth
	{
		get => mTrackWidth;
		set => mTrackWidth = Math.Max(30, value);
	}

	/// The height of the track (default 24).
	public float TrackHeight
	{
		get => mTrackHeight;
		set => mTrackHeight = Math.Max(16, value);
	}

	/// The size of the knob (default 20).
	public float KnobSize
	{
		get => mKnobSize;
		set => mKnobSize = Math.Max(12, value);
	}

	/// Image for the track background (replaces color-based track).
	public ImageBrush? TrackImage
	{
		get => mTrackImage;
		set => mTrackImage = value;
	}

	/// Image for the knob (replaces color-based knob).
	public ImageBrush? KnobImage
	{
		get => mKnobImage;
		set => mKnobImage = value;
	}

	/// Called when IsChecked changes.
	protected override void OnIsCheckedChanged()
	{
		// Snap animation to final position (could be animated in future)
		mAnimationProgress = IsChecked ? 1.0f : 0.0f;
		base.OnIsCheckedChanged();
	}

	/// Measures the toggle switch.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Switch size + optional content
		DesiredSize contentSize = .Zero;
		if (Content != null)
		{
			let contentConstraints = constraints.Deflate(Thickness(mTrackWidth + 8, 0));
			contentSize = Content.Measure(contentConstraints);
		}

		return DesiredSize(
			mTrackWidth + (contentSize.Width > 0 ? 8 + contentSize.Width : 0),
			Math.Max(mTrackHeight, contentSize.Height)
		);
	}

	/// Arranges the toggle switch content.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (Content != null)
		{
			// Content goes to the right of the switch
			let contentX = contentBounds.X + mTrackWidth + 8;
			let contentWidth = contentBounds.Width - mTrackWidth - 8;
			let contentBoundsAdjusted = RectangleF(
				contentX,
				contentBounds.Y,
				contentWidth,
				contentBounds.Height
			);
			Content.Arrange(contentBoundsAdjusted);
		}
	}

	/// Renders the toggle switch.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Calculate track position (vertically centered)
		let trackY = bounds.Y + (bounds.Height - mTrackHeight) / 2;
		let trackRect = RectangleF(bounds.X, trackY, mTrackWidth, mTrackHeight);
		let trackRadius = mTrackHeight / 2;

		// Draw track
		if (mTrackImage.HasValue && mTrackImage.Value.IsValid)
		{
			var img = mTrackImage.Value;
			// Interpolate tint between normal and checked-state tint
			if (IsChecked)
				img.Tint = Palette.Lighten(img.Tint, 0.1f);
			ctx.DrawImageBrush(img, trackRect);
		}
		else
		{
			// Interpolate track color based on animation progress
			let offColor = GetTrackOffColor();
			let onColor = GetCheckedBackground();
			let trackColor = offColor.Interpolate(onColor, mAnimationProgress);
			ctx.FillRoundedRect(trackRect, trackRadius, trackColor);

			// Draw track border
			let borderColor = GetStateBorderColor();
			if (borderColor.A > 0)
			{
				ctx.DrawRoundedRect(trackRect, trackRadius, borderColor, 1);
			}
		}

		// Calculate knob position
		let knobPadding = (mTrackHeight - mKnobSize) / 2;
		let knobMinX = trackRect.X + knobPadding;
		let knobMaxX = trackRect.Right - mKnobSize - knobPadding;
		let knobX = knobMinX + (knobMaxX - knobMinX) * mAnimationProgress;
		let knobY = trackRect.Y + knobPadding;
		let knobRect = RectangleF(knobX, knobY, mKnobSize, mKnobSize);
		let knobRadius = mKnobSize / 2;

		// Draw knob
		if (mKnobImage.HasValue && mKnobImage.Value.IsValid)
		{
			var img = mKnobImage.Value;
			img.Tint = ControlStyle.ModulateTint(img.Tint, CurrentState);
			ctx.DrawImageBrush(img, knobRect);
		}
		else
		{
			// Draw knob shadow
			let shadowColor = Color(0, 0, 0, 40);
			ctx.FillCircle(.(knobX + knobRadius + 1, knobY + knobRadius + 1), knobRadius, shadowColor);

			// Draw knob
			let knobColor = GetKnobColor();
			ctx.FillCircle(.(knobX + knobRadius, knobY + knobRadius), knobRadius, knobColor);
		}

		// Draw content (label text)
		Content?.Render(ctx);

		// Draw focus indicator
		if (IsFocused)
		{
			let focusColor = FocusBorderColor;
			let focusThickness = FocusBorderThickness;
			let focusRect = RectangleF(
				trackRect.X - focusThickness,
				trackRect.Y - focusThickness,
				trackRect.Width + focusThickness * 2,
				trackRect.Height + focusThickness * 2
			);
			ctx.DrawRoundedRect(focusRect, trackRadius + focusThickness, focusColor, focusThickness);
		}
	}

	/// Gets the track color when off.
	private Color GetTrackOffColor()
	{
		if (let theme = Context?.Theme)
			return theme.Palette.Surface;
		return Color(200, 200, 200, 255);
	}

	/// Gets the knob color.
	private Color GetKnobColor()
	{
		let palette = Context?.Theme?.Palette ?? Palette();
		let baseColor = palette.Surface.A > 0 ? palette.Surface : Color(255, 255, 255, 255);
		switch (CurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		case .Pressed:
			return Palette.ComputePressed(baseColor);
		case .Hover:
			return Palette.ComputeHover(baseColor);
		default:
			return baseColor;
		}
	}
}
