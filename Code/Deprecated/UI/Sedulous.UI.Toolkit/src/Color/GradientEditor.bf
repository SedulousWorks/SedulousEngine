using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A colour ramp edited by DIRECT MANIPULATION: click the strip to add a stop, drag its marker
/// to move it, double click to open a picker for it, right click to delete it.
///
/// The stops are kept SORTED by time at all times, which is what lets sampling be a single
/// forward scan and lets a marker dragged past its neighbour simply change places with it. A
/// drag therefore has to track its stop by INDEX through each re-sort, not hold a pointer.
///
/// The editor does not own a colour picker. It reports OnStopColorRequested and the host opens
/// whatever dialog it likes, then calls UpdateStopColor. That keeps the ramp usable with the
/// plain picker, the HDR one, or an eyedropper.
class GradientEditor : View
{
	private const float MarkerStripHeight = 18.0f;
	private const float MarkerHalfWidth = 6.0f;
	private const float MarkerHeight = 10.0f;

	/// The ceiling on stops. Defaults to what the particle system allows.
	public int32 MaxStops = 8;

	/// What the strip shows with no stops at all.
	public Color EmptyFill = Color.Rgb(40, 40, 46);

	public Event<delegate void()> OnEditBegin ~ _.Dispose();
	public Event<delegate void()> OnEditEnd ~ _.Dispose();
	public Event<delegate void(int32)> OnStopAdded ~ _.Dispose();
	public Event<delegate void(int32)> OnStopChanged ~ _.Dispose();
	public Event<delegate void(int32)> OnStopRemoved ~ _.Dispose();
	/// The host opens a colour dialog and calls UpdateStopColor with the result.
	public Event<delegate void(int32)> OnStopColorRequested ~ _.Dispose();

	private List<GradientStop> mStops = new .() ~ delete _;
	private int32 mSelectedIndex = -1;
	private int32 mDraggingIndex = -1;
	private bool mInGesture = false;

	public int32 StopCount => (int32)mStops.Count;

	public int32 SelectedIndex => mSelectedIndex;

	public GradientStop GetStop(int32 index) => mStops[index];

	/// Replaces every stop. Fires NOTHING, because this is the host loading a value rather than
	/// the user editing one.
	public void SetStops(Span<GradientStop> stops)
	{
		mStops.Clear();
		for (let stop in stops)
			mStops.Add(stop);

		mSelectedIndex = -1;
		mDraggingIndex = -1;
		Invalidate();
	}

	/// What the host calls after its colour dialog closes.
	public void UpdateStopColor(int32 index, Float4 color)
	{
		if ((index < 0) || (index >= mStops.Count))
			return;

		mStops[index].Color = color;
		OnStopChanged(index);
		Invalidate();
	}

	/// The ramp at a time, linearly between the two stops around it and flat outside the ends.
	public Float4 Sample(float t)
	{
		if (mStops.IsEmpty)
			return .(0, 0, 0, 0);

		let last = mStops.Count - 1;
		if ((mStops.Count == 1) || (t <= mStops[0].Time))
			return mStops[0].Color;
		if (t >= mStops[last].Time)
			return mStops[last].Color;

		for (int i = 0; i < last; i++)
		{
			let a = mStops[i];
			let b = mStops[i + 1];
			if ((t < a.Time) || (t > b.Time))
				continue;

			// Two stops at the same time have no span to interpolate across, so the earlier
			// one wins outright rather than dividing by nothing.
			let span = b.Time - a.Time;
			if (span < 0.0001f)
				return a.Color;

			let k = (t - a.Time) / span;
			return .(a.Color.X + ((b.Color.X - a.Color.X) * k),
				a.Color.Y + ((b.Color.Y - a.Color.Y) * k),
				a.Color.Z + ((b.Color.Z - a.Color.Z) * k),
				a.Color.W + ((b.Color.W - a.Color.W) * k));
		}

		return mStops[last].Color;
	}

