using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

// The frames, side by side (X7 of Raptor's editor-gui spec): the frame strip and the counters' plots
// under it, on one FrameAxis so they show the same frames at the same places. The strip's bars are
// each frame's CPU time against a budget (within it, over it, over twice it), on a scale with its
// values printed (twice the budget; the frames shown's longest without one), a bar past the scale
// clipped and marked; the frames chosen in the accent, boxed; the name chosen (a scope or a pass)
// drawn inside each bar as its share of the frame. A counter's plot is its value each frame between
// the least and the most shown, which it prints. More frames than pixels share a column, which shows
// the longest of them (a hitch never hidden by its neighbours).
//
// Mouse first, on any of them: a click chooses a frame, a drag a range; the wheel zooms about the
// pointer and a middle drag pans; a double click shows every frame again. While the axis fits (until
// a zoom or a pan) it follows the source's frames as they grow.

/// What a frame axis tells the views on it.
interface IFrameAxisClient
{
	void OnFrameAxisChanged();
}

/// The frames a strip and its plots show: the frame at their start and how many across.
class FrameAxis : RefCounted
{
	/// Never fewer frames across than this (a zoom stops there).
	public const double cMinFrames = 8.0;

	private double mFirst = 0.0;
	private double mCount = 1.0;
	private double mOldest = 0.0;
	private double mNewest = 0.0;
	private bool mAny = false;
	private bool mFits = true;
	/// Not owned: each view leaves as it goes.
	private List<IFrameAxisClient> mClients = new .() ~ delete _;

	/// The frame number at the views' start (fractional: a pan moves by less than a frame).
	public double First => mFirst;
	/// How many frames lie across the views.
	public double Count => mCount;
	/// Whether it shows every frame of the source, following them as they grow.
	public bool Fits => mFits;

	/// Shows [oldest, newest], and keeps doing so as Track is told of more.
	public void Fit(uint64 oldest, uint64 newest)
	{
		mFits = true;
		Show((double)oldest, (double)(Math.Max(newest, oldest) - oldest + 1));
	}

	/// The source's frames now: while it fits, it shows them all.
	public void Track(IProfileSource source)
	{
		mAny = (source != null) && source.HasFrames;
		mOldest = mAny ? (double)source.OldestFrame : 0.0;
		mNewest = mAny ? (double)source.NewestFrame : 0.0;
		if (mFits)
			Show(mOldest, mAny ? (mNewest - mOldest + 1.0) : 1.0);
	}

	/// Zooms by `factor` (above 1 in) about `frame`, which stays where it is: no closer than
	/// cMinFrames across, no further than every frame.
	public void ZoomAbout(double frame, double factor)
	{
		if (factor <= 0.0)
			return;
		let along = (frame - mFirst) / mCount;
		let most = mAny ? Math.Max(mNewest - mOldest + 1.0, cMinFrames) : mCount;
		let count = Math.Clamp(mCount / factor, cMinFrames, most);
		mFits = false;
		Show(frame - along * count, count);
	}

	/// Moves by `frames` (positive shows later ones), kept over the source's frames.
	public void PanBy(double frames)
	{
		mFits = false;
		Show(mFirst + frames, mCount);
	}

	/// The whole frame number at or below `frame` (frame numbers are far past float's whole range).
	public static double Whole(double frame)
	{
		let truncated = (double)(int64)frame;
		return (truncated > frame) ? (truncated - 1.0) : truncated;
	}

	/// The frame at `offset` pixels into a view `width` wide.
	public double FrameAt(float offset, float width) => mFirst + (double)offset / (double)Math.Max(width, 1.0f) * mCount;
	/// Where a frame's start is in a view `width` wide.
	public float OffsetOf(double frame, float width) => (float)((frame - mFirst) / mCount * (double)width);

	public void Join(IFrameAxisClient client)
	{
		mClients.Add(client);
	}

