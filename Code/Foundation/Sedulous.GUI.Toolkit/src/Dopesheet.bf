using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The dopesheet: a timeline source's channels as rows folded by their paths' segments (component,
// property, channel), a parent row showing the keys of every channel under it, on a shared TimeAxis
// (a curve view stands under it on the same axis). Mouse first:
//   - a click on a key selects it (a parent's selects every key under it at that time; Shift or Ctrl
//     adds or takes away), a drag from nothing selects by a box;
//   - a drag moves the selected keys in time (the pressed key on a frame with a frame rate, all kept
//     in the clip), previewed through the source and committed once, Escape giving it up; the
//     source's answer says where the keys went, so the selection follows them;
//   - Delete removes them; a double click on a channel's row inserts a key there (its value the
//     source's);
//   - a click on a row's name folds or opens it; the wheel over the names scrolls the rows, over the
//     keys zooms about the pointer; a middle drag pans.
// Its names are at the inline start (the right, right to left); time runs left to right in either
// direction, as the ruler's does, so a ruler and a curve view beside it start at its keys.

/// A row of a dopesheet: a segment of the channels' paths. A class: it owns its text.
class DopesheetRow
{
	/// The path to it ("Lamp.color").
	public String Path = new .() ~ delete _;
	/// Its last segment ("color").
	public String Name = new .() ~ delete _;
	/// Its segments less one.
	public uint32 Depth = 0;
	/// The channel it is; -1: only a parent.
	public int32 Channel = -1;
	public bool HasChildren = false;
	public bool Folded = false;
}

[GuiReflect(true)]
class Dopesheet : UIWidget, ITimeAxisClient, ITimelineSourceClient
{
	/// The parts it draws: a sheet reaches only the parts named here.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("labels");
		outParts.Add("separator");
		outParts.Add("key");
		outParts.Add("summary");
		outParts.Add("selected");
		outParts.Add("playhead");
		outParts.Add("selection-box");
	}

	public const float cRowHeight = 20.0f;
	public const float cIndent = 12.0f;
	public const float cHitRadius = 5.0f;
	public const float cDragThreshold = 3.0f;

	private enum Drag : uint8
	{
		None,
		Pending,
		Keys,
		Box,
		Pan,
	}

	private class RowNode
	{
		public String Path = new .() ~ delete _;
		public String Name = new .() ~ delete _;
		public uint32 Depth = 0;
		public int32 Channel = -1;
		// Indexes into mNodes.
		public List<int> Children = new .() ~ delete _;
	}

	private Sedulous.GUI.TimeAxis mAxis = null;
	// Not owned: the source outlives the view or is set to null first.
	private ITimelineSource mSource = null;
	private float mLabelWidth = 160.0f;
	private float mRowScroll = 0.0f;
	private List<String> mFolded = new .() ~ DeleteContainerAndItems!(_);
	private List<TimelineKeyRef> mSelection = new .() ~ delete _;

	private bool mDirty = true;
	private List<RowNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<int> mRoots = new .() ~ delete _;
	private List<DopesheetRow> mVisible = new .() ~ DeleteContainerAndItems!(_);
	// Each shown row's node.
	private List<int> mVisibleNodes = new .() ~ delete _;

	private Drag mDrag = .None;
	private Float2 mPressAt = .(0.0f, 0.0f);
	private Float2 mBoxTo = .(0.0f, 0.0f);
	private bool mAdditive = false;
	// The pressed key's time at the press.
	private float mAnchorTime = 0.0f;
	// The keys under the press.
	private List<TimelineKeyRef> mPressed = new .() ~ delete _;
	// The selection as it was when the move began.
	private List<TimelineKeyRef> mMoving = new .() ~ delete _;
	// Their earliest and latest times then.
	private float mMovingLow = 0.0f;
	private float mMovingHigh = 0.0f;
	private float mPanScroll = 0.0f;
	// Each name in turn.
	private Sedulous.GUI.Text mText = new .() ~ delete _;

	public this()
	{
		Tag = "dopesheet";
		TabFocusable = true;
	}

	public ~this()
	{
		if (mAxis != null)
		{
			mAxis.Leave(this);
			mAxis.ReleaseRef();
		}
		if (mSource != null)
			mSource.RemoveTimelineClient(this);
	}

	// === What it shows ===

	/// The axis it reads its time from. It takes a reference of its own: the caller keeps its.
	public Sedulous.GUI.TimeAxis TimeAxis
	{
		get => mAxis;
		set
		{
			if (value != null)
				value.AddRef();
			if (mAxis != null)
			{
				mAxis.Leave(this);
				mAxis.ReleaseRef();
			}
			mAxis = value;
			if (mAxis != null)
				mAxis.Join(this);
			Invalidate();
		}
	}

	/// The channels it shows (not owned: the source outlives the view or is set to null first).
	public ITimelineSource Source
	{
		get => mSource;
		set
		{
			if (mSource != null)
				mSource.RemoveTimelineClient(this);
			mSource = value;
			if (mSource != null)
				mSource.AddTimelineClient(this);
			mSelection.Clear();
			mDirty = true;
			Invalidate();
		}
	}

	/// The names' column (pixels): a ruler above it starts this far in to line up.
	[GuiProperty("label-width")]
	public float LabelWidth
	{
		get => mLabelWidth;
		set
		{
			mLabelWidth = Max(value, 0.0f);
			Invalidate();
		}
	}

	// === Rows ===

	/// The rows shown, folded ones' children left out.
	public List<DopesheetRow> Rows
	{
		get
		{
			Rebuild();
			return mVisible;
		}
	}

	public int32 FindRow(StringView path)
	{
		Rebuild();
		for (int i = 0; i < mVisible.Count; ++i)
		{
			if (mVisible[i].Path == path)
				return (int32)i;
		}
		return -1;
	}

	public void SetFolded(StringView path, bool folded)
	{
		for (int i = 0; i < mFolded.Count; ++i)
		{
			if (mFolded[i] == path)
			{
				if (!folded)
				{
					delete mFolded[i];
					mFolded.RemoveAt(i);
				}
				mDirty = true;
				Invalidate();
				return;
			}
		}
		if (folded)
			mFolded.Add(new String(path));
		mDirty = true;
		Invalidate();
	}

	public bool IsFolded(StringView path)
	{
		for (let at in mFolded)
		{
			if (at == path)
				return true;
		}
		return false;
	}

	/// The keys a row shows at each of its times: its channel's and every channel's under it.
	/// `times` and `keys` are emptied first; the caller deletes what `keys` holds.
	public void GetRowKeys(int row, List<float> times, List<List<TimelineKeyRef>> keys)
	{
		times.Clear();
		ClearAndDeleteItems!(keys);
		Rebuild();
		if ((mSource == null) || (row < 0) || (row >= mVisibleNodes.Count))
			return;
		let channels = scope List<int32>();
		Gather(mVisibleNodes[row], channels);
		let channelTimes = scope List<float>();
		for (let channel in channels)
		{
			mSource.GetKeyTimes(channel, channelTimes);
			for (int i = 0; i < channelTimes.Count; ++i)
			{
				let t = channelTimes[i];
				int at = 0;
				while ((at < times.Count) && (times[at] < t - 1e-5f))
					++at;
				if ((at < times.Count) && (Abs(times[at] - t) <= 1e-5f))
				{
					keys[at].Add(TimelineKeyRef(channel, i));
					continue;
				}
				times.Insert(at, t);
				let here = new List<TimelineKeyRef>();
				here.Add(TimelineKeyRef(channel, i));
				keys.Insert(at, here);
			}
		}
	}

	/// Where a row's key at `time` is drawn (its own space).
	public Float2 KeyPoint(int row, float time)
	{
		let @box = ContentBounds;
		return .(KeysLeft + ((mAxis != null) ? mAxis.TimeToOffset(time) : 0.0f), @box.Y + ((float)row + 0.5f) * cRowHeight - mRowScroll);
	}

	/// The names' column and the keys' area (its own space).
	public Rect NamesBounds
	{
		get
		{
			let @box = ContentBounds;
			let width = Min(mLabelWidth, @box.Width);
			return .(IsRightToLeft ? @box.Right - width : @box.X, @box.Y, width, @box.Height);
		}
	}

	public float KeysLeft
	{
		get
		{
			let @box = ContentBounds;
			return IsRightToLeft ? @box.X : @box.X + mLabelWidth;
		}
	}

	public int32 RowAtY(float y)
	{
		let @box = ContentBounds;
		let at = y - @box.Y + mRowScroll;
		if (at < 0.0f)
			return -1;
		let row = (int32)(at / cRowHeight);
		return (row < (int32)Rows.Count) ? row : -1;
	}

	public float TimeAtX(float x) => (mAxis != null) ? mAxis.OffsetToTime(x - KeysLeft) : 0.0f;
	public float RowScroll => mRowScroll;

	// === The selection ===

	public Span<TimelineKeyRef> Selection => mSelection;

	public void SetSelection(Span<TimelineKeyRef> keys)
	{
		mSelection.Clear();
		for (let key in keys)
			Select(key, true);
		Invalidate();
	}

	public bool IsSelected(TimelineKeyRef key)
	{
		for (let at in mSelection)
		{
			if (at == key)
				return true;
		}
		return false;
	}

	/// Deletes the selected keys, one change; false when none were.
	public bool DeleteSelected()
	{
		if ((mSource == null) || mSelection.IsEmpty)
			return false;
		let done = mSource.DeleteKeys(mSelection);
		mSelection.Clear();
		Invalidate();
		return done;
	}

	public void OnTimeAxisChanged()
	{
		Invalidate();
	}

	public void OnTimelineChanged()
	{
		mDirty = true;
		if ((mSource != null) && (mDrag != .Keys))
		{
			let times = scope List<float>();
			for (int i = mSelection.Count - 1; i >= 0; i--) // an undo may take keys away
			{
				times.Clear();
				if (mSelection[i].Channel < mSource.ChannelCount)
					mSource.GetKeyTimes(mSelection[i].Channel, times);
				if (mSelection[i].Index >= times.Count)
					mSelection.RemoveAt(i);
			}
		}
		Invalidate();
	}

	// === Gestures ===

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((mSource == null) || (mAxis == null))
			return;
		let local = ConvertToNodeSpace(e.Position); // events come in screen space
		if (e.Button == .Middle)
		{
			e.Handled = true;
			mDrag = .Pan;
			mPressAt = local;
			mPanScroll = mAxis.Scroll;
			return;
		}
		if (e.Button != .Left)
			return;
		e.Handled = true;
		RequestFocus();
		if (NamesBounds.Contains(local))
		{
			// The names: a click folds or opens a row that has children.
			let row = RowAtY(local.Y);
			if ((row >= 0) && Rows[row].HasChildren)
				SetFolded(scope String(Rows[row].Path), !Rows[row].Folded);
			return;
		}
		mPressAt = local;
		mBoxTo = local;
		mAdditive = (e.Modifiers & (KeyModShift | KeyModCtrl)) != 0;
		float time = 0.0f;
		let onKey = KeysAt(local, mPressed, out time);
		if ((e.ClickCount == 2) && !onKey)
		{
			let row = RowAtY(local.Y);
			if ((row >= 0) && (Rows[row].Channel >= 0))
			{
				let at = Clamp(mAxis.Snap(TimeAtX(local.X)), 0.0f, mAxis.Duration);
				TimelineKeyRef made;
				if (mSource.InsertKey(Rows[row].Channel, at, out made))
				{
					mSelection.Clear();
					mSelection.Add(made);
				}
			}
			mDrag = .None;
			Invalidate();
			return;
		}
		if (onKey)
		{
			mAnchorTime = time;
			let all = AllSelected(mPressed);
			if (mAdditive)
			{
				for (let key in mPressed)
					Select(key, !all);
			}
			else if (!all)
			{
				mSelection.Clear();
				for (let key in mPressed)
					mSelection.Add(key);
			}
			mDrag = AllSelected(mPressed) ? .Pending : .None;
		}
		else
		{
			if (!mAdditive)
				mSelection.Clear();
			mDrag = .Box;
		}
		Invalidate();
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if ((mDrag == .None) || (mSource == null) || (mAxis == null))
			return;
		let local = ConvertToNodeSpace(e.Position);
		switch (mDrag)
		{
		case .Pending:
			if ((Abs(local.X - mPressAt.X) < cDragThreshold) && (Abs(local.Y - mPressAt.Y) < cDragThreshold))
				return;
			mDrag = .Keys;
			mMoving.Clear();
			let times = scope List<float>();
			bool first = true;
			for (let key in mSelection)
			{
				mMoving.Add(key);
				mSource.GetKeyTimes(key.Channel, times);
				if (key.Index >= times.Count)
					continue;
				mMovingLow = first ? times[key.Index] : Min(mMovingLow, times[key.Index]);
				mMovingHigh = first ? times[key.Index] : Max(mMovingHigh, times[key.Index]);
				first = false;
			}
			mSource.BeginKeysMove();
			MoveTo(local.X);
		case .Keys:
			MoveTo(local.X);
		case .Box:
			mBoxTo = local;
			Invalidate();
		case .Pan:
			mAxis.Scroll = mPanScroll - (local.X - mPressAt.X) / mAxis.PixelsPerSecond;
		default:
		}
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (mDrag == .Pan)
		{
			if (e.Button == .Middle)
				mDrag = .None;
			return;
		}
		if (e.Button != .Left)
			return;
		if ((mDrag == .Box) && (mSource != null))
		{
			let to = ConvertToNodeSpace(e.Position);
			let left = Min(mPressAt.X, to.X);
			let right = Max(mPressAt.X, to.X);
			let top = Min(mPressAt.Y, to.Y);
			let bottom = Max(mPressAt.Y, to.Y);
			let times = scope List<float>();
			let keys = scope List<List<TimelineKeyRef>>();
			defer { ClearAndDeleteItems!(keys); }
			for (int row = 0; row < Rows.Count; ++row)
			{
				GetRowKeys(row, times, keys);
				for (int i = 0; i < times.Count; ++i)
				{
					let at = KeyPoint(row, times[i]);
					if ((at.X >= left) && (at.X <= right) && (at.Y >= top) && (at.Y <= bottom))
					{
						for (let key in keys[i])
							Select(key, true);
					}
				}
			}
			mDrag = .None;
			Invalidate();
			return;
		}
		if ((mDrag == .Pending) && !mAdditive)
		{
			mSelection.Clear(); // a click on a key of several selected selects it alone
			for (let key in mPressed)
				mSelection.Add(key);
			Invalidate();
		}
		EndDrag(true);
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		EndDrag(false);
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((key == .Escape) && (mDrag == .Keys))
		{
			e.Handled = true;
			EndDrag(false);
			return;
		}
		if ((e.Modifiers == 0) && ((key == .Delete) || (key == .Backspace)) && (mDrag == .None))
			e.Handled = DeleteSelected();
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		let steps = (e.Delta.Y != 0.0f) ? e.Delta.Y : e.Delta.X;
		if (steps == 0.0f)
			return;
		e.Handled = true;
		let local = ConvertToNodeSpace(e.Position);
		let @box = ContentBounds;
		if (NamesBounds.Contains(local))
		{
			// Over the names: the rows scroll, kept in what they fill.
			let most = Max(0.0f, (float)Rows.Count * cRowHeight - @box.Height);
			mRowScroll = Clamp(mRowScroll - steps * cRowHeight * 3.0f, 0.0f, most);
			Invalidate();
			return;
		}
		if (mAxis != null)
			mAxis.ZoomAbout(TimeAtX(local.X), Pow(1.2f, steps));
	}

	protected override void OnTextStyleChange()
	{
		mText.Font = Font;
		mText.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
		mText.Color = TextColor;
		mText.SetAlignment(.Start, .Top);
	}

	public override Sedulous.GUI.Cursor CursorNow => (mDrag == .Pan) ? .Grabbing : base.CursorNow;

	// === Drawing ===

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let @box = ContentBounds;
		Color PartColor(StringView name, Color fallback)
		{
			let part = GetPartStyle(name);
			var color = part.HasBackground ? part.Box.BackgroundColor : fallback;
			color.A *= part.Opacity;
			return color;
		}
		let labels = PartColor("labels", .(0.0f, 0.0f, 0.0f, 0.15f));
		let separator = PartColor("separator", .(1.0f, 1.0f, 1.0f, 0.06f));
		let keyColor = PartColor("key", .(0.8f, 0.8f, 0.85f, 1.0f));
		let summary = PartColor("summary", .(0.55f, 0.58f, 0.65f, 1.0f));
		let selected = PartColor("selected", .(1.0f, 0.8f, 0.3f, 1.0f));
		ctx.PushClip(@box);
		let names = NamesBounds;
		let rtl = IsRightToLeft;
		let keysArea = Rect(KeysLeft, @box.Y, Max(0.0f, @box.Width - names.Width), @box.Height);
		ctx.VG.FillRect(names.ToRectangle(), labels);
		let rows = Rows;
		let times = scope List<float>();
		let keys = scope List<List<TimelineKeyRef>>();
		defer { ClearAndDeleteItems!(keys); }
		for (int r = 0; r < rows.Count; ++r)
		{
			let row = rows[r];
			let top = @box.Y + (float)r * cRowHeight - mRowScroll;
			if ((top > @box.Bottom) || (top + cRowHeight < @box.Y))
				continue;
			ctx.VG.FillRect(.(@box.X, top + cRowHeight - 1.0f, @box.Width, 1.0f), separator);
			// From the names' inline start: a chevron, then the name.
			let indent = 4.0f + (float)row.Depth * cIndent;
			let side = rtl ? -1.0f : 1.0f;
			let start = rtl ? names.Right - indent : names.X + indent;
			if (row.HasChildren)
			{
				// A chevron: toward the inline end when folded, down when open.
				let chevron = scope PathBuilder();
				let cx = start + side * 4.0f;
				let cy = top + cRowHeight * 0.5f;
				if (row.Folded)
				{
					chevron.MoveTo(cx - side * 2.0f, cy - 4.0f);
					chevron.LineTo(cx + side * 3.0f, cy);
					chevron.LineTo(cx - side * 2.0f, cy + 4.0f);
				}
				else
				{
					chevron.MoveTo(cx - 4.0f, cy - 2.0f);
					chevron.LineTo(cx, cy + 3.0f);
					chevron.LineTo(cx + 4.0f, cy - 2.0f);
				}
				chevron.Close();
				let chevronPath = chevron.ToPath();
				ctx.VG.FillPath(chevronPath, TextColor);
				delete chevronPath;
			}
			if (mText.HasFont)
			{
				ctx.PushClip(.(names.X + 2.0f, top, Max(0.0f, names.Width - 4.0f), cRowHeight));
				mText.SetString(row.Name);
				let width = mText.Measure().X;
				mText.Draw(ctx, Float2(rtl ? start - 12.0f - width : start + 12.0f, top + 3.0f));
				ctx.PopClip();
			}
			if (mAxis == null)
				continue;
			ctx.PushClip(.(keysArea.X, top, keysArea.Width, cRowHeight));
			GetRowKeys(r, times, keys);
			for (int i = 0; i < times.Count; ++i)
			{
				let at = KeyPoint(r, times[i]);
				let on = AllSelected(keys[i]);
				let size = (row.Channel >= 0) ? 5.0f : 4.0f;
				let diamond = scope PathBuilder();
				diamond.MoveTo(at.X, at.Y - size);
				diamond.LineTo(at.X + size, at.Y);
				diamond.LineTo(at.X, at.Y + size);
				diamond.LineTo(at.X - size, at.Y);
				diamond.Close();
				let diamondPath = diamond.ToPath();
				ctx.VG.FillPath(diamondPath, on ? selected : ((row.Channel >= 0) ? keyColor : summary));
				delete diamondPath;
			}
			ctx.PopClip();
		}
		if (mAxis != null)
		{
			let playhead = PartColor("playhead", .(0.31f, 0.61f, 1.0f, 1.0f));
			let x = KeysLeft + mAxis.TimeToOffset(mAxis.Playhead);
			if ((x >= keysArea.X) && (x <= keysArea.Right))
				ctx.VG.FillRect(.(Floor(x), @box.Y, 1.0f, @box.Height), playhead);
		}
		if (mDrag == .Box)
		{
			let fill = PartColor("selection-box", .(0.31f, 0.61f, 1.0f, 0.2f));
			ctx.VG.FillRect(.(Min(mPressAt.X, mBoxTo.X), Min(mPressAt.Y, mBoxTo.Y), Abs(mBoxTo.X - mPressAt.X), Abs(mBoxTo.Y - mPressAt.Y)), fill);
		}
		ctx.PopClip();
	}

	// The rows again from the channels' paths: a tree by segments, in the order they first appear,
	// then the shown rows in order (a folded row's children left out).
	private void Rebuild()
	{
		if (!mDirty)
			return;
		mDirty = false;
		ClearAndDeleteItems!(mNodes);
		mRoots.Clear();
		ClearAndDeleteItems!(mVisible);
		mVisibleNodes.Clear();
		if (mSource == null)
			return;
		let path = scope String();
		for (int c = 0; c < mSource.ChannelCount; ++c)
		{
			path.Clear();
			mSource.GetChannelPath(c, path);
			int parent = -1;
			int start = 0;
			uint32 depth = 0;
			while (start <= path.Length)
			{
				var end = start;
				while ((end < path.Length) && (path[end] != '.'))
					++end;
				let prefix = path.Substring(0, end);
				let name = path.Substring(start, end - start);
				let siblings = (parent < 0) ? mRoots : mNodes[parent].Children;
				int found = -1;
				for (let n in siblings)
				{
					if (mNodes[n].Path == prefix)
						found = n;
				}
				if (found < 0)
				{
					let node = new RowNode();
					node.Path.Set(prefix);
					node.Name.Set(name);
					node.Depth = depth;
					mNodes.Add(node);
					found = mNodes.Count - 1;
					if (parent < 0)
						mRoots.Add(found);
					else
						mNodes[parent].Children.Add(found);
				}
				parent = found;
				++depth;
				if (end >= path.Length)
					break;
				start = end + 1;
			}
			if (parent >= 0)
				mNodes[parent].Channel = (int32)c;
		}
		for (let root in mRoots)
			Show(root);
	}

	private void Show(int node)
	{
		let n = mNodes[node];
		let row = new DopesheetRow();
		row.Path.Set(n.Path);
		row.Name.Set(n.Name);
		row.Depth = n.Depth;
		row.Channel = n.Channel;
		row.HasChildren = !n.Children.IsEmpty;
		row.Folded = row.HasChildren && IsFolded(n.Path);
		let folded = row.Folded;
		mVisible.Add(row);
		mVisibleNodes.Add(node);
		if (!folded)
		{
			for (let child in n.Children)
				Show(child);
		}
	}

	private void Gather(int node, List<int32> channels)
	{
		if (mNodes[node].Channel >= 0)
			channels.Add(mNodes[node].Channel);
		for (let child in mNodes[node].Children)
			Gather(child, channels);
	}

	private void Select(TimelineKeyRef key, bool on)
	{
		for (int i = 0; i < mSelection.Count; ++i)
		{
			if (mSelection[i] == key)
			{
				if (!on)
					mSelection.RemoveAt(i);
				return;
			}
		}
		if (on)
			mSelection.Add(key);
	}

	private bool AllSelected(Span<TimelineKeyRef> keys)
	{
		for (let key in keys)
		{
			if (!IsSelected(key))
				return false;
		}
		return !keys.IsEmpty;
	}

	// The keys under a point of the key area: a row's marker within reach.
	private bool KeysAt(Float2 local, List<TimelineKeyRef> outKeys, out float time)
	{
		outKeys.Clear();
		time = 0.0f;
		let row = RowAtY(local.Y);
		if (row < 0)
			return false;
		let times = scope List<float>();
		let keys = scope List<List<TimelineKeyRef>>();
		defer { ClearAndDeleteItems!(keys); }
		GetRowKeys(row, times, keys);
		var best = cHitRadius + 1.0f;
		int found = -1;
		for (int i = 0; i < times.Count; ++i)
		{
			let d = Abs(KeyPoint(row, times[i]).X - local.X);
			if ((d <= cHitRadius) && (d < best))
			{
				best = d;
				found = i;
			}
		}
		if (found < 0)
			return false;
		outKeys.AddRange(keys[found]);
		time = times[found];
		return true;
	}

	private void MoveTo(float x)
	{
		var delta = TimeAtX(x) - TimeAtX(mPressAt.X);
		delta = mAxis.Snap(mAnchorTime + delta) - mAnchorTime; // the pressed key on a frame, the rest kept apart
		delta = Clamp(delta, -mMovingLow, mAxis.Duration - mMovingHigh); // all kept in the clip
		let moved = scope List<TimelineKeyRef>();
		mSource.PreviewKeysMove(mMoving, delta, moved);
		mSelection.Clear();
		mSelection.AddRange(moved);
		Invalidate();
	}

	private void EndDrag(bool commit)
	{
		let drag = mDrag;
		mDrag = .None;
		if ((drag != .Keys) || (mSource == null))
			return;
		if (commit)
			mSource.CommitKeysMove();
		else
		{
			mSource.CancelKeysMove();
			mSelection.Clear();
			mSelection.AddRange(mMoving);
		}
		mMoving.Clear();
		Invalidate();
	}
}
