using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// TableView: a virtualised table over a model (eepp's UITableView in role, its column model the
// fullest of the surveyed ones). ItemView realises its rows; a row's content is one cell
// (`tablecell`) per column. Its header (`tableheader`) shows the column names and stays at the top
// while the rows scroll under it, and across with them. Columns are pixels, a percentage of the
// view's width, or auto (an equal share of what is left, no narrower than a minimum); columns
// wider than the view scroll it across. Dragging a header cell's right edge resizes its column (to
// pixels from then on). A click on a header cell reports its column, or with nothing listening
// sorts by it where the model can; the sorted column's cell shows which way. In markup,
// `columns="Name|Score"` and `<TableItem cells="Ada|42"/>` children make a model of its own
// (behind a sorting proxy, numbers kept as numbers so they sort by value).

// A column's header cell: a click reports its column; a drag from its right edge resizes the
// column; the sorted column's cell shows which way (a triangle, up ascending).
class TableHeaderCell : Label
{
	private const float cGrip = 5.0f; // how near its inline-end edge a press resizes

	private TableView mTable; // the view whose header holds it
	private int mColumn = 0;
	private bool mResizing = false;
	private float mPressX = 0.0f;
	private float mStartWidth = 0.0f;

	public this(TableView table)
	{
		mTable = table;
		Tag = "tableheadercell";
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			SetTextAlignment(.Start, .Middle);
			Padding = .(8.0f, 0.0f, 8.0f, 0.0f);
		}
	}

	public int Column
	{
		get => mColumn;
		set => mColumn = value;
	}

	public bool IsResizing => mResizing;

	// A press on its edge, its inline end, resizes its column: a drag from what holds it is not
	// offered.
	public override bool OwnsPressDrag(Float2 local) => OnGripAt(local.X);

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((e.Button != .Left) || !OnGrip(e.Position))
			return;
		// On its edge: a resize, not a click (no sort follows).
		e.Handled = true;
		mResizing = true;
		mPressX = e.Position.X;
		mStartWidth = mTable.GetColumnWidth(mColumn);
		let d = EventDispatcher;
		if (d != null)
			d.SuppressClick();
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (mResizing)
		{
			// Pulled toward the inline end, it widens.
			let dx = e.Position.X - mPressX;
			mTable.[Friend]ResizeColumn(mColumn, mStartWidth + (IsRightToLeft ? -dx : dx));
			return;
		}
		Cursor = OnGrip(e.Position) ? Sedulous.GUI.Cursor.EwResize : Sedulous.GUI.Cursor.Auto; // the edge says it resizes
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		mResizing = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mResizing = false;
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		e.Handled = true;
		mTable.[Friend]HeaderClicked(mColumn);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if ((mTable.SortColumn != (int32)mColumn) || (mTable.SortOrder == .None))
			return;
		// A small triangle at its inline end, up for ascending, down for descending.
		let @box = ContentBounds;
		let s = 4.0f;
		let cx = Rect.MirroredX(@box.X + @box.Width - s, @box, IsRightToLeft);
		let cy = @box.Y + @box.Height * 0.5f;
		let dir = (mTable.SortOrder == .Ascending) ? -1.0f : 1.0f;
		let pb = scope PathBuilder();
		pb.MoveTo(cx - s, cy - dir * s * 0.5f);
		pb.LineTo(cx + s, cy - dir * s * 0.5f);
		pb.LineTo(cx, cy + dir * s * 0.5f);
		pb.Close();
		let path = pb.ToPath();
		ctx.VG.FillPath(path, TextColor);
		delete path;
	}

	private bool OnGripAt(float x) => IsRightToLeft ? (x <= cGrip) : (x >= Size.X - cGrip);
	private bool OnGrip(Float2 world) => OnGripAt(ConvertToNodeSpace(world).X);
}

// A table row's content: one cell per column, placed by the table's widths.
class TableRowContent : UIWidget
{
	private TableView mTable; // the view whose row holds it
	private List<Label> mCells = new .() ~ { for (let cell in _) cell.ReleaseRef(); delete _; };

	public this(TableView table)
	{
		mTable = table;
		Tag = "tablerowcontent";
	}

	public int CellCount => mCells.Count;
	public Label CellAt(int i) => ((i >= 0) && (i < mCells.Count)) ? mCells[i] : null;

