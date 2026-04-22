using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Displays progress as a horizontal or vertical bar.
/// Supports both determinate (showing specific progress) and
/// indeterminate (animated "working") modes.
public class ProgressBar : Control
{
	private float mValue = 0;
	private float mMinimum = 0;
	private float mMaximum = 100;
	private bool mIsIndeterminate = false;
	private Orientation mOrientation = .Horizontal;
	private Color? mTrackColor;
	private Color? mFillColor;
	private ImageBrush? mTrackImage;
	private ImageBrush? mFillImage;

	// Indeterminate animation state
	private const float IndeterminateWidth = 0.3f;  // Width of the moving indicator as fraction of track
	private const float IndeterminateSpeed = 1.5f;  // Complete cycles per second

	/// Creates a new ProgressBar.
	public this()
	{
		// ProgressBars are not focusable
		IsFocusable = false;
		IsTabStop = false;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ProgressBar";

	/// The current value (clamped between Minimum and Maximum).
	public float Value
	{
		get => mValue;
		set
		{
			let clamped = Math.Clamp(value, mMinimum, mMaximum);
			if (mValue != clamped)
			{
				mValue = clamped;
				// No layout invalidation needed, just visual change
			}
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
				// Re-clamp current value
				mValue = Math.Clamp(mValue, mMinimum, mMaximum);
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
				// Re-clamp current value
				mValue = Math.Clamp(mValue, mMinimum, mMaximum);
			}
		}
	}

	/// Whether the progress bar shows indeterminate progress (animated).
	public bool IsIndeterminate
	{
		get => mIsIndeterminate;
		set => mIsIndeterminate = value;
	}

	/// The orientation of the progress bar.
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

	/// The track (background) color. If not set, uses a darker version of the fill.
	public Color TrackColor
	{
		get
		{
			if (mTrackColor.HasValue)
				return mTrackColor.Value;
			// Default: darker version of the background
			let style = GetThemeStyle();
			return Palette.ComputePressed(style.Background);
		}
		set => mTrackColor = value;
	}

	/// The fill (progress) color. If not set, uses theme accent color.
	public Color FillColor
	{
		get
		{
			if (mFillColor.HasValue)
				return mFillColor.Value;
			// Default: use accent color from theme palette
			let palette = Context?.Theme?.Palette ?? Palette();
			return palette.Accent.A > 0 ? palette.Accent : Color(0, 120, 215, 255);
		}
		set => mFillColor = value;
	}

	/// Image for the track background (replaces color-based track).
	public ImageBrush? TrackImage
	{
		get => mTrackImage;
		set => mTrackImage = value;
	}

	/// Image for the fill bar (replaces color-based fill).
	public ImageBrush? FillImage
	{
		get => mFillImage;
		set => mFillImage = value;
	}

	// Note: CornerRadius is inherited from Control

	/// Gets the progress as a value from 0 to 1.
	public float Progress
	{
		get
		{
			let range = mMaximum - mMinimum;
			if (range <= 0)
				return 0;
			return (mValue - mMinimum) / range;
		}
	}

	/// Measures the progress bar.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Default size: thin bar that stretches to fill available space
		switch (mOrientation)
		{
		case .Horizontal:
			let width = constraints.MaxWidth != SizeConstraints.Infinity
				? constraints.MaxWidth
				: 200; // Default width
			return .(width, 8); // 8 pixels tall

		case .Vertical:
			let height = constraints.MaxHeight != SizeConstraints.Infinity
				? constraints.MaxHeight
				: 200; // Default height
			return .(8, height); // 8 pixels wide
		}
	}

	/// Renders the progress bar.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw track (background)
		if (mTrackImage.HasValue && mTrackImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mTrackImage.Value, bounds);
		}
		else
		{
			let trackColor = TrackColor;
			if (CornerRadius > 0)
				ctx.FillRoundedRect(bounds, CornerRadius, trackColor);
			else
				ctx.FillRect(bounds, trackColor);
		}

		// Draw fill
		if (mIsIndeterminate)
		{
			RenderIndeterminate(ctx, bounds, FillColor);
		}
		else
		{
			RenderDeterminate(ctx, bounds, FillColor);
		}
	}

	/// Renders determinate progress.
	private void RenderDeterminate(DrawContext ctx, RectangleF bounds, Color fillColor)
	{
		let progress = Progress;
		if (progress <= 0)
			return;

		RectangleF fillRect;
		switch (mOrientation)
		{
		case .Horizontal:
			let fillWidth = bounds.Width * progress;
			fillRect = .(bounds.X, bounds.Y, fillWidth, bounds.Height);

		case .Vertical:
			// Fill from bottom to top
			let fillHeight = bounds.Height * progress;
			fillRect = .(bounds.X, bounds.Bottom - fillHeight, bounds.Width, fillHeight);
		}

		if (mFillImage.HasValue && mFillImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mFillImage.Value, fillRect);
		}
		else
		{
			if (CornerRadius > 0)
				ctx.FillRoundedRect(fillRect, CornerRadius, fillColor);
			else
				ctx.FillRect(fillRect, fillColor);
		}
	}

	/// Renders indeterminate (animated) progress.
	private void RenderIndeterminate(DrawContext ctx, RectangleF bounds, Color fillColor)
	{
		// Get animation time from context
		let time = Context?.TotalTime ?? 0;

		// Calculate position (0 to 1, wrapping)
		let cyclePosition = (float)((time * IndeterminateSpeed) % 1.0);

		// Use a smooth ease function to make the animation feel more natural
		// Move from -width to 1+width so it fully enters and exits
		let start = -IndeterminateWidth + cyclePosition * (1.0f + IndeterminateWidth * 2);

		RectangleF fillRect;
		switch (mOrientation)
		{
		case .Horizontal:
			let fillStart = bounds.X + bounds.Width * start;
			let fillWidth = bounds.Width * IndeterminateWidth;
			// Clip to bounds
			let clippedStart = Math.Max(fillStart, bounds.X);
			let clippedEnd = Math.Min(fillStart + fillWidth, bounds.Right);
			if (clippedEnd > clippedStart)
			{
				fillRect = .(clippedStart, bounds.Y, clippedEnd - clippedStart, bounds.Height);
			}
			else
			{
				return; // Nothing visible
			}

		case .Vertical:
			let fillStartY = bounds.Y + bounds.Height * start;
			let fillHeight = bounds.Height * IndeterminateWidth;
			// Clip to bounds
			let clippedStartY = Math.Max(fillStartY, bounds.Y);
			let clippedEndY = Math.Min(fillStartY + fillHeight, bounds.Bottom);
			if (clippedEndY > clippedStartY)
			{
				fillRect = .(bounds.X, clippedStartY, bounds.Width, clippedEndY - clippedStartY);
			}
			else
			{
				return; // Nothing visible
			}
		}

		if (mFillImage.HasValue && mFillImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mFillImage.Value, fillRect);
		}
		else
		{
			if (CornerRadius > 0)
				ctx.FillRoundedRect(fillRect, CornerRadius, fillColor);
			else
				ctx.FillRect(fillRect, fillColor);
		}
	}
}
