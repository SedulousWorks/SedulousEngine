using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The counters in two columns, each in its unit: memory as its newest value, the rest as
/// their mean over the frames shown.
class CounterStrip : ProfilerView
{
	public const uint32 Columns = 2;

	public class Row
	{
		public String Name = new .() ~ delete _;
		public String Value = new .() ~ delete _;
	}

	private List<CounterReading> mReadings = new .() ~ delete _;
	private List<Row> mRows = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		mFrameCount = 30;
	}

	/// The model: a row per counter shown, in registration order.
	public Span<Row> Rows => mRows;

	public override void OnDraw(UIDrawContext ctx)
	{
		let column = Width / (float)Columns;
		for (int i < mRows.Count)
		{
			let cell = CellOf(i);
			let x = cell.X;
			let y = cell.Y;
			DrawLabel(ctx, mRows[i].Name, .(x, y, column - 70, LineHeight), Palette.Dim);
			DrawLabel(ctx, mRows[i].Value, .(x + column - 72, y, 68, LineHeight), Palette.Text, .Right);
		}
	}

	/// Where row `index` draws: across the columns, then down a line. Whole numbers of rows: an
	/// int over a uint32 here once came out fractional and dropped the right column half a
	/// line.
	public Float2 CellOf(int index)
	{
		let columns = (int)Columns;
		return .((float)(index % columns) * (Width / (float)Columns), (float)(index / columns) * LineHeight);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// The rows a source of this many counters needs; at least one.
		let rows = Math.Max(((uint32)mRows.Count + Columns - 1) / Columns, 1);
		MeasuredSize = .(constraints.ConstrainWidth(300.0f), constraints.ConstrainHeight((float)rows * LineHeight));
	}

	protected override void Compute()
	{
		let source = SourceOrEmpty;
		ProfileWindow.CollectCounters(source, Range, mReadings);
		let before = mRows.Count;
		ClearAndDeleteItems(mRows);
		let infos = source.Counters;
		for (let reading in mReadings)
		{
			if (!reading.Present || (reading.Counter >= (uint32)infos.Length))
				continue;
			let info = infos[reading.Counter];
			let row = new Row();
			row.Name.Set(info.Name);
			ProfileWindow.FormatCounter((info.Unit == .Bytes) ? reading.Latest : reading.Mean, info.Unit, row.Value);
			mRows.Add(row);
		}
		if (mRows.Count != before)
			Invalidate(); // a row more or fewer: its height changes
	}
}
