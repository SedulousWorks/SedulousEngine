using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A scroll position, dragged by a thumb whose size shows how much of the content is visible.
///
/// Plain fields with explicit setters rather than Properties: every one of them has to clamp or
/// re-clamp something else, so the notification a Property gives would be firing off half
/// finished state.
class ScrollBar : View
{
	/// The bar's thickness across its short axis.
	public float BarThickness = 10.0f;

	public Event<delegate void(ScrollBar, float)> OnValueChanged ~ _.Dispose();

	private float mValue = 0.0f;
	private float mMaxValue = 100.0f;
	private float mViewportSize = 50.0f;
	private bool mIsHorizontal = false;
	private bool mDragging = false;
	private float mDragStartValue = 0.0f;
	private float mDragStartMouse = 0.0f;

	public this(bool horizontal = false)
	{
		mIsHorizontal = horizontal;
		// ALWAYS the arrow. A bar inside a text control would otherwise inherit the parent's
		// I-beam through the effective cursor walk, and a scrollbar is never text.
		Cursor = .Arrow;
	}

	public float Value
	{
		get => mValue;
		set
		{
			let clamped = Clamp(value, 0.0f, mMaxValue);
			if (mValue == clamped)
				return;

			mValue = clamped;
			Invalidate();
			OnValueChanged(this, mValue);
		}
	}

	public float MaxValue
	{
		get => mMaxValue;
		set
		{
			mMaxValue = Max(0.0f, value);
			// Re-clamped through the setter, so shrinking the range pulls the value in with it.
			Value = mValue;
		}
	}

	public float ViewportSize
	{
		get => mViewportSize;
		set
		{
			// Never zero: the thumb ratio divides by it.
			mViewportSize = Max(1.0f, value);
			Invalidate();
		}
	}

	public bool IsHorizontal
	{
		get => mIsHorizontal;
		set
		{
			mIsHorizontal = value;
			Invalidate();
		}
	}

	/// The thumb, in local coordinates.
	public Rectangle GetThumbRect()
	{
		let ratio = ThumbRatio;
		let normalized = NormalizedValue;

		if (mIsHorizontal)
		{
			let thumbWidth = Width * ratio;
			return .((Width - thumbWidth) * normalized, 0, thumbWidth, Height);
		}

		let thumbHeight = Height * ratio;
		return .(0, (Height - thumbHeight) * normalized, Width, thumbHeight);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		// The event's coordinates may belong to another view's space, since the press bubbled
		// to get here. The screen position is the one thing that means the same everywhere.
		let screen = ScreenMouse();
		let local = ScreenToLocal(screen);
		let localPos = mIsHorizontal ? local.X : local.Y;
		let screenPos = mIsHorizontal ? screen.X : screen.Y;

		let thumbRect = GetThumbRect();
		let thumbStart = mIsHorizontal ? thumbRect.X : thumbRect.Y;
		let thumbEnd = thumbStart + (mIsHorizontal ? thumbRect.Width : thumbRect.Height);

		if ((localPos >= thumbStart) && (localPos <= thumbEnd))
		{
			mDragging = true;
			mDragStartValue = mValue;
			mDragStartMouse = screenPos;
			if (Context != null)
				Context.GetFocusManager().SetCapture(this);
		}
		else
		{
			// A press on the track jumps the thumb's CENTRE to the pointer.
			let trackSize = mIsHorizontal ? Width : Height;
			let thumbSize = trackSize * ThumbRatio;
			let clickNormalized = (localPos - thumbSize * 0.5f) / (trackSize - thumbSize);
			Value = Clamp(clickNormalized * mMaxValue, 0.0f, mMaxValue);
		}

		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (!mDragging)
			return;

		let screen = ScreenMouse();
		let screenPos = mIsHorizontal ? screen.X : screen.Y;

		let trackSize = mIsHorizontal ? Width : Height;
		let thumbSize = trackSize * ThumbRatio;
		let trackRange = trackSize - thumbSize;

		// Measured from where the drag STARTED rather than frame to frame, so rounding does
		// not accumulate over a long drag.
		if (trackRange > 0)
		{
			let delta = screenPos - mDragStartMouse;
			Value = mDragStartValue + (delta / trackRange) * mMaxValue;
		}

		e.Handled = true;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();

			e.Handled = true;
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (mIsHorizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(100.0f)),
				constraints.ConstrainHeight(BarThickness));
		else
			MeasuredSize = .(constraints.ConstrainWidth(BarThickness),
				constraints.ConstrainHeight(constraints.BoundedMaxHeight(100.0f)));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let state = GetControlState();
		let bounds = Rectangle(0, 0, Width, Height);

		if (let track = ResolvePartDrawable("track", .Background, state))
			track.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color(40 / 255.0f, 42 / 255.0f, 50 / 255.0f, 150 / 255.0f));

		let thumbRect = GetThumbRect();
		if (let thumb = ResolvePartDrawable("thumb", .Background, state))
			thumb.Draw(ctx, thumbRect);
		else
			ctx.VG.FillRect(thumbRect, Color(100 / 255.0f, 110 / 255.0f, 130 / 255.0f, 200 / 255.0f));
	}

	private Float2 ScreenMouse()
	{
		if ((Context == null) || (Context.GetInputManager() == null))
			return .Zero;

		let input = Context.GetInputManager();
		return .(input.MouseX, input.MouseY);
	}

	/// How much of the bar the thumb fills: the visible fraction of the whole scrollable
	/// extent, floored so the thumb never shrinks to nothing on a very long document.
	private float ThumbRatio => Clamp(mViewportSize / (mMaxValue + mViewportSize), 0.05f, 1.0f);

	private float NormalizedValue => (mMaxValue > 0) ? mValue / mMaxValue : 0.0f;
}
