namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Value slider with track, fill, and draggable thumb.
public class Slider : View
{
	private float mValue;
	private float mMin;
	private float mMax = 1.0f;
	private float mStep;
	private bool mDragging;

	public Orientation Orientation = .Horizontal;

	public float Value
	{
		get => mValue;
		set
		{
			let clamped = SnapToStep(Math.Clamp(value, mMin, mMax));
			if (mValue == clamped) return;
			mValue = clamped;
			Invalidate();
			OnValueChanged(this, mValue);
		}
	}

	public float Min { get => mMin; set { mMin = value; Value = mValue; } }
	public float Max { get => mMax; set { mMax = value; Value = mValue; } }
	public float Step { get => mStep; set => mStep = Math.Max(0, value); }

	public Event<delegate void(Slider, float)> OnValueChanged ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragStarted ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragEnded ~ _.Dispose();

	public this() { IsFocusable = true; IsTabStop = true; Cursor = .Hand; StyleId = new String("slider"); }
	public this(float min, float max, float value = 0) : this() { mMin = min; mMax = max; mValue = Math.Clamp(value, min, max); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation == .Horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth), constraints.ConstrainHeight(20));
		else
			MeasuredSize = .(constraints.ConstrainWidth(20), constraints.ConstrainHeight(constraints.MaxHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let trackHeight = ResolveStyleFloat(.TrackHeight, 4);
		let thumbSize = ResolveStyleFloat(.ThumbSize, 16);
		let thumbHalf = thumbSize * 0.5f;

		let trackDrawable = ResolveStyleDrawable(.TrackDrawable);
		let fillDrawable = ResolveStyleDrawable(.FillDrawable);
		let thumbDrawable = ResolveStyleDrawable(.ThumbDrawable);

		let progress = (mMax > mMin) ? (mValue - mMin) / (mMax - mMin) : 0;

		if (Orientation == .Horizontal)
		{
			let trackY = (Height - trackHeight) * 0.5f;
			let trackLeft = thumbHalf;
			let trackRight = Width - thumbHalf;
			let trackW = trackRight - trackLeft;

			// Track background
			let trackRect = RectangleF(trackLeft, trackY, trackW, trackHeight);
			if (trackDrawable != null)
				trackDrawable.Draw(ctx, trackRect);
			else
				ctx.VG.FillRect(trackRect, .(50, 52, 62, 255));

			// Fill
			let fillW = trackW * progress;
			if (fillW > 0)
			{
				let fillRect = RectangleF(trackLeft, trackY, fillW, trackHeight);
				if (fillDrawable != null)
					fillDrawable.Draw(ctx, fillRect);
				else
					ctx.VG.FillRect(fillRect, .(80, 150, 240, 255));
			}

			// Thumb
			let thumbX = trackLeft + trackW * progress;
			let thumbRect = RectangleF(thumbX - thumbHalf, Height * 0.5f - thumbHalf, thumbSize, thumbSize);
			if (thumbDrawable != null)
				thumbDrawable.Draw(ctx, thumbRect);
			else
				ctx.VG.FillCircle(.(thumbX, Height * 0.5f), thumbHalf, .(220, 220, 230, 255));
		}
		else
		{
			let trackX = (Width - trackHeight) * 0.5f;
			let trackTop = thumbHalf;
			let trackBottom = Height - thumbHalf;
			let trackH = trackBottom - trackTop;

			let trackRect = RectangleF(trackX, trackTop, trackHeight, trackH);
			if (trackDrawable != null)
				trackDrawable.Draw(ctx, trackRect);
			else
				ctx.VG.FillRect(trackRect, .(50, 52, 62, 255));

			let fillH = trackH * progress;
			if (fillH > 0)
			{
				let fillRect = RectangleF(trackX, trackBottom - fillH, trackHeight, fillH);
				if (fillDrawable != null)
					fillDrawable.Draw(ctx, fillRect);
				else
					ctx.VG.FillRect(fillRect, .(80, 150, 240, 255));
			}

			let thumbY = trackBottom - trackH * progress;
			let thumbRect = RectangleF(Width * 0.5f - thumbHalf, thumbY - thumbHalf, thumbSize, thumbSize);
			if (thumbDrawable != null)
				thumbDrawable.Draw(ctx, thumbRect);
			else
				ctx.VG.FillCircle(.(Width * 0.5f, thumbY), thumbHalf, .(220, 220, 230, 255));
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Button == .Left)
		{
			mDragging = true;
			Context?.FocusManager.SetCapture(this);
			UpdateValueFromMouse(e.X, e.Y);
			OnDragStarted(this);
			e.Handled = true;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button == .Left && mDragging)
		{
			mDragging = false;
			Context?.FocusManager.ReleaseCapture();
			OnDragEnded(this);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
		{
			UpdateValueFromMouse(e.X, e.Y);
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		let range = mMax - mMin;
		let smallStep = (mStep > 0) ? mStep : range * 0.05f;

		switch (e.Key)
		{
		case .Right, .Up:    Value = mValue + smallStep; e.Handled = true;
		case .Left, .Down:   Value = mValue - smallStep; e.Handled = true;
		case .Home:          Value = mMin; e.Handled = true;
		case .End:           Value = mMax; e.Handled = true;
		default:
		}
	}

	private void UpdateValueFromMouse(float localX, float localY)
	{
		let thumbSize = ResolveStyleFloat(.ThumbSize, 16);
		let thumbHalf = thumbSize * 0.5f;

		float progress;
		if (Orientation == .Horizontal)
		{
			let trackW = Width - thumbSize;
			progress = (trackW > 0) ? (localX - thumbHalf) / trackW : 0;
		}
		else
		{
			let trackH = Height - thumbSize;
			progress = (trackH > 0) ? 1.0f - (localY - thumbHalf) / trackH : 0;
		}

		Value = mMin + (mMax - mMin) * Math.Clamp(progress, 0, 1);
	}

	private float SnapToStep(float value)
	{
		if (mStep <= 0) return value;
		return mMin + Math.Round((value - mMin) / mStep) * mStep;
	}
}
