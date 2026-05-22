namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Animation;

/// Per-kind discriminator for the type-parameterized track lists on a
/// `PropertyAnimationClip`. Lets the timeline view treat all five
/// type-specific track lists uniformly when drawing rows + dispatch
/// to the right list when it needs to read or mutate keyframes.
public enum PropTrackKind
{
	Float,
	Vector2,
	Vector3,
	Vector4,
	Quaternion
}

/// Identifies a single track on a PropertyAnimationClip: which type-
/// specific list it lives in, and the index within that list.
public struct PropTrackRef
{
	public PropTrackKind Kind;
	public int32 Index;

	public static PropTrackRef Invalid => .() { Kind = .Float, Index = -1 };
	public bool IsValid => Index >= 0;

	[Commutable]
	public static bool operator==(Self a, Self b) =>
		a.Kind == b.Kind && a.Index == b.Index;
}

/// Identifies a single keyframe within a track.
public struct PropKeyframeRef
{
	public PropTrackRef Track;
	public int32 Index;

	public static PropKeyframeRef Invalid => .() { Track = .Invalid, Index = -1 };
	public bool IsValid => Track.IsValid && Index >= 0;

	[Commutable]
	public static bool operator==(Self a, Self b) =>
		a.Track == b.Track && a.Index == b.Index;
}

/// Phase-2 dopesheet for a `PropertyAnimationClip`. Three regions:
///
///   - Left column: track labels (PropertyPath text).
///   - Top strip: time ruler with tick marks every PixelsPerSecond.
///   - Main grid: keyframes drawn as diamonds on each track row, with
///     a vertical playhead line driven by `PlayheadTime`.
///
/// Interaction:
///   - Click in the grid or ruler -> set PlayheadTime.
///   - Drag the playhead -> scrub.
///   - Click on a keyframe -> select it.
///   - Drag a selected keyframe -> retime (clamped to [0, clip.Duration]).
///   - Click on a track label -> select track (highlights and becomes
///     the "active" track for Add-at-playhead operations).
///
/// The widget is fully read-and-write against the clip: any retime,
/// add, or delete mutates `Clip` in-place, fires `OnClipMutated` so the
/// page can mark dirty + rebuild the time-readout label, and triggers
/// a re-sort of the affected track's keyframes.
public class TimelineView : View
{
	private PropertyAnimationClip mClip;
	private float mPlayheadTime;
	private float mPixelsPerSecond = 60.0f;
	private float mLabelColumnWidth = 140.0f;
	private float mRulerHeight = 22.0f;
	private float mTrackRowHeight = 22.0f;

	// A flat snapshot of all tracks across the five type-specific lists.
	// Rebuilt whenever the clip mutates or the clip pointer changes;
	// cheap (one List<TrackRef> with row-count entries) so we don't
	// bother caching across draws otherwise.
	private List<PropTrackRef> mFlatTracks = new .() ~ delete _;

	// Selection + interaction state.
	private PropTrackRef mSelectedTrack = .Invalid;
	private PropKeyframeRef mSelectedKeyframe = .Invalid;
	private bool mDraggingPlayhead;
	private bool mDraggingKeyframe;
	private float mKeyframeDragOriginTime;
	private float mKeyframeDragOriginPlayheadOffset;

	public Event<delegate void(TimelineView)> OnPlayheadChanged ~ _.Dispose();
	public Event<delegate void(TimelineView)> OnSelectionChanged ~ _.Dispose();
	public Event<delegate void(TimelineView)> OnClipMutated ~ _.Dispose();

	public PropertyAnimationClip Clip
	{
		get => mClip;
		set { mClip = value; RebuildFlatTracks(); Invalidate(); }
	}

	public float PlayheadTime
	{
		get => mPlayheadTime;
		set
		{
			let dur = (mClip != null) ? mClip.Duration : 1.0f;
			let clamped = Math.Clamp(value, 0, Math.Max(0.0f, dur));
			if (mPlayheadTime == clamped) return;
			mPlayheadTime = clamped;
			OnPlayheadChanged(this);
			Invalidate();
		}
	}

