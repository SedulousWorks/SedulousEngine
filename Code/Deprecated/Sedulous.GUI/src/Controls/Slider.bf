using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A slider control for selecting a value within a range.
/// Supports horizontal and vertical orientations.
public class Slider : Control
{
	// Value
	private float mValue = 0;
	private float mMinimum = 0;
	private float mMaximum = 100;
	private float mStep = 0; // 0 = continuous

	// Appearance
	private Orientation mOrientation = .Horizontal;
	private float mTrackThickness = 4;
	private float mThumbSize = 16;
	private Color? mTrackColor;
	private Color? mThumbColor;
	private Color? mFillColor;
	private ImageBrush? mTrackImage;
	private ImageBrush? mThumbImage;

	// Ticks
	private float mTickFrequency = 0; // 0 = no ticks
	private TickPlacement mTickPlacement = .None;

	// Interaction state
	private bool mIsDragging = false;
	private float mDragStartValue;

	// Events
	private EventAccessor<delegate void(Slider, float)> mValueChanged = new .() ~ delete _;

	/// Creates a new Slider.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .Pointer;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for slider dimensions.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mTrackThickness = theme?.SliderTrackThickness ?? 4;
		mThumbSize = theme?.SliderThumbSize ?? 16;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Slider";

	/// The current value (clamped between Minimum and Maximum).
	public float Value
	{
		get => mValue;
		set => SetValue(value, true);
	}

	/// Sets the value, optionally raising the ValueChanged event.
	private void SetValue(float value, bool raiseEvent)
	{
		var newValue = Math.Clamp(value, mMinimum, mMaximum);

		// Apply step if specified
		if (mStep > 0)
		{
			newValue = Math.Round((newValue - mMinimum) / mStep) * mStep + mMinimum;
			newValue = Math.Clamp(newValue, mMinimum, mMaximum);
		}

		if (mValue != newValue)
		{
			mValue = newValue;
			if (raiseEvent)
				mValueChanged.[Friend]Invoke(this, mValue);
		}
	}

	/// The minimum value (default 0).
	public float Minimum
	{
		get => mMinimum;
		set
		{
			if (mMinimum != value)
			{
				mMinimum = value;
				SetValue(mValue, false); // Re-clamp
			}
		}
	}

	/// The maximum value (default 100).
	public float Maximum
	{
		get => mMaximum;
		set
		{
			if (mMaximum != value)
			{
				mMaximum = value;
				SetValue(mValue, false); // Re-clamp
			}
		}
	}

	/// The step/increment size (0 = continuous).
	public float Step
	{
		get => mStep;
		set => mStep = Math.Max(0, value);
	}

