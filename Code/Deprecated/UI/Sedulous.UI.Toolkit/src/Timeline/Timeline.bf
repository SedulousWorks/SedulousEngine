using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A time RULER with a draggable playhead, and under it a DOPESHEET of lanes and keys.
///
/// DOMAIN AGNOSTIC. It knows a duration, a playhead, a time to pixel transform and a list of
/// lanes carrying key times. It knows nothing about clips, tracks or what is being animated, so
/// it stays headlessly testable and a consumer stays decoupled from it.
///
/// SECONDS are the only currency. A frame count is a label format and nothing else; no part of
/// the widget's arithmetic is in frames, so changing the display rate cannot move a key.
///
/// The widget NEVER mutates the lane model. A key drag is purely visual, and on release it
/// reports a delta for the host to apply, re-sort and re-select. That is what keeps the model
/// authoritative through an operation that can reorder it.
///
/// The TIME TRANSFORM is shared, not copied: the curve canvas below reads PixelsPerSecond and
/// ScrollSeconds from here, and a cache of its own would be a bug the first time a zoom arrived.
class Timeline : View
{
	private const float RulerHeight = 24.0f;
	private const float MinPixelsPerSecond = 4.0f;
	private const float MaxPixelsPerSecond = 4000.0f;
	private const float MinLabelSpacing = 48.0f;
	private const float ZoomStep = 1.15f;
	private const float KeyRadius = 4.0f;
	private const float KeyHitRadius = 6.0f;
	private const float DragEpsilon = 3.0f;
	private const float PlayheadGrabRadius = 5.0f;
	/// Pixels scrolled per wheel notch.
	private const float WheelPanPixels = 40.0f;
	/// How far past the clip's end the view may scroll, as a fraction of what is visible.
	private const float EndTailFraction = 0.15f;

	/// The width reserved on the left for lane labels. Nought when there are none.
	public float LabelColumnWidth = 0.0f;
	/// Nought labels the ruler in seconds; above nought labels it in frame numbers. DISPLAY
	/// ONLY: nothing here is measured in frames.
	public int32 DisplayFps = 0;

	public Event<delegate void(float)> OnPlayheadMoved ~ _.Dispose();
	public Event<delegate void()> OnSelectionChanged ~ _.Dispose();
	/// A key drag committed: move every selected key by this many seconds.
	public Event<delegate void(float)> OnKeysMoved ~ _.Dispose();
	/// The USER picked a lane, by clicking its label or one of its keys. Never fires for a
	/// programmatic set, so a host can follow its own selection without looping.
	public Event<delegate void(int32)> OnLaneSelected ~ _.Dispose();
	/// The zoom or scroll changed, so anything sharing this transform must re-sync.
	public Event<delegate void()> OnViewChanged ~ _.Dispose();

	private float mDuration = 1.0f;
	private float mPlayhead = 0.0f;
	private float mPixelsPerSecond = 100.0f;
	private float mScrollSeconds = 0.0f;

	private bool mDragging = false;
	private bool mPanning = false;
	private float mPanStartX = 0.0f;
	private float mPanStartScroll = 0.0f;

	/// OWNED.
	private List<DopesheetLane> mLanes = new .() ~ DeleteContainerAndItems!(_);
	/// The selection, PACKED as lane in the high half and index in the low half, so a pair is
	/// one comparable value.
	private List<uint64> mSelection = new .() ~ delete _;

	private bool mKeyDragging = false;
	private float mDragStartX = 0.0f;
	private float mDragDeltaX = 0.0f;
	private bool mBoxSelecting = false;
	private Float2 mBoxStart = .Zero;
	private Float2 mBoxEnd = .Zero;
	private int32 mSelectedLane = -1;

	// ---- The clock ------------------------------------------------------------------------------

	/// The clip's length: the ruler's extent, and what the playhead is clamped to.
	public float Duration => mDuration;

	public void SetDuration(float seconds)
	{
		mDuration = Max(seconds, 0.0f);
		// Re-clamped, because a clip that just got shorter must not leave the playhead or the
		// view stranded past its own end.
		SetPlayheadTime(mPlayhead);
		mScrollSeconds = ClampScroll(mScrollSeconds);
		Invalidate();
	}

	public float PlayheadTime => mPlayhead;

	/// Clamped into the clip. Reports only an actual move, so a host writing the same time every
	/// frame while playing does not fire an event every frame.
	public void SetPlayheadTime(float seconds)
	{
		let clamped = Clamp(seconds, 0.0f, Max(mDuration, 0.0f));
		if (clamped == mPlayhead)
			return;

		mPlayhead = clamped;
		OnPlayheadMoved(mPlayhead);
		Invalidate();
	}

	public float PixelsPerSecond => mPixelsPerSecond;

	public void SetPixelsPerSecond(float pixelsPerSecond)
	{
		mPixelsPerSecond = Clamp(pixelsPerSecond, MinPixelsPerSecond, MaxPixelsPerSecond);
		// Zooming OUT shrinks how far the view may scroll, so the offset is re-clamped after.
		mScrollSeconds = ClampScroll(mScrollSeconds);
		OnViewChanged();
		Invalidate();
	}

