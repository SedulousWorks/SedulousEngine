using System;
using System.Collections;

namespace Sedulous.GUI;

// TableModel: a concrete multi-column Model - named columns and a grid of Variant cells, each row
// with an id of its own (eepp's table models in role). Each cell can be any Variant (string,
// number, bool), so numeric columns sort by value (Variant.Compare) rather than as text. Its
// edits tell its views the rows they touch; SetColumns and Clear reset them. It keeps its own
// copy of every name and cell it is given (the caller keeps what it passed) and hands out views.

class TableModel : IModel
{
	private List<String> mColumns = new .() ~ DeleteContainerAndItems!(_);
	private List<List<Sedulous.GUI.Variant>> mRows = new .() ~ { for (let row in _) DeleteRow(row); delete _; };
	private RowIds mIds = new .() ~ delete _;
	private bool mEditable = false;

	public this() { }

	public void SetColumns(Span<StringView> columns)
	{
		// The copies first: `columns` may view the names being replaced.
		let next = new List<String>(columns.Length);
		for (let column in columns)
			next.Add(new String(column));
		DeleteContainerAndItems!(mColumns);
		mColumns = next;
		NotifyReset();
	}

	public void AddRow(Span<Sedulous.GUI.Variant> cells) => InsertRow(mRows.Count, cells);

	/// Inserts a row of copies of `cells` at `at` (past the end: last).
	public void InsertRow(int at, Span<Sedulous.GUI.Variant> cells)
	{
		var at;
		if ((at < 0) || (at > mRows.Count))
			at = mRows.Count;
		let row = new List<Sedulous.GUI.Variant>(cells.Length);
		for (let cell in cells)
			row.Add(cell.Copy());
		mRows.Insert(at, row);
		mIds.Insert(at);
		NotifyRowsInserted(.(), (int32)at, 1);
	}

	public void RemoveRow(int row)
	{
		if ((row < 0) || (row >= mRows.Count))
			return;
		DeleteRow(mRows[row]);
		mRows.RemoveAt(row);
		mIds.Remove(row);
		NotifyRowsRemoved(.(), (int32)row, 1);
	}

	/// Sets a cell to a copy of `value`, the row grown with empty cells to reach it.
	public void SetCell(int row, int column, Sedulous.GUI.Variant value)
	{
		if ((row < 0) || (row >= mRows.Count) || (column < 0))
			return;
		let copy = value.Copy(); // before the old cell goes: `value` may be a view of it
		let cells = mRows[row];
		while (cells.Count <= column)
			cells.Add(.());
		cells[column].Dispose();
		cells[column] = copy;
		NotifyRowsChanged(.(), (int32)row, 1);
	}

	public void Clear()
	{
		for (let row in mRows)
			DeleteRow(row);
		mRows.Clear();
		mIds.Reset(0);
		NotifyReset();
	}

	/// Its cells may be edited in place.
	public bool Editable
	{
		get => mEditable;
		set => mEditable = value;
	}

	// The raw cell (no display conversion), a view of it; empty if out of range.
	public Sedulous.GUI.Variant Cell(int row, int column)
	{
		if ((row < 0) || (row >= mRows.Count) || (column < 0) || (column >= mRows[row].Count))
			return .();
		return mRows[row][column].View();
	}

	public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mRows.Count;
	public override int ColumnCount() => mColumns.Count;

	public override void ColumnName(int column, String outText)
	{
		if ((column >= 0) && (column < mColumns.Count))
			outText.Append(mColumns[column]);
	}

	public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
	{
		if (!IsValidIndex(index))
			return .();
		if ((role == .Display) || (role == .Sort))
			return Cell(index.Row, index.Column);
		return .();
	}

	public override ItemId IdOf(ModelIndex index) => index.IsValid ? mIds.At(index.Row) : NoItem;

	public override ModelIndex IndexOfId(ItemId id)
	{
		let row = mIds.RowOf(id);
		return (row >= 0) ? MakeModelIndex(row) : .();
	}

	public override bool IsEditable(ModelIndex index) => mEditable && IsValidIndex(index);

	public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value)
	{
		if (!IsEditable(index))
			return false;
		// An edit keeps the cell's kind: a number column takes numbers.
		let before = Cell(index.Row, index.Column);
		var next = value;
		if ((before.Kind == .Int) || (before.Kind == .Float))
		{
			let text = scope String();
			value.ToString(text);
			if (!(double.Parse(text) case .Ok(let number)))
				return false;
			next = (before.Kind == .Int) ? Sedulous.GUI.Variant((int64)number) : Sedulous.GUI.Variant(number);
		}
		SetCell(index.Row, index.Column, next);
		return true;
	}

	private static void DeleteRow(List<Sedulous.GUI.Variant> row)
	{
		for (int i = 0; i < row.Count; i++)
			row[i].Dispose();
		delete row;
	}
}
