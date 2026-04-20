namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Value slider with draggable thumb. Supports horizontal/vertical,
/// min/max range, and optional step snapping.
public class Slider : View
{
	private float mValue;
	private float mMin;
	private float mMax = 1;
	private float mStep;
	private Orientation mOrientation = .Horizontal;
	private bool mDragging;

	private const float TrackHeight = 4;
	private const float ThumbSize = 14;

	public Event<delegate void(Slider, float)> OnValueChanged ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragStarted ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragEnded ~ _.Dispose();

	public float Value
	{
		get => mValue;
		set
		{
			var v = Math.Clamp(value, mMin, mMax);
			if (mStep > 0)
				v = SnapToStep(v);
			if (mValue != v)
			{
				mValue = v;
				InvalidateVisual();
				OnValueChanged(this, v);
			}
		}
	}

	public float Min
	{
		get => mMin;
		set { mMin = value; if (mMax < mMin) mMax = mMin; Value = mValue; }
	}

	public float Max
	{
		get => mMax;
		set { mMax = value; if (mMin > mMax) mMin = mMax; Value = mValue; }
	}

	public float Step
	{
		get => mStep;
		set { mStep = Math.Max(0, value); Value = mValue; }
	}

	public Orientation Orientation
	{
		get => mOrientation;
		set { mOrientation = value; InvalidateLayout(); }
	}

	public this()
	{
		IsFocusable = true;
		Cursor = .Hand;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (mOrientation == .Horizontal)
			MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(24));
		else
			MeasuredSize = .(wSpec.Resolve(24), hSpec.Resolve(0));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let ratio = (mMax > mMin) ? (mValue - mMin) / (mMax - mMin) : 0;

		let trackBg = ctx.Theme?.GetColor("Slider.Track", .(50, 52, 62, 255)) ?? .(50, 52, 62, 255);
		let fillColor = ctx.Theme?.TryGetColor("Slider.Fill") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
		let thumbColor = ctx.Theme?.GetColor("Slider.Thumb", .(220, 220, 230, 255)) ?? .(220, 220, 230, 255);
		let thumbHover = ctx.Theme?.GetColor("Slider.ThumbHover", .(240, 240, 250, 255)) ?? .(240, 240, 250, 255);

