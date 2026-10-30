using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

// The frames chosen on one time axis (X7 of Raptor's editor-gui spec): a lane per thread with its
// scopes stacked by depth, the GPU's passes in a lane of their own drawn as the scopes are; the ruler
// (the time from the first frame's start) and the frames' row pinned on top; the lanes' names in a
// column at the start, as wide as the frame strip's gutter. A scope keeps its name's colour in every
// lane. Scopes too narrow to draw are kept, side by side as one hatched block with their count, never
// dropped.
//
// Mouse first: the wheel zooms about the pointer (Shift and the wheel scroll the lanes), a drag pans
// (a middle drag too), a double click zooms to what is under the pointer (a scope; nothing: the frames
// again; a lane's name: the lane's span), Fit in the corner fits the frames. A click on a scope
// chooses its name (on nothing, none): its every instance lit and the rest dimmed, the page's other
// views told. A drag on the ruler marks a span (its length read out), a click there lets it go. A
// click on a lane's arrow folds it to one row. The hover outlines the name's other instances and names
// the scope with its duration.

[GuiReflect(true)]
class ProfileTimeline : ProfilerWidget
{
	/// The lanes' names; the frame strip's gutter.
	public const float cHeaderWidth = 128.0f;
	/// The ruler's ticks and times.
	public const float cTickHeight = 20.0f;
	/// The frames' row under it.
	public const float cFramesHeight = 16.0f;
	public const float cRulerHeight = cTickHeight + cFramesHeight;
	/// A depth of scopes.
	public const float cRowHeight = 18.0f;
	public const float cLaneGap = 6.0f;
	/// Narrower scopes join a hatched block.
	public const float cMinBarWidth = 3.0f;
	/// A lane's arrow, at its name's start.
	public const float cFoldWidth = 18.0f;
	public const float cMinLabelSpacing = 72.0f;
	public const float cDragThreshold = 3.0f;
	/// The GPU's lane, among the threads' indices.
	public const uint32 cGpuLane = ~0U;

	/// A lane. A class: it owns its name.
	public class Lane
	{
		public String Name = new .() ~ delete _;
		public bool Gpu = false;
		/// The thread's index; cGpuLane for the GPU's.
		public uint32 Thread = 0;
		public uint32 Depths = 1;
		public bool Folded = false;
		/// Its top in the view, after the lanes' scroll.
		public float Y = 0.0f;
		public float Height = 0.0f;
	}

	public struct Bar
	{
		/// Its lane's index in Lanes.
		public uint32 LaneIndex = 0;
		public uint32 Depth = 0;
		public uint32 Name = 0;
		public bool Gpu = false;
		public int64 BeginTick = 0;
		public int64 EndTick = 0;
		/// 0: one scope; else the scopes a hatched block holds.
		public uint32 Merged = 0;
		public Rect Box = .();

		public this() { }

		public this(uint32 lane, uint32 depth, uint32 name, bool gpu, int64 beginTick, int64 endTick, uint32 merged, Rect rect)
		{
			LaneIndex = lane;
			Depth = depth;
			Name = name;
			Gpu = gpu;
			BeginTick = beginTick;
			EndTick = endTick;
			Merged = merged;
			Box = rect;
		}
	}

	private enum Drag : uint8
	{
		None,
		/// Pressed in the lanes, not yet past the threshold: a click.
		PendingPan,
		Pan,
		/// Pressed on the ruler: a click lets the span go.
		PendingSpan,
		Span,
	}

	private struct FrameEdge
	{
		public uint64 Frame;
		/// Its start.
		public float X;
		/// Its end.
		public float Next;
		public float Ms;
	}

	// Narrow scopes side by side, gathered into one block.
	private struct Pending
	{
		public Bar Block = .();
		public bool Open = false;

		public this() { }
	}

	private double mViewBegin = 0.0;
	private double mViewEnd = 1.0;
	private float mScrollY = 0.0f;
	private List<uint32> mFolded = new .() ~ delete _;
	private Drag mDrag = .None;
	private Float2 mPressAt = .(0.0f, 0.0f);
	private Float2 mLastAt = .(0.0f, 0.0f);
	private Float2 mPointer = .(0.0f, 0.0f);
	private bool mPointerIn = false;
	private String mTip = new .() ~ delete _;

