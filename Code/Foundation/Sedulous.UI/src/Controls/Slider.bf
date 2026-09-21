using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A value picked by dragging a thumb along a track.
///
/// The Min and Max PROPERTIES shadow Core's free Min and Max functions inside this class, so
/// the clamping is spelled as Clamp, which is the same thing and reads better anyway. Beef's
/// free functions live in an anonymous static block and have no name to qualify with.
class Slider : View
{
	public Property<float> Value = new .(0.0f) ~ delete _;
	public Property<float> Min = new .(0.0f) ~ delete _;
	public Property<float> Max = new .(1.0f) ~ delete _;
	/// Zero means continuous.
	public Property<float> Step = new .(0.0f) ~ delete _;
	public Property<Orientation> Orientation = new .(.Horizontal) ~ delete _;

	public Event<delegate void(Slider, float)> OnValueChanged ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragStarted ~ _.Dispose();
	public Event<delegate void(Slider)> OnDragEnded ~ _.Dispose();

	private bool mDragging = false;

	public this()
	{
		Init();
	}

	public this(float minValue, float maxValue, float value = 0.0f)
	{
		Init();
		Min.SetSilent(minValue);
		Max.SetSilent(maxValue);
		Value.SetSilent(Clamp(value, minValue, maxValue));
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if (e.Button == .Left)
		{
			mDragging = true;
			// Captured, so the drag keeps arriving here once the pointer leaves the track.
			if (Context != null)
				Context.GetFocusManager().SetCapture(this);

			UpdateValueFromMouse(e.X, e.Y);
			OnDragStarted(this);
			e.Handled = true;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if ((e.Button == .Left) && mDragging)
		{
			mDragging = false;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();

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
		if (!IsEffectivelyEnabled())
			return;

		// With no step, a key moves a twentieth of the range: a sensible nudge whatever the
		// scale, rather than a fixed amount that is huge on one slider and invisible on another.
		let range = Max.Value - Min.Value;
		let smallStep = (Step.Value > 0) ? Step.Value : range * 0.05f;

		switch (e.Key)
		{
		case .Right, .Up:
			Value.Value = Value.Value + smallStep;
			e.Handled = true;
		case .Left, .Down:
			Value.Value = Value.Value - smallStep;
			e.Handled = true;
		case .Home:
			Value.Value = Min.Value;
			e.Handled = true;
		case .End:
			Value.Value = Max.Value;
			e.Handled = true;
		default:
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation.Value == .Horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(160.0f)),
				constraints.ConstrainHeight(20.0f));
		else
			MeasuredSize = .(constraints.ConstrainWidth(20.0f),
				constraints.ConstrainHeight(constraints.BoundedMaxHeight(160.0f)));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let state = GetControlState();
		let trackThickness = ResolvePartFloat("track", .Height, state, 4.0f);
		let thumbSize = ResolvePartFloat("thumb", .Width, state, 16.0f);
		let thumbHalf = thumbSize * 0.5f;

		let trackDrawable = ResolvePartDrawable("track", .Background, state);
		let fillDrawable = ResolvePartDrawable("fill", .Background, state);
		let thumbDrawable = ResolvePartDrawable("thumb", .Background, state);

		let progress = (Max.Value > Min.Value)
			? (Value.Value - Min.Value) / (Max.Value - Min.Value)
			: 0.0f;

		let trackColor = Color(50 / 255.0f, 52 / 255.0f, 62 / 255.0f, 1.0f);
		let fillColor = Color(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f);
		let thumbColor = Color(220 / 255.0f, 220 / 255.0f, 230 / 255.0f, 1.0f);

		if (Orientation.Value == .Horizontal)
		{
			// The track is inset by half a thumb at each end, so the thumb's own travel stays
			// inside the control rather than hanging off the ends.
			let trackY = (Height - trackThickness) * 0.5f;
			let trackLeft = thumbHalf;
			let trackWidth = (Width - thumbHalf) - trackLeft;

			DrawPart(ctx, trackDrawable, .(trackLeft, trackY, trackWidth, trackThickness), trackColor);

			let fillWidth = trackWidth * progress;
			if (fillWidth > 0)
				DrawPart(ctx, fillDrawable, .(trackLeft, trackY, fillWidth, trackThickness), fillColor);

			let thumbX = trackLeft + trackWidth * progress;
			if (thumbDrawable != null)
				thumbDrawable.Draw(ctx, .(thumbX - thumbHalf, Height * 0.5f - thumbHalf, thumbSize, thumbSize));
			else
				ctx.VG.FillCircle(.(thumbX, Height * 0.5f), thumbHalf, thumbColor);
		}
		else
		{
			let trackX = (Width - trackThickness) * 0.5f;
			let trackTop = thumbHalf;
			let trackHeight = (Height - thumbHalf) - trackTop;

			DrawPart(ctx, trackDrawable, .(trackX, trackTop, trackThickness, trackHeight), trackColor);

			// Vertical runs bottom to top: the fill grows UP from the low end, which is where a
			// vertical slider's minimum sits.
			let fillHeight = trackHeight * progress;
			if (fillHeight > 0)
				DrawPart(ctx, fillDrawable,
					.(trackX, (trackTop + trackHeight) - fillHeight, trackThickness, fillHeight), fillColor);

			let thumbY = (trackTop + trackHeight) - trackHeight * progress;
			if (thumbDrawable != null)
				thumbDrawable.Draw(ctx, .(Width * 0.5f - thumbHalf, thumbY - thumbHalf, thumbSize, thumbSize));
			else
				ctx.VG.FillCircle(.(Width * 0.5f, thumbY), thumbHalf, thumbColor);
		}
	}

	private static void DrawPart(UIDrawContext ctx, Drawable drawable, Rectangle rect, Color fallback)
	{
		if (drawable != null)
			drawable.Draw(ctx, rect);
		else
			ctx.VG.FillRect(rect, fallback);
	}

	private void UpdateValueFromMouse(float localX, float localY)
	{
		let thumbSize = ResolvePartFloat("thumb", .Width, GetControlState(), 16.0f);
		let thumbHalf = thumbSize * 0.5f;

		// Measured against the THUMB's travel, not the control's width: the pointer lands on
		// the thumb's centre, which can only reach from one half-thumb to the other.
		var progress = 0.0f;
		if (Orientation.Value == .Horizontal)
		{
			let trackWidth = Width - thumbSize;
			progress = (trackWidth > 0) ? (localX - thumbHalf) / trackWidth : 0.0f;
		}
		else
		{
			let trackHeight = Height - thumbSize;
			progress = (trackHeight > 0) ? 1.0f - (localY - thumbHalf) / trackHeight : 0.0f;
		}

		Value.Value = Min.Value + (Max.Value - Min.Value) * Clamp(progress, 0.0f, 1.0f);
	}

	private float SnapToStep(float value)
	{
		if (Step.Value <= 0)
			return value;

		// Snapped relative to Min, not to zero, so a range starting at 3 with a step of 5 lands
		// on 3, 8, 13 rather than 5, 10, 15.
		return Min.Value + Round((value - Min.Value) / Step.Value) * Step.Value;
	}

	private void ReclampValue()
	{
		let clamped = SnapToStep(Clamp(Value.Value, Min.Value, Max.Value));
		if (clamped != Value.Value)
			Value.Value = clamped;
	}

	private void Init()
	{
		IsFocusable = true;
		IsTabStop = true;
		// The arrows drive the value, so focus must not hand them to the focus manager.
		WantsArrowKeys = true;
		Cursor = .Hand;

		Value.SetOwner(this, .Visual);
		Min.SetOwner(this, .Visual);
		Max.SetOwner(this, .Visual);
		Step.SetOwner(this, .Visual);
		Orientation.SetOwner(this);

		// Clamped and snapped on the way in, written back with SetSilent: a plain assignment
		// from inside a Changed handler is swallowed by the property's reentrancy guard, and
		// would leave the out of range value in place.
		Value.Changed.Add(new (val) =>
			{
				let clamped = SnapToStep(Clamp(val, Min.Value, Max.Value));
				if (clamped != val)
					Value.SetSilent(clamped);

				OnValueChanged(this, Value.Value);
			});

		// Moving an end, or changing the step, can strand the value outside the range.
		Min.Changed.Add(new (val) => { ReclampValue(); });
		Max.Changed.Add(new (val) => { ReclampValue(); });
		Step.Changed.Add(new (val) =>
			{
				Step.SetSilent((val < 0.0f) ? 0.0f : val);
				ReclampValue();
			});
	}
}