		if (mOrientation == .Horizontal)
			DrawHorizontal(ctx, ratio, trackBg, fillColor, thumbColor, thumbHover);
		else
			DrawVertical(ctx, ratio, trackBg, fillColor, thumbColor, thumbHover);
	}

	private void DrawHorizontal(UIDrawContext ctx, float ratio, Color trackBg, Color fillColor, Color thumbNormal, Color thumbHover)
	{
		let thumbHalf = ThumbSize * 0.5f;
		let trackStart = thumbHalf;
		let trackEnd = Width - thumbHalf;
		let trackW = trackEnd - trackStart;
		let trackY = (Height - TrackHeight) * 0.5f;
		let state = GetControlState();

		// Track.
		let trackBounds = RectangleF(trackStart, trackY, trackW, TrackHeight);
		if (!ctx.TryDrawDrawable("Slider.Track", trackBounds, state))
			ctx.VG.FillRoundedRect(trackBounds, TrackHeight * 0.5f, trackBg);

		// Fill.
		let fillW = trackW * ratio;
		if (fillW > 0)
		{
			let fillBounds = RectangleF(trackStart, trackY, fillW, TrackHeight);
			if (!ctx.TryDrawDrawable("Slider.Fill", fillBounds, state))
				ctx.VG.FillRoundedRect(fillBounds, TrackHeight * 0.5f, fillColor);
		}

		// Thumb.
		let thumbX = trackStart + trackW * ratio;
		let thumbY = Height * 0.5f;
		let thumbBounds = RectangleF(thumbX - thumbHalf, thumbY - thumbHalf, ThumbSize, ThumbSize);
		if (!ctx.TryDrawDrawable("Slider.Thumb", thumbBounds, state))
		{
			let tc = (IsHovered || mDragging) ? thumbHover : thumbNormal;
			ctx.VG.FillCircle(.(thumbX, thumbY), thumbHalf, tc);
		}

		// Focus ring.
		if (IsFocused)
			ctx.VG.StrokeCircle(.(thumbX, thumbY), thumbHalf + 2,
				ctx.Theme?.GetColor("Focus.Ring", .(100, 160, 255, 180)) ?? .(100, 160, 255, 180), 2);
	}

	private void DrawVertical(UIDrawContext ctx, float ratio, Color trackBg, Color fillColor, Color thumbNormal, Color thumbHover)
	{
		let thumbHalf = ThumbSize * 0.5f;
		let trackStart = thumbHalf;
		let trackEnd = Height - thumbHalf;
		let trackLen = trackEnd - trackStart;
		let trackX = (Width - TrackHeight) * 0.5f;
		let state = GetControlState();

		// Track.
		let trackBounds = RectangleF(trackX, trackStart, TrackHeight, trackLen);
		if (!ctx.TryDrawDrawable("Slider.Track", trackBounds, state))
			ctx.VG.FillRoundedRect(trackBounds, TrackHeight * 0.5f, trackBg);

		// Fill (bottom-up).
		let fillH = trackLen * ratio;
		if (fillH > 0)
		{
			let fillBounds = RectangleF(trackX, trackEnd - fillH, TrackHeight, fillH);
			if (!ctx.TryDrawDrawable("Slider.Fill", fillBounds, state))
				ctx.VG.FillRoundedRect(fillBounds, TrackHeight * 0.5f, fillColor);
		}

		// Thumb.
		let thumbX = Width * 0.5f;
		let thumbY = trackEnd - trackLen * ratio;
		let thumbBounds = RectangleF(thumbX - thumbHalf, thumbY - thumbHalf, ThumbSize, ThumbSize);
		if (!ctx.TryDrawDrawable("Slider.Thumb", thumbBounds, state))
		{
			let tc = (IsHovered || mDragging) ? thumbHover : thumbNormal;
			ctx.VG.FillCircle(.(thumbX, thumbY), thumbHalf, tc);
		}

		if (IsFocused)
			ctx.VG.StrokeCircle(.(thumbX, thumbY), thumbHalf + 2,
				ctx.Theme?.GetColor("Focus.Ring", .(100, 160, 255, 180)) ?? .(100, 160, 255, 180), 2);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;
		mDragging = true;
		Context?.FocusManager.SetCapture(this);
		OnDragStarted(this);
		UpdateValueFromMouse(e.X, e.Y);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
			UpdateValueFromMouse(e.X, e.Y);
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button != .Left || !mDragging) return;
		mDragging = false;
		Context?.FocusManager.ReleaseCapture();
		OnDragEnded(this);
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		let stepAmt = mStep > 0 ? mStep : (mMax - mMin) * 0.05f;

		if (mOrientation == .Horizontal)
		{
			if (e.Key == .Right) { Value = mValue + stepAmt; e.Handled = true; }
			else if (e.Key == .Left) { Value = mValue - stepAmt; e.Handled = true; }
		}
		else
		{
			if (e.Key == .Up) { Value = mValue + stepAmt; e.Handled = true; }
			else if (e.Key == .Down) { Value = mValue - stepAmt; e.Handled = true; }
		}

		if (e.Key == .Home) { Value = mMin; e.Handled = true; }
		else if (e.Key == .End) { Value = mMax; e.Handled = true; }
	}

	private void UpdateValueFromMouse(float localX, float localY)
	{
		let thumbHalf = ThumbSize * 0.5f;
		float ratio;

		if (mOrientation == .Horizontal)
		{
			let trackW = Width - ThumbSize;
			ratio = (trackW > 0) ? (localX - thumbHalf) / trackW : 0;
		}
		else
		{
			let trackH = Height - ThumbSize;
			ratio = (trackH > 0) ? 1.0f - (localY - thumbHalf) / trackH : 0;
		}

		ratio = Math.Clamp(ratio, 0, 1);
		Value = mMin + ratio * (mMax - mMin);
	}

	private float SnapToStep(float value)
	{
		if (mStep <= 0) return value;
		let snapped = mMin + Math.Round((value - mMin) / mStep) * mStep;
		return Math.Clamp(snapped, mMin, mMax);
	}
}
