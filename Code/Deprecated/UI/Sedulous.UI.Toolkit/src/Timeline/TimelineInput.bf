using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[Timeline]]: scrubbing, lane and key selection, box select, the visual key drag, and the pan
/// and zoom that everything sharing the transform follows.
extension Timeline
{
	public override void OnMouseDown(MouseEventArgs e)
	{
		// The middle button PANS, which is what every tool of this shape does.
		if (e.Button == .Middle)
		{
			mPanning = true;
			mPanStartX = e.X;
			mPanStartScroll = mScrollSeconds;
			Capture();
			e.Handled = true;
			return;
		}

		if (e.Button != .Left)
			return;

		if (e.X < LabelColumnWidth)
		{
			OnGutterDown(e);
			return;
		}

		Capture();
		e.Handled = true;

		// The ruler band scrubs, and so does the whole widget when there are no lanes at all,
		// since then there is nothing else the click could mean.
		if ((e.Y <= RulerHeight) || mLanes.IsEmpty)
		{
			mDragging = true;
			SetPlayheadTime(XToTime(e.X));
			return;
		}

		OnLaneAreaDown(e);
		Invalidate();
	}

	/// The gutter selects a track. The corner ABOVE the lanes, beside the ruler, stays inert:
	/// there is no lane there to pick.
	private void OnGutterDown(MouseEventArgs e)
	{
		if (e.Y <= RulerHeight)
			return;

		var laneY = RulerHeight;
		for (int32 i = 0; i < mLanes.Count; i++)
		{
			if ((e.Y >= laneY) && (e.Y < laneY + mLanes[i].Height))
			{
				SelectLaneFromUser(i);
				e.Handled = true;
				return;
			}

			laneY += mLanes[i].Height;
		}
	}

	private void OnLaneAreaDown(MouseEventArgs e)
	{
		let additive = e.Modifiers.HasFlag(.Ctrl);

		if (HitTestKey(e.X, e.Y, let lane, let index))
		{
			// Picking a key picks its TRACK too, so the strip below follows without a second
			// click in the gutter.
			SelectLaneFromUser((int32)lane);

			let key = Pack(lane, index);
			if (additive)
			{
				ToggleSelection(key);
				OnSelectionChanged();
			}
			else if (!mSelection.Contains(key))
			{
				// A plain click on an UNSELECTED key replaces the selection; on one already
				// selected it leaves the set alone, so a multi-key drag survives being started
				// from any member of it.
				mSelection.Clear();
				mSelection.Add(key);
				OnSelectionChanged();
			}

			mKeyDragging = true;
			mDragStartX = e.X;
			mDragDeltaX = 0.0f;
			return;
		}

		// A press ON the playhead grabs it even down among the lanes, rather than starting a
		// box select the user did not intend.
		if (Abs(e.X - TimeToX(mPlayhead)) <= PlayheadGrabRadius)
		{
			mDragging = true;
			SetPlayheadTime(XToTime(e.X));
			return;
		}

		if (!additive && !mSelection.IsEmpty)
		{
			mSelection.Clear();
			OnSelectionChanged();
		}

		mBoxSelecting = true;
		mBoxStart = .(e.X, e.Y);
		mBoxEnd = mBoxStart;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mPanning)
		{
			if (mPixelsPerSecond > 0.0f)
				SetScrollSeconds(mPanStartScroll - ((e.X - mPanStartX) / mPixelsPerSecond));

			e.Handled = true;
			Invalidate();
			return;
		}

		if (mDragging)
		{
			SetPlayheadTime(XToTime(e.X));
			e.Handled = true;
			return;
		}

		if (mKeyDragging)
		{
			// VISUAL only: the offset is drawn, and the model is untouched until release.
			mDragDeltaX = e.X - mDragStartX;
			e.Handled = true;
			Invalidate();
			return;
		}

		if (mBoxSelecting)
		{
			mBoxEnd = .(e.X, e.Y);
			e.Handled = true;
			Invalidate();
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if ((e.Button == .Middle) && mPanning)
		{
			mPanning = false;
			ReleaseCapture();
			e.Handled = true;
			return;
		}

		if (e.Button != .Left)
			return;

		let wasActive = mDragging || mKeyDragging || mBoxSelecting;

		if (mKeyDragging)
		{
			CommitKeyDrag();
		}
		else if (mBoxSelecting)
		{
			mBoxSelecting = false;
			ApplyBoxSelection();
			OnSelectionChanged();
			Invalidate();
		}

		mDragging = false;
		if (wasActive)
			ReleaseCapture();

		e.Handled = true;
	}

