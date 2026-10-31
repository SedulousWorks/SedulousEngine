using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

// The in-game overlay on the GUI (Raptor's engine-ui-removal spec, layer 1; its profiler spec, P4):
// the frame time graph (the newest frames' CPU and GPU times against the 60 and 30 fps budgets), the
// frame statistics, the top CPU scopes by their own time and the top GPU passes, and the counters,
// stacked on one translucent panel in a corner of whatever it fills. It never takes the pointer, so
// the game under it plays on. It reads the focus's source (the live store, for a game); the host
// shows it, arms the profiler while it shows, and calls Refresh each frame.
//
// Its colours are its parts' (`profileroverlay::panel`, `::plot`, `::cpu`, `::gpu`, `::budget`,
// `::note`, `::text`), each with the old overlay's colour where no sheet gives one: a game's sheet
// knows nothing of it, and it reads the same over any game.

/// Which corner of what it fills the panel sits in.
enum OverlayCorner : uint8
{
	TopRight,
	TopLeft,
	BottomRight,
	BottomLeft,
}

[GuiReflect]
class ProfilerOverlay : ProfilerWidget
{
	public const float cPanelWidth = 360.0f;
	public const float cPadding = 8.0f;
	public const float cGap = 6.0f;
	public const float cMargin = 8.0f;
	public const float cLineHeight = 15.0f;
	public const float cGraphHeight = 64.0f;
	public static readonly float[2] cBudgets = .(16.667f, 33.333f);
	/// The graph and the statistics: two seconds at 60 fps.
	public const uint32 cGraphFrames = 120;
	/// The lists and counters: steady, yet recent.
	public const uint32 cListFrames = 30;
	public const uint32 cScopeRows = 6;
	public const uint32 cPassRows = 5;
	public const uint32 cCounterColumns = 2;
	private static readonly String[7] cParts = .("panel", "plot", "cpu", "gpu", "budget", "note", "text");

	/// A row of a top list: a name, its ms a frame, its bar against the longest (0 to 1).
	public class TopRow
	{
		public String Name = new .() ~ delete _;
		public float MsPerFrame = 0.0f;
		public float Bar = 0.0f;
	}

	/// A counter shown: its name and its value, formatted.
	public class CounterRow
	{
		public String Name = new .() ~ delete _;
		public String Value = new .() ~ delete _;
	}

	private List<FrameTime> mTimes = new .() ~ delete _;
	private List<Float2> mCpuPoints = new .() ~ delete _;
	private List<Float2> mGpuPoints = new .() ~ delete _;
	private List<String> mStatLines = new .() ~ DeleteContainerAndItems!(_);
	private List<TopRow> mScopes = new .() ~ DeleteContainerAndItems!(_);
	private List<TopRow> mPasses = new .() ~ DeleteContainerAndItems!(_);
	private List<CounterRow> mCounters = new .() ~ DeleteContainerAndItems!(_);
	/// A list's, as collected.
	private List<TopEntry> mEntries = new .() ~ delete _;
	/// The counters', as collected.
	private List<CounterReading> mReadings = new .() ~ delete _;
	private float mScaleMs = 20.0f;
	private OverlayCorner mCorner = .TopRight;

	public this()
	{
		Tag = "profileroverlay";
		TabFocusable = false;
		HitTestVisible = false; // it shows; the game keeps the pointer
		SetInlineStyle("font-size", "11px");
	}