	public PropTrackRef SelectedTrack => mSelectedTrack;
	public PropKeyframeRef SelectedKeyframe => mSelectedKeyframe;
	public float PixelsPerSecond => mPixelsPerSecond;

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	/// Call after external code mutates the clip (added/removed track,
	/// duration change, etc.). Drops selection if it's no longer valid
	/// and refreshes the row count.
	public void RefreshFromClip()
	{
		RebuildFlatTracks();
		if (!IsTrackValid(mSelectedTrack))
		{
			mSelectedTrack = .Invalid;
			mSelectedKeyframe = .Invalid;
			OnSelectionChanged(this);
		}
		else if (!IsKeyframeValid(mSelectedKeyframe))
		{
			mSelectedKeyframe = .Invalid;
			OnSelectionChanged(this);
		}
		Invalidate();
	}

	/// Adds a keyframe at PlayheadTime on the selected track with a
	/// type-appropriate default value (zero / identity). Returns true
	/// on success. No-op when no track is selected.
	public bool AddKeyframeAtPlayheadOnSelectedTrack()
	{
		if (!mSelectedTrack.IsValid || mClip == null) return false;

		let t = mPlayheadTime;
		switch (mSelectedTrack.Kind)
		{
		case .Float:
			let track = mClip.FloatTracks[mSelectedTrack.Index];
			track.AddKeyframe(t, 0.0f);
			track.SortKeyframes();
		case .Vector2:
			let track = mClip.Vector2Tracks[mSelectedTrack.Index];
			track.AddKeyframe(t, .Zero);
			track.SortKeyframes();
		case .Vector3:
			let track = mClip.Vector3Tracks[mSelectedTrack.Index];
			track.AddKeyframe(t, .Zero);
			track.SortKeyframes();
		case .Vector4:
			let track = mClip.Vector4Tracks[mSelectedTrack.Index];
			track.AddKeyframe(t, .Zero);
			track.SortKeyframes();
		case .Quaternion:
			let track = mClip.QuaternionTracks[mSelectedTrack.Index];
			track.AddKeyframe(t, .Identity);
			track.SortKeyframes();
		}

		mClip.ComputeDuration();
		OnClipMutated(this);
		Invalidate();
		return true;
	}

	/// Deletes the currently-selected keyframe. No-op when none selected.
	public bool DeleteSelectedKeyframe()
	{
		if (!mSelectedKeyframe.IsValid || mClip == null) return false;

		let tr = mSelectedKeyframe.Track;
		let idx = mSelectedKeyframe.Index;

		switch (tr.Kind)
		{
		case .Float:
			let list = mClip.FloatTracks[tr.Index].Keyframes;
			if (idx < list.Count) list.RemoveAt(idx);
		case .Vector2:
			let list = mClip.Vector2Tracks[tr.Index].Keyframes;
			if (idx < list.Count) list.RemoveAt(idx);
		case .Vector3:
			let list = mClip.Vector3Tracks[tr.Index].Keyframes;
			if (idx < list.Count) list.RemoveAt(idx);
		case .Vector4:
			let list = mClip.Vector4Tracks[tr.Index].Keyframes;
			if (idx < list.Count) list.RemoveAt(idx);
		case .Quaternion:
			let list = mClip.QuaternionTracks[tr.Index].Keyframes;
			if (idx < list.Count) list.RemoveAt(idx);
		}

		mSelectedKeyframe = .Invalid;
		mClip.ComputeDuration();
		OnSelectionChanged(this);
		OnClipMutated(this);
		Invalidate();
		return true;
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(constraints.MaxHeight));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		// Background.
		ctx.VG.FillRect(.(0, 0, Width, Height), .(18, 19, 24, 255));

		DrawLabelColumn(ctx);
		DrawRuler(ctx);
		DrawTrackRows(ctx);
		DrawPlayhead(ctx);

