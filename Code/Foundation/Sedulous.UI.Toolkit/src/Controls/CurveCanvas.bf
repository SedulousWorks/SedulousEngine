namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Interactive curve editor canvas. Renders Hermite-interpolated keypoints
/// over a [0,1] time axis and a value axis (auto-fit or explicit). Model-
/// agnostic: callers push keys via SetKeys and listen to OnKey* events to
/// project mutations back to their domain type (particle curves, animation
/// easing, audio envelopes, tone-mapping LUTs - anything keyframe-based).
///
/// v1 interactions:
///   - Left click empty space      -> add a key at the clicked (t, v)
///   - Left click on key           -> select; drag moves the key
///   - Right click on key          -> delete
///   - No tangent handle editing   -> tangents stay at the values pushed via
///                                    SetKeys; default to zero for new keys
public class CurveCanvas : View
{
	/// One keypoint in the canvas's internal representation. Times stay in
	/// [0, 1]; values are in user space. Tangents are slope (dy/dt) at the
	/// key - canvas does not edit them in v1 but renders the resulting
	/// Hermite curve faithfully.
	public struct Key
	{
		public float Time;
		public float Value;
		public float TangentIn;
		public float TangentOut;

		public this(float time, float value, float tangentIn = 0, float tangentOut = 0)
		{
			Time = time;
			Value = value;
			TangentIn = tangentIn;
			TangentOut = tangentOut;
		}
	}

	private List<Key> mKeys = new .() ~ delete _;
	private int32 mSelectedIndex = -1;
	private int32 mDraggingIndex = -1;
	private bool mInGesture;

	/// Per-curve maximum keypoint count. Defaults to the particle limit.
	public int32 MaxKeys = 8;

	/// When true, ValueMin / ValueMax are derived from the current keys
	/// (with a small margin). When false, the explicit ValueMin/ValueMax
	/// are used. Callers that know the natural domain (e.g. alpha curves
	/// are always [0,1]) should pin the range.
	public bool AutoFitValueRange = true;

	public float ValueMin = 0;
	public float ValueMax = 1;

	/// Curve stroke color. Wrappers can tint per-channel (red for X, green
	/// for Y, etc).
	public Color CurveColor = .(180, 200, 255, 255);

	/// Fired when an edit gesture starts (mouse-down on a key, or click-add).
	public Event<delegate void()> OnEditBegin ~ _.Dispose();

	/// Fired when an edit gesture commits (mouse-up or escape).
	public Event<delegate void()> OnEditEnd ~ _.Dispose();

	/// Fired whenever an existing key was repositioned. Payload: index.
	public Event<delegate void(int32)> OnKeyChanged ~ _.Dispose();

	/// Fired after a new key was inserted at the given index.
	public Event<delegate void(int32)> OnKeyAdded ~ _.Dispose();

	/// Fired after an existing key was deleted; payload is the *old* index
	/// (before removal) so callers can mirror the removal in their model.
	public Event<delegate void(int32)> OnKeyRemoved ~ _.Dispose();

	public int32 KeyCount => (int32)mKeys.Count;
	public int32 SelectedIndex => mSelectedIndex;

	public Key GetKey(int32 i) => mKeys[i];

	/// Replace all keys without firing events. Used by editors to push the
	/// model state into the canvas after binding.
	public void SetKeys(Span<Key> keys)
	{
		mKeys.Clear();
		for (let k in keys)
			mKeys.Add(k);
		mSelectedIndex = -1;
		mDraggingIndex = -1;
		Invalidate();
	}

	// === Hermite evaluation (matches ParticleCurveFloat.Evaluate) ===

