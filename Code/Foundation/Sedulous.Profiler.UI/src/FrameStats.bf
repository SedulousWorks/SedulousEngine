using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// Three lines: the newest CPU and GPU frame times with their minimum, median and maximum over
/// the frames shown, and the frames a second.
class FrameStats : ProfilerView
{
	private List<FrameTime> mTimes = new .() ~ delete _;
	private List<String> mLines = new .() ~ DeleteContainerAndItems!(_);
	private FrameWindowStats mStats;
	private float mNewestCpuMs;
	private float mNewestGpuMs;
	private float mFps;

	/// The model: the statistics, the newest times, and the lines drawn.
	public FrameWindowStats Stats => mStats;
	public float NewestCpuMs => mNewestCpuMs;
	public float NewestGpuMs => mNewestGpuMs;
	public float Fps => mFps;
	public Span<String> Lines => mLines;

	public override void OnDraw(UIDrawContext ctx)
	{
		Color[3] colors = .(Palette.Cpu, Palette.Gpu, Palette.Text);
		for (int i < mLines.Count)
		{
			let y = (float)i * LineHeight;
			ctx.VG.FillRect(.(0, y + 4, 3, LineHeight - 8), colors[Math.Min(i, 2)]);
			DrawLabel(ctx, mLines[i], .(8, y, Width - 8, LineHeight), Palette.Text);
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(300.0f), constraints.ConstrainHeight(3 * LineHeight));
	}

	protected override void Compute()
	{
		ProfileWindow.CollectFrameTimes(SourceOrEmpty, Range, mTimes);
		mStats = ProfileWindow.StatsOf(mTimes);
		mNewestCpuMs = 0.0f;
		mNewestGpuMs = 0.0f;
		for (let t in mTimes) // oldest first: the last ones seen are the newest
		{
			mNewestCpuMs = t.CpuMs;
			if (t.HasGpu)
				mNewestGpuMs = t.GpuMs;
		}
		mFps = (mStats.Cpu.Mean > 0.0f) ? (1000.0f / mStats.Cpu.Mean) : 0.0f;
		ClearAndDeleteItems(mLines);
		mLines.Add(Line("CPU", mNewestCpuMs, mStats.Cpu, .. new .()));
		if (mStats.Gpu.Count > 0)
			mLines.Add(Line("GPU", mNewestGpuMs, mStats.Gpu, .. new .()));
		else
			mLines.Add(new .("GPU  no timings"));
		mLines.Add(new String()..AppendF("{:F0} fps over {} frames", mFps, mStats.Cpu.Count));
	}

	private static void Line(StringView lane, float newest, TimeStats stats, String outLine)
	{
		outLine.AppendF("{}  {:F2} ms   min {:F1}  med {:F1}  max {:F1}", lane, newest, stats.Min, stats.Median, stats.Max);
	}
}
