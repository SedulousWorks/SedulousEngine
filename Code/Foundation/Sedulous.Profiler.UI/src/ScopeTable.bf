using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The selected frames' scopes and GPU passes by name: their total time, their own time
/// (children taken out) and how many there were, in ms over the selection. A click on a
/// column's heading sorts by it (again: the other way); a click on a row selects that name,
/// which the panel's timeline highlights; the wheel scrolls the rows.
class ScopeTable : ProfilerView
{
	/// Each number column.
	public const float NumberWidth = 72.0f;
	public const float RowHeight = 18.0f;

	public enum Column : uint8
	{
		Name,
		Total,
		Self,
		Count
	}

	public class Row
	{
		public uint32 Name;
		public bool Gpu;
		public String Label = new .() ~ delete _;
		public double TotalMs;
		public double SelfMs;
		public uint64 Count;
	}

	private RangeTotals mTotals = new .() ~ delete _;
	private List<Row> mRows = new .() ~ DeleteContainerAndItems!(_);
	private FrameRange mFrames = .();
	private Column mSort = .Self;
	private bool mDescending = true;
	private int mSelected = -1;
	private uint32 mSelectedName;
	private bool mSelectedGpu;
	private bool mHasSelection;
	private int mScroll;

	/// Who hears a row selected: its row, or null for none.
	public Event<delegate void(Row row)> OnSelect ~ _.Dispose();

	public this()
	{
		IsHitTestVisible = true; // sorts, selects and scrolls
	}

	/// Totals these frames.
	public FrameRange Frames
	{
		get => mFrames;
		set
		{
			mFrames = value;
			mScroll = 0;
			Refresh();
		}
	}

	/// Sorts by `column`, the largest (or Z) first when `descending`.
	public void SortBy(Column column, bool descending)
	{
		mSort = column;
		mDescending = descending;
		Refresh();
	}

	public Column SortColumn => mSort;
	public bool SortDescending => mDescending;

	/// The model: the rows in their order, and the selected one (-1: none).
	public Span<Row> Rows => mRows;
	public int SelectedRow => mSelected;

	/// Selects a row (-1: none); who hears gets it, or null for none.
	public void SelectRow(int row)
	{
		mSelected = ((row >= 0) && (row < mRows.Count)) ? row : -1;
		mSelectedName = (mSelected >= 0) ? mRows[mSelected].Name : 0;
		mSelectedGpu = (mSelected >= 0) && mRows[mSelected].Gpu;
		mHasSelection = mSelected >= 0;
		InvalidateVisual();
		OnSelect((mSelected >= 0) ? mRows[mSelected] : null);
	}

	/// The column a heading's x falls in, and the row a point's y does (-1: the heading or none).
	public Column ColumnAt(float x)
	{
		let numbers = Width - 3 * NumberWidth;
		if (x < numbers)
			return .Name;
		let index = (int)((x - numbers) / NumberWidth);
		return (index == 0) ? .Total : ((index == 1) ? .Self : .Count);
	}

	public int RowAt(float y)
	{
		if (y < RowHeight)
			return -1;
		let row = (int)((y - RowHeight) / RowHeight) + mScroll;
		return (row < mRows.Count) ? row : -1;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;
		if (e.Y < RowHeight)
		{
			let column = ColumnAt(e.X);
			SortBy(column, (column == mSort) ? !mDescending : (column != .Name));
		}
		else
		{
			SelectRow(RowAt(e.Y));
		}
		e.Handled = true;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		let visible = (int)(Height / RowHeight) - 1;
		let most = Math.Max(mRows.Count - visible, 0);
		mScroll = Math.Clamp(mScroll - (int)(e.DeltaY * 3.0f), 0, most);
		InvalidateVisual();
		e.Handled = true;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;
		let h = Height;
		let vg = ctx.VG;
		vg.FillRect(.(0, 0, w, h), Palette.Plot);
		ctx.PushClip(.(0, 0, w, h));
		let numbers = w - 3 * NumberWidth;
		StringView[4] headings = .("Name", "Total ms", "Self ms", "Count");
		let text = scope String();
		for (int c < 4)
		{
			text.Set(headings[c]);
			if ((Column)c == mSort)
				text.Append(mDescending ? " v" : " ^");
			let cell = (c == 0) ? Rectangle(6, 0, numbers - 12, RowHeight)
				: Rectangle(numbers + (float)(c - 1) * NumberWidth, 0, NumberWidth - 6, RowHeight);
			DrawLabel(ctx, text, cell, Palette.Dim, (c == 0) ? .Left : .Right);
		}
		vg.DrawLine(.(0, RowHeight), .(w, RowHeight), Palette.Grid, 1.0f);
		for (int i = mScroll; i < mRows.Count; i++)
		{
			let y = RowHeight + (float)(i - mScroll) * RowHeight;
			if (y > h)
				break;
			let row = mRows[i];
			if (i == mSelected)
				vg.FillRect(.(0, y, w, RowHeight), Palette.Selection);
			vg.FillRect(.(4, y + 5, 4, RowHeight - 10), row.Gpu ? Palette.Gpu : Palette.Cpu);
			DrawLabel(ctx, row.Label, .(12, y, numbers - 18, RowHeight), Palette.Text);
			for (int c < 3)
			{
				text.Clear();
				switch (c)
				{
				case 0: text.AppendF("{:F3}", row.TotalMs);
				case 1: text.AppendF("{:F3}", row.SelfMs);
				default: text.AppendF("{}", row.Count);
				}
				DrawLabel(ctx, text, .(numbers + (float)c * NumberWidth, y, NumberWidth - 6, RowHeight), Palette.Text, .Right);
			}
		}
		ctx.PopClip();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(360.0f), constraints.ConstrainHeight(240.0f));
	}

	protected override void Compute()
	{
		let source = SourceOrEmpty;
		ProfileWindow.CollectTotals(source, mFrames, mTotals);
		ClearAndDeleteItems(mRows);
		let frequency = source.TickFrequency;
		for (int which < 2)
		{
			for (let total in (which == 0) ? mTotals.Scopes : mTotals.Passes)
			{
				let row = new Row();
				row.Name = total.Name;
				row.Gpu = total.Gpu;
				row.Label.Set(source.NameOf(total.Name));
				row.TotalMs = ProfileWindow.TicksToMs(total.TotalTicks, frequency);
				row.SelfMs = ProfileWindow.TicksToMs(total.SelfTicks, frequency);
				row.Count = total.Count;
				mRows.Add(row);
			}
		}
		let sort = mSort;
		let descending = mDescending;
		mRows.Sort(scope (a, b) =>
			{
				int order = 0;
				switch (sort)
				{
				case .Name: order = String.Compare(a.Label, b.Label, false);
				case .Total: order = a.TotalMs <=> b.TotalMs;
				case .Self: order = a.SelfMs <=> b.SelfMs;
				case .Count: order = a.Count <=> b.Count;
				}
				return descending ? -order : order;
			});
		// The selection follows its name through a re-sort or new frames.
		mSelected = -1;
		if (mHasSelection)
		{
			for (int i < mRows.Count)
			{
				if ((mRows[i].Name == mSelectedName) && (mRows[i].Gpu == mSelectedGpu))
					mSelected = i;
			}
		}
	}
}