	private float Evaluate(float t)
	{
		if (mKeys.Count == 0) return 0;
		if (mKeys.Count == 1) return mKeys[0].Value;

		if (t <= mKeys[0].Time) return mKeys[0].Value;
		if (t >= mKeys[mKeys.Count - 1].Time) return mKeys[mKeys.Count - 1].Value;

		for (int32 i = 0; i < mKeys.Count - 1; i++)
		{
			let a = mKeys[i];
			let b = mKeys[i + 1];
			if (t >= a.Time && t <= b.Time)
			{
				let seg = b.Time - a.Time;
				if (seg < 0.0001f) return a.Value;
				let lt = (t - a.Time) / seg;
				let lt2 = lt * lt;
				let lt3 = lt2 * lt;
				return (2 * lt3 - 3 * lt2 + 1) * a.Value
					+ (lt3 - 2 * lt2 + lt) * (a.TangentOut * seg)
					+ (-2 * lt3 + 3 * lt2) * b.Value
					+ (lt3 - lt2) * (b.TangentIn * seg);
			}
		}
		return mKeys[mKeys.Count - 1].Value;
	}

	// === Auto-fit value range ===

	private void UpdateAutoFit()
	{
		if (!AutoFitValueRange || mKeys.Count == 0) return;
		float lo = float.MaxValue, hi = float.MinValue;
		for (let k in mKeys)
		{
			if (k.Value < lo) lo = k.Value;
			if (k.Value > hi) hi = k.Value;
		}
		if (lo == hi)
		{
			ValueMin = lo - 1;
			ValueMax = hi + 1;
		}
		else
		{
			let margin = (hi - lo) * 0.1f;
			ValueMin = lo - margin;
			ValueMax = hi + margin;
		}
	}

	// === Coordinate transforms ===

	private float TimeToX(float t) => t * Width;
	private float ValueToY(float v)
	{
		let denom = (ValueMax - ValueMin);
		if (denom < 0.0001f) return Height * 0.5f;
		return Height * (1.0f - (v - ValueMin) / denom);
	}

	private float XToTime(float x) => Math.Clamp(x / Width, 0, 1);
	private float YToValue(float y)
	{
		let r = Math.Clamp(y / Height, 0, 1);
		return ValueMax - r * (ValueMax - ValueMin);
	}

	// === Hit testing ===

	private const float KeyHitRadius = 8;
	private const float KeyDrawRadius = 4;

	private int32 KeyAt(float x, float y)
	{
		UpdateAutoFit();
		for (int32 i = 0; i < mKeys.Count; i++)
		{
			let kx = TimeToX(mKeys[i].Time);
			let ky = ValueToY(mKeys[i].Value);
			let dx = x - kx;
			let dy = y - ky;
			if (dx * dx + dy * dy <= KeyHitRadius * KeyHitRadius)
				return i;
		}
		return -1;
	}