	/// The orientation of the slider.
	public Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (mOrientation != value)
			{
				mOrientation = value;
				InvalidateLayout();
			}
		}
	}

	/// The thickness of the track.
	public float TrackThickness
	{
		get => mTrackThickness;
		set
		{
			if (mTrackThickness != value)
			{
				mTrackThickness = Math.Max(1, value);
				InvalidateLayout();
			}
		}
	}

	/// The size (diameter) of the thumb.
	public float ThumbSize
	{
		get => mThumbSize;
		set
		{
			if (mThumbSize != value)
			{
				mThumbSize = Math.Max(4, value);
				InvalidateLayout();
			}
		}
	}

	/// The track color.
	public Color TrackColor
	{
		get
		{
			if (mTrackColor.HasValue)
				return mTrackColor.Value;
			let style = GetThemeStyle();
			if (style.Background.A > 0)
				return style.Background;
			let palette = Context?.Theme?.Palette ?? Palette();
			return palette.Surface.A > 0 ? palette.Surface : Color(60, 60, 60, 255);
		}
		set => mTrackColor = value;
	}

	/// The thumb color.
	public Color ThumbColor
	{
		get
		{
			if (mThumbColor.HasValue)
				return mThumbColor.Value;
			let palette = Context?.Theme?.Palette ?? Palette();
			return palette.Accent.A > 0 ? palette.Accent : Color(0, 120, 215, 255);
		}
		set => mThumbColor = value;
	}

	/// The fill color (track portion before thumb).
	public Color FillColor
	{
		get
		{
			if (mFillColor.HasValue)
				return mFillColor.Value;
			// Default: same as thumb but slightly dimmer
			return ThumbColor.Interpolate(Color.Black, 0.2f);
		}
		set => mFillColor = value;
	}

	/// Image for the track background (replaces color-based track).
	public ImageBrush? TrackImage
	{
		get => mTrackImage;
		set => mTrackImage = value;
	}

	/// Image for the thumb (replaces color-based thumb).
	public ImageBrush? ThumbImage
	{
		get => mThumbImage;
		set => mThumbImage = value;
	}

	/// Tick mark frequency (0 = no ticks).
	public float TickFrequency
	{
		get => mTickFrequency;
		set => mTickFrequency = Math.Max(0, value);
	}

	/// Where to place tick marks.
	public TickPlacement TickPlacement
	{
		get => mTickPlacement;
		set => mTickPlacement = value;
	}

	/// Event fired when the value changes.
	public EventAccessor<delegate void(Slider, float)> ValueChanged => mValueChanged;

	/// Gets the value as a normalized position (0 to 1).
	private float NormalizedValue
	{
		get
		{
			let range = mMaximum - mMinimum;
			if (range <= 0)
				return 0;
			return (mValue - mMinimum) / range;
		}
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Size based on orientation
		switch (mOrientation)
		{
		case .Horizontal:
			let width = constraints.MaxWidth != SizeConstraints.Infinity
				? constraints.MaxWidth
				: 200;
			return .(width, Math.Max(mThumbSize, mTrackThickness + 8));

		case .Vertical:
			let height = constraints.MaxHeight != SizeConstraints.Infinity
				? constraints.MaxHeight
				: 200;
			return .(Math.Max(mThumbSize, mTrackThickness + 8), height);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ContentBounds;

		// Calculate track and thumb geometry
		let (trackRect, thumbCenter) = GetGeometry(bounds);

		// Draw track background
		let trackRadius = mTrackThickness / 2;
		if (mTrackImage.HasValue && mTrackImage.Value.IsValid)
			ctx.DrawImageBrush(mTrackImage.Value, trackRect);
		else
			ctx.FillRoundedRect(trackRect, trackRadius, TrackColor);

		// Draw filled portion
		RenderFill(ctx, trackRect, thumbCenter, trackRadius);

		// Draw tick marks
		if (mTickFrequency > 0 && mTickPlacement != .None)
		{
			RenderTicks(ctx, bounds);
		}

		// Draw thumb
		RenderThumb(ctx, thumbCenter);

		// Draw focus indicator
		if (IsFocused)
		{
			let focusRect = RectangleF(
				thumbCenter.X - mThumbSize / 2 - 2,
				thumbCenter.Y - mThumbSize / 2 - 2,
				mThumbSize + 4,
				mThumbSize + 4
			);
			ctx.DrawRoundedRect(focusRect, mThumbSize / 2 + 2, FocusBorderColor, FocusBorderThickness);
		}
	}

	private (RectangleF trackRect, Vector2 thumbCenter) GetGeometry(RectangleF bounds)
	{
		let thumbRadius = mThumbSize / 2;
		let normalizedValue = NormalizedValue;

		RectangleF trackRect;
		Vector2 thumbCenter;

		switch (mOrientation)
		{
		case .Horizontal:
			// Track is centered vertically, inset by thumb radius on sides
			let trackY = bounds.Y + (bounds.Height - mTrackThickness) / 2;
			let trackStart = bounds.X + thumbRadius;
			let trackEnd = bounds.Right - thumbRadius;
			let trackLength = trackEnd - trackStart;

			trackRect = .(trackStart, trackY, trackLength, mTrackThickness);
			thumbCenter = .(trackStart + trackLength * normalizedValue, bounds.Y + bounds.Height / 2);

		case .Vertical:
			// Track is centered horizontally, inset by thumb radius on top/bottom
			let trackX = bounds.X + (bounds.Width - mTrackThickness) / 2;
			let trackStart = bounds.Y + thumbRadius;
			let trackEnd = bounds.Bottom - thumbRadius;
			let trackLength = trackEnd - trackStart;

			trackRect = .(trackX, trackStart, mTrackThickness, trackLength);
			// For vertical, 0 is at bottom, 1 is at top
			thumbCenter = .(bounds.X + bounds.Width / 2, trackEnd - trackLength * normalizedValue);
		}

		return (trackRect, thumbCenter);
	}

	private void RenderFill(DrawContext ctx, RectangleF trackRect, Vector2 thumbCenter, float trackRadius)
	{
		let fillColor = FillColor;

		switch (mOrientation)
		{
		case .Horizontal:
			if (thumbCenter.X > trackRect.X)
			{
				let fillRect = RectangleF(trackRect.X, trackRect.Y, thumbCenter.X - trackRect.X, trackRect.Height);
				ctx.FillRoundedRect(fillRect, trackRadius, fillColor);
			}

		case .Vertical:
			if (thumbCenter.Y < trackRect.Bottom)
			{
				let fillRect = RectangleF(trackRect.X, thumbCenter.Y, trackRect.Width, trackRect.Bottom - thumbCenter.Y);
				ctx.FillRoundedRect(fillRect, trackRadius, fillColor);
			}
		}
	}

	private void RenderThumb(DrawContext ctx, Vector2 center)
	{
		let thumbRect = RectangleF(
			center.X - mThumbSize / 2,
			center.Y - mThumbSize / 2,
			mThumbSize,
			mThumbSize
		);

		if (mThumbImage.HasValue && mThumbImage.Value.IsValid)
		{
			var img = mThumbImage.Value;
			// Apply state tint modulation
			if (mIsDragging)
				img.Tint = Palette.Darken(img.Tint, 0.15f);
			else if (IsHovered)
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
			ctx.DrawImageBrush(img, thumbRect);
		}
		else
		{
			var thumbColor = ThumbColor;

			// Adjust color based on state
			if (mIsDragging)
				thumbColor = thumbColor.Interpolate(Color.Black, 0.2f);
			else if (IsHovered)
				thumbColor = thumbColor.Interpolate(Color.White, 0.1f);

			ctx.FillRoundedRect(thumbRect, mThumbSize / 2, thumbColor);
		}
	}

	private void RenderTicks(DrawContext ctx, RectangleF bounds)
	{
		let range = mMaximum - mMinimum;
		if (range <= 0 || mTickFrequency <= 0)
			return;

		let tickColor = TrackColor.Interpolate(Color.White, 0.3f);
		let thumbRadius = mThumbSize / 2;

		for (float v = mMinimum; v <= mMaximum; v += mTickFrequency)
		{
			let normalized = (v - mMinimum) / range;
			float tickX, tickY;

			switch (mOrientation)
			{
			case .Horizontal:
				let trackStart = bounds.X + thumbRadius;
				let trackLength = bounds.Width - mThumbSize;
				tickX = trackStart + trackLength * normalized;

				if (mTickPlacement == .TopLeft || mTickPlacement == .Both)
					ctx.FillRect(.(tickX - 1, bounds.Y, 2, 4), tickColor);
				if (mTickPlacement == .BottomRight || mTickPlacement == .Both)
					ctx.FillRect(.(tickX - 1, bounds.Bottom - 4, 2, 4), tickColor);

			case .Vertical:
				let trackStart = bounds.Y + thumbRadius;
				let trackLength = bounds.Height - mThumbSize;
				tickY = trackStart + trackLength * (1 - normalized); // Inverted for vertical

				if (mTickPlacement == .TopLeft || mTickPlacement == .Both)
					ctx.FillRect(.(bounds.X, tickY - 1, 4, 2), tickColor);
				if (mTickPlacement == .BottomRight || mTickPlacement == .Both)
					ctx.FillRect(.(bounds.Right - 4, tickY - 1, 4, 2), tickColor);
			}
		}
	}

	// === Input ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && IsEffectivelyEnabled)
		{
			// Calculate value from click position
			let clickValue = PositionToValue(e.LocalX, e.LocalY);
			SetValue(clickValue, true);

			// Start drag
			mIsDragging = true;
			mDragStartValue = mValue;
			Context?.FocusManager?.SetCapture(this);

			e.Handled = true;
		}
	}

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		if (mIsDragging)
		{
			let newValue = PositionToValue(e.LocalX, e.LocalY);
			SetValue(newValue, true);
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (e.Button == .Left && mIsDragging)
		{
			mIsDragging = false;
			Context?.FocusManager?.ReleaseCapture();
			e.Handled = true;
		}
	}

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		if (IsEffectivelyEnabled)
		{
			let step = mStep > 0 ? mStep : (mMaximum - mMinimum) / 100;
			if (e.DeltaY > 0)
				SetValue(mValue + step, true);
			else if (e.DeltaY < 0)
				SetValue(mValue - step, true);
			e.Handled = true;
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (!IsEffectivelyEnabled)
			return;

		let step = mStep > 0 ? mStep : (mMaximum - mMinimum) / 100;
		let largeStep = mStep > 0 ? mStep * 10 : (mMaximum - mMinimum) / 10;

		switch (e.Key)
		{
		case .Left, .Down:
			SetValue(mValue - step, true);
			e.Handled = true;
		case .Right, .Up:
			SetValue(mValue + step, true);
			e.Handled = true;
		case .PageDown:
			SetValue(mValue - largeStep, true);
			e.Handled = true;
		case .PageUp:
			SetValue(mValue + largeStep, true);
			e.Handled = true;
		case .Home:
			SetValue(mMinimum, true);
			e.Handled = true;
		case .End:
			SetValue(mMaximum, true);
			e.Handled = true;
		default:
		}
	}

	protected override void OnLostFocus(FocusEventArgs e)
	{
		base.OnLostFocus(e);

		if (mIsDragging)
		{
			mIsDragging = false;
			if (Context?.FocusManager?.CapturedElement == this)
				Context?.FocusManager?.ReleaseCapture();
		}
	}

	private float PositionToValue(float localX, float localY)
	{
		let bounds = ContentBounds;
		let thumbRadius = mThumbSize / 2;

		// Local coordinates are relative to ArrangedBounds origin
		// ContentBounds are also relative to ArrangedBounds, so we need local offset
		let localOffsetX = bounds.X - ArrangedBounds.X;
		let localOffsetY = bounds.Y - ArrangedBounds.Y;

		float normalized;
		switch (mOrientation)
		{
		case .Horizontal:
			let trackStart = localOffsetX + thumbRadius;
			let trackLength = bounds.Width - mThumbSize;
			if (trackLength <= 0)
				return mMinimum;
			normalized = Math.Clamp((localX - trackStart) / trackLength, 0, 1);

		case .Vertical:
			let trackStart = localOffsetY + thumbRadius;
			let trackLength = bounds.Height - mThumbSize;
			if (trackLength <= 0)
				return mMinimum;
			// Inverted for vertical (top = max)
			normalized = 1 - Math.Clamp((localY - trackStart) / trackLength, 0, 1);
		}

		return mMinimum + normalized * (mMaximum - mMinimum);
	}
}

/// Placement of tick marks on a slider.
public enum TickPlacement
{
	/// No tick marks.
	None,
	/// Tick marks on top (horizontal) or left (vertical).
	TopLeft,
	/// Tick marks on bottom (horizontal) or right (vertical).
	BottomRight,
	/// Tick marks on both sides.
	Both
}