	/// The parts it draws, which a sheet styles as `profileroverlay::part`.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		base.CollectStyleParts(outParts);
		for (let part in cParts)
			outParts.Add(part);
	}

	public OverlayCorner Corner
	{
		get => mCorner;
		set
		{
			mCorner = value;
			Invalidate();
		}
	}

	/// Reads the source again (a new frame): what it shows, then a draw.
	public void Refresh()
	{
		Compute();
		Invalidate();
	}

	public override void OnProfileSourceChanged() => Refresh();
	public override void OnProfileFramesChanged() => Refresh();

	// === What it shows (the model its draw reads; tests read it too) ===

	/// The panel in its own space, for the size it was last laid out at.
	public Rect Panel => PanelIn(ContentBounds);

	public float PanelHeight
	{
		get
		{
			let counterLines = (float)Math.Max((mCounters.Count + (int)cCounterColumns - 1) / (int)cCounterColumns, 1);
			return 2 * cPadding + cGraphHeight + 3 * cLineHeight + (float)(cScopeRows + 1) * cLineHeight +
				(float)(cPassRows + 1) * cLineHeight + counterLines * cLineHeight + 4 * cGap;
		}
	}

	/// The graph's top in ms (20 doubled until it holds the highest time) and its lines, in the
	/// graph's own space (newest at its right edge, a step a frame back from there).
	public float ScaleMs => mScaleMs;
	public Span<Float2> CpuPoints => mCpuPoints;
	public Span<Float2> GpuPoints => mGpuPoints;

	public static float ScaleFor(float highestMs)
	{
		var scale = 20.0f;
		while ((scale < highestMs) && (scale < 10240.0f))
			scale *= 2.0f;
		return scale;
	}

	/// The statistics' three lines: the CPU's, the GPU's, the frame rate's.
	public Span<String> StatLines => mStatLines;
	public Span<TopRow> Scopes => mScopes;
	public Span<TopRow> Passes => mPasses;
	public Span<CounterRow> Counters => mCounters;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let panel = PanelIn(ContentBounds);
		if (panel.Width <= 2 * cPadding)
			return;
		let text = PartText("text", .(0.94f, 0.95f, 0.97f, 1.0f));
		let note = PartText("note", .(0.66f, 0.69f, 0.74f, 1.0f));
		let cpu = PartColor("cpu", .(0.36f, 0.70f, 1.0f, 1.0f));
		let gpu = PartColor("gpu", .(1.0f, 0.64f, 0.26f, 1.0f));
		let vg = ctx.VG;
		vg.FillRoundedRect(panel.ToRectangle(), 6.0f, PartColor("panel", .(0.05f, 0.06f, 0.08f, 0.82f)));
		let x = panel.X + cPadding;
		let width = panel.Width - 2 * cPadding;
		var y = panel.Y + cPadding;

		// The graph: the budgets, the area under the CPU line and the line, the GPU's line.
		let graph = Rect(x, y, width, cGraphHeight);
		PlaceGraph(width); // laid out at another width since the last refresh
		vg.FillRect(graph.ToRectangle(), PartColor("plot", .(1.0f, 1.0f, 1.0f, 0.05f)));
		for (let budget in cBudgets)
		{
			if (budget >= mScaleMs)
				continue;
			let by = graph.Y + YOf(budget);
			vg.DrawLine(.(graph.X, by), .(graph.X + width, by), PartColor("budget", .(1.0f, 1.0f, 1.0f, 0.28f)), 1.0f);
			DrawLabel(ctx, scope String()..AppendF("{:F1}", budget), Rect(graph.X + 2, by - cLineHeight, 60, cLineHeight), note);
		}
		if (mCpuPoints.Count >= 2)
		{
			vg.BeginPath();
			vg.MoveTo(.(graph.X + mCpuPoints[0].X, graph.Y + cGraphHeight));
			for (let p in mCpuPoints)
				vg.LineTo(.(graph.X + p.X, graph.Y + p.Y));
			vg.LineTo(.(graph.X + mCpuPoints.Back.X, graph.Y + cGraphHeight));
			vg.ClosePath();
			vg.Fill(Color(cpu.R, cpu.G, cpu.B, cpu.A * 0.22f));
			StrokeLine(vg, mCpuPoints, .(graph.X, graph.Y), cpu);
		}
		if (mGpuPoints.Count >= 2)
			StrokeLine(vg, mGpuPoints, .(graph.X, graph.Y), gpu);
		DrawLabel(ctx, scope String()..AppendF("{:F0}", mScaleMs), Rect(graph.X + width - 62, graph.Y, 60, cLineHeight), note, .Right);
		y += cGraphHeight + cGap;

		// The statistics, each line marked in its lane's colour.
		Color[3] marks = .(cpu, gpu, text);
		for (int i < mStatLines.Count)
		{
			vg.FillRect(.(x, y + 4, 3, cLineHeight - 8), marks[Math.Min(i, 2)]);
			DrawLabel(ctx, mStatLines[i], Rect(x + 8, y, width - 8, cLineHeight), text);
			y += cLineHeight;
		}
		y += cGap;

		y = DrawTop(ctx, "CPU scopes (self), ms a frame", mScopes, cScopeRows, cpu, Rect(x, y, width, 0), text, note);
		y = DrawTop(ctx, "GPU passes, ms a frame", mPasses, cPassRows, gpu, Rect(x, y, width, 0), text, note);

		// The counters, in two columns.
		let column = width / (float)cCounterColumns;
		for (int i < mCounters.Count)
		{
			let cx = x + (float)(i % (int)cCounterColumns) * column;
			let cy = y + (float)(i / (int)cCounterColumns) * cLineHeight;
			DrawLabel(ctx, mCounters[i].Name, Rect(cx, cy, column - 74, cLineHeight), note);
			DrawLabel(ctx, mCounters[i].Value, Rect(cx + column - 72, cy, 68, cLineHeight), text, .Right);
		}
	}

	private Rect PanelIn(Rect @box)
	{
		let width = Math.Min(cPanelWidth, Math.Max(@box.Width - 2 * cMargin, 0.0f));
		let height = PanelHeight;
		let right = (mCorner == .TopRight) || (mCorner == .BottomRight);
		let bottom = (mCorner == .BottomRight) || (mCorner == .BottomLeft);
		return Rect(right ? @box.X + Math.Max(@box.Width - cMargin - width, 0.0f) : @box.X + cMargin,
			bottom ? @box.Y + Math.Max(@box.Height - cMargin - height, 0.0f) : @box.Y + cMargin, width, height);
	}

	// A part's text colour, or `fallback` where the sheet gives none (not the cascade's: a game's
	// text colour is the game's, not the overlay's).
	private Color PartText(StringView part, Color fallback)
	{
		let style = GetPartStyle(part);
		return style.HasColor ? style.TextColor : fallback;
	}

	// What it shows, from the source: the graph's frames and the statistics over the newest
	// cGraphFrames, the lists and counters over the newest cListFrames.
	private void Compute()
	{
		let source = Source;
		mTimes.Clear();
		ClearAndDeleteItems!(mStatLines);
		ClearAndDeleteItems!(mScopes);
		ClearAndDeleteItems!(mPasses);
		ClearAndDeleteItems!(mCounters);
		if ((source != null) && source.HasFrames)
		{
			ProfileWindow.CollectFrameTimes(source, ProfileWindow.LastFrames(source, cGraphFrames), mTimes);
			let stats = ProfileWindow.StatsOf(mTimes);
			var newestCpu = 0.0f;
			var newestGpu = 0.0f;
			for (let t in mTimes) // oldest first: the last ones seen are the newest
			{
				newestCpu = t.CpuMs;
				if (t.HasGpu)
					newestGpu = t.GpuMs;
			}
			let fps = (stats.Cpu.Mean > 0.0f) ? 1000.0f / stats.Cpu.Mean : 0.0f;
			mStatLines.Add(StatLine("CPU", newestCpu, stats.Cpu, .. new .()));
			if (stats.Gpu.Count > 0)
				mStatLines.Add(StatLine("GPU", newestGpu, stats.Gpu, .. new .()));
			else
				mStatLines.Add(new .("GPU  no timings"));
			mStatLines.Add(new String()..AppendF("{:F0} fps over {} frames", fps, stats.Cpu.Count));

			let recent = ProfileWindow.LastFrames(source, cListFrames);
			CollectTopRows(source, recent, .Scopes, cScopeRows, mScopes);
			CollectTopRows(source, recent, .GpuPasses, cPassRows, mPasses);
			ProfileWindow.CollectCounters(source, recent, mReadings);
			let infos = source.Counters;
			for (let reading in mReadings)
			{
				if (!reading.Present || (reading.Counter >= (uint32)infos.Length))
					continue;
				let info = infos[(int)reading.Counter];
				// What the device did a frame, as its mean (the numbers hold still); what it
				// holds, as the newest.
				let row = new CounterRow();
				row.Name.Set(info.Name);
				ProfileWindow.FormatCounter((info.Unit == .Bytes) ? reading.Latest : reading.Mean, info.Unit, row.Value);
				mCounters.Add(row);
			}
		}
		var highest = 0.0f;
		for (let t in mTimes)
			highest = Math.Max(highest, Math.Max(t.CpuMs, t.HasGpu ? t.GpuMs : 0.0f));
		mScaleMs = ScaleFor(highest);
		PlaceGraph(Panel.Width - 2 * cPadding);
	}

	// The lines' points for a graph `width` wide: a slot for each of cGraphFrames, the newest at
	// the right edge, so a short history grows in from the right rather than stretching.
	private void PlaceGraph(float width)
	{
		mCpuPoints.Clear();
		mGpuPoints.Clear();
		if (mTimes.IsEmpty || (width <= 0.0f))
			return;
		let step = width / (float)(cGraphFrames - 1);
		let newest = mTimes.Back.Frame;
		for (let t in mTimes)
		{
			let x = width - (float)(newest - t.Frame) * step;
			mCpuPoints.Add(.(x, YOf(t.CpuMs)));
			if (t.HasGpu)
				mGpuPoints.Add(.(x, YOf(t.GpuMs)));
		}
	}

	private float YOf(float ms) => cGraphHeight * (1.0f - Math.Min(ms / mScaleMs, 1.0f));

	private void CollectTopRows(IProfileSource source, FrameRange range, TopLane lane, uint32 count, List<TopRow> outRows)
	{
		ProfileWindow.CollectTop(source, range, lane, count, mEntries);
		let longest = mEntries.IsEmpty ? 0.0f : mEntries[0].MsPerFrame;
		for (let entry in mEntries)
		{
			let row = new TopRow();
			row.Name.Set(source.NameOf(entry.Name));
			row.MsPerFrame = entry.MsPerFrame;
			row.Bar = (longest > 0.0f) ? entry.MsPerFrame / longest : 0.0f;
			outRows.Add(row);
		}
	}

	private static void StatLine(StringView lane, float newest, TimeStats stats, String outLine)
	{
		outLine.AppendF("{}  {:F2} ms   min {:F1}  med {:F1}  max {:F1}", lane, newest, stats.Min, stats.Median, stats.Max);
	}

	// A list's heading and rows, each a bar against the longest; answers the y under it.
	private float DrawTop(DrawContext ctx, StringView heading, List<TopRow> rows, uint32 count, Color bar, Rect at, Color text, Color note)
	{
		DrawLabel(ctx, heading, Rect(at.X, at.Y, at.Width, cLineHeight), note);
		for (int i < rows.Count)
		{
			let y = at.Y + (float)(i + 1) * cLineHeight;
			ctx.VG.FillRect(.(at.X, y + 2, at.Width * rows[i].Bar, cLineHeight - 4), Color(bar.R, bar.G, bar.B, bar.A * 0.35f));
			DrawLabel(ctx, rows[i].Name, Rect(at.X + 4, y, at.Width - 64, cLineHeight), text);
			DrawLabel(ctx, scope String()..AppendF("{:F2}", rows[i].MsPerFrame), Rect(at.X + at.Width - 58, y, 56, cLineHeight), text, .Right);
		}
		return at.Y + (float)(count + 1) * cLineHeight + cGap;
	}

	private static void StrokeLine(Sedulous.VG.VGContext vg, List<Float2> points, Float2 origin, Color color)
	{
		vg.BeginPath();
		vg.MoveTo(.(origin.X + points[0].X, origin.Y + points[0].Y));
		for (int i = 1; i < points.Count; i++)
			vg.LineTo(.(origin.X + points[i].X, origin.Y + points[i].Y));
		vg.Stroke(color, 1.5f);
	}
}
