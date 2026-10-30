using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

// The frames chosen's scopes as a table (X7 of Raptor's editor-gui spec): by default the call tree,
// each thread a group and the GPU's passes one, a scope under the one it ran in (the frames merged:
// a scope's every run in the same place is one row); sorted by any other heading, a flat list of
// names, the longest first (again: the other way). Columns: calls, total and self time (its
// children's taken out), the mean and the longest call, and its share of the frames' time. Over a
// span marked on the timeline, the span's: scopes cut to it.
//
// Mouse first: a click on a row chooses its name (the page's other views told), a click on a row's
// arrow folds or opens it, a click on a heading sorts by it, the wheel scrolls the rows. A filter
// shows the names holding its text (and in the tree, the rows they hang from).

/// A table's column, its heading's order.
enum ScopeColumn : uint8
{
	/// The call tree; the others sort a flat list.
	Name,
	Calls,
	Total,
	Self,
	Mean,
	Max,
	Share,
}

/// A row of the call tree: a thread's group, or a scope in the place it ran.
class ScopeNode
{
	public uint32 Name = 0;
	public bool Gpu = false;
	/// A thread's (or the GPU's) group: a name, no numbers.
	public bool Group = false;
	public String GroupName = new .() ~ delete _;
	public uint32 Thread = 0;
	public int32 Parent = -1;
	/// 0 for a group.
	public uint32 Depth = 0;
	public uint64 Calls = 0;
	public int64 TotalTicks = 0;
	public int64 SelfTicks = 0;
	public int64 MaxTicks = 0;
	/// Its place, kept across rebuilds: the fold remembers it by this.
	public uint64 Key = 0;
	public List<uint32> Children = new .() ~ delete _;
}

/// What the call tree is built from: the frames chosen and the span marked, if any.
class ScopeTree
{
	/// Groups first in their order, then scopes as met.
	public List<ScopeNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	/// The groups.
	public List<uint32> Roots = new .() ~ delete _;
	/// The frames' (or the span's) length, for a scope's share.
	public int64 FrameTicks = 0;

	public void Clear()
	{
		ClearAndDeleteItems!(Nodes);
		Roots.Clear();
		FrameTicks = 0;
	}

	/// Builds it from `source` over `frames`, the scopes cut to `span` when it is marked.
	public void Build(IProfileSource source, FrameRange frames, MarkedSpan span)
	{
		Clear();
		if (frames.Empty)
			return;
		let order = scope List<int>();
		let stack = scope List<uint32>();
		let passes = scope List<ScopeEvent>();
		for (var n = frames.First; n <= frames.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			FrameTicks += Cut(frame.BeginTick, frame.EndTick, span);
			for (let thread in frame.Threads)
			{
				if (thread.Scopes.IsEmpty)
					continue;
				let group = GroupOf(thread.Thread, false, source);
				AddRuns(thread.Scopes, group, false, span, order, stack);
			}
			if (!frame.Gpu.IsEmpty)
			{
				let group = GroupOf(uint32.MaxValue, true, source);
				passes.Clear();
				for (let pass in frame.Gpu)
					passes.Add(.(pass.Name, pass.Depth, pass.BeginTick, pass.EndTick));
				AddRuns(passes, group, true, span, order, stack);
			}
		}
		// Self: a node's total less its children's.
		for (let node in Nodes)
		{
			int64 children = 0;
			for (let child in node.Children)
				children += Nodes[child].TotalTicks;
			node.SelfTicks = node.TotalTicks - Math.Min(children, node.TotalTicks);
		}
		// The GPU's group last; the threads' in their order.
		Roots.Sort(scope (a, b) =>
			{
				let x = Nodes[a];
				let y = Nodes[b];
				if (x.Gpu != y.Gpu)
					return x.Gpu ? 1 : -1;
				return x.Thread <=> y.Thread;
			});
	}

