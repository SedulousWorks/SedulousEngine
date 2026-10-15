using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The selected frames on one time axis: a lane per thread with its scopes stacked by depth, a
/// GPU lane with its passes, the frames' edges as lines. The wheel zooms about the pointer (the
/// time under it stays put), a drag pans, Shift and the wheel scroll the lanes, a double click
/// fits the selection again, and hovering a bar names it with its duration. A name the scope
/// table selects is highlighted wherever it ran. What it lays out (the lanes, the bars) is its
/// model, which the draw and the tests read.
class Timeline : ProfilerView
{
	/// The lanes' names.
	public const float HeaderWidth = 96.0f;
	/// The frames' numbers.
	public const float RulerHeight = 18.0f;
	/// A depth of scopes.
	public const float RowHeight = 16.0f;
	public const float LaneGap = 6.0f;
	/// Narrower bars are not drawn.
	public const float MinBarWidth = 0.25f;

	public class Lane
	{
		public String Name = new .() ~ delete _;
		public bool Gpu;
		/// The thread's index (CPU lanes).
		public uint32 Thread;
		/// Rows of scopes.
		public uint32 Depths = 1;
		/// Top, in the view (after the lanes' scroll).
		public float Y;
		public float Height;
	}

	public struct Bar
	{
		public uint32 Lane;
		public uint32 Depth;
		public uint32 Name;
		public bool Gpu;
		public int64 BeginTick;
		public int64 EndTick;
		/// In the view.
		public Rectangle Rect;
	}

	private List<Lane> mLanes = new .() ~ DeleteContainerAndItems!(_);
	private List<Bar> mBars = new .() ~ delete _;
	private List<float> mFrameEdges = new .() ~ delete _;
	private FrameRange mFrames = .();
	private double mViewBegin;
	private double mViewEnd = 1.0;
	private float mScrollY;
	private int mHovered = -1;
	/// Where the pointer last was over the view, and whether it still is: the hovered bar is
	/// found again from it whenever the bars are rebuilt (a frame scrolls by, the view zooms),
	/// where a kept index would name whatever bar now has it.
	private Float2 mPointer;
	private bool mPointerIn;
	private bool mPanning;
	private float mLastX;
	private uint32 mHighlight;
	private bool mHighlightGpu;
	private bool mHighlighting;

	public this()
	{
		IsHitTestVisible = true; // it zooms, pans and hovers
	}

	public override bool OwnsPressDrag => true;

	/// Shows these frames, the whole span in view.
	public FrameRange Frames
	{
		get => mFrames;
		set
		{
			mFrames = value;
			FitView();
			Refresh();
		}
	}

	/// The view back to the selected frames' whole span: from the first frame's start to the
	/// last frame's end or its last GPU pass's, whichever is later.
	public void FitView()
	{
		let source = SourceOrEmpty;
		mViewBegin = 0.0;
		mViewEnd = 1.0;
		mScrollY = 0.0f;
		if (mFrames.Empty)
			return;
		var any = false;
		for (var n = mFrames.First; n <= mFrames.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			let begin = (double)frame.BeginTick;
			var end = (double)frame.EndTick;
			for (let pass in frame.Gpu)
				end = Math.Max(end, (double)pass.EndTick);
			mViewBegin = any ? Math.Min(mViewBegin, begin) : begin;
			mViewEnd = any ? Math.Max(mViewEnd, end) : end;
			any = true;
		}
		if (mViewEnd <= mViewBegin)
			mViewEnd = mViewBegin + 1.0;
	}

	/// The time (in the source's ticks) shown at `x`, and where a time shows.
	public double TickAt(float x) => mViewBegin + (double)((x - HeaderWidth) / PlotWidth) * (mViewEnd - mViewBegin);
	public float XAt(double tick) => HeaderWidth + (float)((tick - mViewBegin) / (mViewEnd - mViewBegin)) * PlotWidth;
	public double ViewBegin => mViewBegin;
	public double ViewEnd => mViewEnd;

	/// Zooms by `factor` (above one in) about `x`: the time under it stays under it. No closer
	/// than a microsecond across the plot.
	public void ZoomAt(float x, float factor)
	{
		if (factor <= 0.0f)
			return;
		let anchor = TickAt(x);
		let minimum = (double)SourceOrEmpty.TickFrequency / 1.0e6;
		let span = Math.Max((mViewEnd - mViewBegin) / (double)factor, Math.Max(minimum, 1.0e-9));
		let along = (double)((x - HeaderWidth) / PlotWidth);
		mViewBegin = anchor - along * span;
		mViewEnd = mViewBegin + span;
		Refresh();
	}