	// ---- Input ----------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left)
			OnLeftDown(e);
		else if (e.Button == .Right)
			OnRightDown(e);
	}

	private void OnLeftDown(MouseEventArgs e)
	{
		let hit = MarkerAt(e.X, e.Y);
		if (hit >= 0)
		{
			mSelectedIndex = hit;
			Invalidate();

			// A double click asks for the colour dialog rather than starting a drag, so the
			// second press does not nudge the stop it just opened.
			if (e.ClickCount >= 2)
			{
				OnStopColorRequested(hit);
				e.Handled = true;
				return;
			}

			mDraggingIndex = hit;
			BeginGesture();
			Capture();
			e.Handled = true;
			return;
		}

		if (!IsOverStrip(e.Y) || (mStops.Count >= MaxStops))
			return;

		// A new stop takes the colour the ramp ALREADY has at that point, so adding one changes
		// nothing until it is moved. Adding a stop should not repaint the gradient.
		let time = XToTime(e.X);
		let color = mStops.IsEmpty ? Float4(1, 1, 1, 1) : Sample(time);

		BeginGesture();
		let index = InsertSorted(.(time, color));
		mSelectedIndex = index;
		mDraggingIndex = index;
		OnStopAdded(index);
		Capture();
		e.Handled = true;
		Invalidate();
	}

	private void OnRightDown(MouseEventArgs e)
	{
		let hit = MarkerAt(e.X, e.Y);
		if (hit < 0)
			return;

		BeginGesture();
		mStops.RemoveAt(hit);

		// The selection is an index into a list that just shifted.
		if (mSelectedIndex == hit)
			mSelectedIndex = -1;
		else if (mSelectedIndex > hit)
			mSelectedIndex--;

		OnStopRemoved(hit);
		EndGesture();
		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if ((mDraggingIndex < 0) || (mDraggingIndex >= mStops.Count))
			return;

		// Removed and re-inserted rather than moved in place, so dragging a stop past its
		// neighbour reorders the list and the two simply swap.
		var moved = mStops[mDraggingIndex];
		moved.Time = XToTime(e.X);
		mStops.RemoveAt(mDraggingIndex);

		let index = InsertSorted(moved);
		mDraggingIndex = index;
		mSelectedIndex = index;

		OnStopChanged(index);
		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDraggingIndex < 0)
			return;

		mDraggingIndex = -1;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();

		EndGesture();
		e.Handled = true;
	}

	// ---- Drawing --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let canvas = ResolveStyleColor(.Background, Color.Rgb(28, 28, 33));
		ctx.VG.FillRect(Rectangle(0, 0, Width, Height), canvas);

		let stripBottom = StripBottom;
		DrawRamp(ctx, stripBottom);

		let border = ResolveStyleColor(.BorderColor, Color.Rgb(60, 60, 68));
		ctx.VG.FillRect(.(0, 0, Width, 1), border);
		ctx.VG.FillRect(.(0, stripBottom - 1, Width, 1), border);

		// The marker gutter is a step up from the canvas, so the triangles sit on a band rather
		// than floating.
		ctx.VG.FillRect(.(0, stripBottom, Width, MarkerStripHeight),
			Palette.Lighten(canvas, 0.05f));

		DrawMarkers(ctx, stripBottom);
	}

	/// Sampled one pixel column at a time. The ramp is arbitrary, with any number of stops, so
	/// there is no gradient primitive that could express it.
	private void DrawRamp(UIDrawContext ctx, float stripBottom)
	{
		if (mStops.IsEmpty)
		{
			ctx.VG.FillRect(.(0, 0, Width, stripBottom), EmptyFill);
			return;
		}

		let columns = (int32)Max(Width, 1.0f);
		for (int32 i = 0; i < columns; i++)
		{
			let t = (float)i / (columns - 1);
			ctx.VG.FillRect(.((float)i, 0, 1, stripBottom), ToColor(Sample(t)));
		}
	}

	private void DrawMarkers(UIDrawContext ctx, float stripBottom)
	{
		let dim = ResolveStyleColor(.TextDimColor, Color.Rgb(200, 200, 210));

		for (int32 i = 0; i < mStops.Count; i++)
		{
			let x = TimeToX(mStops[i].Time);
			let isSelected = i == mSelectedIndex;
			let top = stripBottom + 2;
			let bottom = top + MarkerHeight;

			// FILLED with the stop's own colour, so the gutter reads as a legend for the ramp
			// above it, and outlined so a dark stop is still findable.
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(x, top);
			ctx.VG.LineTo(x - MarkerHalfWidth, bottom);
			ctx.VG.LineTo(x + MarkerHalfWidth, bottom);
			ctx.VG.ClosePath();
			ctx.VG.Fill(ToColor(mStops[i].Color));

			ctx.VG.BeginPath();
			ctx.VG.MoveTo(x, top);
			ctx.VG.LineTo(x - MarkerHalfWidth, bottom);
			ctx.VG.LineTo(x + MarkerHalfWidth, bottom);
			ctx.VG.ClosePath();
			ctx.VG.Stroke(isSelected ? Color.Rgb(255, 220, 100) : dim, isSelected ? 2.0f : 1.0f);
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(200.0f), constraints.ConstrainHeight(60.0f));
	}

	// ---- Internals ------------------------------------------------------------------------------

	private float StripBottom => Height - MarkerStripHeight;

	private float TimeToX(float t) => t * Width;

	private float XToTime(float x) => Clamp(x / Width, 0.0f, 1.0f);

	private bool IsOverStrip(float y) => y < StripBottom;

	/// Minus one when the point is over no marker, or not in the gutter at all.
	private int32 MarkerAt(float x, float y)
	{
		if (y < StripBottom)
			return -1;

		for (int32 i = 0; i < mStops.Count; i++)
		{
			// Two pixels of slack either side, because a six pixel half width is a small
			// target for a moving pointer.
			if (Abs(x - TimeToX(mStops[i].Time)) <= (MarkerHalfWidth + 2))
				return i;
		}

		return -1;
	}

	private void Capture()
	{
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
	}

	private void BeginGesture()
	{
		if (mInGesture)
			return;

		mInGesture = true;
		OnEditBegin();
	}

	private void EndGesture()
	{
		if (!mInGesture)
			return;

		mInGesture = false;
		OnEditEnd();
	}

	/// Inserts before the first stop LATER than this one, so equal times keep the order they
	/// arrived in and a stop dragged onto another does not jump past it.
	private int32 InsertSorted(GradientStop stop)
	{
		var index = (int32)mStops.Count;
		for (int32 i = 0; i < mStops.Count; i++)
		{
			if (mStops[i].Time > stop.Time)
			{
				index = i;
				break;
			}
		}

		mStops.Insert(index, stop);
		return index;
	}

	private static Color ToColor(Float4 color) =>
		.(Clamp(color.X, 0.0f, 1.0f), Clamp(color.Y, 0.0f, 1.0f), Clamp(color.Z, 0.0f, 1.0f),
			Clamp(color.W, 0.0f, 1.0f));
}
