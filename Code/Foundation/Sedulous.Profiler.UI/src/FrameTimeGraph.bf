using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The last frames' CPU and GPU times as two lines, the CPU's filled beneath, against the 60
/// and 30 frames a second budgets; the scale doubles from 20 ms until it holds the highest, so
/// a hitch neither flattens the rest for long nor makes the graph jitter. In the editor's
/// panel it is the frame strip: fitted to every frame its source holds, and interactive, a
/// click selecting a frame and a drag a range, which the panel's timeline and table then show.
class FrameTimeGraph : ProfilerView
{
	public const float GraphHeight = 64.0f;
	public static float[2] Budgets = .(16.667f, 33.333f);

	private List<FrameTime> mTimes = new .() ~ delete _;
	private List<Float2> mCpuPoints = new .() ~ delete _;
	private List<Float2> mGpuPoints = new .() ~ delete _;
	private float mScaleMs = 20.0f;
	/// View units a frame.
	private float mStep;
	private bool mFit;
	private FrameRange mSelection = .();
	/// The frame a drag began on.
	private uint64 mAnchor;
	private bool mDragging;

	/// Who hears when a click or a drag changes the selection.
	public Event<delegate void(FrameRange selection)> OnSelectionChanged ~ _.Dispose();

	/// The model: the frames shown, the graph's top in ms, and the lines' points in the view.
	public Span<FrameTime> Times => mTimes;
	public float ScaleMs => mScaleMs;
	public Span<Float2> CpuPoints => mCpuPoints;
	public Span<Float2> GpuPoints => mGpuPoints;

	/// Shows every frame the source holds across the width (the panel's strip), rather than
	/// the newest FrameCount.
	public bool FitToSource
	{
		get => mFit;
		set
		{
			mFit = value;
			Refresh();
		}
	}

	/// Takes the pointer: a click selects the frame under it, a drag the frames it spans.
	public bool Interactive
	{
		get => IsHitTestVisible;
		set => IsHitTestVisible = value;
	}

	public override bool OwnsPressDrag => IsHitTestVisible;

	/// The frames selected (empty for none).
	public FrameRange Selection
	{
		get => mSelection;
		set
		{
			mSelection = value;
			InvalidateVisual();
		}
	}

	/// The frame drawn nearest `x` in the view (none when it shows no frames).
	public FrameRange FrameAt(float x)
	{
		var at = FrameRange();
		if (mTimes.IsEmpty)
			return at;
		let newest = mTimes.Back.Frame;
		let back = (mStep > 0.0f) ? ((Width - x) / mStep + 0.5f) : 0.0f;
		let steps = (back <= 0.0f) ? 0 : (uint64)back;
		let oldest = mTimes[0].Frame;
		at.First = (steps > newest - oldest) ? oldest : (newest - steps);
		at.Last = at.First;
		at.Empty = false;
		return at;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		let at = FrameAt(e.X);
		if ((e.Button != .Left) || at.Empty)
			return;
		mAnchor = at.First;
		mDragging = true;
		Select(at);
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let at = FrameAt(e.X);
		if (!mDragging || at.Empty)
			return;
		var range = FrameRange();
		range.First = Math.Min(mAnchor, at.First);
		range.Last = Math.Max(mAnchor, at.First);
		range.Empty = false;
		if ((range.First != mSelection.First) || (range.Last != mSelection.Last))
			Select(range);
		e.Handled = true;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (!mDragging)
			return;
		mDragging = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();
		e.Handled = true;
	}

	/// The scale for a highest time: 20 ms doubled until it holds it.
	public static float ScaleFor(float highestMs)
	{
		var scale = 20.0f;
		while ((scale < highestMs) && (scale < 10240.0f))
			scale *= 2.0f;
		return scale;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		Compute(); // the size may have changed since the last refresh
		let w = Width;
		let h = Height;
		let vg = ctx.VG;
		vg.FillRect(.(0, 0, w, h), Palette.Plot);
		if (!mSelection.Empty && !mTimes.IsEmpty)
		{
			let x0 = XOf(mSelection.First) - mStep * 0.5f;
			let x1 = XOf(mSelection.Last) + mStep * 0.5f;
			vg.FillRect(.(x0, 0, Math.Max(x1 - x0, 2.0f), h), Palette.Selection);
		}
		let label = scope String();
		for (let budget in Budgets)
		{
			if (budget < mScaleMs)
			{
				let y = YOf(budget);
				vg.DrawLine(.(0, y), .(w, y), Palette.Budget, 1.0f);
				label.Clear();
				label.AppendF("{:F1}", budget);
				DrawLabel(ctx, label, .(2, y - LineHeight, 60, LineHeight), Palette.Dim);
			}
		}
		if (mCpuPoints.Count >= 2)
		{
			// The area under the CPU line, then the line.
			vg.BeginPath();
			vg.MoveTo(.(mCpuPoints[0].X, h));
			for (let p in mCpuPoints)
				vg.LineTo(p);
			vg.LineTo(.(mCpuPoints.Back.X, h));
			vg.ClosePath();
			vg.Fill(Color(Palette.Cpu.R, Palette.Cpu.G, Palette.Cpu.B, 0.22f));
			StrokeLine(ctx, mCpuPoints, Palette.Cpu);
		}
		if (mGpuPoints.Count >= 2)
			StrokeLine(ctx, mGpuPoints, Palette.Gpu);
		label.Clear();
		label.AppendF("{:F0}", mScaleMs);
		DrawLabel(ctx, label, .(w - 62, 0, 60, LineHeight), Palette.Dim, .Right);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(300.0f), constraints.ConstrainHeight(GraphHeight));
	}

	protected override void Compute()
	{
		let source = SourceOrEmpty;
		var range = Range;
		if (mFit && source.HasFrames)
		{
			range.First = source.OldestFrame;
			range.Last = source.NewestFrame;
			range.Empty = false;
		}
		ProfileWindow.CollectFrameTimes(source, range, mTimes);
		var highest = 0.0f;
		for (let t in mTimes)
			highest = Math.Max(highest, Math.Max(t.CpuMs, t.HasGpu ? t.GpuMs : 0.0f));
		mScaleMs = ScaleFor(highest);
		// Slots for the whole window, newest at the right edge, so a short history grows in
		// from the right rather than stretching.
		mCpuPoints.Clear();
		mGpuPoints.Clear();
		let slots = mFit ? (range.Empty ? 1 : (range.Last - range.First + 1)) : (uint64)mFrameCount;
		mStep = (slots > 1) ? (Width / (float)(slots - 1)) : Width;
		for (let t in mTimes)
		{
			let x = XOf(t.Frame);
			mCpuPoints.Add(.(x, YOf(t.CpuMs)));
			if (t.HasGpu)
				mGpuPoints.Add(.(x, YOf(t.GpuMs)));
		}
	}

	private void Select(FrameRange range)
	{
		Selection = range;
		OnSelectionChanged(range);
	}

	/// Newest at the right edge, a step a frame back from there.
	private float XOf(uint64 frame)
	{
		let newest = mTimes.IsEmpty ? 0 : mTimes.Back.Frame;
		return Width - (float)(newest - frame) * mStep;
	}

	private float YOf(float ms) => Height * (1.0f - Math.Min(ms / mScaleMs, 1.0f));

	private static void StrokeLine(UIDrawContext ctx, Span<Float2> points, Color color)
	{
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(points[0]);
		for (int i = 1; i < points.Length; i++)
			ctx.VG.LineTo(points[i]);
		ctx.VG.Stroke(color, 1.5f);
	}
}