	// What Compute made, and what it made it from.
	private List<Lane> mLanes = new .() ~ DeleteContainerAndItems!(_);
	private List<Bar> mBars = new .() ~ delete _;
	private List<FrameEdge> mEdges = new .() ~ delete _;
	private int32 mHovered = -1;
	private bool mDirty = true;
	private double mComputedBegin = 0.0;
	private double mComputedEnd = 0.0;
	private float mComputedScroll = 0.0f;
	private float mComputedWidth = -1.0f;
	private float mComputedHeight = -1.0f;

	public this()
	{
		Tag = "profiletimeline";
		TabFocusable = false;
	}

	// === The view ===

	/// The time shown at the plot's start and end, in the source's ticks.
	public double ViewBegin => mViewBegin;
	public double ViewEnd => mViewEnd;

	/// The view back to the frames chosen: the first's start to the last's end or its last GPU pass's,
	/// whichever is later.
	public void FitView()
	{
		mScrollY = 0.0f;
		if (FramesSpan(let begin, let end))
			ZoomTo((double)begin, (double)end);
		else
		{
			mViewBegin = 0.0;
			mViewEnd = 1.0;
			Invalidate();
		}
	}

	/// Shows [begin, end] (ticks), with a sliver of room either side.
	public void ZoomTo(double begin, double end)
	{
		let span = Math.Max(end - begin, MinSpan);
		let room = span * 0.01;
		mViewBegin = begin - room;
		mViewEnd = begin + span + room;
		Invalidate();
	}

	/// Zooms by `factor` (above 1 in) about `x` (its own space): the time under it stays. No closer
	/// than a microsecond across the plot.
	public void ZoomAt(float x, float factor)
	{
		if (factor <= 0.0f)
			return;
		let anchor = TickAt(x);
		let span = Math.Max((mViewEnd - mViewBegin) / (double)factor, MinSpan);
		let plot = PlotBounds;
		let along = (double)((x - plot.X) / Math.Max(plot.Width, 1.0f));
		mViewBegin = anchor - along * span;
		mViewEnd = mViewBegin + span;
		Invalidate();
	}

	/// Moves the view by `dx` pixels (positive shows earlier time) and the lanes by `dy`.
	public void PanBy(float dx, float dy)
	{
		let shift = (double)(dx / Math.Max(PlotBounds.Width, 1.0f)) * (mViewEnd - mViewBegin);
		mViewBegin -= shift;
		mViewEnd -= shift;
		ScrollLanes(-dy);
		Invalidate();
	}

	/// Scrolls the lanes by `dy` pixels (positive shows later lanes), kept over them.
	public void ScrollLanes(float dy)
	{
		mScrollY = Math.Clamp(mScrollY + dy, 0.0f, Math.Max(LanesHeight - (PlotBounds.Height - cRulerHeight), 0.0f));
		Invalidate();
	}

	public float LaneScroll => mScrollY;

	/// The plot (its own space): the content less the names' column.
	public Rect PlotBounds
	{
		get
		{
			let @box = ContentBounds;
			let header = Math.Min(cHeaderWidth, @box.Width);
			return .(@box.X + header, @box.Y, Math.Max(@box.Width - header, 0.0f), @box.Height);
		}
	}

	/// The time at `x` (its own space).
	public double TickAt(float x)
	{
		let plot = PlotBounds;
		return mViewBegin + (double)((x - plot.X) / Math.Max(plot.Width, 1.0f)) * (mViewEnd - mViewBegin);
	}

	/// Where a time is drawn.
	public float XAt(double tick)
	{
		let plot = PlotBounds;
		return plot.X + (float)((tick - mViewBegin) / (mViewEnd - mViewBegin)) * plot.Width;
	}

	// === Lanes ===

	/// Folds a lane to one row (its top scopes as plain activity), or opens it.
	public void SetFolded(uint32 thread, bool folded)
	{
		for (int i < mFolded.Count)
		{
			if (mFolded[i] == thread)
			{
				if (!folded)
					mFolded.RemoveAt(i);
				mDirty = true;
				Invalidate();
				return;
			}
		}
		if (folded)
			mFolded.Add(thread);
		mDirty = true;
		Invalidate();
	}

	public bool IsFolded(uint32 thread) => mFolded.Contains(thread);

	// === The model (the draw and the tests read it) ===

	public Span<Lane> Lanes
	{
		get
		{
			Compute();
			return mLanes;
		}
	}