	/// Moves the view by `dx` view units (positive shows earlier time).
	public void PanBy(float dx)
	{
		let shift = (double)(dx / PlotWidth) * (mViewEnd - mViewBegin);
		mViewBegin -= shift;
		mViewEnd -= shift;
		Refresh();
	}

	/// Highlights every bar of `name` in the CPU scopes or the GPU passes; none with
	/// ClearHighlight.
	public void SetHighlight(uint32 name, bool gpu)
	{
		mHighlight = name;
		mHighlightGpu = gpu;
		mHighlighting = true;
		InvalidateVisual();
	}

	public void ClearHighlight()
	{
		mHighlighting = false;
		InvalidateVisual();
	}

	public bool IsHighlighted(Bar bar) => mHighlighting && (bar.Name == mHighlight) && (bar.Gpu == mHighlightGpu);

	/// The model: the lanes and the bars in view, the frames' edges, the bar under the pointer.
	public Span<Lane> Lanes => mLanes;
	public Span<Bar> Bars => mBars;
	public Span<float> FrameEdges => mFrameEdges;
	public Bar? Hovered => ((mHovered >= 0) && (mHovered < mBars.Count)) ? mBars[mHovered] : null;

	/// The index of the bar at a point in the view, or -1.
	public int BarAt(Float2 point)
	{
		for (int i = mBars.Count - 1; i >= 0; i--)
		{
			let r = mBars[i].Rect;
			if ((point.X >= r.X) && (point.X <= r.X + Math.Max(r.Width, 2.0f)) && (point.Y >= r.Y) && (point.Y < r.Y + r.Height))
				return i;
		}
		return -1;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (e.Modifiers.HasFlag(.Shift))
		{
			mScrollY = Math.Max(mScrollY - e.DeltaY * RowHeight * 3.0f, 0.0f);
			Refresh();
		}
		else if (e.DeltaY != 0.0f)
		{
			ZoomAt(e.X, (e.DeltaY > 0.0f) ? 1.25f : 0.8f);
		}
		e.Handled = true;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;
		if (e.ClickCount >= 2)
		{
			FitView(); // a double click: the whole selection again
			Refresh();
			e.Handled = true;
			return;
		}
		mPanning = true;
		mLastX = e.X;
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mPanning)
		{
			PanBy(e.X - mLastX);
			mLastX = e.X;
			e.Handled = true;
			return;
		}
		mPointer = .(e.X, e.Y);
		mPointerIn = true;
		let hovered = BarAt(mPointer);
		if (hovered != mHovered)
		{
			mHovered = hovered;
			InvalidateVisual();
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (!mPanning)
			return;
		mPanning = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();
		e.Handled = true;
	}

	public override void OnMouseLeave()
	{
		mPointerIn = false;
		if (mHovered >= 0)
		{
			mHovered = -1;
			InvalidateVisual();
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		Compute(); // the size may have changed since the last refresh
		let w = Width;
		let h = Height;
		let vg = ctx.VG;
		vg.FillRect(.(0, 0, w, h), Palette.Plot);
		ctx.PushClip(.(0, 0, w, h));
		for (let lane in mLanes)
		{
			vg.DrawLine(.(0, lane.Y - LaneGap * 0.5f), .(w, lane.Y - LaneGap * 0.5f), Palette.Grid, 1.0f);
			DrawLabel(ctx, lane.Name, .(4, lane.Y, HeaderWidth - 8, RowHeight), lane.Gpu ? Palette.Gpu : Palette.Dim);
		}
		ctx.PushClip(.(HeaderWidth, 0, PlotWidth, h));
		for (let x in mFrameEdges)
			vg.DrawLine(.(x, 0), .(x, h), Palette.Budget, 1.0f);
		let source = SourceOrEmpty;
		for (let bar in mBars)
		{
			var color = BarColor(bar);
			if (mHighlighting && !IsHighlighted(bar))
				color.A *= 0.35f;
			vg.FillRect(bar.Rect, color);
			if (IsHighlighted(bar))
				vg.StrokeRect(bar.Rect, Palette.Highlight, 1.0f);
			if (bar.Rect.Width > 40.0f)
				DrawLabel(ctx, source.NameOf(bar.Name), .(bar.Rect.X + 3, bar.Rect.Y, bar.Rect.Width - 6, bar.Rect.Height), Palette.Text);
		}
		ctx.PopClip();
		vg.FillRect(.(HeaderWidth, 0, PlotWidth, RulerHeight), Palette.Panel);
		DrawRuler(ctx);
		if (let bar = Hovered)
		{
			let info = scope String();
			info.AppendF("{}  {:F3} ms  {}", source.NameOf(bar.Name), ProfileWindow.TicksToMs(bar.EndTick - bar.BeginTick, source.TickFrequency),
				bar.Gpu ? "GPU" : "CPU");
			let infoBox = Rectangle(Math.Max(w - 320.0f, HeaderWidth), RulerHeight + 2, 316, RowHeight + 4);
			vg.FillRoundedRect(infoBox, 3.0f, Palette.Panel);
			DrawLabel(ctx, info, .(infoBox.X + 6, infoBox.Y + 2, infoBox.Width - 12, RowHeight), Palette.Text);
		}
		ctx.PopClip();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(600.0f), constraints.ConstrainHeight(240.0f));
	}

