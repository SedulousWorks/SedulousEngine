using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A scrollbar control for scrolling content.
/// The thumb size represents the viewport size relative to content size.
public class ScrollBar : Control
{
	// Scroll position
	private float mValue = 0;
	private float mMinimum = 0;
	private float mMaximum = 100;
	private float mViewportSize = 10; // Size of visible area (determines thumb size)
	private float mSmallChange = 1;   // Arrow button / wheel increment
	private float mLargeChange = 10;  // Page up/down / track click

	// Appearance
	private Orientation mOrientation = .Vertical;
	private float mThickness = 16;
	private Color? mTrackColor;
	private Color? mThumbColor;
	private ImageBrush? mTrackImage;
	private ImageBrush? mThumbImage;

	// Interaction state
	private bool mIsDragging = false;
	private float mDragOffset; // Offset from thumb top/left to mouse position

	// Events
	private EventAccessor<delegate void(ScrollBar, float)> mScroll = new .() ~ delete _;

	/// Creates a new ScrollBar.
	public this()
	{
		IsFocusable = false; // Scrollbars typically not keyboard focusable
		IsTabStop = false;
	}

	/// Creates a new ScrollBar with specified orientation.
	public this(Orientation orientation) : this()
	{
		mOrientation = orientation;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for scrollbar dimensions.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mThickness = theme?.ScrollBarThickness ?? 16;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ScrollBar";

	/// The current scroll position.
	public float Value
	{
		get => mValue;
		set => SetValue(value, true);
	}

	/// Sets the value, optionally raising the Scroll event.
	private void SetValue(float value, bool raiseEvent)
	{
		let newValue = Math.Clamp(value, mMinimum, Math.Max(mMinimum, mMaximum - mViewportSize));
		if (mValue != newValue)
		{
			mValue = newValue;
			if (raiseEvent)
				mScroll.[Friend]Invoke(this, mValue);
		}
	}

	/// The minimum scroll value (default 0).
	public float Minimum
	{
		get => mMinimum;
		set
		{
			if (mMinimum != value)
			{
				mMinimum = value;
				SetValue(mValue, false);
			}
		}
	}

	/// The maximum scroll value (content extent).
	public float Maximum
	{
		get => mMaximum;
		set
		{
			if (mMaximum != value)
			{
				mMaximum = value;
				SetValue(mValue, false);
			}
		}
	}

	/// The viewport size (visible area). Determines thumb size.
	public float ViewportSize
	{
		get => mViewportSize;
		set
		{
			let newValue = Math.Max(1, value);
			if (mViewportSize != newValue)
			{
				mViewportSize = newValue;
				SetValue(mValue, false);
			}
		}
	}

	/// Small change amount (arrow buttons, mouse wheel).
	public float SmallChange
	{
		get => mSmallChange;
		set => mSmallChange = Math.Max(0, value);
	}

	/// Large change amount (page up/down, track click).
	public float LargeChange
	{
		get => mLargeChange;
		set => mLargeChange = Math.Max(0, value);
	}

	/// The orientation of the scrollbar.
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

	/// The thickness of the scrollbar.
	public float Thickness
	{
		get => mThickness;
		set
		{
			if (mThickness != value)
			{
				mThickness = Math.Max(8, value);
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
			return palette.Background.A > 0 ? palette.Background : Color(40, 40, 40, 255);
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
			let style = GetThemeStyle();
			if (style.Foreground.A > 0)
				return style.Foreground;
			let palette = Context?.Theme?.Palette ?? Palette();
			return palette.Surface.A > 0 ? palette.Surface : Color(100, 100, 100, 255);
		}
		set => mThumbColor = value;
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

	/// Event fired when scroll position changes.
	public EventAccessor<delegate void(ScrollBar, float)> Scroll => mScroll;

	/// Whether the scrollbar is needed (content larger than viewport).
	public bool IsScrollNeeded => mMaximum > mMinimum + mViewportSize;

	/// The scrollable range (Maximum - ViewportSize - Minimum).
	public float ScrollableRange => Math.Max(0, mMaximum - mViewportSize - mMinimum);

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		switch (mOrientation)
		{
		case .Horizontal:
			let width = constraints.MaxWidth != SizeConstraints.Infinity
				? constraints.MaxWidth
				: 100;
			return .(width, mThickness);

		case .Vertical:
			let height = constraints.MaxHeight != SizeConstraints.Infinity
				? constraints.MaxHeight
				: 100;
			return .(mThickness, height);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw track
		if (mTrackImage.HasValue && mTrackImage.Value.IsValid)
			ctx.DrawImageBrush(mTrackImage.Value, bounds);
		else
			ctx.FillRect(bounds, TrackColor);

		// Draw thumb if scrolling is needed
		if (IsScrollNeeded)
		{
			let thumbRect = GetThumbRect(bounds);

			if (mThumbImage.HasValue && mThumbImage.Value.IsValid)
			{
				var img = mThumbImage.Value;
				// Apply state tint modulation
				if (mIsDragging)
					img.Tint = Palette.Lighten(img.Tint, 0.15f);
				else if (IsHovered && IsMouseOverThumb(thumbRect))
					img.Tint = Palette.Lighten(img.Tint, 0.10f);
				ctx.DrawImageBrush(img, thumbRect);
			}
			else
			{
				var thumbColor = ThumbColor;

				// Adjust color based on state
				if (mIsDragging)
					thumbColor = thumbColor.Interpolate(Color.White, 0.2f);
				else if (IsHovered && IsMouseOverThumb(thumbRect))
					thumbColor = thumbColor.Interpolate(Color.White, 0.1f);

				let cornerRadius = Math.Min(thumbRect.Width, thumbRect.Height) / 2;
				ctx.FillRoundedRect(thumbRect, cornerRadius, thumbColor);
			}
		}
	}

	private RectangleF GetThumbRect(RectangleF trackBounds)
	{
		let totalRange = mMaximum - mMinimum;
		if (totalRange <= 0)
			return trackBounds;

		// Thumb size is proportional to viewport/content ratio
		let thumbRatio = Math.Clamp(mViewportSize / totalRange, 0.1f, 1.0f);

		// Thumb position based on scroll value
		let scrollRange = ScrollableRange;
		let positionRatio = scrollRange > 0 ? (mValue - mMinimum) / scrollRange : 0;

		let padding = 2.0f; // Small padding from edges

		switch (mOrientation)
		{
		case .Horizontal:
			let availableWidth = trackBounds.Width - padding * 2;
			let thumbWidth = Math.Max(20, availableWidth * thumbRatio);
			let thumbX = trackBounds.X + padding + (availableWidth - thumbWidth) * positionRatio;
			return .(thumbX, trackBounds.Y + padding, thumbWidth, trackBounds.Height - padding * 2);

		case .Vertical:
			let availableHeight = trackBounds.Height - padding * 2;
			let thumbHeight = Math.Max(20, availableHeight * thumbRatio);
			let thumbY = trackBounds.Y + padding + (availableHeight - thumbHeight) * positionRatio;
			return .(trackBounds.X + padding, thumbY, trackBounds.Width - padding * 2, thumbHeight);
		}
	}

	private bool IsMouseOverThumb(RectangleF thumbRect)
	{
		let mousePos = Context?.InputManager?.LastMousePosition ?? .Zero;
		let localX = mousePos.X - ArrangedBounds.X;
		let localY = mousePos.Y - ArrangedBounds.Y;
		let localThumb = RectangleF(thumbRect.X - ArrangedBounds.X, thumbRect.Y - ArrangedBounds.Y, thumbRect.Width, thumbRect.Height);
		return localThumb.Contains(localX, localY);
	}

	// === Input ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && IsEffectivelyEnabled && IsScrollNeeded)
		{
			let bounds = ArrangedBounds;
			let thumbRect = GetThumbRect(bounds);

			// Use global mouse position for reliable hit testing
			let globalMousePos = Context?.InputManager?.LastMousePosition ?? .Zero;
			let clickX = globalMousePos.X;
			let clickY = globalMousePos.Y;

			if (thumbRect.Contains(clickX, clickY))
			{
				// Start thumb drag
				mIsDragging = true;
				switch (mOrientation)
				{
				case .Horizontal:
					mDragOffset = clickX - thumbRect.X;
				case .Vertical:
					mDragOffset = clickY - thumbRect.Y;
				}
				Context?.FocusManager?.SetCapture(this);
			}
			else
			{
				// Click on track - page up/down
				switch (mOrientation)
				{
				case .Horizontal:
					if (clickX < thumbRect.X)
						SetValue(mValue - mLargeChange, true);
					else
						SetValue(mValue + mLargeChange, true);
				case .Vertical:
					if (clickY < thumbRect.Y)
						SetValue(mValue - mLargeChange, true);
					else
						SetValue(mValue + mLargeChange, true);
				}
			}

			e.Handled = true;
		}
	}

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		if (mIsDragging)
		{
			let bounds = ArrangedBounds;
			let padding = 2.0f;

			// Use global mouse position for reliable tracking
			let globalMousePos = Context?.InputManager?.LastMousePosition ?? .Zero;

			switch (mOrientation)
			{
			case .Horizontal:
				let availableWidth = bounds.Width - padding * 2;
				let thumbRatio = Math.Clamp(mViewportSize / (mMaximum - mMinimum), 0.1f, 1.0f);
				let thumbWidth = Math.Max(20, availableWidth * thumbRatio);
				let trackStart = bounds.X + padding;
				let trackRange = availableWidth - thumbWidth;

				if (trackRange > 0)
				{
					let thumbLeft = globalMousePos.X - mDragOffset;
					let normalized = Math.Clamp((thumbLeft - trackStart) / trackRange, 0, 1);
					SetValue(mMinimum + normalized * ScrollableRange, true);
				}

			case .Vertical:
				let availableHeight = bounds.Height - padding * 2;
				let thumbRatio = Math.Clamp(mViewportSize / (mMaximum - mMinimum), 0.1f, 1.0f);
				let thumbHeight = Math.Max(20, availableHeight * thumbRatio);
				let trackStart = bounds.Y + padding;
				let trackRange = availableHeight - thumbHeight;

				if (trackRange > 0)
				{
					let thumbTop = globalMousePos.Y - mDragOffset;
					let normalized = Math.Clamp((thumbTop - trackStart) / trackRange, 0, 1);
					SetValue(mMinimum + normalized * ScrollableRange, true);
				}
			}
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

		if (IsEffectivelyEnabled && IsScrollNeeded)
		{
			if (e.DeltaY > 0)
				SetValue(mValue - mSmallChange * 3, true);
			else if (e.DeltaY < 0)
				SetValue(mValue + mSmallChange * 3, true);
			e.Handled = true;
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		// Don't stop dragging on mouse leave - that's handled by capture
	}

	/// Scrolls up/left by SmallChange.
	public void ScrollUp() => SetValue(mValue - mSmallChange, true);

	/// Scrolls down/right by SmallChange.
	public void ScrollDown() => SetValue(mValue + mSmallChange, true);

	/// Scrolls up/left by LargeChange.
	public void PageUp() => SetValue(mValue - mLargeChange, true);

	/// Scrolls down/right by LargeChange.
	public void PageDown() => SetValue(mValue + mLargeChange, true);

	/// Scrolls to the beginning.
	public void ScrollToBeginning() => SetValue(mMinimum, true);

	/// Scrolls to the end.
	public void ScrollToEnd() => SetValue(mMaximum - mViewportSize, true);
}