	private static int64 Cut(int64 begin, int64 end, MarkedSpan span)
	{
		if (!span.Any)
			return end - begin;
		let from = Math.Max(begin, span.BeginTick);
		let to = Math.Min(end, span.EndTick);
		return (to > from) ? (to - from) : 0;
	}

	private uint32 GroupOf(uint32 thread, bool gpu, IProfileSource source)
	{
		for (let root in Roots)
		{
			if ((Nodes[root].Gpu == gpu) && (Nodes[root].Thread == thread))
				return root;
		}
		let group = new ScopeNode();
		group.Group = true;
		group.Gpu = gpu;
		group.Thread = thread;
		group.Key = Mix(0x9E3779B97F4A7C15UL, gpu ? 0xFFFFFFFFUL : ((uint64)thread + 1));
		if (gpu)
			group.GroupName.Set("GPU");
		else
		{
			for (let info in source.Threads)
			{
				if (info.Index == thread)
					group.GroupName.Set(info.Name);
			}
			if (group.GroupName.IsEmpty)
				group.GroupName.AppendF("Thread {}", thread);
		}
		Nodes.Add(group);
		Roots.Add((uint32)(Nodes.Count - 1));
		return (uint32)(Nodes.Count - 1);
	}

	// A thread's runs of one frame into the tree: in order of their start (the outer first), each
	// under the run it lies in.
	private void AddRuns(List<ScopeEvent> runs, uint32 group, bool gpu, MarkedSpan span, List<int> order, List<uint32> stack)
	{
		order.Clear();
		for (int i < runs.Count)
			order.Add(i);
		order.Sort(scope (a, b) =>
			{
				if (runs[a].BeginTick != runs[b].BeginTick)
					return runs[a].BeginTick <=> runs[b].BeginTick;
				return runs[a].Depth <=> runs[b].Depth;
			});
		stack.Clear(); // the open runs' nodes, by depth
		let depths = scope List<uint32>();
		for (let i in order)
		{
			let run = runs[i];
			while (!depths.IsEmpty && (depths.Back >= run.Depth + 1))
			{
				depths.PopBack();
				stack.PopBack();
			}
			let parent = stack.IsEmpty ? group : stack.Back;
			let node = Child(parent, run.Name, gpu);
			let ticks = Cut(run.BeginTick, run.EndTick, span);
			if ((ticks > 0) || !span.Any)
			{
				let at = Nodes[node];
				at.Calls++;
				at.TotalTicks += ticks;
				at.MaxTicks = Math.Max(at.MaxTicks, ticks);
			}
			stack.Add(node);
			depths.Add(run.Depth + 1);
		}
	}

	private uint32 Child(uint32 parent, uint32 name, bool gpu)
	{
		for (let child in Nodes[parent].Children)
		{
			if (Nodes[child].Name == name)
				return child;
		}
		let node = new ScopeNode();
		node.Name = name;
		node.Gpu = gpu;
		node.Parent = (int32)parent;
		node.Thread = Nodes[parent].Thread;
		node.Depth = Nodes[parent].Depth + 1;
		node.Key = Mix(Nodes[parent].Key, (uint64)name + 1);
		Nodes.Add(node);
		let at = (uint32)(Nodes.Count - 1);
		Nodes[parent].Children.Add(at);
		return at;
	}

	private static uint64 Mix(uint64 a, uint64 b)
	{
		var h = a ^ (b + 0x9E3779B97F4A7C15UL + (a << 6) + (a >> 2));
		h ^= h >> 31;
		h *= 0xBF58476D1CE4E5B9UL;
		return h ^ (h >> 29);
	}
}

[GuiReflect(true)]
class ScopeTable : ProfilerWidget
{
	public const float cRowHeight = 22.0f;
	public const float cHeadingHeight = 24.0f;
	public const float cNumberWidth = 72.0f;
	public const float cIndent = 16.0f;
	public const float cArrowWidth = 16.0f;
	/// Tree rows open to this depth until folded.
	public const uint32 cOpenDepth = 3;
	public const int cColumnCount = 7;
	private static readonly String[cColumnCount] cHeadings = .("Name", "Calls", "Total ms", "Self ms", "Mean", "Max", "Frame");