	public Span<Bar> Bars
	{
		get
		{
			Compute();
			return mBars;
		}
	}

	/// The bar at a point (its own space), or -1: its index in Bars.
	public int32 BarAt(Float2 point)
	{
		Compute();
		if (point.Y < PlotBounds.Y + cRulerHeight)
			return -1;
		for (int i = mBars.Count - 1; i >= 0; i--)
		{
			let r = mBars[i].Box;
			if ((point.X >= r.X - 1.0f) && (point.X <= r.X + Math.Max(r.Width, 1.0f) + 1.0f) && (point.Y >= r.Y) && (point.Y < r.Y + r.Height))
				return (int32)i;
		}
		return -1;
	}

	/// The lane whose name is at a point (its own space), or -1.
	public int32 LaneAt(Float2 point)
	{
		Compute();
		for (int i < mLanes.Count)
		{
			if ((point.Y >= mLanes[i].Y) && (point.Y < mLanes[i].Y + mLanes[i].Height + cLaneGap))
				return (int32)i;
		}
		return -1;
	}

	/// The scope under the pointer (-1: none): its index in Bars.
	public int32 Hovered
	{
		get
		{
			Compute();
			return ((mHovered >= 0) && (mHovered < mBars.Count)) ? mHovered : -1;
		}
	}

	/// Whether a bar is the name chosen's.
	public bool IsChosen(Bar bar) => (bar.Merged == 0) && (mFocus != null) && mFocus.Name.Is(bar.Name, bar.Gpu);

	/// The scope under the pointer named with its duration, else its own tooltip.
	public override StringView TooltipText
	{
		get
		{
			mTip.Clear();
			let source = Source;
			let hovered = Hovered;
			if ((hovered >= 0) && (source != null))
			{
				let bar = mBars[hovered];
				let ms = ProfileWindow.TicksToMs(bar.EndTick - bar.BeginTick, source.TickFrequency);
				if (bar.Merged > 0)
					mTip.AppendF("{0} scopes too short to draw, {1:F3} ms in all: zoom in", bar.Merged, ms);
				else
					mTip.AppendF("{0}  {1:F3} ms", source.NameOf(bar.Name), ms);
				return mTip;
			}
			return base.TooltipText;
		}
	}

	public override void OnProfileSourceChanged()
	{
		mDirty = true;
		Invalidate();
	}

	public override void OnProfileFramesChanged()
	{
		mDirty = true;
		FitView();
	}

	public override void OnProfileChoiceChanged()
	{
		Invalidate();
	}

	public override Sedulous.GUI.Cursor CursorNow => (mDrag == .Pan) ? .Grabbing : base.CursorNow;