	/// A SMALL move is a click, not a drag. Without the threshold every selecting click would
	/// commit a sub pixel move and land an undo entry for nothing.
	private void CommitKeyDrag()
	{
		let deltaX = mDragDeltaX;
		mKeyDragging = false;
		mDragDeltaX = 0.0f;

		if ((Abs(deltaX) >= DragEpsilon) && (mPixelsPerSecond > 0.0f))
			OnKeysMoved(deltaX / mPixelsPerSecond);

		Invalidate();
	}

	/// A horizontal wheel, which is what a trackpad sends, and Shift with a vertical one both
	/// PAN. A plain vertical wheel zooms.
	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		let panDelta = (e.DeltaX != 0.0f) ? e.DeltaX
			: (e.Modifiers.HasFlag(.Shift) ? e.DeltaY : 0.0f);

		if (panDelta != 0.0f)
		{
			if (mPixelsPerSecond > 0.0f)
				SetScrollSeconds(mScrollSeconds - (panDelta * WheelPanPixels / mPixelsPerSecond));

			e.Handled = true;
			Invalidate();
			return;
		}

		if (e.DeltaY == 0.0f)
			return;

		// ANCHORED at the cursor: the time under the pointer stays under it, so zooming feels
		// like moving toward what you are looking at rather than toward the left edge.
		let timeAtCursor = XToTime(e.X);
		SetPixelsPerSecond(mPixelsPerSecond * ((e.DeltaY > 0.0f) ? ZoomStep : (1.0f / ZoomStep)));
		SetScrollSeconds(timeAtCursor - ((e.X - LabelColumnWidth) / mPixelsPerSecond));
		e.Handled = true;
		Invalidate();
	}

	// ---- Helpers --------------------------------------------------------------------------------

	private void Capture()
	{
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
	}

	private void ReleaseCapture()
	{
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();
	}

	private void SelectLaneFromUser(int32 lane)
	{
		if (lane == mSelectedLane)
			return;

		mSelectedLane = lane;
		OnLaneSelected(lane);
		Invalidate();
	}

	private void ToggleSelection(uint64 key)
	{
		if (!mSelection.Remove(key))
			mSelection.Add(key);
	}

	/// The lane row under y, and the NEAREST key on it within the hit radius.
	///
	/// Nearest rather than first, because keys close together in time overlap on screen and the
	/// one whose centre is closest is the one the user aimed at.
	private bool HitTestKey(float x, float y, out uint32 outLane, out uint32 outIndex)
	{
		outLane = 0;
		outIndex = 0;

		var laneY = RulerHeight;
		for (int li = 0; li < mLanes.Count; li++)
		{
			let lane = mLanes[li];
			if ((y < laneY) || (y >= laneY + lane.Height))
			{
				laneY += lane.Height;
				continue;
			}

			var best = KeyHitRadius;
			var found = false;
			for (int ki = 0; ki < lane.KeyTimes.Count; ki++)
			{
				let distance = Abs(TimeToX(lane.KeyTimes[ki]) - x);
				if (distance > best)
					continue;

				best = distance;
				outLane = (uint32)li;
				outIndex = (uint32)ki;
				found = true;
			}

			return found;
		}

		return false;
	}

	/// Adds every key whose marker falls inside the box. A lane counts when its CENTRE LINE is
	/// inside, so a box that merely clips the top of a row does not take it.
	private void ApplyBoxSelection()
	{
		let left = Min(mBoxStart.X, mBoxEnd.X);
		let top = Min(mBoxStart.Y, mBoxEnd.Y);
		let right = Max(mBoxStart.X, mBoxEnd.X);
		let bottom = Max(mBoxStart.Y, mBoxEnd.Y);

		var laneY = RulerHeight;
		for (int li = 0; li < mLanes.Count; li++)
		{
			let lane = mLanes[li];
			let centerY = laneY + (lane.Height * 0.5f);
			laneY += lane.Height;

			if ((centerY < top) || (centerY > bottom))
				continue;

			for (int ki = 0; ki < lane.KeyTimes.Count; ki++)
			{
				let x = TimeToX(lane.KeyTimes[ki]);
				if ((x < left) || (x > right))
					continue;

				let key = Pack((uint32)li, (uint32)ki);
				if (!mSelection.Contains(key))
					mSelection.Add(key);
			}
		}
	}
}
