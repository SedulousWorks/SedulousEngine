using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The scopes (by their own time) or GPU passes that took longest over the frames shown, in ms
/// a frame, each with a bar against the longest.
class TopList : ProfilerView
{
	public class Row
	{
		public String Name = new .() ~ delete _;
		public float MsPerFrame;
		public float CallsPerFrame;
		/// Nought to one of the longest row.
		public float Bar;
	}

	private TopLane mLane;
	private uint32 mRowCount;
	private List<TopEntry> mEntries = new .() ~ delete _;
	private List<Row> mRows = new .() ~ DeleteContainerAndItems!(_);

	public this(TopLane lane = .Scopes, uint32 rows = 6)
	{
		mLane = lane;
		mRowCount = rows;
		mFrameCount = 30;
	}

	public TopLane Lane => mLane;
	/// The model: the rows drawn, longest first.
	public Span<Row> Rows => mRows;

	public override void OnDraw(UIDrawContext ctx)
	{
		let bar = (mLane == .GpuPasses) ? Palette.Gpu : Palette.Cpu;
		DrawLabel(ctx, (mLane == .GpuPasses) ? "GPU passes, ms a frame" : "CPU scopes (self), ms a frame",
			.(0, 0, Width, LineHeight), Palette.Dim);
		let ms = scope String();
		for (int i < mRows.Count)
		{
			let y = (float)(i + 1) * LineHeight;
			ctx.VG.FillRect(.(0, y + 2, Width * mRows[i].Bar, LineHeight - 4), Color(bar.R, bar.G, bar.B, 0.35f));
			DrawLabel(ctx, mRows[i].Name, .(4, y, Width - 60, LineHeight), Palette.Text);
			ms.Clear();
			ms.AppendF("{:F2}", mRows[i].MsPerFrame);
			DrawLabel(ctx, ms, .(Width - 58, y, 56, LineHeight), Palette.Text, .Right);
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(300.0f), constraints.ConstrainHeight((float)(mRowCount + 1) * LineHeight));
	}

	protected override void Compute()
	{
		let source = SourceOrEmpty;
		ProfileWindow.CollectTop(source, Range, mLane, mRowCount, mEntries);
		ClearAndDeleteItems(mRows);
		let longest = mEntries.IsEmpty ? 0.0f : mEntries[0].MsPerFrame;
		for (let entry in mEntries)
		{
			let row = new Row();
			row.Name.Set(source.NameOf(entry.Name));
			row.MsPerFrame = entry.MsPerFrame;
			row.CallsPerFrame = entry.CallsPerFrame;
			row.Bar = (longest > 0.0f) ? (entry.MsPerFrame / longest) : 0.0f;
			mRows.Add(row);
		}
	}
}