	/// A row shown: a tree node, or in the flat list a name's totals. Its label is the source's
	/// name or the tree's group name: good until the table rebuilds.
	public struct Row
	{
		/// The tree's node (the tree), or -1 (the flat list).
		public int32 Node = -1;
		public uint32 Name = 0;
		public bool Gpu = false;
		public bool Group = false;
		public StringView Label = default;
		public uint32 Depth = 0;
		public bool HasChildren = false;
		public bool Open = false;
		public uint64 Calls = 0;
		public int64 TotalTicks = 0;
		public int64 SelfTicks = 0;
		public int64 MaxTicks = 0;
	}

	private ScopeColumn mSort = .Name;
	private bool mDescending = true;
	private String mFilter = new .() ~ delete _;
	/// Nodes folded or opened against their default, by their place.
	private List<uint64> mToggled = new .() ~ delete _;
	private float mScroll = 0.0f;
	private int mHovered = -1;

	private ScopeTree mTree = new .() ~ delete _;
	private List<Row> mRows = new .() ~ delete _;
	private MarkedSpan mBuiltSpan = .();
	private bool mTreeDirty = true;
	private bool mRowsDirty = true;

	/// The parts it draws, which the sheet styles as `tag::part`.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		base.CollectStyleParts(outParts);
		outParts.Add("heading");
		outParts.Add("sorted");
		outParts.Add("separator");
		outParts.Add("group");
		outParts.Add("fold");
		outParts.Add("chosen");
		outParts.Add("hover");
	}
	public this()
	{
		Tag = "scopetable";
		TabFocusable = false;
	}

	// === What it shows ===

	public ScopeColumn SortColumn => mSort;
	public bool SortsDescending => mDescending;

	/// Sorts by `column` (Name: the tree), longest first unless `descending` is false.
	public void SortBy(ScopeColumn column, bool descending = true)
	{
		mSort = column;
		mDescending = descending;
		mScroll = 0.0f;
		mRowsDirty = true;
		Invalidate();
	}

	/// Shows only the names holding `text` (any case); empty: all.
	public void SetFilter(StringView text)
	{
		mFilter.Set(text);
		mScroll = 0.0f;
		mRowsDirty = true;
		Invalidate();
	}

	public StringView Filter => mFilter;

	/// Folds or opens a tree row (by its place).
	public void SetOpen(Row row, bool open)
	{
		if (row.Node < 0)
			return;
		let node = Tree.Nodes[row.Node];
		let byDefault = node.Group || (node.Depth < cOpenDepth);
		mToggled.Remove(node.Key);
		if (open != byDefault)
			mToggled.Add(node.Key);
		mRowsDirty = true;
		Invalidate();
	}

	// === The model (the draw and the tests read it) ===

	public ScopeTree Tree
	{
		get
		{
			Refresh();
			return mTree;
		}
	}

	public Span<Row> Rows
	{
		get
		{
			Refresh();
			return mRows;
		}
	}

	/// The row at a point's y (its own space), or -1.
	public int RowAt(float y)
	{
		let @box = ContentBounds;
		let at = y - @box.Y - cHeadingHeight + mScroll;
		if ((y < @box.Y + cHeadingHeight) || (at < 0.0f))
			return -1;
		let row = (int)(at / cRowHeight);
		return (row < Rows.Length) ? row : -1;
	}

	/// The heading at a point's x (its own space).
	public ScopeColumn ColumnAt(float x)
	{
		let @box = ContentBounds;
		let fromEnd = @box.Right - x;
		if ((fromEnd < 0.0f) || (fromEnd >= cNumberWidth * (float)(cColumnCount - 1)))
			return .Name;
		return (ScopeColumn)(cColumnCount - 1 - (int)(fromEnd / cNumberWidth));
	}

	/// A row's value in a column (ms, or calls), as the table writes it, appended.
	public void CellText(Row row, ScopeColumn column, String outText)
	{
		let source = Source;
		if (row.Group || (source == null))
			return;
		let frequency = source.TickFrequency;
		switch (column)
		{
		case .Name:
			outText.Append(row.Label);
		case .Calls:
			outText.AppendF("{}", row.Calls);
		case .Total:
			outText.AppendF("{:F2}", ProfileWindow.TicksToMs(row.TotalTicks, frequency));
		case .Self:
			outText.AppendF("{:F2}", ProfileWindow.TicksToMs(row.SelfTicks, frequency));
		case .Mean:
			outText.AppendF("{:F2}", (row.Calls > 0) ? (ProfileWindow.TicksToMs(row.TotalTicks, frequency) / (float)row.Calls) : 0.0f);
		case .Max:
			outText.AppendF("{:F2}", ProfileWindow.TicksToMs(row.MaxTicks, frequency));
		case .Share:
			outText.AppendF("{:F1}%", (mTree.FrameTicks > 0) ? (100.0 * (double)row.TotalTicks / (double)mTree.FrameTicks) : 0.0);
		}
	}

	public override void OnProfileSourceChanged() => Dirty();
	public override void OnProfileFramesChanged() => Dirty();

	public override void OnProfileChoiceChanged()
	{
		// The span cuts the scopes; the name only lights its rows.
		let span = (mFocus != null) ? mFocus.Span : MarkedSpan();
		if (!span.Equals(mBuiltSpan))
			Dirty();
		Invalidate();
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		let at = Local(e.Position);
		let @box = ContentBounds;
		if (at.Y < @box.Y + cHeadingHeight)
		{
			let column = ColumnAt(at.X);
			SortBy(column, (column == mSort) ? !mDescending : true);
			return;
		}
		let index = RowAt(at.Y);
		if (index < 0)
		{
			if (mFocus != null)
				mFocus.ClearName();
			return;
		}
		let row = mRows[index];
		let arrowX = @box.X + 6.0f + (float)row.Depth * cIndent;
		if (row.HasChildren && (at.X >= arrowX) && (at.X < arrowX + cArrowWidth))
		{
			SetOpen(row, !row.Open);
			return;
		}
		if (row.Group)
		{
			SetOpen(row, !row.Open);
			return;
		}
		if (mFocus != null)
			mFocus.ChooseName(row.Name, row.Gpu);
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let hovered = RowAt(Local(e.Position).Y);
		if (hovered != mHovered)
		{
			mHovered = hovered;
			Invalidate();
		}
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		base.OnMouseLeave(e);
		mHovered = -1;
		Invalidate();
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		e.Handled = true;
		let @box = ContentBounds;
		let most = Math.Max((float)Rows.Length * cRowHeight - (@box.Height - cHeadingHeight), 0.0f);
		mScroll = Math.Clamp(mScroll - e.Delta.Y * cRowHeight * 3.0f, 0.0f, most);
		Invalidate();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		Refresh();
		let @box = ContentBounds;
		let text = TextColor;
		let dim = PartTextColor("group");
		let heading = PartTextColor("heading");
		let separator = PartColor("separator", .(0.5f, 0.5f, 0.5f, 0.3f));
		let source = Source;
		let label = scope String();

		// The headings.
		ctx.VG.FillRect(.(@box.X, @box.Y, @box.Width, cHeadingHeight), PartColor("heading", .(0.0f, 0.0f, 0.0f, 0.12f)));
		for (int c < cColumnCount)
		{
			let column = (ScopeColumn)c;
			let cell = CellBounds(column, @box.Y, cHeadingHeight);
			let color = (column == mSort) ? PartTextColor("sorted") : heading;
			label.Set(cHeadings[c]);
			if ((column == mSort) && (column != .Name))
				label.Append(mDescending ? " ▾" : " ▴");
			DrawLabel(ctx, label, cell, color, (column == .Name) ? .Start : .End);
		}
		ctx.VG.FillRect(.(@box.X, @box.Y + cHeadingHeight - 1.0f, @box.Width, 1.0f), separator);

		// The rows.
		ctx.PushClip(.(@box.X, @box.Y + cHeadingHeight, @box.Width, Math.Max(@box.Height - cHeadingHeight, 0.0f)));
		let chosen = (mFocus != null) ? mFocus.Name : ChosenName();
		let fold = PartColor("fold", dim);
		for (int i = (int)(mScroll / cRowHeight); i < mRows.Count; i++)
		{
			let y = @box.Y + cHeadingHeight + (float)i * cRowHeight - mScroll;
			if (y > @box.Bottom)
				break;
			let row = mRows[i];
			let line = Rect(@box.X, y, @box.Width, cRowHeight);
			if (!row.Group && chosen.Is(row.Name, row.Gpu))
				ctx.VG.FillRect(line.ToRectangle(), PartColor("chosen", .(0.18f, 0.43f, 0.87f, 0.35f)));
			else if (i == mHovered)
				ctx.VG.FillRect(line.ToRectangle(), PartColor("hover", .(1.0f, 1.0f, 1.0f, 0.05f)));
			var x = @box.X + 6.0f + (float)row.Depth * cIndent;
			if (row.HasChildren)
				DrawArrow(ctx, .(x + cArrowWidth * 0.5f, y + cRowHeight * 0.5f), !row.Open, fold);
			x += cArrowWidth;
			if (!row.Group && (source != null))
			{
				ctx.VG.FillRoundedRect(.(x, y + cRowHeight * 0.5f - 5.0f, 10.0f, 10.0f), 2.0f, NameColor(source.NameOf(row.Name)));
				x += 14.0f;
			}
			let name = CellBounds(.Name, y, cRowHeight);
			DrawLabel(ctx, row.Label, .(x, y, Math.Max(name.Right - x, 0.0f), cRowHeight), row.Group ? dim : text);
			for (int c = 1; c < cColumnCount; c++)
			{
				let column = (ScopeColumn)c;
				label.Clear();
				CellText(row, column, label);
				DrawLabel(ctx, label, CellBounds(column, y, cRowHeight), text, .End);
			}
		}
		ctx.PopClip();
	}

	private void Dirty()
	{
		mTreeDirty = true;
		mRowsDirty = true;
		Invalidate();
	}

	// A column's cell on a line at `y`: the numbers right to left from the end, the name the rest.
	private Rect CellBounds(ScopeColumn column, float y, float height)
	{
		let @box = ContentBounds;
		let numbers = cNumberWidth * (float)(cColumnCount - 1);
		if (column == .Name)
			return .(@box.X + 6.0f, y, Math.Max(@box.Width - numbers - 12.0f, 0.0f), height);
		let fromEnd = cColumnCount - 1 - (int)column;
		return .(@box.Right - (float)(fromEnd + 1) * cNumberWidth, y, cNumberWidth - 8.0f, height);
	}

	private void Refresh()
	{
		let source = Source;
		if (mTreeDirty)
		{
			mTreeDirty = false;
			mRowsDirty = true;
			mBuiltSpan = (mFocus != null) ? mFocus.Span : MarkedSpan();
			if (source != null)
				mTree.Build(source, mFocus.Frames, mBuiltSpan);
			else
				mTree.Clear();
		}
		if (!mRowsDirty)
			return;
		mRowsDirty = false;
		mRows.Clear();
		if (source == null)
			return;
		if (mSort == .Name)
		{
			for (let root in mTree.Roots)
				AddTreeRows(root, source);
			return;
		}
		AddFlatRows(source);
	}

	private bool Matches(StringView name)
	{
		if (mFilter.IsEmpty)
			return true;
		return name.Contains(mFilter, true);
	}

	// Whether a node, or one under it, holds the filter's text.
	private bool Shows(uint32 index, IProfileSource source)
	{
		let node = mTree.Nodes[index];
		if (!node.Group && (node.Calls > 0) && Matches(source.NameOf(node.Name)))
			return true; // a node with no call ran only outside the span: shown for its children
		for (let child in node.Children)
		{
			if (Shows(child, source))
				return true;
		}
		return false;
	}

	private bool IsOpen(ScopeNode node)
	{
		var open = node.Group || (node.Depth < cOpenDepth);
		for (let key in mToggled)
		{
			if (key == node.Key)
				open = !open;
		}
		return open || !mFilter.IsEmpty; // a filter opens what it shows
	}

	private void AddTreeRows(uint32 index, IProfileSource source)
	{
		let node = mTree.Nodes[index];
		if (!Shows(index, source))
			return;
		Row row = .();
		row.Node = (int32)index;
		row.Name = node.Name;
		row.Gpu = node.Gpu;
		row.Group = node.Group;
		row.Label = node.Group ? StringView(node.GroupName) : source.NameOf(node.Name);
		row.Depth = node.Depth;
		row.HasChildren = !node.Children.IsEmpty;
		row.Open = IsOpen(node);
		row.Calls = node.Calls;
		row.TotalTicks = node.TotalTicks;
		row.SelfTicks = node.SelfTicks;
		row.MaxTicks = node.MaxTicks;
		mRows.Add(row);
		if (!row.Open)
			return;
		// Children by their total, the longest first.
		let children = scope List<uint32>();
		children.AddRange(node.Children);
		children.Sort(scope (a, b) => mTree.Nodes[b].TotalTicks <=> mTree.Nodes[a].TotalTicks);
		for (let child in children)
			AddTreeRows(child, source);
	}

	private void AddFlatRows(IProfileSource source)
	{
		for (let node in mTree.Nodes)
		{
			if (node.Group || (node.Calls == 0) || !Matches(source.NameOf(node.Name)))
				continue;
			int found = -1;
			for (int i < mRows.Count)
			{
				if ((mRows[i].Name == node.Name) && (mRows[i].Gpu == node.Gpu))
					found = i;
			}
			if (found < 0)
			{
				Row added = .();
				added.Name = node.Name;
				added.Gpu = node.Gpu;
				added.Label = source.NameOf(node.Name);
				mRows.Add(added);
				found = mRows.Count - 1;
			}
			let row = &mRows[found];
			row.Calls += node.Calls;
			row.TotalTicks += node.TotalTicks;
			row.SelfTicks += node.SelfTicks;
			row.MaxTicks = Math.Max(row.MaxTicks, node.MaxTicks);
		}
		let column = mSort;
		let descending = mDescending;
		mRows.Sort(scope (a, b) =>
			{
				let x = Value(a, column);
				let y = Value(b, column);
				if (x != y)
					return descending ? (y <=> x) : (x <=> y);
				return StringView.Compare(a.Label, b.Label, false);
			});
	}

	private static double Value(Row row, ScopeColumn column)
	{
		switch (column)
		{
		case .Calls: return (double)row.Calls;
		case .Self: return (double)row.SelfTicks;
		case .Mean: return (row.Calls > 0) ? ((double)row.TotalTicks / (double)row.Calls) : 0.0;
		case .Max: return (double)row.MaxTicks;
		case .Name, .Total, .Share: return (double)row.TotalTicks;
		}
	}

	// A row's arrow: down when open, toward the name when folded.
	private static void DrawArrow(DrawContext ctx, Float2 at, bool folded, Color color)
	{
		let arrow = scope PathBuilder();
		if (folded)
		{
			arrow.MoveTo(at.X - 2.0f, at.Y - 4.0f);
			arrow.LineTo(at.X + 3.0f, at.Y);
			arrow.LineTo(at.X - 2.0f, at.Y + 4.0f);
		}
		else
		{
			arrow.MoveTo(at.X - 4.0f, at.Y - 2.0f);
			arrow.LineTo(at.X + 4.0f, at.Y - 2.0f);
			arrow.LineTo(at.X, at.Y + 3.0f);
		}
		arrow.Close();
		let path = arrow.ToPath();
		ctx.VG.FillPath(path, color);
		delete path;
	}
}