	public float ScrollSeconds => mScrollSeconds;

	public void SetScrollSeconds(float seconds)
	{
		mScrollSeconds = ClampScroll(seconds);
		OnViewChanged();
		Invalidate();
	}

	/// How many seconds the ruler shows at the current zoom. Nought before the first layout.
	public float VisibleSeconds
	{
		get
		{
			let span = Width - LabelColumnWidth;
			return ((span > 0.0f) && (mPixelsPerSecond > 0.0f)) ? (span / mPixelsPerSecond) : 0.0f;
		}
	}

	public float TimeToX(float t) =>
		LabelColumnWidth + ((t - mScrollSeconds) * mPixelsPerSecond);

	public float XToTime(float x) => (mPixelsPerSecond > 0.0f)
		? (mScrollSeconds + ((x - LabelColumnWidth) / mPixelsPerSecond))
		: mScrollSeconds;

	/// The ruler's label spacing, from the one, two, five times a power of ten sequence: the
	/// smallest such step at least `minLabelSpacing` pixels wide.
	///
	/// That family is chosen because its members subdivide the way people read time, and
	/// because picking the smallest one that FITS means labels never collide at any zoom.
	public static float PickTickStep(float pixelsPerSecond, float minLabelSpacing)
	{
		if ((pixelsPerSecond <= 0.0f) || (minLabelSpacing <= 0.0f))
			return 1.0f;

		let minStep = minLabelSpacing / pixelsPerSecond;
		let magnitude = Pow(10.0f, Floor(Log10(minStep)));

		for (let multiplier in float[](1.0f, 2.0f, 5.0f))
		{
			if ((multiplier * magnitude) >= minStep)
				return multiplier * magnitude;
		}

		return 10.0f * magnitude;
	}

	// ---- The lane model -------------------------------------------------------------------------

	/// Replaces the lanes. CONSUMES the list and every lane in it.
	///
	/// The selection is DROPPED, because it addresses keys by position and the positions have
	/// just been rebuilt underneath it.
	public void SetLanes(List<DopesheetLane> lanes)
	{
		ClearAndDeleteItems!(mLanes);
		for (let lane in lanes)
			mLanes.Add(lane);
		delete lanes;

		mSelection.Clear();
		if (mSelectedLane >= mLanes.Count)
			mSelectedLane = -1; // fewer lanes than before, so the pick is gone

		Invalidate();
	}

	public int LaneCount => mLanes.Count;

	/// BORROWED.
	public DopesheetLane GetLane(int index) => mLanes[index];

	/// The selected track. Minus one for none.
	public int32 SelectedLane => mSelectedLane;

	/// A programmatic set: clamps, and stays QUIET so a host driving the selection does not hear
	/// its own write back.
	public void SetSelectedLane(int32 lane)
	{
		mSelectedLane = ((lane >= 0) && (lane < mLanes.Count)) ? lane : -1;
		Invalidate();
	}

	public int SelectedCount => mSelection.Count;

	public bool IsKeySelected(uint32 lane, uint32 index) => mSelection.Contains(Pack(lane, index));

	public void ClearSelection()
	{
		if (mSelection.IsEmpty)
			return;

		mSelection.Clear();
		OnSelectionChanged();
		Invalidate();
	}

	/// Replaces the selection wholesale, which is how a host re-selects by time after applying a
	/// move that reordered the keys.
	public void SetSelection(Span<DopesheetKeyRef> keys)
	{
		mSelection.Clear();
		for (let key in keys)
			mSelection.Add(Pack(key.Lane, key.Index));

		Invalidate();
	}

	public void GetSelection(List<DopesheetKeyRef> outKeys)
	{
		for (let packed in mSelection)
			outKeys.Add(.((uint32)(packed >> 32), (uint32)(packed & 0xFFFFFFFF)));
	}

	// ---- Internals ------------------------------------------------------------------------------

	private static uint64 Pack(uint32 lane, uint32 index) => ((uint64)lane << 32) | (uint64)index;

	/// Keeps the view over the content: never before the start, and never so far past the end
	/// that the clip leaves the screen. A small TAIL past the end stays reachable so a key
	/// sitting exactly on the last frame is still grabbable.
	///
	/// Before layout only the lower bound is known, since the visible width is not yet.
	private float ClampScroll(float seconds)
	{
		let visible = VisibleSeconds;
		if (visible <= 0.0f)
			return Max(seconds, 0.0f);

		return Clamp(seconds, 0.0f, Max(mDuration + (visible * EndTailFraction) - visible, 0.0f));
	}

	private float LanesHeight()
	{
		var total = 0.0f;
		for (let lane in mLanes)
			total += lane.Height;
		return total;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(200.0f),
			constraints.ConstrainHeight(RulerHeight + LanesHeight()));
	}
}