	protected override void OnMouseDown(MouseEvent e)
	{
		let at = Local(e.Position);
		let plot = PlotBounds;
		if (e.Button == .Middle)
		{
			e.Handled = true;
			BeginDrag(.Pan, at);
			return;
		}
		if (e.Button != .Left)
			return;
		e.Handled = true;
		if (at.X < plot.X)
		{
			// The corner's Fit, a lane's arrow, a lane's name.
			if (at.Y < plot.Y + cRulerHeight)
			{
				FitView();
				return;
			}
			let lane = LaneAt(at);
			if (lane < 0)
				return;
			let shown = mLanes[lane];
			if (e.ClickCount == 2)
				ZoomToLane(shown);
			else if (at.X < plot.X - cHeaderWidth + cFoldWidth)
				SetFolded(shown.Thread, !shown.Folded);
			return;
		}
		if (at.Y < plot.Y + cRulerHeight)
		{
			BeginDrag(.PendingSpan, at);
			return;
		}
		if (e.ClickCount == 2)
		{
			let bar = BarAt(at);
			if (bar >= 0)
				ZoomTo((double)mBars[bar].BeginTick, (double)mBars[bar].EndTick);
			else
				FitView();
			return;
		}
		BeginDrag(.PendingPan, at);
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let at = Local(e.Position);
		mPointer = at;
		mPointerIn = true;
		let past = (Math.Abs(at.X - mPressAt.X) >= cDragThreshold) || (Math.Abs(at.Y - mPressAt.Y) >= cDragThreshold);
		if ((mDrag == .PendingPan) && past)
			mDrag = .Pan;
		if ((mDrag == .PendingSpan) && past)
			mDrag = .Span;
		if (mDrag == .Pan)
		{
			PanBy(at.X - mLastAt.X, at.Y - mLastAt.Y);
			mLastAt = at;
		}
		else if ((mDrag == .Span) && (mFocus != null))
		{
			// To the nearest tick on either side.
			let from = Math.Max(TickAt(mPressAt.X), 0.0) + 0.5;
			let to = Math.Max(TickAt(at.X), 0.0) + 0.5;
			mFocus.SetSpan((int64)from, (int64)to);
		}
		Hover();
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (e.Button == .Left)
		{
			if ((mDrag == .PendingPan) && (mFocus != null))
			{
				// A click: the name of the scope under it chosen, or none.
				let bar = BarAt(mPressAt);
				if ((bar >= 0) && (mBars[bar].Merged == 0))
					mFocus.ChooseName(mBars[bar].Name, mBars[bar].Gpu);
				else if (bar < 0)
					mFocus.ClearName();
			}
			else if ((mDrag == .PendingSpan) && (mFocus != null))
				mFocus.ClearSpan();
		}
		if ((e.Button == .Left) || ((e.Button == .Middle) && (mDrag == .Pan)))
			mDrag = .None;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mDrag = .None;
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		base.OnMouseLeave(e);
		mPointerIn = false;
		Hover();
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		e.Handled = true;
		if ((e.Modifiers & KeyModShift) != 0)
		{
			ScrollLanes(-((e.Delta.Y != 0.0f) ? e.Delta.Y : e.Delta.X) * cRowHeight * 3.0f);
			return;
		}
		if (e.Delta.Y != 0.0f)
			ZoomAt(Local(e.Position).X, Pow(1.25f, e.Delta.Y));
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		Compute();
		let @box = ContentBounds;
		let plot = PlotBounds;
		let source = Source;
		let separator = PartColor("separator", .(0.5f, 0.5f, 0.5f, 0.25f));
		let edgeColor = PartColor("frame-edge", .(0.6f, 0.6f, 0.6f, 0.8f));
		let dimText = PartTextColor("ruler");
		let barText = PartTextColor("bar");
		let hoverEdge = PartColor("hover", .(1.0f, 1.0f, 1.0f, 0.7f));
		let chosenEdge = PartColor("chosen", .(1.0f, 1.0f, 1.0f, 1.0f));
		let hatch = PartColor("hatch", .(0.55f, 0.57f, 0.62f, 0.35f));
		let activity = PartColor("activity", .(0.44f, 0.53f, 0.72f, 0.4f));
		let choosing = (mFocus != null) && mFocus.Name.Any;
		let hoveredIndex = Hovered;
		let label = scope String();

		// The lanes: their separators, then their scopes.
		ctx.PushClip(.(plot.X, plot.Y + cRulerHeight, plot.Width, Math.Max(plot.Height - cRulerHeight, 0.0f)));
		for (let lane in mLanes)
			ctx.VG.FillRect(.(plot.X, lane.Y + lane.Height + cLaneGap * 0.5f, plot.Width, 1.0f), separator);
		for (let bar in mBars)
		{
			let lane = mLanes[bar.LaneIndex];
			if (bar.Merged > 0)
			{
				DrawHatch(ctx, bar.Box, hatch);
				if (bar.Box.Width > 28.0f)
					DrawLabel(ctx, label..Clear()..AppendF("×{}", bar.Merged), bar.Box, barText, .Center);
				continue;
			}
			let name = (source != null) ? source.NameOf(bar.Name) : StringView();
			var color = lane.Folded ? activity : NameColor(name);
			if (choosing && !IsChosen(bar))
				color.A *= 0.45f;
			ctx.VG.FillRect(bar.Box.ToRectangle(), color);
			if (IsChosen(bar))
				ctx.VG.StrokeRect(bar.Box.ToRectangle(), chosenEdge, 1.0f);
			else if ((hoveredIndex >= 0) && (mBars[hoveredIndex].Merged == 0) && (mBars[hoveredIndex].Name == bar.Name) && (mBars[hoveredIndex].Gpu == bar.Gpu))
				ctx.VG.StrokeRect(bar.Box.ToRectangle(), hoverEdge, 1.0f);
			if (!lane.Folded && (bar.Box.Width > 24.0f))
			{
				let ms = ProfileWindow.TicksToMs(bar.EndTick - bar.BeginTick, source.TickFrequency);
				label.Clear();
				label.AppendF("{0}  {1:F2} ms", name, ms);
				let roomy = LabelWidth(label) + 8.0f < bar.Box.Width;
				var text = barText;
				if (choosing && !IsChosen(bar))
					text.A *= 0.6f;
				DrawLabel(ctx, roomy ? (StringView)label : name, .(bar.Box.X + 4.0f, bar.Box.Y, bar.Box.Width - 8.0f, bar.Box.Height), text, .Center);
			}
		}
		ctx.PopClip();

		// The frames' edges, down the ruler's foot and the lanes; the span marked.
		ctx.PushClip(.(plot.X, plot.Y + cTickHeight, plot.Width, Math.Max(plot.Height - cTickHeight, 0.0f)));
		for (let edge in mEdges)
			ctx.VG.FillRect(.(Floor(edge.X), plot.Y + cTickHeight, 1.0f, plot.Height - cTickHeight), edgeColor);
		ctx.PopClip();
		ctx.PushClip(plot);
		if ((mFocus != null) && mFocus.Span.Any)
		{
			let span = mFocus.Span;
			let x0 = XAt((double)span.BeginTick);
			let x1 = XAt((double)span.EndTick);
			ctx.VG.FillRect(.(x0, plot.Y, x1 - x0, plot.Height), PartColor("span", .(0.18f, 0.43f, 0.87f, 0.12f)));
			let spanEdge = PartColor("span-edge", .(0.18f, 0.43f, 0.87f, 1.0f));
			ctx.VG.FillRect(.(Floor(x0), plot.Y, 1.0f, plot.Height), spanEdge);
			ctx.VG.FillRect(.(Floor(x1), plot.Y, 1.0f, plot.Height), spanEdge);
		}
		ctx.PopClip();

		// The ruler: its ticks and times, the span's length, the frames' numbers.
		ctx.VG.FillRect(.(plot.X, plot.Y, plot.Width, cRulerHeight), PartColor("ruler", .(0.0f, 0.0f, 0.0f, 0.15f)));
		ctx.PushClip(.(plot.X, plot.Y, plot.Width, cRulerHeight));
		DrawTicks(ctx, plot, dimText);
		if ((mFocus != null) && mFocus.Span.Any && (source != null))
		{
			let span = mFocus.Span;
			let x0 = XAt((double)span.BeginTick);
			let x1 = XAt((double)span.EndTick);
			ctx.VG.FillRect(.(x0, plot.Y, x1 - x0, cTickHeight), PartColor("span-head", .(0.18f, 0.43f, 0.87f, 0.35f)));
			label.Clear();
			label.AppendF("{0:F2} ms", ProfileWindow.TicksToMs(span.EndTick - span.BeginTick, source.TickFrequency));
			DrawLabel(ctx, label, .(x0, plot.Y, Math.Max(x1 - x0, LabelWidth(label) + 8.0f), cTickHeight), PartTextColor("span-head"), .Center);
		}
		for (let edge in mEdges)
		{
			let room = edge.Next - edge.X;
			if ((room < 30.0f) || (source == null))
				continue;
			label.Clear();
			if (room > 150.0f)
				label.AppendF("Frame {0}  {1:F2} ms", edge.Frame, edge.Ms);
			else
				label.AppendF("{}", edge.Frame);
			let x = Math.Max(edge.X, plot.X) + 3.0f;
			DrawLabel(ctx, label, .(x, plot.Y + cTickHeight, Math.Min(edge.Next, plot.Right) - x - 3.0f, cFramesHeight), PartTextColor("frame"));
		}
		ctx.PopClip();

		// The names' column over everything: the corner's Fit, then each lane's arrow and name.
		let header = Rect(@box.X, @box.Y, plot.X - @box.X, @box.Height);
		ctx.VG.FillRect(header.ToRectangle(), PartColor("header", .(0.0f, 0.0f, 0.0f, 0.1f)));
		ctx.VG.FillRect(.(plot.X - 1.0f, @box.Y, 1.0f, @box.Height), separator);
		DrawLabel(ctx, "Fit", .(header.X, header.Y, header.Width, cRulerHeight), PartTextColor("fit"), .Center);
		ctx.VG.FillRect(.(header.X, plot.Y + cRulerHeight - 1.0f, header.Width, 1.0f), separator);
		ctx.PushClip(.(header.X, plot.Y + cRulerHeight, header.Width, Math.Max(header.Height - cRulerHeight, 0.0f)));
		let fold = PartColor("fold", dimText);
		for (let lane in mLanes)
		{
			DrawArrow(ctx, .(header.X + 9.0f, lane.Y + cRowHeight * 0.5f), lane.Folded, fold);
			DrawLabel(ctx, lane.Name, .(header.X + cFoldWidth, lane.Y, header.Width - cFoldWidth - 4.0f, cRowHeight),
				PartTextColor(lane.Gpu ? "gpu-name" : "lane-name"));
		}
		ctx.PopClip();
	}