	public void Leave(IFrameAxisClient client)
	{
		for (int i < mClients.Count)
		{
			if (mClients[i] === client)
			{
				mClients.RemoveAt(i);
				return;
			}
		}
	}

	private void Show(double first, double count)
	{
		var first;
		var count;
		count = Math.Max(count, 1.0);
		if (mAny)
		{
			let end = mNewest + 1.0;
			first = Math.Clamp(first, mOldest, Math.Max(mOldest, end - count));
		}
		if ((first == mFirst) && (count == mCount))
			return;
		mFirst = first;
		mCount = count;
		for (let client in mClients)
			client.OnFrameAxisChanged();
	}
}

/// A column of a strip or a plot: the frames it shows (one, or the several sharing a pixel) and where
/// it is drawn.
struct FrameColumn
{
	public uint64 First = 0;
	public uint64 Last = 0;
	/// From the plot's start.
	public float X = 0.0f;
	public float Width = 0.0f;

	public this() { }
}

/// What a strip and a plot share: the axis, the gutter at their start (the scale, a counter's name)
/// and the gestures.
[GuiReflect]
abstract class FrameAxisView : ProfilerWidget, IFrameAxisClient
{
	/// The gutter at the start: the scale's values, a counter's name. The timeline's lane names are as
	/// wide, so the page's columns line up.
	public const float cGutterWidth = 128.0f;
	public const float cDragThreshold = 3.0f;

	protected FrameAxis mAxis = null;
	private delegate void() mOnFramesPicked ~ delete _;
	private bool mChoosing = false;
	private uint64 mPressFrame = 0;
	private float mPressX = 0.0f;
	private bool mPanning = false;
	private float mPanFrom = 0.0f;
	private double mPanFirst = 0.0;
	private bool mHovering = false;
	private float mHoverX = 0.0f;
	private String mHoverTip = new .() ~ delete _;

