namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Standalone scrollbar view. Independently themeable, plugged into
/// ScrollView by composition (not in mChildren). Supports thumb dragging.
public class ScrollBar : View
{
	public Orientation Orientation = .Vertical;
	public float Value;           // current scroll position
	public float Min;             // minimum scroll value (usually 0)
	public float MaxValue = 100;  // total scrollable range
	public float ViewportSize;    // visible portion size
	public float BarThickness = 8;
	public float SmallChange = 20;  // arrow key / single-click step
	private float mLargeChange;     // page step (0 = auto: 90% of viewport)
	public float LargeChange { get => (mLargeChange > 0) ? mLargeChange : ViewportSize * 0.9f; set => mLargeChange = value; }

	// Drag state.
	private bool mDragging;
	private float mDragOffset;  // offset from thumb top/left to mouse pos at drag start

	// Callback when the user drags the thumb - ScrollView subscribes.
	public delegate void(float newValue) OnValueChanged ~ delete _;

	private Color? mTrackColor;
	private Color? mThumbColor;

	public Color TrackColor
	{
		get => mTrackColor ?? Context?.Theme?.GetColor("ScrollBar.Track") ?? .(80, 80, 80, 100);
		set => mTrackColor = value;
	}

	public Color ThumbColor
	{
		get => mThumbColor ?? Context?.Theme?.GetColor("ScrollBar.Thumb") ?? .(180, 180, 180, 200);
		set => mThumbColor = value;
	}

	/// Ratio of viewport to total content (0..1). Determines thumb size.
	public float ThumbRatio => (MaxValue > 0 && ViewportSize > 0)
		? Math.Clamp(ViewportSize / (MaxValue + ViewportSize), 0.05f, 1.0f) : 1.0f;

	/// Normalized scroll position (0..1).
	public float NormalizedValue => (MaxValue > 0) ? Math.Clamp(Value / MaxValue, 0, 1) : 0;

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (Orientation == .Vertical)
			MeasuredSize = .(wSpec.Resolve(BarThickness), hSpec.Resolve(0));
		else
			MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(BarThickness));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();

		// Track
		if (!ctx.TryDrawDrawable("ScrollBar.Track", bounds, state))
			ctx.VG.FillRoundedRect(bounds, BarThickness * 0.5f, TrackColor);

		// Thumb
		if (ThumbRatio < 1.0f)
		{
			let thumbRect = GetThumbRect();
			if (!ctx.TryDrawDrawable("ScrollBar.Thumb", thumbRect, state))
				ctx.VG.FillRoundedRect(thumbRect, BarThickness * 0.4f, ThumbColor);
		}
	}

	/// Get the thumb rectangle in local coordinates.
	public RectangleF GetThumbRect()
	{
		if (Orientation == .Vertical)
		{
			let trackH = Height;
			let thumbH = Math.Max(BarThickness, trackH * ThumbRatio);
			let thumbY = NormalizedValue * (trackH - thumbH);
			return .(0, thumbY, Width, thumbH);
		}
		else
		{
			let trackW = Width;
			let thumbW = Math.Max(BarThickness, trackW * ThumbRatio);
			let thumbX = NormalizedValue * (trackW - thumbW);
			return .(thumbX, 0, thumbW, Height);
		}
	}

	// === Thumb drag interaction ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		let thumbRect = GetThumbRect();
		let pos = (Orientation == .Vertical) ? e.Y : e.X;
		let thumbStart = (Orientation == .Vertical) ? thumbRect.Y : thumbRect.X;
		let thumbEnd = thumbStart + ((Orientation == .Vertical) ? thumbRect.Height : thumbRect.Width);

		if (pos >= thumbStart && pos <= thumbEnd)
		{
			// Clicked on thumb - start drag.
			mDragging = true;
			mDragOffset = pos - thumbStart;
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
		}
		else
		{
			// Clicked on track - page-scroll toward click position.
			if (pos < thumbStart)
				Value = Math.Max(Min, Value - LargeChange);
			else
				Value = Math.Min(MaxValue, Value + LargeChange);
			OnValueChanged?.Invoke(Value);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (!mDragging) return;

		let thumbRect = GetThumbRect();
		let trackSize = (Orientation == .Vertical) ? Height : Width;
		let thumbSize = (Orientation == .Vertical) ? thumbRect.Height : thumbRect.Width;
		let pos = (Orientation == .Vertical) ? e.Y : e.X;

		let newThumbPos = pos - mDragOffset;
		let normalized = Math.Clamp(newThumbPos / (trackSize - thumbSize), 0, 1);
		Value = normalized * MaxValue;
		OnValueChanged?.Invoke(Value);
		e.Handled = true;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}
}
