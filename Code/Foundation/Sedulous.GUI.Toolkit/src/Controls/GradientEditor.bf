namespace Sedulous.GUI.Toolkit;

using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Interactive color-ramp editor. Stops along a normalized [0, 1] time
/// axis carry RGBA values; the widget renders a live linearly-interpolated
/// gradient strip and lets the user add / move / delete / re-color stops
/// via direct manipulation.
///
/// Model-agnostic: callers push stops via SetStops and listen to OnStop*
/// events to project mutations back to their domain type. Reusable for
/// any color ramp - particle color-over-lifetime, terrain blends, tone-
/// mapping LUTs, material gradient inputs, post-FX color grading bands.
///
/// v1 interactions:
///   - Click on gradient strip         -> add stop at the clicked time
///                                        with the color sampled at that
///                                        point (so adds "blend in" rather
///                                        than appearing from nowhere)
///   - Click on stop marker            -> select; drag horizontally to
///                                        move its Time (clamped [0, 1])
///   - Right click on stop marker      -> delete
///   - Double click on stop marker     -> fires OnStopColorRequested(idx);
///                                        wrapping editor opens a color
///                                        picker and calls back via
///                                        UpdateStopColor.
public class GradientEditor : View
{
	/// One stop in the gradient. Time in [0, 1]; Color in HDR-allowed
	/// Vector4 (R, G, B, A).
	public struct Stop
	{
		public float Time;
		public Vector4 Color;

		public this(float time, Vector4 color)
		{
			Time = time;
			Color = color;
		}
	}

	private List<Stop> mStops = new .() ~ delete _;
	private int32 mSelectedIdx = -1;
	private int32 mDraggingIdx = -1;
	private bool mInGesture;

	/// Cap on the number of stops. Defaults to the particle limit.
	public int32 MaxStops = 8;

	/// Color used to fill the gradient strip when there are no stops.
	public Color EmptyFill = .(40, 40, 46, 255);

	/// Fired when an edit gesture starts.
	public Event<delegate void()> OnEditBegin ~ _.Dispose();

	/// Fired when an edit gesture commits.
	public Event<delegate void()> OnEditEnd ~ _.Dispose();

	/// Fired after a new stop was inserted at the given index.
	public Event<delegate void(int32)> OnStopAdded ~ _.Dispose();

	/// Fired when an existing stop's Time changed (Color edits flow through
	/// UpdateStopColor and also fire this event with the new index).
	public Event<delegate void(int32)> OnStopChanged ~ _.Dispose();

	/// Fired after an existing stop was deleted; payload is the OLD index.
	public Event<delegate void(int32)> OnStopRemoved ~ _.Dispose();

	/// Fired when the user requests to edit a stop's color (double-click).
	/// Wrapping editors should respond by opening a color picker, then
	/// calling UpdateStopColor(idx, newColor) when the user commits.
	public Event<delegate void(int32)> OnStopColorRequested ~ _.Dispose();

	public int32 StopCount => (int32)mStops.Count;
	public int32 SelectedIndex => mSelectedIdx;
	public Stop GetStop(int32 i) => mStops[i];

	/// Replace all stops. Does not fire events.
	public void SetStops(Span<Stop> stops)
	{
		mStops.Clear();
		for (let s in stops) mStops.Add(s);
		mSelectedIdx = -1;
		mDraggingIdx = -1;
		Invalidate();
	}

	/// Update a single stop's color (typically called from the color
	/// picker callback). Fires OnStopChanged.
	public void UpdateStopColor(int32 idx, Vector4 color)
	{
		if (idx < 0 || idx >= mStops.Count) return;
		var s = mStops[idx];
		s.Color = color;
		mStops[idx] = s;
		OnStopChanged(idx);
		Invalidate();
	}

	// === Sampling (linear interp between stops) ===

	private Vector4 Sample(float t)
	{
		if (mStops.Count == 0) return .(0, 0, 0, 0);
		if (mStops.Count == 1) return mStops[0].Color;
		if (t <= mStops[0].Time) return mStops[0].Color;
		if (t >= mStops[mStops.Count - 1].Time) return mStops[mStops.Count - 1].Color;

		for (int32 i = 0; i < mStops.Count - 1; i++)
		{
			let a = mStops[i];
			let b = mStops[i + 1];
			if (t >= a.Time && t <= b.Time)
			{
				let seg = b.Time - a.Time;
				if (seg < 0.0001f) return a.Color;
				let lt = (t - a.Time) / seg;
				return .(
					a.Color.X + (b.Color.X - a.Color.X) * lt,
					a.Color.Y + (b.Color.Y - a.Color.Y) * lt,
					a.Color.Z + (b.Color.Z - a.Color.Z) * lt,
					a.Color.W + (b.Color.W - a.Color.W) * lt);
			}
		}
		return mStops[mStops.Count - 1].Color;
	}

	// === Coordinate / layout ===

	private const float MarkerStripHeight = 18;
	private const float MarkerHalfWidth = 6;
	private const float MarkerHeight = 10;

	private float StripBottom => Height - MarkerStripHeight;
	private float TimeToX(float t) => t * Width;
	private float XToTime(float x) => Math.Clamp(x / Width, 0, 1);

	private bool IsOverStrip(float y) => y < StripBottom;
	private bool IsOverMarkers(float y) => y >= StripBottom;

	private int32 MarkerAt(float x, float y)
	{
		if (!IsOverMarkers(y)) return -1;
		for (int32 i = 0; i < mStops.Count; i++)
		{
			let mx = TimeToX(mStops[i].Time);
			if (Math.Abs(x - mx) <= MarkerHalfWidth + 2)
				return i;
		}
		return -1;
	}