	/// The parts it draws, which the sheet styles as `tag::part`.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		base.CollectStyleParts(outParts);
		outParts.Add("plot");
		outParts.Add("chosen-box");
		outParts.Add("chosen-fill");
	}
	public this()
	{
		TabFocusable = false;
	}

	public ~this()
	{
		if (mAxis != null)
		{
			mAxis.Leave(this);
			mAxis.ReleaseRef();
		}
	}

	/// The frames it shows (shared with the other views of the page). It takes a reference of its
	/// own: the caller keeps its.
	public FrameAxis Axis
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
			{
				mAxis.Join(this);
				mAxis.Track(Source);
			}
			Invalidate();
		}
	}

	/// Told when the user chooses frames here (a click, a drag): a page stops following then.
	/// OWNERSHIP of `callback` transfers.
	public void SetOnFramesPicked(delegate void() callback)
	{
		delete mOnFramesPicked;
		mOnFramesPicked = callback;
	}

	/// The plot's bounds (its own space): the content less the gutter.
	public Rect PlotBounds
	{
		get
		{
			let @box = ContentBounds;
			let gutter = Math.Min(cGutterWidth, @box.Width);
			return .(@box.X + gutter, @box.Y, Math.Max(@box.Width - gutter, 0.0f), @box.Height);
		}
	}

	/// The frame at a point's x (its own space), clamped to the source's frames; false off them.
	public bool FrameAtX(float x, out uint64 frame)
	{
		frame = 0;
		let source = Source;
		if ((mAxis == null) || (source == null) || !source.HasFrames)
			return false;
		let plot = PlotBounds;
		let at = mAxis.FrameAt(x - plot.X, plot.Width);
		let clamped = Math.Clamp(FrameAxis.Whole(at), (double)source.OldestFrame, (double)source.NewestFrame);
		frame = (uint64)clamped;
		return true;
	}

	/// The columns across the plot now (into `outColumns`, cleared first): a frame each, or the frames
	/// sharing a pixel.
	public void GetColumns(List<FrameColumn> outColumns)
	{
		outColumns.Clear();
		let source = Source;
		if ((mAxis == null) || (source == null) || !source.HasFrames)
			return;
		let plot = PlotBounds;
		if (plot.Width <= 0.0f)
			return;
		let oldest = source.OldestFrame;
		let newest = source.NewestFrame;
		let perPixel = mAxis.Count / (double)plot.Width;
		if (perPixel <= 1.0)
		{
			let first = (uint64)Math.Max(FrameAxis.Whole(mAxis.First), (double)oldest);
			let end = Math.Min(mAxis.First + mAxis.Count, (double)newest + 1.0);
			for (uint64 n = first; (double)n < end; n++)
			{
				var column = FrameColumn();
				column.First = n;
				column.Last = n;
				column.X = mAxis.OffsetOf((double)n, plot.Width);
				column.Width = mAxis.OffsetOf((double)(n + 1), plot.Width) - column.X;
				outColumns.Add(column);
			}
			return;
		}
		let pixels = (int32)Ceil(plot.Width);
		for (int32 x < pixels)
		{
			let from = Math.Max(FrameAxis.Whole(mAxis.FrameAt((float)x, plot.Width)), (double)oldest);
			let to = Math.Min(FrameAxis.Whole(mAxis.FrameAt((float)(x + 1), plot.Width) - 1e-9), (double)newest);
			if (to < from)
				continue;
			var column = FrameColumn();
			column.First = (uint64)from;
			column.Last = (uint64)to;
			column.X = (float)x;
			column.Width = 1.0f;
			outColumns.Add(column);
		}
	}

	/// The frame under the pointer described (its time, a counter's value), else its own tooltip.
	public override StringView TooltipText => !mHoverTip.IsEmpty ? mHoverTip : base.TooltipText;

	public void OnFrameAxisChanged()
	{
		Invalidate();
	}

	public override void OnProfileSourceChanged()
	{
		if (mAxis != null)
			mAxis.Track(Source);
		Invalidate();
	}

	public override Sedulous.GUI.Cursor CursorNow => mPanning ? .Grabbing : base.CursorNow;

	protected override void OnMouseDown(MouseEvent e)
	{
		if (mAxis == null)
			return;
		let at = Local(e.Position);
		if (e.Button == .Left)
		{
			e.Handled = true;
			if (e.ClickCount == 2)
			{
				let source = Source;
				if ((source != null) && source.HasFrames)
					mAxis.Fit(source.OldestFrame, source.NewestFrame);
				return;
			}
			if (!FrameAtX(at.X, out mPressFrame))
				return;
			mChoosing = true;
			mPressX = at.X;
			Pick(mPressFrame, mPressFrame);
		}
		else if (e.Button == .Middle)
		{
			e.Handled = true;
			mPanning = true;
			mPanFrom = at.X;
			mPanFirst = mAxis.First;
		}
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let at = Local(e.Position);
		mHoverX = at.X;
		mHovering = true;
		if (mChoosing && (Math.Abs(at.X - mPressX) >= cDragThreshold))
		{
			if (FrameAtX(at.X, let frame))
				Pick(Math.Min(frame, mPressFrame), Math.Max(frame, mPressFrame));
		}
		else if (mPanning && (mAxis != null))
		{
			let plot = PlotBounds;
			let perPixel = mAxis.Count / (double)Math.Max(plot.Width, 1.0f);
			mAxis.PanBy(mPanFirst - mAxis.First - (double)(at.X - mPanFrom) * perPixel);
		}
		UpdateHoverTip();
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (e.Button == .Left)
			mChoosing = false;
		if (e.Button == .Middle)
			mPanning = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mChoosing = false;
		mPanning = false;
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		base.OnMouseLeave(e);
		mHovering = false;
		mHoverTip.Clear();
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		if ((mAxis == null) || (e.Delta.Y == 0.0f))
			return;
		e.Handled = true;
		let plot = PlotBounds;
		let at = Local(e.Position);
		mAxis.ZoomAbout(mAxis.FrameAt(at.X - plot.X, plot.Width), (double)Pow(1.25f, e.Delta.Y));
	}

	/// What the tooltip says over `frame` (the frame under the pointer), appended.
	protected abstract void DescribeFrame(uint64 frame, String outText);

	/// The frames chosen, drawn: their columns filled in the accent are the view's own; the box around
	/// them is common.
	protected void DrawChosenBox(DrawContext ctx, Span<FrameColumn> columns, Rect plot)
	{
		let chosen = (mFocus != null) ? mFocus.Frames : FrameRange();
		if (chosen.Empty || columns.IsEmpty)
			return;
		var from = -1.0f;
		var to = -1.0f;
		for (let column in columns)
		{
			if ((column.Last >= chosen.First) && (column.First <= chosen.Last))
			{
				if (from < 0.0f)
					from = column.X;
				to = column.X + column.Width;
			}
		}
		if (from < 0.0f)
			return;
		let edge = PartColor("chosen-box", .(0.36f, 0.55f, 0.95f, 1.0f));
		let fill = PartColor("chosen-fill", .(0.18f, 0.43f, 0.87f, 0.14f));
		let @box = Rect(plot.X + from, plot.Y, Math.Max(to - from, 2.0f), plot.Height);
		ctx.VG.FillRect(@box.ToRectangle(), fill);
		ctx.VG.StrokeRect(@box.ToRectangle(), edge, 1.0f);
	}

	private void Pick(uint64 first, uint64 last)
	{
		if (mFocus == null)
			return;
		var range = FrameRange();
		range.First = first;
		range.Last = last;
		range.Empty = false;
		mFocus.SetFrames(range);
		if (mOnFramesPicked != null)
			mOnFramesPicked();
	}

	private void UpdateHoverTip()
	{
		mHoverTip.Clear();
		if (mHovering && (mHoverX >= PlotBounds.X) && FrameAtX(mHoverX, let frame))
			DescribeFrame(frame, mHoverTip);
	}
}

