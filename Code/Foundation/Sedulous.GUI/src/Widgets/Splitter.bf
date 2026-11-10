using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Splitter: panes side by side (or one above another) with a handle between each two that resizes
// them. The one splitter: docking's splits and every other split are this widget.
//
// Its children are its panes, laid out along its axis by their weights. Each pane gets at least
// its minimum along the axis: its sheet's min-width (or min-height), else none. Not its content's:
// the user alone moves a handle, so a pane whose content grows (a tab shown with longer text) wraps
// or clips it where it stands rather than pushing its neighbours. When even the minimums do not
// fit, it gives them and clips what passes its end.
//
// A SplitterHandle sits between each two panes, kept in step as panes come and go (a pane added in
// markup or by code gets its handle). A handle is a widget of its own: focusable, read as a
// separator whose value is where it stands, dragged by the pointer, moved by the arrow keys along
// the axis (Shift for longer steps; Home and End to its limits), and a double click gives the panes
// back the shares they were given. A resize moves the two panes either side of the handle alone; a
// pane that goes gives its share to its neighbours, the other panes keeping theirs.

/// Which way a Splitter's panes go.
enum SplitterAxis : uint8
{
	/// Side by side, from the inline start.
	Horizontal,
	/// One above another.
	Vertical,
}

/// The handle between two of a Splitter's panes.
[GuiReflect]
class SplitterHandle : UIWidget
{
	/// How far an arrow key moves it, and with Shift.
	public const float cStep = 8.0f;
	public const float cLongStep = 48.0f;

	private float mThickness = 6.0f;
	// Where along it the press took it, in its own space.
	private float mGrab = 0.0f;
	private bool mDragging = false;

	public this()
	{
		Tag = "splitter-handle";
		AccessRoleName = "separator"; // what a screen reader takes it for
		TabFocusable = true;
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			EditLayoutStyle(scope (s) => { s.Shrink = 0.0f; });
		}
	}

	/// Where it stands, as a screen reader reads a separator: the share of the panes' room before
	/// it, 0 to 100.
	[GuiProperty("", .None, "value")]
	public double Value
	{
		get
		{
			let splitter = Splitter;
			if (splitter == null)
				return 0.0;
			float before = 0.0f;
			float all = 0.0f;
			let sizes = splitter.[Friend]mSizes;
			for (int i = 0; i < sizes.Count; ++i)
			{
				all += sizes[i];
				if (i <= Index)
					before += sizes[i];
			}
			return (all > 0.0f) ? 100.0 * (double)before / (double)all : 0.0;
		}
		set
		{
			let splitter = Splitter;
			if (splitter == null)
				return;
			float all = 0.0f;
			for (let size in splitter.[Friend]mSizes)
				all += size;
			var position = (float)(Math.Clamp(value, 0.0, 100.0) / 100.0) * all;
			let thickness = splitter.[Friend]mThickness;
			for (int i = 0; (i < Index) && (i < thickness.Count); ++i)
				position += thickness[i];
			if (splitter.IsRightToLeft && Horizontal)
				position = splitter.ContentBounds.Width - position - Size.X; // its value runs from the inline start
			splitter.MoveHandleTo(Index, position);
		}
	}

	[GuiProperty("", .None, "min")]
	public double Min => 0.0;

	[GuiProperty("", .None, "max")]
	public double Max => 100.0;

	/// How thick it is along its splitter's axis, when its sheet does not size it.
	[GuiProperty("thickness")]
	public float Thickness
	{
		get => mThickness;
		set
		{
			mThickness = Math.Max(0.0f, value);
			RequestLayout();
		}
	}

	public Sedulous.GUI.Splitter Splitter => Parent as Sedulous.GUI.Splitter;

	/// Its place among its splitter's handles.
	public int Index
	{
		get
		{
			let splitter = Splitter;
			if (splitter != null)
			{
				let handles = splitter.[Friend]mHandles;
				for (int i = 0; i < handles.Count; ++i)
				{
					if (handles[i] == this)
						return i;
				}
			}
			return 0;
		}
	}

	public override Float2 MeasureContent(Float2 available)
	{
		return Horizontal ? Float2(mThickness, 0.0f) : Float2(0.0f, mThickness);
	}

	public override bool OwnsPressDrag(Float2 local) => true;

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		if (e.ClickCount >= 2)
		{
			if (let splitter = Splitter)
				splitter.ResetWeights();
			return;
		}
		mDragging = true;
		let local = ConvertToNodeSpace(e.Position); // events come in screen space
		mGrab = Horizontal ? local.X : local.Y;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let splitter = Splitter;
		if (!mDragging || (splitter == null))
			return;
		// The pointer in the splitter's content box, less where along the handle it was taken.
		let area = splitter.ContentBounds;
		let local = splitter.ConvertToNodeSpace(e.Position);
		let at = Horizontal ? local.X - area.X : local.Y - area.Y;
		splitter.MoveHandleTo(Index, at - mGrab);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		mDragging = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mDragging = false;
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let splitter = Splitter;
		if (splitter == null)
			return;
		let step = ((e.Modifiers & KeyModShift) != 0) ? cLongStep : cStep;
		let area = splitter.ContentBounds;
		let here = Horizontal ? Position.X - area.X : Position.Y - area.Y;
		var to = here;
		let key = (KeyCode)e.KeyCode;
		if ((Horizontal && (key == .Left)) || (!Horizontal && (key == .Up)))
			to = here - step;
		else if ((Horizontal && (key == .Right)) || (!Horizontal && (key == .Down)))
			to = here + step;
		else if (key == .Home)
			to = (splitter.IsRightToLeft && Horizontal) ? 1.0e9f : -1.0e9f; // the inline start
		else if (key == .End)
			to = (splitter.IsRightToLeft && Horizontal) ? -1.0e9f : 1.0e9f;
		else
			return;
		e.Handled = true;
		splitter.MoveHandleTo(Index, to);
	}

	private bool Horizontal
	{
		get
		{
			let splitter = Splitter;
			return (splitter == null) || (splitter.Axis == .Horizontal);
		}
	}
}