	// === Mouse ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left)
		{
			let hit = KeyAt(e.X, e.Y);
			if (hit >= 0)
			{
				mSelectedIndex = hit;
				mDraggingIndex = hit;
				BeginGesture();
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				Invalidate();
				return;
			}

			// Empty space -> add key (respect MaxKeys cap).
			if (mKeys.Count < MaxKeys)
			{
				let t = XToTime(e.X);
				let v = YToValue(e.Y);
				let newIndex = InsertSorted(.(t, v));
				mSelectedIndex = newIndex;
				mDraggingIndex = newIndex;
				BeginGesture();
				OnKeyAdded(newIndex);
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				Invalidate();
			}
		}
		else if (e.Button == .Right)
		{
			let hit = KeyAt(e.X, e.Y);
			if (hit >= 0)
			{
				let oldIdx = hit;
				mKeys.RemoveAt(hit);
				if (mSelectedIndex == hit) mSelectedIndex = -1;
				else if (mSelectedIndex > hit) mSelectedIndex--;
				BeginGesture();
				OnKeyRemoved(oldIdx);
				EndGesture();
				e.Handled = true;
				Invalidate();
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDraggingIndex < 0 || mDraggingIndex >= mKeys.Count) return;

		let newTime = XToTime(e.X);
		let newValue = YToValue(e.Y);

		// Update key in place; preserve tangents.
		var k = mKeys[mDraggingIndex];
		k.Time = newTime;
		k.Value = newValue;
		mKeys[mDraggingIndex] = k;

		// Re-sort by time. Track moved index across the sort so selection
		// stays on the same logical key.
		let movedKey = mKeys[mDraggingIndex];
		mKeys.RemoveAt(mDraggingIndex);
		let insertIdx = FindInsertIndex(movedKey.Time);
		mKeys.Insert(insertIdx, movedKey);
		mDraggingIndex = (int32)insertIdx;
		mSelectedIndex = mDraggingIndex;

		OnKeyChanged(mDraggingIndex);
		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDraggingIndex >= 0)
		{
			mDraggingIndex = -1;
			Context?.FocusManager.ReleaseCapture();
			EndGesture();
			e.Handled = true;
		}
	}

	// === Gesture bookkeeping ===

	private void BeginGesture()
	{
		if (!mInGesture)
		{
			mInGesture = true;
			OnEditBegin();
		}
	}

	private void EndGesture()
	{
		if (mInGesture)
		{
			mInGesture = false;
			OnEditEnd();
		}
	}

	// === Insertion in time-sorted order ===

	private int32 InsertSorted(Key k)
	{
		let idx = FindInsertIndex(k.Time);
		mKeys.Insert(idx, k);
		return (int32)idx;
	}

	private int FindInsertIndex(float time)
	{
		for (int i = 0; i < mKeys.Count; i++)
		{
			if (mKeys[i].Time > time)
				return i;
		}
		return mKeys.Count;
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		UpdateAutoFit();

		// Background.
		ctx.VG.FillRect(.(0, 0, Width, Height), .(28, 28, 33, 255));

		// Vertical grid: t = 0, 0.25, 0.5, 0.75, 1.
		let gridColor = Color(50, 50, 58, 255);
		for (int i = 0; i <= 4; i++)
		{
			let x = (i / 4.0f) * Width;
			ctx.VG.FillRect(.(x, 0, 1, Height), gridColor);
		}
		// Horizontal grid: top, middle, bottom.
		ctx.VG.FillRect(.(0, 0, Width, 1), gridColor);
		ctx.VG.FillRect(.(0, Height * 0.5f, Width, 1), gridColor);
		ctx.VG.FillRect(.(0, Height - 1, Width, 1), gridColor);

		// Curve polyline.
		if (mKeys.Count > 0)
		{
			const int32 SAMPLES = 128;
			ctx.VG.BeginPath();
			for (int32 i = 0; i <= SAMPLES; i++)
			{
				let t = i / (float)SAMPLES;
				let v = Evaluate(t);
				let x = TimeToX(t);
				let y = ValueToY(v);
				if (i == 0) ctx.VG.MoveTo(x, y);
				else ctx.VG.LineTo(x, y);
			}
			ctx.VG.Stroke(CurveColor, 1.5f);
		}

		// Keypoints.
		for (int32 i = 0; i < mKeys.Count; i++)
		{
			let k = mKeys[i];
			let cx = TimeToX(k.Time);
			let cy = ValueToY(k.Value);
			let isSel = (i == mSelectedIndex);
			ctx.VG.FillCircle(.(cx, cy), KeyDrawRadius, isSel ? .(255, 220, 100, 255) : CurveColor);
			if (isSel)
			{
				// Hollow ring outside.
				ctx.VG.BeginPath();
				ctx.VG.MoveTo(cx + KeyDrawRadius + 2, cy);
				for (int32 a = 1; a <= 32; a++)
				{
					let theta = (a / 32.0f) * 2.0f * Math.PI_f;
					ctx.VG.LineTo(cx + (KeyDrawRadius + 2) * Math.Cos(theta),
								  cy + (KeyDrawRadius + 2) * Math.Sin(theta));
				}
				ctx.VG.Stroke(.(255, 220, 100, 255), 1.5f);
			}
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Prefer a reasonable canvas size; let the parent constrain.
		MeasuredSize = .(
			constraints.ConstrainWidth(200),
			constraints.ConstrainHeight(120));
	}
}