/// A column's frames: the longest one's CPU and GPU times, and the chosen name's longest share in
/// them.
struct FrameColumnTimes
{
	public float CpuMs = 0.0f;
	public float GpuMs = 0.0f;
	public float ChosenMs = 0.0f;
	public bool Any = false;
	/// A frame of it is among those chosen.
	public bool Chosen = false;

	public this() { }
}

/// The frames' CPU times against a budget; the frames chosen; the name chosen inside them.
[GuiReflect(true)]
class FrameStrip : FrameAxisView
{
	public const float cDefaultHeight = 64.0f;

	private float mBudgetMs = 0.0f;

	/// The parts it draws, which the sheet styles as `tag::part`.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		base.CollectStyleParts(outParts);
		outParts.Add("scale");
		outParts.Add("on-time");
		outParts.Add("over");
		outParts.Add("far-over");
		outParts.Add("clipped");
		outParts.Add("chosen");
		outParts.Add("share");
		outParts.Add("budget");
	}
	public this()
	{
		Tag = "framestrip";
		EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(cDefaultHeight); });
	}

	/// The frame's budget in ms (a frame within it is on time); 0: none.
	public float BudgetMs
	{
		get => mBudgetMs;
		set
		{
			mBudgetMs = Math.Max(value, 0.0f);
			Invalidate();
		}
	}

	/// The bars' scale (ms at the plot's top) over these columns: twice the budget, or without one the
	/// longest frame shown rounded up to 1, 2 or 5 times a power of ten.
	public float ScaleMs(Span<FrameColumnTimes> times)
	{
		if (mBudgetMs > 0.0f)
			return mBudgetMs * 2.0f;
		var most = 0.0f;
		for (let t in times)
			most = Math.Max(most, t.CpuMs);
		return NiceCeiling(Math.Max(most, 1.0f));
	}

	/// Each column's times (the longest of its frames), in the columns' order, into `outTimes`
	/// (cleared first).
	public void GetColumnTimes(Span<FrameColumn> columns, List<FrameColumnTimes> outTimes)
	{
		outTimes.Clear();
		let source = Source;
		if (source == null)
			return;
		let frequency = source.TickFrequency;
		let chosen = (mFocus != null) ? mFocus.Frames : FrameRange();
		let name = (mFocus != null) ? mFocus.Name : ChosenName();
		for (let column in columns)
		{
			var times = FrameColumnTimes();
			for (uint64 n = column.First; n <= column.Last; n++)
			{
				let frame = source.Frame(n);
				if (frame == null)
					continue;
				times.Any = true;
				times.CpuMs = Math.Max(times.CpuMs, ProfileWindow.TicksToMs(frame.EndTick - frame.BeginTick, frequency));
				if (name.Any)
					times.ChosenMs = Math.Max(times.ChosenMs, ProfileWindow.TicksToMs(ProfileFrames.NameTicksInFrame(frame, name), frequency));
				if (frame.GpuValid && !frame.Gpu.IsEmpty)
				{
					var begin = frame.Gpu[0].BeginTick;
					var end = frame.Gpu[0].EndTick;
					for (let pass in frame.Gpu)
					{
						begin = Math.Min(begin, pass.BeginTick);
						end = Math.Max(end, pass.EndTick);
					}
					times.GpuMs = Math.Max(times.GpuMs, ProfileWindow.TicksToMs(end - begin, frequency));
				}
				if (!chosen.Empty && (n >= chosen.First) && (n <= chosen.Last))
					times.Chosen = true;
			}
			outTimes.Add(times);
		}
	}

	protected override void DescribeFrame(uint64 frame, String outText)
	{
		let source = Source;
		let record = (source != null) ? source.Frame(frame) : null;
		if (record == null)
		{
			outText.AppendF("Frame {}: not recorded", frame);
			return;
		}
		let frequency = source.TickFrequency;
		outText.AppendF("Frame {0}: {1:F2} ms", frame, ProfileWindow.TicksToMs(record.EndTick - record.BeginTick, frequency));
		if ((mFocus != null) && mFocus.Name.Any)
		{
			outText.AppendF(", {0} {1:F2} ms", source.NameOf(mFocus.Name.Name),
				ProfileWindow.TicksToMs(ProfileFrames.NameTicksInFrame(record, mFocus.Name), frequency));
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let plot = PlotBounds;
		let columns = scope List<FrameColumn>();
		GetColumns(columns);
		let times = scope List<FrameColumnTimes>();
		GetColumnTimes(columns, times);
		let scale = ScaleMs(times);
		ctx.VG.FillRect(plot.ToRectangle(), PartColor("plot", .(0.0f, 0.0f, 0.0f, 0.18f)));

		// The scale: its top, the budget's line where there is one, its foot.
		let dim = PartTextColor("scale");
		let gutter = Rect(plot.X - cGutterWidth, plot.Y, cGutterWidth - 6.0f, plot.Height);
		DrawLabel(ctx, scope String()..AppendF("{0:F1}", scale), .(gutter.X, plot.Y, gutter.Width, 12.0f), dim, .End);
		DrawLabel(ctx, "0 ms", .(gutter.X, plot.Bottom - 12.0f, gutter.Width, 12.0f), dim, .End);

		let onTime = PartColor("on-time", .(0.25f, 0.61f, 0.42f, 1.0f));
		let over = PartColor("over", .(0.79f, 0.60f, 0.18f, 1.0f));
		let far = PartColor("far-over", .(0.78f, 0.31f, 0.25f, 1.0f));
		let chosenColor = PartColor("chosen", .(0.18f, 0.43f, 0.87f, 1.0f));
		let share = PartColor("share", .(0.0f, 0.0f, 0.0f, 0.40f));
		let clip = PartColor("clipped", far);
		ctx.PushClip(plot);
		for (int i < columns.Count)
		{
			let t = times[i];
			if (!t.Any)
				continue;
			let column = columns[i];
			let inset = (column.Width >= 3.0f) ? (column.Width * 0.12f) : 0.0f;
			let x = plot.X + column.X + inset;
			let w = Math.Max(column.Width - inset * 2.0f, 1.0f);
			let h = Math.Min(t.CpuMs / scale, 1.0f) * plot.Height;
			var color = onTime;
			if ((mBudgetMs > 0.0f) && (t.CpuMs > mBudgetMs * 2.0f))
				color = far;
			else if ((mBudgetMs > 0.0f) && (t.CpuMs > mBudgetMs))
				color = over;
			if (t.Chosen)
				color = chosenColor;
			ctx.VG.FillRect(.(x, plot.Bottom - h, w, h), color);
			if (t.ChosenMs > 0.0f)
			{
				let sh = Math.Min(t.ChosenMs / scale, 1.0f) * plot.Height;
				ctx.VG.FillRect(.(x, plot.Bottom - sh, w, sh), share);
			}
			if (t.CpuMs > scale)
				ctx.VG.FillRect(.(x, plot.Y, w, 3.0f), clip);
		}
		if (mBudgetMs > 0.0f)
		{
			let line = PartColor("budget", .(0.6f, 0.6f, 0.6f, 0.9f));
			let y = Floor(plot.Bottom - mBudgetMs / scale * plot.Height);
			ctx.VG.FillRect(.(plot.X, y, plot.Width, 1.0f), line);
			ctx.PopClip();
			DrawLabel(ctx, scope String()..AppendF("{0:F1}", mBudgetMs), .(gutter.X, y - 6.0f, gutter.Width, 12.0f), dim, .End);
			ctx.PushClip(plot);
		}
		DrawChosenBox(ctx, columns, plot);
		ctx.PopClip();
	}

	// The least of 1, 2 or 5 times a power of ten at least `value`.
	private static float NiceCeiling(float value)
	{
		let magnitude = Pow(10.0f, Floor(Log(value) / Log(10.0f)));
		for (let m in float[4](1.0f, 2.0f, 5.0f, 10.0f))
		{
			if (m * magnitude >= value * 0.9999f)
				return m * magnitude;
		}
		return 10.0f * magnitude;
	}
}