	private double MinSpan
	{
		get
		{
			let source = Source;
			return Math.Max((source != null) ? ((double)source.TickFrequency / 1.0e6) : 1.0, 1.0e-9);
		}
	}

	// The frames chosen's span in ticks; false when none has a record.
	private bool FramesSpan(out int64 begin, out int64 end)
	{
		begin = 0;
		end = 0;
		let source = Source;
		let frames = (mFocus != null) ? mFocus.Frames : FrameRange();
		var any = false;
		for (uint64 n = frames.First; (source != null) && !frames.Empty && (n <= frames.Last); n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			var last = frame.EndTick;
			for (let pass in frame.Gpu)
				last = Math.Max(last, pass.EndTick);
			begin = any ? Math.Min(begin, frame.BeginTick) : frame.BeginTick;
			end = any ? Math.Max(end, last) : last;
			any = true;
		}
		return any;
	}

	private void ZoomToLane(Lane lane)
	{
		var any = false;
		var begin = 0.0;
		var end = 0.0;
		let bars = scope List<Bar>();
		AllBarsOf(lane, bars);
		for (let bar in bars)
		{
			begin = any ? Math.Min(begin, (double)bar.BeginTick) : (double)bar.BeginTick;
			end = any ? Math.Max(end, (double)bar.EndTick) : (double)bar.EndTick;
			any = true;
		}
		if (any)
			ZoomTo(begin, end);
	}