	// === Mouse ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left)
		{
			let markerHit = MarkerAt(e.X, e.Y);
			if (markerHit >= 0)
			{
				mSelectedIdx = markerHit;
				if (e.ClickCount >= 2)
				{
					// Double-click on a marker -> request color edit.
					OnStopColorRequested(markerHit);
					e.Handled = true;
					Invalidate();
					return;
				}
				mDraggingIdx = markerHit;
				BeginGesture();
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				Invalidate();
				return;
			}

			// Click on gradient strip - add a stop at the clicked time,
			// initial color sampled from the existing gradient so the new
			// stop "blends in" rather than appearing as a hard edge.
			if (IsOverStrip(e.Y) && mStops.Count < MaxStops)
			{
				let t = XToTime(e.X);
				let initialColor = mStops.Count > 0 ? Sample(t) : Vector4(1, 1, 1, 1);
				BeginGesture();
				let idx = InsertSorted(.(t, initialColor));
				mSelectedIdx = idx;
				mDraggingIdx = idx;
				OnStopAdded(idx);
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				Invalidate();
			}
		}
		else if (e.Button == .Right)
		{
			let markerHit = MarkerAt(e.X, e.Y);
			if (markerHit >= 0)
			{
				let oldIdx = markerHit;
				BeginGesture();
				mStops.RemoveAt(markerHit);
				if (mSelectedIdx == markerHit) mSelectedIdx = -1;
				else if (mSelectedIdx > markerHit) mSelectedIdx--;
				OnStopRemoved(oldIdx);
				EndGesture();
				e.Handled = true;
				Invalidate();
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDraggingIdx < 0 || mDraggingIdx >= mStops.Count) return;
		let newTime = XToTime(e.X);
		var s = mStops[mDraggingIdx];
		s.Time = newTime;
		mStops[mDraggingIdx] = s;

		// Re-sort by time; track moved index.
		let moved = mStops[mDraggingIdx];
		mStops.RemoveAt(mDraggingIdx);
		let newIdx = InsertSorted(moved);
		mDraggingIdx = newIdx;
		mSelectedIdx = newIdx;

		OnStopChanged(newIdx);
		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDraggingIdx >= 0)
		{
			mDraggingIdx = -1;
			Context?.FocusManager.ReleaseCapture();
			EndGesture();
			e.Handled = true;
		}
	}

	private void BeginGesture()
	{
		if (!mInGesture) { mInGesture = true; OnEditBegin(); }
	}

	private void EndGesture()
	{
		if (mInGesture) { mInGesture = false; OnEditEnd(); }
	}

	private int32 InsertSorted(Stop s)
	{
		int32 idx = (int32)mStops.Count;
		for (int32 i = 0; i < mStops.Count; i++)
		{
			if (mStops[i].Time > s.Time) { idx = i; break; }
		}
		mStops.Insert(idx, s);
		return idx;
	}

	// === Drawing ===

	private static Color Vector4ToColor(Vector4 c)
	{
		// Clamp + quantize for the rendering color path.
		let r = (uint8)Math.Clamp((int32)(c.X * 255), 0, 255);
		let g = (uint8)Math.Clamp((int32)(c.Y * 255), 0, 255);
		let b = (uint8)Math.Clamp((int32)(c.Z * 255), 0, 255);
		let a = (uint8)Math.Clamp((int32)(c.W * 255), 0, 255);
		return .(r, g, b, a);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Outer background.
		ctx.VG.FillRect(.(0, 0, Width, Height), .(28, 28, 33, 255));

		let stripH = StripBottom;
		if (mStops.Count == 0)
		{
			ctx.VG.FillRect(.(0, 0, Width, stripH), EmptyFill);
		}
		else
		{
			// Sample the gradient at 1-px columns. Cheap; Width is typically
			// modest (a property grid row).
			let cols = (int32)Math.Max(Width, 1);
			for (int32 i = 0; i < cols; i++)
			{
				let t = i / (float)(cols - 1);
				let c = Vector4ToColor(Sample(t));
				ctx.VG.FillRect(.(i, 0, 1, stripH), c);
			}
		}

		// Strip border.
		ctx.VG.FillRect(.(0, 0, Width, 1), .(60, 60, 68, 255));
		ctx.VG.FillRect(.(0, stripH - 1, Width, 1), .(60, 60, 68, 255));

		// Marker strip background.
		ctx.VG.FillRect(.(0, stripH, Width, MarkerStripHeight), .(35, 35, 41, 255));

		// Markers - triangle pointing up.
		for (int32 i = 0; i < mStops.Count; i++)
		{
			let mx = TimeToX(mStops[i].Time);
			let isSel = (i == mSelectedIdx);
			let body = Vector4ToColor(mStops[i].Color);
			let stroke = isSel ? Color(255, 220, 100, 255) : Color(200, 200, 210, 255);

			// Filled triangle.
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(mx, stripH + 2);
			ctx.VG.LineTo(mx - MarkerHalfWidth, stripH + 2 + MarkerHeight);
			ctx.VG.LineTo(mx + MarkerHalfWidth, stripH + 2 + MarkerHeight);
			ctx.VG.ClosePath();
			ctx.VG.Fill(body);

			// Outline.
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(mx, stripH + 2);
			ctx.VG.LineTo(mx - MarkerHalfWidth, stripH + 2 + MarkerHeight);
			ctx.VG.LineTo(mx + MarkerHalfWidth, stripH + 2 + MarkerHeight);
			ctx.VG.ClosePath();
			ctx.VG.Stroke(stroke, isSel ? 2.0f : 1.0f);
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(
			constraints.ConstrainWidth(200),
			constraints.ConstrainHeight(60));
	}
}
