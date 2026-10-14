using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The last frames' CPU and GPU times as two lines, the CPU's filled beneath, against the 60
/// and 30 frames a second budgets; the scale doubles from 20 ms until it holds the highest.
class FrameTimeGraph : ProfilerView
{
	public const float GraphHeight = 64.0f;
	public static float[2] Budgets = .(16.667f, 33.333f);

	private List<FrameTime> mTimes = new .() ~ delete _;
	private List<Float2> mCpuPoints = new .() ~ delete _;
	private List<Float2> mGpuPoints = new .() ~ delete _;
	private float mScaleMs = 20.0f;

	/// The model: the frames shown, the graph's top in ms, and the lines' points in the view.
	public Span<FrameTime> Times => mTimes;
	public float ScaleMs => mScaleMs;
	public Span<Float2> CpuPoints => mCpuPoints;
	public Span<Float2> GpuPoints => mGpuPoints;

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
		ProfileWindow.CollectFrameTimes(SourceOrEmpty, Range, mTimes);
		var highest = 0.0f;
		for (let t in mTimes)
			highest = Math.Max(highest, Math.Max(t.CpuMs, t.HasGpu ? t.GpuMs : 0.0f));
		mScaleMs = ScaleFor(highest);
		// Slots for the whole window, newest at the right edge, so a short history grows in
		// from the right rather than stretching.
		mCpuPoints.Clear();
		mGpuPoints.Clear();
		let w = Width;
		let step = (mFrameCount > 1) ? (w / (float)(mFrameCount - 1)) : w;
		let newest = mTimes.IsEmpty ? 0 : mTimes.Back.Frame;
		for (let t in mTimes)
		{
			let x = w - (float)(newest - t.Frame) * step;
			mCpuPoints.Add(.(x, YOf(t.CpuMs)));
			if (t.HasGpu)
				mGpuPoints.Add(.(x, YOf(t.GpuMs)));
		}
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