	/// As many cells as `count`.
	public void EnsureCells(int count)
	{
		while (mCells.Count < count)
		{
			let cell = new Label();
			cell.Tag = "tablecell"; // a row's, not a sheet's generic label
			using (StyleWriteScope(cell))
			{
				cell.SetTextAlignment(.Start, .Middle);
				cell.Padding = .(8.0f, 0.0f, 8.0f, 0.0f);
				cell.HitTestVisible = false; // a press on it is the row's
			}
			ShareTextStyle(cell);
			AddChild(cell);
			mCells.Add(cell); // the reference it was made with
		}
		for (int i = 0; i < mCells.Count; ++i)
			mCells[i].Displayed = i < count;
	}

	public override Float2 MeasureContent(Float2 available)
	{
		// As tall as its tallest cell at its column's width.
		float height = 0.0f;
		for (int c = 0; c < mCells.Count; ++c)
		{
			if (mCells[c].Displayed)
			{
				let w = mTable.GetColumnWidth(c);
				height = Math.Max(height, mCells[c].Measure(LayoutConstraints(.(w, 0.0f), .(w, cUnbounded), .(w, -1.0f), true, false)).Y);
			}
		}
		return .(available.X, height);
	}

	public override void OnLayout()
	{
		// Its columns from the inline start.
		let @box = ContentBounds;
		let rtl = IsRightToLeft;
		var x = @box.X;
		for (int c = 0; c < mCells.Count; ++c)
		{
			if (!mCells[c].Displayed)
				continue;
			let w = mTable.GetColumnWidth(c);
			mCells[c].Arrange(Rect.MirroredIn(.(x, @box.Y, w, @box.Height), @box, rtl));
			x += w;
		}
	}

	protected override void OnTextStyleChange()
	{
		for (let cell in mCells)
			ShareTextStyle(cell);
	}
}

/// A row of a table written in markup: its cells as text, '|' between them.
[GuiReflect(true)]
class TableItem : UIWidget
{
	private String mCells = new .() ~ delete _;
	private delegate void() mOnCellsChanged ~ delete _;

	public this()
	{
		Tag = "tableitem";
		Displayed = false; // data, not drawn
	}

	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name != "cells")
			return base.SetMarkupAttribute(name, value);
		mCells.Set(value);
		return true;
	}

	/// Its cells, '|' between them; set after the table took it in (a script's `add` then
	/// `cells`), the table's row follows.
	[GuiProperty]
	public StringView Cells
	{
		get => mCells;
		set
		{
			mCells.Set(value);
			if (mOnCellsChanged != null)
				mOnCellsChanged();
		}
	}

	/// The table that took it in hears when its cells change. OWNERSHIP of `callback` transfers.
	public void SetOnCellsChanged(delegate void() callback)
	{
		delete mOnCellsChanged;
		mOnCellsChanged = callback;
	}
}

[GuiReflect(true), Scriptable]
class TableView : ItemView
{
	private UIWidget mHeader ~ _.ReleaseRef();
	private List<TableHeaderCell> mHeaderCells = new .() ~ { for (let cell in _) cell.ReleaseRef(); delete _; };
	private List<LayoutLength> mColumnWidths = new .() ~ delete _; // auto when unset
	private List<float> mWidths = new .() ~ delete _; // resolved for the current layout (RowWidth works them out)
	private delegate void(int column) mOnHeaderClicked ~ delete _;
	private int32 mSortColumn = -1;
	private Sedulous.GUI.SortOrder mSortOrder = .None;
	private float mHeaderHeight = 26.0f;
	private float mMinColumnWidth = 40.0f;
	private TableModel mOwnTable = null; // markup's rows; let go in the destructor, after its proxy
	private List<TableItem> mRowItems = new .() ~ { for (let item in _) item.ReleaseRef(); delete _; }; // the items they came from, each its row's
	private SortingProxyModel mOwnProxy = null; // over it, so its header sorts
	private Node mMarkupHost = null ~ _?.ReleaseRef(); // where markup's rows land, then taken in
	private bool mEditable = false;
	private Color mHeaderColor = .(0.20f, 0.22f, 0.27f, 1.0f);
	private Color mHeaderTextColor = .(0.86f, 0.89f, 0.94f, 1.0f);
	// What ColumnWidthsText and ColumnsText last wrote.
	private String mColumnWidthsText = new .() ~ delete _;
	private String mColumnsText = new .() ~ delete _;