	// Every scope of a lane in the frames chosen, in view or not.
	private void AllBarsOf(Lane lane, List<Bar> outBars)
	{
		let source = Source;
		let frames = (mFocus != null) ? mFocus.Frames : FrameRange();
		for (uint64 n = frames.First; (source != null) && !frames.Empty && (n <= frames.Last); n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			if (lane.Gpu)
			{
				for (let pass in frame.Gpu)
					outBars.Add(.(0, pass.Depth, pass.Name, true, pass.BeginTick, pass.EndTick, 0, .()));
			}
			else
			{
				for (let thread in frame.Threads)
				{
					if (thread.Thread != lane.Thread)
						continue;
					for (let scopeEvent in thread.Scopes)
						outBars.Add(.(0, scopeEvent.Depth, scopeEvent.Name, false, scopeEvent.BeginTick, scopeEvent.EndTick, 0, .()));
				}
			}
		}
	}

	private void BeginDrag(Drag drag, Float2 at)
	{
		mDrag = drag;
		mPressAt = at;
		mLastAt = at;
	}

	private void Hover()
	{
		let hovered = mPointerIn ? BarAt(mPointer) : -1;
		if (hovered != mHovered)
		{
			mHovered = hovered;
			Invalidate();
		}
	}

	private float LanesHeight
	{
		get
		{
			Compute();
			var height = cLaneGap;
			for (let lane in mLanes)
				height += lane.Height + cLaneGap;
			return height;
		}
	}

