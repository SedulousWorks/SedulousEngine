namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Value slider with track, fill, and draggable thumb.
public class Slider : View
{
	private bool mDragging;

	public Property<float> Value = new .(0) ~ delete _;
	public Property<float> Min = new .(0) ~ delete _;
	public Property<float> Max = new .(1.0f) ~ delete _;
	public Property<float> Step = new .(0) ~ delete _;
	public Property<Orientation> Orientation = new .(.Horizontal) ~ delete _;

	public Event<delegate void(Slider, float)> OnValueChanged ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragStarted ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragEnded ~ _.Dispose();

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		WantsArrowKeys = true;
		Cursor = .Hand;

		Value.SetOwner(this, .Visual);
		Min.SetOwner(this, .Visual);
		Max.SetOwner(this, .Visual);
		Step.SetOwner(this, .Visual);
		Orientation.SetOwner(this);

		// Clamp and snap Value whenever it, Min, Max, or Step change.
		Value.Changed.Add(new [&] (val) => {
			let clamped = SnapToStep(Math.Clamp(val, Min.Value, Max.Value));
			if (clamped != val)
				Value.SetSilent(clamped);
			OnValueChanged(this, Value.Value);
		});

		Min.Changed.Add(new [&] (val) => { ReclampValue(); });
		Max.Changed.Add(new [&] (val) => { ReclampValue(); });
		Step.Changed.Add(new [&] (val) => {
			Step.SetSilent(Math.Max(0, val));
			ReclampValue();
		});
	}

	public this(float min, float max, float value = 0) : this()
	{
		Min.SetSilent(min);
		Max.SetSilent(max);
		Value.SetSilent(Math.Clamp(value, min, max));
	}

	private void ReclampValue()
	{
		let clamped = SnapToStep(Math.Clamp(Value.Value, Min.Value, Max.Value));
		if (clamped != Value.Value)
			Value.Value = clamped;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation.Value == .Horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth), constraints.ConstrainHeight(20));
		else
			MeasuredSize = .(constraints.ConstrainWidth(20), constraints.ConstrainHeight(constraints.MaxHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let state = GetControlState();
		let trackHeight = ResolvePartFloat("track", .Height, state, 4);
		let thumbSize = ResolvePartFloat("thumb", .Width, state, 16);
		let thumbHalf = thumbSize * 0.5f;

		let trackDrawable = ResolvePartDrawable("track", .Background, state);
		let fillDrawable = ResolvePartDrawable("fill", .Background, state);
		let thumbDrawable = ResolvePartDrawable("thumb", .Background, state);

		let progress = (Max.Value > Min.Value) ? (Value.Value - Min.Value) / (Max.Value - Min.Value) : 0;

		if (Orientation.Value == .Horizontal)
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
		let range = Max.Value - Min.Value;
		let smallStep = (Step.Value > 0) ? Step.Value : range * 0.05f;

		switch (e.Key)
		{
		case .Right, .Up:    Value.Value = Value.Value + smallStep; e.Handled = true;
		case .Left, .Down:   Value.Value = Value.Value - smallStep; e.Handled = true;
		case .Home:          Value.Value = Min.Value; e.Handled = true;
		case .End:           Value.Value = Max.Value; e.Handled = true;
		default:
		}
	}

	private void UpdateValueFromMouse(float localX, float localY)
	{
		let thumbSize = ResolvePartFloat("thumb", .Width, GetControlState(), 16);
		let thumbHalf = thumbSize * 0.5f;

		float progress;
		if (Orientation.Value == .Horizontal)
		{
			let trackW = Width - thumbSize;
			progress = (trackW > 0) ? (localX - thumbHalf) / trackW : 0;
		}
		else
		{
			let trackH = Height - thumbSize;
			progress = (trackH > 0) ? 1.0f - (localY - thumbHalf) / trackH : 0;
		}

		Value.Value = Min.Value + (Max.Value - Min.Value) * Math.Clamp(progress, 0, 1);
	}

	private float SnapToStep(float value)
	{
		if (Step.Value <= 0) return value;
		return Min.Value + Math.Round((value - Min.Value) / Step.Value) * Step.Value;
	}
}