		// Border between label column and grid.
		ctx.VG.DrawLine(.(mLabelColumnWidth, 0), .(mLabelColumnWidth, Height),
			.(36, 38, 46, 255), 1.0f);
		// Border between ruler and grid.
		ctx.VG.DrawLine(.(0, mRulerHeight), .(Width, mRulerHeight),
			.(36, 38, 46, 255), 1.0f);
	}

	private void DrawLabelColumn(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, mLabelColumnWidth, Height), .(22, 23, 30, 255));

		let font = ctx.FontService?.GetFont(11);
		if (font == null) return;

		let labelTextColor = Color(200, 200, 210, 255);
		let selectedFill = Color(60, 80, 110, 255);

		for (int i = 0; i < mFlatTracks.Count; i++)
		{
			let tr = mFlatTracks[i];
			let y = mRulerHeight + i * mTrackRowHeight;
			let rowRect = RectangleF(0, y, mLabelColumnWidth, mTrackRowHeight);

			if (tr == mSelectedTrack)
				ctx.VG.FillRect(rowRect, selectedFill);

			let path = GetTrackPropertyPath(tr);
			let kindMark = GetTrackKindLabel(tr.Kind);

			let line = scope String();
			line.AppendF("[{}] {}", kindMark, path.IsEmpty ? "(unnamed)" : path);

			ctx.VG.DrawText(line, font,
				.(6, y, mLabelColumnWidth - 8, mTrackRowHeight),
				.Left, .Middle, labelTextColor);
		}
	}

	private void DrawRuler(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(mLabelColumnWidth, 0, Width - mLabelColumnWidth, mRulerHeight),
			.(28, 29, 36, 255));

		let font = ctx.FontService?.GetFont(10);
		if (font == null) return;

		let tickColor = Color(80, 80, 90, 255);
		let textColor = Color(170, 170, 180, 255);
		let dur = (mClip != null) ? Math.Max(mClip.Duration, 1.0f) : 1.0f;

		// Tick every 0.5s, label every 1s.
		var tSeconds = 0;
		let step = 0.5f;
		var t = 0.0f;
		while (t <= dur + 0.001f)
		{
			let x = TimeToPixels(t);
			let isWhole = (Math.Abs(t - Math.Round(t)) < 0.001f);
			let tickH = isWhole ? mRulerHeight - 4 : mRulerHeight * 0.5f;
			ctx.VG.DrawLine(.(x, mRulerHeight - tickH), .(x, mRulerHeight),
				tickColor, 1.0f);

			if (isWhole)
			{
				let label = scope String();
				label.AppendF("{}s", tSeconds);
				ctx.VG.DrawText(label, font, .(x + 3, 0, 40, mRulerHeight),
					.Left, .Middle, textColor);
				tSeconds++;
			}
			t += step;
		}
	}

	private void DrawTrackRows(UIDrawContext ctx)
	{
		let gridLeft = mLabelColumnWidth;
		let gridTop = mRulerHeight;
		let gridRight = Width;
		let gridBottom = Height;

		let rowAlt = Color(22, 23, 30, 255);
		let rowSel = Color(36, 48, 66, 255);
		let gridLine = Color(30, 31, 38, 255);

		// Row backgrounds + horizontal separators.
		for (int i = 0; i < mFlatTracks.Count; i++)
		{
			let tr = mFlatTracks[i];
			let y = gridTop + i * mTrackRowHeight;
			let rowRect = RectangleF(gridLeft, y, gridRight - gridLeft, mTrackRowHeight);

			if (tr == mSelectedTrack)
				ctx.VG.FillRect(rowRect, rowSel);
			else if (i % 2 == 1)
				ctx.VG.FillRect(rowRect, rowAlt);

			ctx.VG.DrawLine(.(gridLeft, y + mTrackRowHeight),
				.(gridRight, y + mTrackRowHeight), gridLine, 1.0f);
		}

		// Keyframes.
		let kfFill = Color(220, 200, 120, 255);
		let kfSelectedFill = Color(255, 230, 90, 255);
		let kfStroke = Color(80, 70, 30, 255);

		for (int i = 0; i < mFlatTracks.Count; i++)
		{
			let tr = mFlatTracks[i];
			let y = gridTop + i * mTrackRowHeight + mTrackRowHeight * 0.5f;
			let count = GetTrackKeyframeCount(tr);
			for (int32 k = 0; k < count; k++)
			{
				let time = GetKeyframeTime(tr, k);
				let x = TimeToPixels(time);
				let isSel = mSelectedKeyframe.IsValid &&
				            mSelectedKeyframe.Track == tr &&
				            mSelectedKeyframe.Index == k;
				DrawDiamond(ctx, .(x, y), 6.0f, isSel ? kfSelectedFill : kfFill, kfStroke);
			}
		}

		// Track-grid empty-state message.
		if (mFlatTracks.Count == 0)
		{
			let font = ctx.FontService?.GetFont(11);
			if (font != null)
			{
				ctx.VG.DrawText("(no tracks - Phase 3 adds the picker)", font,
					.(gridLeft, gridTop, gridRight - gridLeft, gridBottom - gridTop),
					.Center, .Middle, .(140, 140, 155, 255));
			}
		}
	}

	private void DrawPlayhead(UIDrawContext ctx)
	{
		let x = TimeToPixels(mPlayheadTime);
		if (x < mLabelColumnWidth) return;
		ctx.VG.DrawLine(.(x, 0), .(x, Height), .(240, 80, 80, 255), 1.0f);

		// Head triangle in the ruler row.
		let h = 6.0f;
		Vector2[] tri = scope .(
			.(x - h, 0),
			.(x + h, 0),
			.(x, h * 1.5f));
		ctx.VG.FillPolygon(tri, .(240, 80, 80, 255));
	}

	private void DrawDiamond(UIDrawContext ctx, Vector2 center, float size, Color fill, Color stroke)
	{
		// Immediate-mode path so we get fill + stroke off the same shape
		// without rebuilding it.
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(center.X, center.Y - size);
		ctx.VG.LineTo(center.X + size, center.Y);
		ctx.VG.LineTo(center.X, center.Y + size);
		ctx.VG.LineTo(center.X - size, center.Y);
		ctx.VG.ClosePath();
		ctx.VG.Fill(fill);
		ctx.VG.Stroke(stroke, 1.0f);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left) { base.OnMouseDown(e); return; }
		if (mClip == null) return;

		// Track-label column click: select the track.
		if (e.X < mLabelColumnWidth)
		{
			let rowIndex = (int)((e.Y - mRulerHeight) / mTrackRowHeight);
			if (rowIndex >= 0 && rowIndex < mFlatTracks.Count)
			{
				let newSel = mFlatTracks[rowIndex];
				if (newSel != mSelectedTrack)
				{
					mSelectedTrack = newSel;
					mSelectedKeyframe = .Invalid;
					OnSelectionChanged(this);
					Invalidate();
				}
			}
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
			return;
		}

		// Grid / ruler click: hit-test keyframes first; if no hit, set the playhead.
		let hit = HitTestKeyframe(e.X, e.Y);
		if (hit.IsValid)
		{
			mSelectedKeyframe = hit;
			mSelectedTrack = hit.Track;
			OnSelectionChanged(this);

			mDraggingKeyframe = true;
			mKeyframeDragOriginTime = GetKeyframeTime(hit.Track, hit.Index);
			mKeyframeDragOriginPlayheadOffset = PixelsToTime(e.X) - mKeyframeDragOriginTime;

			Context?.FocusManager.SetCapture(this);
			Invalidate();
			e.Handled = true;
			return;
		}

		// No keyframe hit - drive the playhead.
		mDraggingPlayhead = true;
		PlayheadTime = PixelsToTime(e.X);
		Context?.FocusManager.SetCapture(this);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDraggingPlayhead)
		{
			PlayheadTime = PixelsToTime(e.X);
			e.Handled = true;
			return;
		}

		if (mDraggingKeyframe && mSelectedKeyframe.IsValid && mClip != null)
		{
			let newTime = Math.Max(0.0f, PixelsToTime(e.X) - mKeyframeDragOriginPlayheadOffset);
			SetKeyframeTime(mSelectedKeyframe, newTime);
			Invalidate();
			e.Handled = true;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button == .Left)
		{
			let wasDraggingKeyframe = mDraggingKeyframe;
			mDraggingPlayhead = false;
			mDraggingKeyframe = false;
			Context?.FocusManager.ReleaseCapture();
			if (wasDraggingKeyframe)
			{
				// Re-sort to keep the per-track Keyframes list in time
				// order after a retime crossed an adjacent keyframe.
				SortAndReselect(mSelectedKeyframe);
				OnClipMutated(this);
			}
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key == .Delete && mSelectedKeyframe.IsValid)
		{
			DeleteSelectedKeyframe();
			e.Handled = true;
		}
	}

	// === Selection / mutation helpers ===

	private void SetKeyframeTime(PropKeyframeRef kf, float newTime)
	{
		let tr = kf.Track;
		let idx = kf.Index;
		switch (tr.Kind)
		{
		case .Float:
			let list = mClip.FloatTracks[tr.Index].Keyframes;
			if (idx < list.Count) { var k = list[idx]; k.Time = newTime; list[idx] = k; }
		case .Vector2:
			let list = mClip.Vector2Tracks[tr.Index].Keyframes;
			if (idx < list.Count) { var k = list[idx]; k.Time = newTime; list[idx] = k; }
		case .Vector3:
			let list = mClip.Vector3Tracks[tr.Index].Keyframes;
			if (idx < list.Count) { var k = list[idx]; k.Time = newTime; list[idx] = k; }
		case .Vector4:
			let list = mClip.Vector4Tracks[tr.Index].Keyframes;
			if (idx < list.Count) { var k = list[idx]; k.Time = newTime; list[idx] = k; }
		case .Quaternion:
			let list = mClip.QuaternionTracks[tr.Index].Keyframes;
			if (idx < list.Count) { var k = list[idx]; k.Time = newTime; list[idx] = k; }
		}
	}

	private void SortAndReselect(PropKeyframeRef before)
	{
		if (!before.IsValid || mClip == null) return;
		let tr = before.Track;

		// Capture the kept-keyframe's time, sort, find it again, update
		// the selection so the user keeps "their" keyframe even if its
		// index changed after a retime crossed a neighbor.
		let keptTime = GetKeyframeTime(tr, before.Index);
		switch (tr.Kind)
		{
		case .Float:      mClip.FloatTracks[tr.Index].SortKeyframes();
		case .Vector2:    mClip.Vector2Tracks[tr.Index].SortKeyframes();
		case .Vector3:    mClip.Vector3Tracks[tr.Index].SortKeyframes();
		case .Vector4:    mClip.Vector4Tracks[tr.Index].SortKeyframes();
		case .Quaternion: mClip.QuaternionTracks[tr.Index].SortKeyframes();
		}

		let newIdx = FindKeyframeByTime(tr, keptTime);
		if (newIdx >= 0)
			mSelectedKeyframe = .() { Track = tr, Index = (int32)newIdx };
		else
			mSelectedKeyframe = .Invalid;

		mClip.ComputeDuration();
		OnSelectionChanged(this);
	}

	private int FindKeyframeByTime(PropTrackRef tr, float time)
	{
		let count = GetTrackKeyframeCount(tr);
		for (int32 i = 0; i < count; i++)
		{
			if (Math.Abs(GetKeyframeTime(tr, i) - time) < 0.0001f)
				return i;
		}
		return -1;
	}

	private PropKeyframeRef HitTestKeyframe(float x, float y)
	{
		if (y < mRulerHeight) return .Invalid;
		let rowIndex = (int)((y - mRulerHeight) / mTrackRowHeight);
		if (rowIndex < 0 || rowIndex >= mFlatTracks.Count) return .Invalid;
		let tr = mFlatTracks[rowIndex];
		let count = GetTrackKeyframeCount(tr);
		const float HitRadius = 7.0f;
		for (int32 k = 0; k < count; k++)
		{
			let kx = TimeToPixels(GetKeyframeTime(tr, k));
			if (Math.Abs(kx - x) <= HitRadius)
				return .() { Track = tr, Index = k };
		}
		return .Invalid;
	}

	// === Kind dispatch helpers ===

	private void RebuildFlatTracks()
	{
		mFlatTracks.Clear();
		if (mClip == null) return;

		for (int32 i = 0; i < mClip.FloatTracks.Count; i++)
			mFlatTracks.Add(.() { Kind = .Float, Index = i });
		for (int32 i = 0; i < mClip.Vector2Tracks.Count; i++)
			mFlatTracks.Add(.() { Kind = .Vector2, Index = i });
		for (int32 i = 0; i < mClip.Vector3Tracks.Count; i++)
			mFlatTracks.Add(.() { Kind = .Vector3, Index = i });
		for (int32 i = 0; i < mClip.Vector4Tracks.Count; i++)
			mFlatTracks.Add(.() { Kind = .Vector4, Index = i });
		for (int32 i = 0; i < mClip.QuaternionTracks.Count; i++)
			mFlatTracks.Add(.() { Kind = .Quaternion, Index = i });
	}

	private int32 GetTrackKeyframeCount(PropTrackRef tr)
	{
		if (mClip == null) return 0;
		switch (tr.Kind)
		{
		case .Float:      return (int32)mClip.FloatTracks[tr.Index].Keyframes.Count;
		case .Vector2:    return (int32)mClip.Vector2Tracks[tr.Index].Keyframes.Count;
		case .Vector3:    return (int32)mClip.Vector3Tracks[tr.Index].Keyframes.Count;
		case .Vector4:    return (int32)mClip.Vector4Tracks[tr.Index].Keyframes.Count;
		case .Quaternion: return (int32)mClip.QuaternionTracks[tr.Index].Keyframes.Count;
		}
	}

	private float GetKeyframeTime(PropTrackRef tr, int32 keyframeIndex)
	{
		if (mClip == null) return 0;
		switch (tr.Kind)
		{
		case .Float:      return mClip.FloatTracks[tr.Index].Keyframes[keyframeIndex].Time;
		case .Vector2:    return mClip.Vector2Tracks[tr.Index].Keyframes[keyframeIndex].Time;
		case .Vector3:    return mClip.Vector3Tracks[tr.Index].Keyframes[keyframeIndex].Time;
		case .Vector4:    return mClip.Vector4Tracks[tr.Index].Keyframes[keyframeIndex].Time;
		case .Quaternion: return mClip.QuaternionTracks[tr.Index].Keyframes[keyframeIndex].Time;
		}
	}

	private StringView GetTrackPropertyPath(PropTrackRef tr)
	{
		if (mClip == null) return default;
		switch (tr.Kind)
		{
		case .Float:      return mClip.FloatTracks[tr.Index].PropertyPath;
		case .Vector2:    return mClip.Vector2Tracks[tr.Index].PropertyPath;
		case .Vector3:    return mClip.Vector3Tracks[tr.Index].PropertyPath;
		case .Vector4:    return mClip.Vector4Tracks[tr.Index].PropertyPath;
		case .Quaternion: return mClip.QuaternionTracks[tr.Index].PropertyPath;
		}
	}

	private static StringView GetTrackKindLabel(PropTrackKind kind)
	{
		switch (kind)
		{
		case .Float:      return "F";
		case .Vector2:    return "V2";
		case .Vector3:    return "V3";
		case .Vector4:    return "V4";
		case .Quaternion: return "Q";
		}
	}

	private bool IsTrackValid(PropTrackRef tr)
	{
		if (!tr.IsValid || mClip == null) return false;
		switch (tr.Kind)
		{
		case .Float:      return tr.Index < (int32)mClip.FloatTracks.Count;
		case .Vector2:    return tr.Index < (int32)mClip.Vector2Tracks.Count;
		case .Vector3:    return tr.Index < (int32)mClip.Vector3Tracks.Count;
		case .Vector4:    return tr.Index < (int32)mClip.Vector4Tracks.Count;
		case .Quaternion: return tr.Index < (int32)mClip.QuaternionTracks.Count;
		}
	}

	private bool IsKeyframeValid(PropKeyframeRef kf)
	{
		if (!kf.IsValid) return false;
		if (!IsTrackValid(kf.Track)) return false;
		return kf.Index < GetTrackKeyframeCount(kf.Track);
	}

	// === Coordinate conversion ===

	private float TimeToPixels(float time)
	{
		return mLabelColumnWidth + time * mPixelsPerSecond;
	}

	private float PixelsToTime(float x)
	{
		return Math.Max(0.0f, (x - mLabelColumnWidth) / mPixelsPerSecond);
	}
}