	// The lanes, their scopes in view and the frames' edges, from the frames chosen.
	private void Compute()
	{
		let plot = PlotBounds;
		let bounds = ContentBounds;
		let same = !mDirty && (mComputedBegin == mViewBegin) && (mComputedEnd == mViewEnd) && (mComputedScroll == mScrollY)
			&& (mComputedWidth == bounds.Width) && (mComputedHeight == bounds.Height);
		if (same)
			return;
		mDirty = false;
		mComputedBegin = mViewBegin;
		mComputedEnd = mViewEnd;
		mComputedScroll = mScrollY;
		mComputedWidth = bounds.Width;
		mComputedHeight = bounds.Height;
		ClearAndDeleteItems!(mLanes);
		mBars.Clear();
		mEdges.Clear();
		let source = Source;
		let frames = (mFocus != null) ? mFocus.Frames : FrameRange();
		if ((source == null) || frames.Empty || (plot.Width <= 0.0f))
		{
			mHovered = -1;
			return;
		}
		// The lanes: each thread with a scope in the frames, in the threads' order, then the GPU.
		uint32 gpuDepths = 0;
		var anyGpu = false;
		for (uint64 n = frames.First; n <= frames.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			for (let thread in frame.Threads)
			{
				if (thread.Scopes.IsEmpty)
					continue;
				let lane = LaneFor(thread.Thread, source);
				for (let scopeEvent in thread.Scopes)
					lane.Depths = Math.Max(lane.Depths, scopeEvent.Depth + 1);
			}
			for (let pass in frame.Gpu)
			{
				anyGpu = true;
				gpuDepths = Math.Max(gpuDepths, pass.Depth + 1);
			}
		}
		if (anyGpu)
		{
			let gpu = new Lane();
			gpu.Name.Set("GPU");
			gpu.Gpu = true;
			gpu.Thread = cGpuLane;
			gpu.Depths = Math.Max(gpuDepths, 1);
			mLanes.Add(gpu);
		}
		var y = plot.Y + cRulerHeight + cLaneGap - mScrollY;
		for (let lane in mLanes)
		{
			lane.Folded = IsFolded(lane.Thread);
			lane.Y = y;
			lane.Height = (float)(lane.Folded ? 1 : lane.Depths) * cRowHeight;
			y += lane.Height + cLaneGap;
		}
		// The scopes in view, a lane and a depth at a time so narrow ones join their neighbours.
		for (uint32 l < (uint32)mLanes.Count)
		{
			let lane = mLanes[l];
			for (uint32 depth < (lane.Folded ? 1 : lane.Depths))
			{
				var pending = Pending();
				for (uint64 n = frames.First; n <= frames.Last; n++)
				{
					let frame = source.Frame(n);
					if (frame == null)
						continue;
					if (lane.Gpu)
					{
						for (let pass in frame.Gpu)
						{
							if (pass.Depth == depth)
								Place(ref pending, l, depth, pass.Name, true, pass.BeginTick, pass.EndTick);
						}
					}
					else
					{
						for (let thread in frame.Threads)
						{
							if (thread.Thread != lane.Thread)
								continue;
							for (let scopeEvent in thread.Scopes)
							{
								if (scopeEvent.Depth == depth)
									Place(ref pending, l, depth, scopeEvent.Name, false, scopeEvent.BeginTick, scopeEvent.EndTick);
							}
						}
					}
				}
				Flush(ref pending);
			}
		}
		for (uint64 n = frames.First; n <= frames.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			var edge = FrameEdge();
			edge.Frame = n;
			edge.X = XAt((double)frame.BeginTick);
			edge.Next = XAt((double)frame.EndTick);
			edge.Ms = ProfileWindow.TicksToMs(frame.EndTick - frame.BeginTick, source.TickFrequency);
			if ((edge.Next >= plot.X) && (edge.X <= plot.Right))
				mEdges.Add(edge);
		}
		// The bars are new: the one under the pointer is found again.
		mHovered = -1;
		if (mPointerIn && (mPointer.Y >= plot.Y + cRulerHeight))
		{
			for (int i = mBars.Count - 1; (i >= 0) && (mHovered < 0); i--)
			{
				let r = mBars[i].Box;
				if ((mPointer.X >= r.X - 1.0f) && (mPointer.X <= r.X + Math.Max(r.Width, 1.0f) + 1.0f) && (mPointer.Y >= r.Y) && (mPointer.Y < r.Y + r.Height))
					mHovered = (int32)i;
			}
		}
	}

	private void Place(ref Pending pending, uint32 lane, uint32 depth, uint32 name, bool gpu, int64 begin, int64 end)
	{
		let plot = PlotBounds;
		let x0 = XAt((double)begin);
		let x1 = XAt((double)end);
		if ((x1 < plot.X) || (x0 > plot.Right))
			return;
		let top = mLanes[lane].Y + (float)depth * cRowHeight + 1.0f;
		if (x1 - x0 >= cMinBarWidth)
		{
			Flush(ref pending);
			let left = Math.Max(x0, plot.X - 2.0f);
			mBars.Add(.(lane, depth, name, gpu, begin, end, 0, .(left, top, Math.Min(x1, plot.Right + 2.0f) - left, cRowHeight - 2.0f)));
			return;
		}
		if (pending.Open && (x0 - pending.Block.Box.Right <= 2.0f))
		{
			pending.Block.EndTick = Math.Max(pending.Block.EndTick, end);
			pending.Block.Box.Width = Math.Max(pending.Block.Box.Width, x1 - pending.Block.Box.X);
			pending.Block.Merged++;
			return;
		}
		Flush(ref pending);
		pending.Open = true;
		pending.Block = .(lane, depth, name, gpu, begin, end, 1, .(x0, top, x1 - x0, cRowHeight - 2.0f));
	}