[GuiReflect(true)]
class Splitter : UIWidget
{
	private struct PaneState
	{
		/// One of its children.
		public Node Pane = null;
		public float Weight = 1.0f;

		public this() { }

		public this(Node pane, float weight)
		{
			Pane = pane;
			Weight = weight;
		}
	}

	private SplitterAxis mAxis = .Horizontal;
	private List<PaneState> mPanes = new .() ~ delete _;
	// A reference held to each.
	private List<SplitterHandle> mHandles = new .() ~ { for (let h in _) h.ReleaseRef(); delete _; };
	private List<float> mGiven = new .() ~ delete _;
	// Each pane's size along the axis, as last laid out.
	private List<float> mSizes = new .() ~ delete _;
	// And its minimum.
	private List<float> mMinimums = new .() ~ delete _;
	// Each handle's.
	private List<float> mThickness = new .() ~ delete _;
	private bool mSyncing = false;
	private delegate void() mOnResized ~ delete _;
	// What WeightsText last wrote.
	private String mWeightsText = new .() ~ delete _;

	public this()
	{
		Tag = "splitter";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.OverflowX = .Hidden; // what passes its end when the minimums do not fit
					s.OverflowY = .Hidden;
				});
		}
	}

	public SplitterAxis Axis
	{
		get => mAxis;
		set
		{
			if (value == mAxis)
				return;
			mAxis = value;
			for (let handle in mHandles)
			{
				MarkAxis(handle);
				handle.RequestLayout(); // its thickness lies along the other axis now
			}
			RequestLayout();
		}
	}

	/// Markup's and a sheet's `axis`: horizontal or vertical.
	[GuiProperty("axis")]
	public StringView AxisName
	{
		get => (mAxis == .Vertical) ? "vertical" : "horizontal";
		set => Axis = (value == "vertical") ? .Vertical : .Horizontal;
	}

	public int PaneCount => mPanes.Count;
	public Node GetPane(int index) => (index < mPanes.Count) ? mPanes[index].Pane : null;
	public SplitterHandle GetHandle(int index) => (index < mHandles.Count) ? mHandles[index] : null;

	/// The panes' shares, in order (any scale: 1 2 1 gives the middle pane half). They are what a
	/// double click on a handle gives back; panes past them take an even share.
	public void SetWeights(Span<float> weights)
	{
		mGiven.Clear();
		for (let weight in weights)
			mGiven.Add(weight);
		ResetWeights();
	}

	/// Markup's and a sheet's `weights`: the shares, separated by spaces (or commas).
	[GuiProperty("weights")]
	public StringView WeightsText
	{
		get
		{
			let text = mWeightsText;
			text.Clear();
			for (int i = 0; i < mGiven.Count; ++i)
			{
				if (i != 0)
					text.Append(' ');
				mGiven[i].ToString(text);
			}
			return text;
		}
		set
		{
			let weights = scope List<float>();
			int start = 0;
			for (int i = 0; i <= value.Length; ++i)
			{
				if ((i == value.Length) || (value[i] == ' ') || (value[i] == ','))
				{
					if (i > start)
						weights.Add((float)TextRunsDetail.ParseFloat(value.Substring(start, i - start)).GetValueOrDefault(1.0));
					start = i + 1;
				}
			}
			SetWeights(weights);
		}
	}

	/// Each pane's share now, adding up to 1, appended to `outWeights`.
	public void GetWeights(List<float> outWeights)
	{
		float sum = 0.0f;
		for (let pane in mPanes)
			sum += pane.Weight;
		for (let pane in mPanes)
			outWeights.Add((sum > 0.0f) ? pane.Weight / sum : 0.0f);
	}

	/// The given shares back (an even share where none was given).
	public void ResetWeights()
	{
		for (int i = 0; i < mPanes.Count; ++i)
			mPanes[i].Weight = ((i < mGiven.Count) && (mGiven[i] > 0.0f)) ? mGiven[i] : 1.0f;
		RequestLayout();
		Changed();
	}

	/// Moves handle `index` so it starts `position` along the axis in this splitter's content box
	/// (physical: from the left, or the top), as far as the two panes' minimums let it.
	public void MoveHandleTo(int index, float position)
	{
		var position;
		if ((index + 1 >= mPanes.Count) || (index + 1 >= mSizes.Count) || (mMinimums.Count != mSizes.Count))
			return;
		// Where it starts now, from the inline start; the position taken there too.
		float start = 0.0f;
		for (int i = 0; i <= index; ++i)
			start += mSizes[i] + ((i < index) ? mThickness[i] : 0.0f);
		if (Horizontal && IsRightToLeft)
			position = ContentBounds.Width - position - mThickness[index];
		let a = mSizes[index];
		let b = mSizes[index + 1];
		let lowest = mMinimums[index];
		let highest = a + b - mMinimums[index + 1];
		if (highest < lowest)
			return; // the two have no room to give each other
		let to = Math.Clamp(a + position - start, lowest, highest);
		if (to == a)
			return;
		// The two panes alone change, their shares keeping their sum.
		let both = mPanes[index].Weight + mPanes[index + 1].Weight;
		mPanes[index].Weight = both * to / (a + b);
		mPanes[index + 1].Weight = both - mPanes[index].Weight;
		mSizes[index] = to;
		mSizes[index + 1] = a + b - to;
		RequestLayout();
		Changed();
	}

	/// The panes' sizes along the axis as last laid out, in order.
	public Span<float> PaneSizes => mSizes;

	/// After a handle moved or the shares were reset (what a dock layout writes back). OWNERSHIP
	/// of `callback` transfers.
	public void SetOnResized(delegate void() callback)
	{
		delete mOnResized;
		mOnResized = callback;
	}

	public override Float2 MeasureContent(Float2 available)
	{
		var size = Float2(0.0f, 0.0f);
		for (int i = 0; i < ChildCount; ++i)
		{
			let child = GetChildAt(i);
			let measured = child.Measure(LayoutConstraints());
			if (Horizontal)
			{
				size.X += measured.X;
				size.Y = Math.Max(size.Y, measured.Y);
			}
			else
			{
				size.Y += measured.Y;
				size.X = Math.Max(size.X, measured.X);
			}
		}
		return size;
	}

	public override void OnChildrenChanged()
	{
		SyncPanes();
	}

	public override void OnLayout()
	{
		let area = ContentBounds;
		let main = Horizontal ? area.Width : area.Height;
		let count = mPanes.Count;
		mThickness.Clear();
		float handles = 0.0f;
		for (let handle in mHandles)
		{
			let t = Along(handle.Measure(LayoutConstraints()));
			mThickness.Add(t);
			handles += t;
		}
		let room = Math.Max(0.0f, main - handles);
		mMinimums.Clear();
		float minimums = 0.0f;
		for (let pane in mPanes)
		{
			let least = MinimumOf(pane.Pane);
			mMinimums.Add(least);
			minimums += least;
		}
		// Each pane's share of the room, then those below their minimums held at them and the rest
		// shared again among the others, until none is below; when the minimums alone pass the
		// room, each has its minimum and what passes the end is clipped.
		mSizes.Count = count;
		if (minimums >= room)
		{
			for (int i = 0; i < count; ++i)
				mSizes[i] = mMinimums[i];
		}
		else
		{
			let held = scope bool[count];
			for (int round = 0; round <= count; ++round)
			{
				float free = room;
				float weights = 0.0f;
				for (int i = 0; i < count; ++i)
				{
					if (held[i])
						free -= mMinimums[i];
					else
						weights += mPanes[i].Weight;
				}
				bool more = false;
				for (int i = 0; i < count; ++i)
				{
					if (held[i])
					{
						mSizes[i] = mMinimums[i];
						continue;
					}
					mSizes[i] = (weights > 0.0f) ? free * mPanes[i].Weight / weights : free / (float)count;
					if (mSizes[i] < mMinimums[i])
					{
						held[i] = true;
						more = true;
					}
				}
				if (!more)
					break;
			}
		}
		// In order from the inline start (a horizontal splitter right to left runs from the right).
		let mirrored = Horizontal && IsRightToLeft;
		float along = 0.0f;
		for (int i = 0; i < count; ++i)
		{
			Place(mPanes[i].Pane, mSizes[i], area, mirrored, ref along);
			if (i < mHandles.Count)
				Place(mHandles[i], mThickness[i], area, mirrored, ref along);
		}
		for (let handle in mHandles)
			handle.MarkAccessDirty(); // its value moved
	}

	private bool Horizontal => mAxis == .Horizontal;

	private float Along(Float2 v) => Horizontal ? v.X : v.Y;

	private void MarkAxis(SplitterHandle handle)
	{
		handle.RemoveClass(Horizontal ? "vertical" : "horizontal");
		handle.AddClass(Horizontal ? "horizontal" : "vertical");
		handle.Cursor = Horizontal ? .EwResize : .NsResize;
	}

	// Arranges `node` `size` along the axis from `along`, which it moves on past it.
	private void Place(Node node, float size, Rect area, bool mirrored, ref float along)
	{
		Rect at;
		if (Horizontal)
		{
			let x = mirrored ? area.X + area.Width - along - size : area.X + along;
			at = .(x, area.Y, size, area.Height);
		}
		else
			at = .(area.X, area.Y + along, area.Width, size);
		node.Arrange(at);
		along += size;
	}

	// A pane's least size along the axis: its sheet's minimum, else none.
	private float MinimumOf(Node pane)
	{
		let s = pane.LayoutStyle;
		let area = ContentBounds;
		let given = (Horizontal ? s.MinWidth : s.MinHeight).Resolve(Horizontal ? area.Width : area.Height);
		return given.HasValue ? Math.Max(0.0f, given.Value) : 0.0f;
	}

	// The panes found among the children again, a handle between each two, the children in that
	// order; a pane gone gives its share to its neighbours.
	private void SyncPanes()
	{
		if (mSyncing)
			return;
		mSyncing = true;
		// The panes, in the children's order.
		let found = scope List<Node>();
		for (int i = 0; i < ChildCount; ++i)
		{
			let child = GetChildAt(i);
			if (!(child is SplitterHandle))
				found.Add(child);
		}
		// Shares: a pane that stays keeps its own; one that went gives its share to its neighbours
		// that stay, in proportion to theirs; a new one takes its given share, or the average of
		// the others'.
		let before = scope List<PaneState>();
		before.AddRange(mPanes);
		mPanes.Clear();
		for (int i = 0; i < before.Count; ++i)
		{
			if (found.Contains(before[i].Pane))
				continue;
			int previous = -1;
			int next = -1;
			for (int j = i; j > 0; --j)
			{
				if (found.Contains(before[j - 1].Pane))
				{
					previous = j - 1;
					break;
				}
			}
			for (int j = i + 1; j < before.Count; ++j)
			{
				if (found.Contains(before[j].Pane))
				{
					next = j;
					break;
				}
			}
			let gone = before[i].Weight;
			let both = ((previous >= 0) ? before[previous].Weight : 0.0f) + ((next >= 0) ? before[next].Weight : 0.0f);
			if (previous >= 0)
				before[previous].Weight += (both > 0.0f) ? gone * before[previous].Weight / both : gone;
			if (next >= 0)
				before[next].Weight += (both > 0.0f) ? gone * before[next].Weight / both : ((previous >= 0) ? 0.0f : gone);
		}
		float kept = 0.0f;
		int keptCount = 0;
		for (let state in before)
		{
			if (found.Contains(state.Pane))
			{
				kept += state.Weight;
				++keptCount;
			}
		}
		for (int i = 0; i < found.Count; ++i)
		{
			var state = PaneState(found[i], 0.0f);
			bool known = false;
			for (let old in before)
			{
				if (old.Pane == found[i])
				{
					state.Weight = old.Weight;
					known = true;
				}
			}
			if (!known)
				state.Weight = ((i < mGiven.Count) && (mGiven[i] > 0.0f)) ? mGiven[i] : ((keptCount > 0) ? kept / (float)keptCount : 1.0f);
			mPanes.Add(state);
		}
		// A handle between each two panes.
		let wanted = (mPanes.Count > 0) ? mPanes.Count - 1 : 0;
		while (mHandles.Count > wanted)
		{
			let last = mHandles.PopBack();
			last.RemoveFromParent();
			last.ReleaseRef();
		}
		while (mHandles.Count < wanted)
		{
			let handle = new SplitterHandle();
			MarkAxis(handle);
			mHandles.Add(handle);
		}
		// The children in order: a pane, a handle, a pane, ... (focus and a screen reader go so).
		int at = 0;
		for (int i = 0; i < mPanes.Count; ++i)
		{
			for (int k = 0; k < 2; ++k)
			{
				Node node = (k == 0) ? mPanes[i].Pane : ((i < mHandles.Count) ? (Node)mHandles[i] : null);
				if (node == null)
					continue;
				if (GetChildAt(at) != node)
				{
					node.AddRef(); // held while it moves
					if (node.Parent == this)
						node.RemoveFromParent();
					AddChildAt(node, at);
					node.ReleaseRef();
				}
				++at;
			}
		}
		mSyncing = false;
		RequestLayout();
	}

	private void Changed()
	{
		if (mOnResized != null)
			mOnResized();
	}
}