/// A counter's value each frame, on the strip's axis: its name in the gutter, the least and the most
/// shown printed over the plot, and its mean over the frames chosen.
[GuiReflect(true)]
class CounterPlot : FrameAxisView
{
	public const float cDefaultHeight = 26.0f;

	private uint32 mCounter = 0;

	/// The parts it draws, which the sheet styles as `tag::part`.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		base.CollectStyleParts(outParts);
		outParts.Add("name");
		outParts.Add("bar");
		outParts.Add("chosen");
		outParts.Add("range");
		outParts.Add("range-backing");
	}
	public this()
	{
		Tag = "counterplot";
		EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(cDefaultHeight); });
	}

	/// The counter it plots, by its index in the source's counters.
	public uint32 Counter
	{
		get => mCounter;
		set
		{
			mCounter = value;
			Invalidate();
		}
	}

	/// A column's value: the most of its frames' (false when none of them set it).
	/// Its mean over the frames chosen that set it (false: none chosen, or none of them did).
	public bool ChosenMean(out double mean)
	{
		mean = 0.0;
		let source = Source;
		let chosen = (mFocus != null) ? mFocus.Frames : FrameRange();
		if ((source == null) || chosen.Empty)
			return false;
		double sum = 0.0;
		uint32 count = 0;
		for (var n = chosen.First; n <= chosen.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			for (let v in frame.Counters)
			{
				if (v.Counter == mCounter)
				{
					sum += v.Value;
					count++;
				}
			}
		}
		if (count == 0)
			return false;
		mean = sum / (double)count;
		return true;
	}

	/// What it prints over its plot, appended: the least and the most shown, the chosen frames'
	/// mean.
	public void RangeText(double least, double most, String outText)
	{
		let source = Source;
		if ((source == null) || (mCounter >= (uint32)source.Counters.Length))
			return;
		let unit = source.Counters[mCounter].Unit;
		ProfileWindow.FormatCounter(least, unit, outText);
		outText.Append(" to ");
		ProfileWindow.FormatCounter(most, unit, outText);
		if (ChosenMean(let mean))
		{
			outText.Append(", mean ");
			ProfileWindow.FormatCounter(mean, unit, outText);
		}
	}

	public bool ColumnValue(FrameColumn column, out double value)
	{
		value = 0.0;
		let source = Source;
		var any = false;
		for (uint64 n = column.First; (source != null) && (n <= column.Last); n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			for (let v in frame.Counters)
			{
				if (v.Counter == mCounter)
				{
					value = any ? Math.Max(value, v.Value) : v.Value;
					any = true;
				}
			}
		}
		return any;
	}

	protected override void DescribeFrame(uint64 frame, String outText)
	{
		let source = Source;
		if ((source == null) || (mCounter >= (uint32)source.Counters.Length))
			return;
		let info = source.Counters[mCounter];
		var column = FrameColumn();
		column.First = frame;
		column.Last = frame;
		if (!ColumnValue(column, let value))
		{
			outText.AppendF("{} at frame {}: not set", info.Name, frame);
			return;
		}
		outText.AppendF("{} at frame {}: ", info.Name, frame);
		ProfileWindow.FormatCounter(value, info.Unit, outText);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let plot = PlotBounds;
		ctx.VG.FillRect(plot.ToRectangle(), PartColor("plot", .(0.0f, 0.0f, 0.0f, 0.18f)));
		let source = Source;
		if ((source == null) || (mCounter >= (uint32)source.Counters.Length))
			return;
		let info = source.Counters[mCounter];
		DrawLabel(ctx, info.Name, .(plot.X - cGutterWidth, plot.Y, cGutterWidth - 6.0f, plot.Height), PartTextColor("name"), .End);

		let columns = scope List<FrameColumn>();
		GetColumns(columns);
		let values = scope List<double>();
		let set = scope List<bool>();
		var least = 0.0;
		var most = 0.0;
		var any = false;
		for (let column in columns)
		{
			let has = ColumnValue(column, let value);
			values.Add(value);
			set.Add(has);
			if (has)
			{
				least = any ? Math.Min(least, value) : value;
				most = any ? Math.Max(most, value) : value;
				any = true;
			}
		}
		if (!any)
			return;
		let bar = PartColor("bar", .(0.44f, 0.53f, 0.72f, 1.0f));
		let chosenColor = PartColor("chosen", .(0.18f, 0.43f, 0.87f, 1.0f));
		let chosen = (mFocus != null) ? mFocus.Frames : FrameRange();
		let span = Math.Max(most - least, 1e-9);
		ctx.PushClip(plot);
		for (int i < columns.Count)
		{
			if (!set[i])
				continue;
			let column = columns[i];
			// The least shown stands 2 pixels high, so a flat counter still shows.
			let h = 2.0f + (float)((values[i] - least) / span) * (plot.Height - 4.0f);
			let isChosen = !chosen.Empty && (column.Last >= chosen.First) && (column.First <= chosen.Last);
			ctx.VG.FillRect(.(plot.X + column.X, plot.Bottom - h, Math.Max(column.Width, 1.0f), h), isChosen ? chosenColor : bar);
		}
		ctx.PopClip();
		let range = RangeText(least, most, .. scope .());
		// On a backing of the plot's colour at its end, so the bars under it never hide it.
		let width = Math.Min(LabelWidth(range) + 8.0f, plot.Width);
		let backing = Rect(plot.Right - width, plot.Y + 2.0f, width, plot.Height - 4.0f);
		ctx.VG.FillRoundedRect(backing.ToRectangle(), 3.0f, PartColor("range-backing", .(0.1f, 0.1f, 0.12f, 0.85f)));
		DrawLabel(ctx, range, .(backing.X + 4.0f, plot.Y, width - 8.0f, plot.Height), PartTextColor("range"), .End);
	}
}