	private void Flush(ref Pending pending)
	{
		if (!pending.Open)
			return;
		pending.Open = false;
		var block = pending.Block;
		block.Box.Width = Math.Max(block.Box.Width, 1.0f);
		if (block.Merged == 1)
			block.Merged = 0; // one narrow scope alone: a thin bar of its own
		mBars.Add(block);
	}

	private Lane LaneFor(uint32 thread, IProfileSource source)
	{
		int at = 0;
		while ((at < mLanes.Count) && (mLanes[at].Thread < thread))
			at++;
		if ((at < mLanes.Count) && (mLanes[at].Thread == thread))
			return mLanes[at];
		let lane = new Lane();
		lane.Thread = thread;
		for (let info in source.Threads)
		{
			if (info.Index == thread)
				lane.Name.Set(info.Name);
		}
		if (lane.Name.IsEmpty)
			lane.Name.AppendF("Thread {}", thread);
		mLanes.Insert(at, lane);
		return lane;
	}

	// The ruler's ticks: a step of 1, 2 or 5 times a power of ten of ms, at least the label spacing
	// apart, labelled from the first frame's start.
	private void DrawTicks(DrawContext ctx, Rect plot, Color text)
	{
		let source = Source;
		if (source == null)
			return;
		if (!FramesSpan(let origin, ?))
			return;
		let msPerPixel = (mViewEnd - mViewBegin) / (double)source.TickFrequency * 1000.0 / (double)Math.Max(plot.Width, 1.0f);
		let step = PickStep((float)(msPerPixel * cMinLabelSpacing));
		let ticksPerMs = (double)source.TickFrequency / 1000.0;
		let firstMs = (mViewBegin - (double)origin) / ticksPerMs;
		let lastMs = (mViewEnd - (double)origin) / ticksPerMs;
		let tick = PartColor("tick", text);
		let label = scope String();
		for (int64 i = (int64)(firstMs / (double)step) - 1; (double)i * (double)step <= lastMs; i++)
		{
			let ms = (double)i * (double)step;
			let x = XAt((double)origin + ms * ticksPerMs);
			ctx.VG.FillRect(.(Floor(x), plot.Y + cTickHeight * 0.5f, 1.0f, cTickHeight * 0.5f), tick);
			label.Clear();
			FormatStep((float)ms, step, label);
			label.Append(" ms");
			DrawLabel(ctx, label, .(x + 3.0f, plot.Y, cMinLabelSpacing, cTickHeight * 0.6f), text);
		}
	}

	// `ms` to the decimals of `step`, appended.
	private static void FormatStep(float ms, float step, String outText)
	{
		int32 decimals = 0;
		for (var s = step; (s < 0.999f) && (decimals < 6); s *= 10.0f)
			decimals++;
		outText.AppendF(scope String()..AppendF("{{0:F{}}}", decimals), ms);
	}

	private static float PickStep(float least)
	{
		if (least <= 0.0f)
			return 1.0f;
		let magnitude = Pow(10.0f, Floor(Log(least) / Log(10.0f)));
		for (let m in float[4](1.0f, 2.0f, 5.0f, 10.0f))
		{
			if (m * magnitude >= least * 0.9999f)
				return m * magnitude;
		}
		return 10.0f * magnitude;
	}

	// A block of scopes too narrow to draw: diagonal strokes over a faint fill.
	private static void DrawHatch(DrawContext ctx, Rect r, Color color)
	{
		ctx.VG.FillRect(r.ToRectangle(), color);
		ctx.PushClip(r);
		var stroke = color;
		stroke.A = Math.Min(color.A * 2.0f, 1.0f);
		for (var x = r.X - r.Height; x < r.Right; x += 5.0f)
			ctx.VG.DrawLine(.(x, r.Bottom), .(x + r.Height, r.Y), stroke, 1.0f);
		ctx.PopClip();
	}

	// A lane's arrow: down when open, toward the name when folded.
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