	protected override void Compute()
	{
		ClearAndDeleteItems(mLanes);
		mBars.Clear();
		mFrameEdges.Clear();
		mHovered = -1;
		let source = SourceOrEmpty;
		if (mFrames.Empty || (Width - HeaderWidth <= 0.0f))
			return;
		// The lanes: each thread with a scope in the frames, in thread order, then the GPU.
		uint32 gpuDepths = 0;
		var anyGpu = false;
		for (var n = mFrames.First; n <= mFrames.Last; n++)
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
			gpu.Depths = Math.Max(gpuDepths, 1);
			mLanes.Add(gpu);
		}
		var y = RulerHeight + LaneGap - mScrollY;
		for (let lane in mLanes)
		{
			lane.Y = y;
			lane.Height = (float)lane.Depths * RowHeight;
			y += lane.Height + LaneGap;
		}
		// The bars in view, and the frames' edges.
		for (var n = mFrames.First; n <= mFrames.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			let edge = XAt((double)frame.BeginTick);
			if ((edge >= HeaderWidth) && (edge <= Width))
				mFrameEdges.Add(edge);
			for (let thread in frame.Threads)
			{
				let lane = LaneIndexOf(thread.Thread);
				for (let scopeEvent in thread.Scopes)
					AddBar(lane, scopeEvent.Depth, scopeEvent.Name, false, scopeEvent.BeginTick, scopeEvent.EndTick);
			}
			if (anyGpu)
			{
				for (let pass in frame.Gpu)
					AddBar((uint32)(mLanes.Count - 1), pass.Depth, pass.Name, true, pass.BeginTick, pass.EndTick);
			}
		}
		mHovered = mPointerIn ? BarAt(mPointer) : -1;
	}

	private float PlotWidth => Math.Max(Width - HeaderWidth, 1.0f);

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

	private uint32 LaneIndexOf(uint32 thread)
	{
		for (int i < mLanes.Count)
		{
			if (!mLanes[i].Gpu && (mLanes[i].Thread == thread))
				return (uint32)i;
		}
		return 0;
	}

	private void AddBar(uint32 lane, uint32 depth, uint32 name, bool gpu, int64 begin, int64 end)
	{
		let x0 = Math.Max(XAt((double)begin), HeaderWidth);
		let x1 = Math.Min(XAt((double)end), Width);
		if ((x1 < HeaderWidth) || (x0 > Width) || (x1 - x0 < MinBarWidth) || (lane >= (uint32)mLanes.Count))
			return;
		var bar = Bar();
		bar.Lane = lane;
		bar.Depth = depth;
		bar.Name = name;
		bar.Gpu = gpu;
		bar.BeginTick = begin;
		bar.EndTick = end;
		bar.Rect = .(x0, mLanes[(int)lane].Y + (float)depth * RowHeight, x1 - x0, RowHeight - 1.0f);
		mBars.Add(bar);
	}

	/// A name keeps its colour: a shade of the lane's hue picked by the name.
	private Color BarColor(Bar bar)
	{
		let shade = 0.70f + 0.30f * (float)((bar.Name * 2654435761U) % 7U) / 6.0f;
		let baseColor = bar.Gpu ? Palette.Gpu : Palette.Cpu;
		return .(baseColor.R * shade, baseColor.G * shade, baseColor.B * shade, 0.85f);
	}

	/// The frames' numbers along the top, at their edges.
	private void DrawRuler(UIDrawContext ctx)
	{
		if (mFrames.Empty)
			return;
		let source = SourceOrEmpty;
		let label = scope String();
		for (var n = mFrames.First; n <= mFrames.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			let x = XAt((double)frame.BeginTick);
			let next = XAt((double)frame.EndTick);
			if ((next < HeaderWidth) || (x > Width) || (next - x < 36.0f))
				continue;
			label.Clear();
			label.AppendF("#{}  {:F2} ms", n, ProfileWindow.TicksToMs(frame.EndTick - frame.BeginTick, source.TickFrequency));
			let left = Math.Max(x, HeaderWidth);
			DrawLabel(ctx, label, .(left + 3, 0, next - left - 6, RulerHeight), Palette.Dim);
		}
	}
}
