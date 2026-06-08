namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Standalone scrollbar control. Used by ScrollView internally.
public class ScrollBar : View
{
	private float mValue;
	private float mMaxValue = 100;
	private float mViewportSize = 50;
	private bool mIsHorizontal;
	private bool mDragging;
	private float mDragStartValue;
	private float mDragStartMouse;

	/// Scrollbar thickness in pixels.
	public float BarThickness = 10;

	/// Value change callback.
	public Event<delegate void(ScrollBar, float)> OnValueChanged ~ _.Dispose();

	/// Current scroll position (0 to MaxValue).
	public float Value
	{
		get => mValue;
		set
		{
			let clamped = Math.Clamp(value, 0, mMaxValue);
			if (mValue == clamped) return;
			mValue = clamped;
			Invalidate();
			OnValueChanged(this, mValue);
		}
	}

	/// Maximum scroll value.
	public float MaxValue
	{
		get => mMaxValue;
		set { mMaxValue = Math.Max(0, value); Value = mValue; }
	}

	/// Size of the visible viewport (determines thumb size).
	public float ViewportSize
	{
		get => mViewportSize;
		set { mViewportSize = Math.Max(1, value); Invalidate(); }
	}

	/// Whether this is a horizontal scrollbar.
	public bool IsHorizontal
	{
		get => mIsHorizontal;
		set { mIsHorizontal = value; Invalidate(); }
	}

	public this(bool horizontal = false)
	{
		mIsHorizontal = horizontal;
	}

	/// Thumb size ratio (0-1).
	private float ThumbRatio => Math.Clamp(mViewportSize / (mMaxValue + mViewportSize), 0.05f, 1.0f);

	/// Normalized position (0-1).
	private float NormalizedValue => (mMaxValue > 0) ? mValue / mMaxValue : 0;

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (mIsHorizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth), constraints.ConstrainHeight(BarThickness));
		else
			MeasuredSize = .(constraints.ConstrainWidth(BarThickness), constraints.ConstrainHeight(constraints.MaxHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let state = GetControlState();
		let trackDrawable = ResolvePartDrawable("track", .Background, state);
		let thumbDrawable = ResolvePartDrawable("thumb", .Background, state);

		let bounds = RectangleF(0, 0, Width, Height);

		// Track
		if (trackDrawable != null)
			trackDrawable.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, .(40, 42, 50, 150));

		// Thumb
		let thumbRect = GetThumbRect();
		if (thumbDrawable != null)
			thumbDrawable.Draw(ctx, thumbRect);
		else
			ctx.VG.FillRect(thumbRect, .(100, 110, 130, 200));
	}

	/// Get the thumb rectangle in local coordinates.
	public RectangleF GetThumbRect()
	{
		let ratio = ThumbRatio;
		let norm = NormalizedValue;

		if (mIsHorizontal)
		{
			let thumbW = Width * ratio;
			let thumbX = (Width - thumbW) * norm;
			return .(thumbX, 0, thumbW, Height);
		}
		else
		{
			let thumbH = Height * ratio;
			let thumbY = (Height - thumbH) * norm;
			return .(0, thumbY, Width, thumbH);
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left) return;

		// Use ScreenToLocal for all coordinate calculations - e.X/e.Y may be
		// in a different view's space due to event bubbling.
		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));
		let localPos = mIsHorizontal ? local.X : local.Y;
		let screenPos = mIsHorizontal ? screenX : screenY;

		let thumbRect = GetThumbRect();
		let thumbStart = mIsHorizontal ? thumbRect.X : thumbRect.Y;
		let thumbEnd = thumbStart + (mIsHorizontal ? thumbRect.Width : thumbRect.Height);

		if (localPos >= thumbStart && localPos <= thumbEnd)
		{
			// Drag thumb
			mDragging = true;
			mDragStartValue = mValue;
			mDragStartMouse = screenPos;
			Context?.FocusManager.SetCapture(this);
		}
		else
		{
			// Page scroll - jump toward click
			let trackSize = mIsHorizontal ? Width : Height;
			let thumbSize = trackSize * ThumbRatio;
			let clickNorm = (localPos - thumbSize * 0.5f) / (trackSize - thumbSize);
			Value = Math.Clamp(clickNorm * mMaxValue, 0, mMaxValue);
		}

		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (!mDragging) return;

		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let screenPos = mIsHorizontal ? screenX : screenY;

		let trackSize = mIsHorizontal ? Width : Height;
		let thumbSize = trackSize * ThumbRatio;
		let trackRange = trackSize - thumbSize;

		if (trackRange > 0)
		{
			let delta = screenPos - mDragStartMouse;
			let valueDelta = (delta / trackRange) * mMaxValue;
			Value = mDragStartValue + valueDelta;
		}

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