	public this()
	{
		Tag = "tableview";
		AccessRoleName = "table"; // what a screen reader takes it for
		mHeader = new UIWidget();
		mHeader.Tag = "tableheader";
		mHeader.SetBox(FilledBox(mHeaderColor, scope NodeBox())); // its own face, which a sheet's replaces
		AddChild(mHeader);
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			TextColor = .(0.86f, 0.89f, 0.94f, 1.0f);
			EditLayoutStyle(scope (s) => { s.OverflowX = .Auto; }); // columns past its width
		}
	}

	// Its own model goes before the view's base would let go of it: let go first (the proxy
	// before the model it listens to).
	public ~this()
	{
		Model = null;
		delete mOwnProxy;
		delete mOwnTable;
	}

	public float HeaderHeight
	{
		get => mHeaderHeight;
		set
		{
			mHeaderHeight = Math.Max(0.0f, value);
			RequestLayout();
		}
	}

	/// A column's width: pixels, a percentage of the view's width, or auto.
	public void SetColumnWidth(int column, LayoutLength width)
	{
		while (mColumnWidths.Count <= column)
			mColumnWidths.Add(LayoutLength());
		mColumnWidths[column] = width;
		RequestLayout();
	}

	/// Every column's width as text, one per column (`120px 30% auto`; a bare number is pixels):
	/// markup's `column-widths`.
	[GuiProperty("column-widths"), Scriptable]
	public StringView ColumnWidthsText
	{
		get
		{
			mColumnWidthsText.Clear();
			for (int c = 0; c < mColumnWidths.Count; ++c)
			{
				if (c > 0)
					mColumnWidthsText.Append(' ');
				let w = mColumnWidths[c];
				switch (w.Kind)
				{
				case .Px: mColumnWidthsText.AppendF("{}px", w.Value);
				case .Percent: mColumnWidthsText.AppendF("{}%", w.Value);
				case .Calc: mColumnWidthsText.AppendF("calc({}px + {}%)", w.Value, w.PercentPart);
				default: mColumnWidthsText.Append("auto");
				}
			}
			return mColumnWidthsText;
		}
		set
		{
			mColumnWidths.Clear();
			var rest = ParseUtil.Trim(value);
			while (rest.Length != 0)
			{
				int end = 0;
				while ((end < rest.Length) && (rest[end] != ' '))
					++end;
				let word = rest.Substring(0, end);
				rest = ParseUtil.Trim(rest.Substring(end, rest.Length - end));
				var width = LayoutLength();
				if ((word.Length > 1) && (word[word.Length - 1] == '%'))
					width = LayoutLength.Percent(ParseNumber(word.Substring(0, word.Length - 1)));
				else if (word != "auto")
				{
					let digits = ((word.Length > 2) && (word.Substring(word.Length - 2, 2) == "px")) ? word.Substring(0, word.Length - 2) : word;
					width = LayoutLength.Px(ParseNumber(digits));
				}
				mColumnWidths.Add(width);
			}
			RequestLayout();
		}
	}

	/// The narrowest a column gets (an auto one squeezed, one dragged).
	public float MinColumnWidth
	{
		get => mMinColumnWidth;
		set
		{
			mMinColumnWidth = Math.Max(1.0f, value);
			RequestLayout();
		}
	}

	/// Its columns' total width in the last layout (past the view's: it scrolls across).
	public float ColumnsWidth
	{
		get
		{
			float total = 0.0f;
			for (let w in mWidths)
				total += w;
			return total;
		}
	}

	/// The sort indicator: which column shows which way (a header click that sorts sets it).
	public void SetSortIndicator(int32 column, Sedulous.GUI.SortOrder order)
	{
		mSortColumn = column;
		mSortOrder = order;
		for (let cell in mHeaderCells)
			cell.Invalidate();
	}

	public int32 SortColumn => mSortColumn;
	public Sedulous.GUI.SortOrder SortOrder => mSortOrder;

	/// A column's width in the last layout.
	public float GetColumnWidth(int column) => ((column >= 0) && (column < mWidths.Count)) ? mWidths[column] : 0.0f;
	public int ColumnCount => (Model != null) ? Model.ColumnCount() : 0;

	// === Markup: a model of its own ===

	/// Its columns' names, '|' between them (markup's `columns`).
	[GuiProperty("columns"), Scriptable]
	public StringView ColumnsText
	{
		get
		{
			mColumnsText.Clear();
			let name = scope String();
			for (int c = 0; c < ColumnCount; ++c)
			{
				if (c > 0)
					mColumnsText.Append('|');
				name.Clear();
				Model.ColumnName(c, name);
				mColumnsText.Append(name);
			}
			return mColumnsText;
		}
		set
		{
			EnsureOwnModel();
			let text = scope String(value); // the names are views into it
			let columns = scope List<StringView>();
			SplitItems(text, columns);
			mOwnTable.SetColumns(columns);
		}
	}

	/// Its own model's cells may be edited in place (F2).
	[GuiProperty("editable"), Scriptable]
	public bool Editable
	{
		get => mEditable;
		set
		{
			EnsureOwnModel();
			mOwnTable.Editable = value;
			mEditable = value;
		}
	}

	/// Markup's children are its rows (TableItems).
	public override Node ChildHost
	{
		get
		{
			if (mMarkupHost == null)
				mMarkupHost = new MarkupChildHost(new (host) => { AdoptRows(host); });
			return mMarkupHost;
		}
	}

	/// Header clicks (a column); with none set, a click sorts where the model can. OWNERSHIP of
	/// `callback` transfers.
	public void SetOnColumnHeaderClicked(delegate void(int column) callback)
	{
		delete mOnHeaderClicked;
		mOnHeaderClicked = callback;
	}

	public Node Header => mHeader;

	// Its header cells write in its font (their colour is their own: tableheadercell { color }).
	protected override void OnTextStyleChange()
	{
		for (let h in mHeaderCells)
			ShareTextStyle(h, false);
		base.OnTextStyleChange();
	}

	protected override StringView RowTag => "tablerow";
	protected override float ContentTopInset => mHeaderHeight;

	protected override void OnModelChanged()
	{
		SyncHeader();
	}

	// The columns' widths for this layout, from the content box's width: a row is as wide as the
	// view, or as the columns when they are wider.
	protected override float RowWidth(float width)
	{
		ComputeColumnWidths(width);
		return Math.Max(width, ColumnsWidth);
	}

	protected override Node CreateContent(uint32 type) => new TableRowContent(this);

	protected override void BindContent(Node content, int32 item, ModelIndex index)
	{
		let row = (TableRowContent)content;
		let columns = ColumnCount;
		row.EnsureCells(columns);
		let text = scope String();
		for (int c = 0; c < columns; ++c)
		{
			text.Clear();
			Model.Data(Model.Index(item, (int32)c)).ToString(text);
			row.CellAt(c).Text = text;
		}
	}

	protected override Rect EditRect(ItemRow row, int32 column)
	{
		let @box = row.ContentBounds;
		var x = @box.X;
		for (int32 c = 0; (c < column) && (c < (int32)mWidths.Count); ++c)
			x += mWidths[c];
		return Rect.MirroredIn(.(x, @box.Y, GetColumnWidth(Math.Max(0, column)), @box.Height), @box, IsRightToLeft);
	}

	// The header lies at the top of the view, over the rows scrolled under it.
	protected override void OnLayoutDecorations()
	{
		// Over the rows, from where they start (their columns from the inline start).
		let @box = ContentBounds;
		mHeader.Visible = mHeaderHeight > 0.0f;
		let width = Math.Max(@box.Width, ColumnsWidth);
		mHeader.Arrange(.(RowLeft(@box, width), @box.Y + ScrollOffset.Y, width, mHeaderHeight));
		let across = Rect(0.0f, 0.0f, width, mHeaderHeight);
		let rtl = IsRightToLeft;
		float x = 0.0f;
		for (int c = 0; c < mHeaderCells.Count; ++c)
		{
			let w = GetColumnWidth(c);
			mHeaderCells[c].Arrange(Rect.MirroredIn(.(x, 0.0f, w, mHeaderHeight), across, rtl));
			x += w;
		}
		if (GetChildIndex(mHeader) + 1 != ChildCount)
			mHeader.ToFront(); // drawn, and pressed, over the rows
	}

	// Markup's rows taken in, each item kept: a script that added it sets its cells after,
	// through the handle it holds, and the row follows.
	private void AdoptRows(Node host)
	{
		EnsureOwnModel();
		while (host.ChildCount != 0)
		{
			let child = host.GetChildAt(0);
			child.AddRef(); // held across its move
			host.RemoveChild(child);
			if (let item = child as TableItem)
			{
				let row = mOwnTable.RowCount(ModelIndex());
				let cells = scope List<Sedulous.GUI.Variant>();
				let text = scope String(item.Cells); // the cells view into it
				ParseCells(text, cells);
				mOwnTable.AddRow(cells);
				item.SetOnCellsChanged(new () =>
					{
						let now = scope String(item.Cells);
						let parsed = scope List<Sedulous.GUI.Variant>();
						ParseCells(now, parsed);
						for (int c = 0; c < parsed.Count; ++c)
							mOwnTable.SetCell(row, c, parsed[c]);
					});
				item.AddRef();
				mRowItems.Add(item);
			}
			child.ReleaseRef();
		}
	}

	// The header's cells follow the columns (cells kept while the columns stay, so a press on one
	// that sorts does not free the cell under the pointer).
	private void SyncHeader()
	{
		let columns = ColumnCount;
		while (mHeaderCells.Count > columns)
		{
			let cell = mHeaderCells.PopBack();
			cell.RemoveFromParent();
			cell.ReleaseRef();
		}
		while (mHeaderCells.Count < columns)
		{
			let cell = new TableHeaderCell(this);
			cell.Column = mHeaderCells.Count;
			ShareTextStyle(cell, false);
			using (StyleWriteScope(cell))
			{
				cell.TextColor = mHeaderTextColor;
			}
			mHeader.AddChild(cell);
			mHeaderCells.Add(cell); // the reference it was made with
		}
		let name = scope String();
		for (int c = 0; c < columns; ++c)
		{
			name.Clear();
			Model.ColumnName(c, name);
			mHeaderCells[c].Text = name;
		}
	}

	private void HeaderClicked(int column)
	{
		if (mOnHeaderClicked != null)
		{
			mOnHeaderClicked(column);
			return;
		}
		// Nothing listening: sort by it where the model can (a new column ascending, the same one
		// turning over).
		let order = ((mSortColumn == (int32)column) && (mSortOrder == .Ascending)) ? Sedulous.GUI.SortOrder.Descending : Sedulous.GUI.SortOrder.Ascending;
		if ((Model != null) && Model.Sort(column, order))
			SetSortIndicator((int32)column, order);
	}

	// Pixels and percentages as they say, auto columns an equal share of what is left; none
	// narrower than the minimum (so the columns may come out wider than the view).
	private void ComputeColumnWidths(float bodyWidth)
	{
		let columns = ColumnCount;
		let before = scope List<float>();
		before.AddRange(mWidths);
		mWidths.Clear();
		float given = 0.0f;
		int autoCount = 0;
		for (int c = 0; c < columns; ++c)
		{
			let w = (c < mColumnWidths.Count) ? mColumnWidths[c] : LayoutLength();
			let px = w.Resolve(bodyWidth);
			if (px.HasValue)
				given += Math.Max(mMinColumnWidth, px.Value);
			else
				++autoCount;
		}
		let share = (autoCount > 0) ? (bodyWidth - given) / (float)autoCount : 0.0f;
		for (int c = 0; c < columns; ++c)
		{
			let w = (c < mColumnWidths.Count) ? mColumnWidths[c] : LayoutLength();
			let px = w.Resolve(bodyWidth);
			mWidths.Add(Math.Max(mMinColumnWidth, px.HasValue ? px.Value : share));
		}
		// Widths changed with the row's own width the same (one column narrower, an auto one
		// wider): the rows' cells are placed again, as the header's are.
		bool changed = before.Count != mWidths.Count;
		for (int c = 0; (c < mWidths.Count) && !changed; ++c)
			changed = before[c] != mWidths[c];
		if (changed)
		{
			for (let row in LiveRows)
			{
				let content = row.Content;
				if (content != null)
					content.RequestLayout();
			}
		}
	}

	private void EnsureOwnModel()
	{
		if (mOwnTable != null)
			return;
		mOwnTable = new TableModel();
		mOwnProxy = new SortingProxyModel(mOwnTable);
		Model = mOwnProxy;
	}

	// A row's cells from text, added to `outCells` (text cells are views into `text`): a number
	// stays a number (it sorts by value).
	private static void ParseCells(StringView text, List<Sedulous.GUI.Variant> outCells)
	{
		let cells = scope List<StringView>();
		SplitItems(text, cells);
		for (let cell in cells)
		{
			bool integer = cell.Length != 0;
			for (int i = 0; i < cell.Length; ++i)
				integer = integer && (((cell[i] >= '0') && (cell[i] <= '9')) || ((i == 0) && (cell[i] == '-') && (cell.Length > 1)));
			double? number = null;
			if (double.Parse(cell) case .Ok(let parsed))
				number = parsed;
			if (integer)
				outCells.Add(Sedulous.GUI.Variant((int64)(number ?? 0.0)));
			else if (number.HasValue && (cell.Length != 0))
				outCells.Add(Sedulous.GUI.Variant(number.Value));
			else
				outCells.Add(Sedulous.GUI.Variant(cell));
		}
	}

	// A number written in a width (0 when it is none).
	private static float ParseNumber(StringView text)
	{
		if (double.Parse(text) case .Ok(let value))
			return (float)value;
		return 0.0f;
	}

	// A drag of a header cell's edge: the column takes that many pixels.
	private void ResizeColumn(int column, float width)
	{
		SetColumnWidth(column, LayoutLength.Px(Math.Max(mMinColumnWidth, width)));
	}
}
