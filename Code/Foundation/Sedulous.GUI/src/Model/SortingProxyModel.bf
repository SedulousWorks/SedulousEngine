using System;
using System.Collections;

namespace Sedulous.GUI;

// SortingProxyModel: wraps a source Model and presents the same columns with the rows reordered
// by a sort column. Modeled on eepp's Models::SortingProxyModel (role only). It is both an
// IModel (what a view binds to) and an IModelClient of the source (so it re-sorts + re-notifies
// when the source changes). Sorting uses Variant.Compare on the Sort role, so numeric columns
// order by value. A stable sort keeps equal rows in source order.
//
// Because a TableView is a client of this proxy, its column-header click asks the model to Sort,
// which re-sorts and refreshes the view with no view-side changes.

class SortingProxyModel : IModel, IModelClient
{
	/// Not owned: the source outlives the proxy, or is replaced first.
	private IModel mSource = null;
	/// Proxy row -> source row.
	private List<int32> mRowMap = new .() ~ delete _;
	private int32 mSortColumn = -1;
	private SortOrder mOrder = .None;

	public this() { }

	public this(IModel source)
	{
		Source = source;
	}

	public ~this()
	{
		if (mSource != null)
			mSource.RemoveClient(this);
	}

	/// The model it sorts; setting it re-sorts and resets its views.
	public IModel Source
	{
		get => mSource;
		set
		{
			if (mSource != null)
				mSource.RemoveClient(this);
			mSource = value;
			if (mSource != null)
				mSource.AddClient(this);
			Rebuild();
			NotifyReset();
		}
	}

	// Sort by a column in a given order (None restores source order): the sort capability a
	// view's header asks for.
	public override bool Sort(int column, SortOrder order)
	{
		mSortColumn = (int32)column;
		mOrder = order;
		Rebuild();
		NotifyReset();
		return true;
	}

	// Header-click behavior: a new column sorts ascending; the same column toggles
	// ascending <-> descending.
	public void ToggleSort(int column)
	{
		if (mSortColumn == (int32)column)
			mOrder = (mOrder == .Ascending) ? .Descending : .Ascending;
		else
		{
			mSortColumn = (int32)column;
			mOrder = .Ascending;
		}
		Rebuild();
		NotifyReset();
	}

	public int32 SortColumn => mSortColumn;
	public SortOrder SortOrder => mOrder;

	// The source row a proxy row maps to (-1 if out of range).
	public int32 SourceRow(int32 proxyRow) => ((proxyRow >= 0) && (proxyRow < mRowMap.Count)) ? mRowMap[proxyRow] : -1;

	// The source changed, in any way: re-sort and reset our own views (a range in the source
	// lands anywhere in the sorted order). The ranges default to this.
	public void OnModelReset()
	{
		Rebuild();
		NotifyReset();
	}

	public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mRowMap.Count;
	public override int ColumnCount() => (mSource != null) ? mSource.ColumnCount() : 0;

	public override void ColumnName(int column, String outText)
	{
		if (mSource != null)
			mSource.ColumnName(column, outText);
	}

	public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
	{
		let sourceRow = SourceRow(index.Row);
		if ((mSource == null) || (sourceRow < 0))
			return .();
		return mSource.Data(MakeModelIndex(sourceRow, index.Column), role);
	}

	// A row keeps its source row's id, so a view's selection survives a sort.
	public override ItemId IdOf(ModelIndex index)
	{
		let sourceRow = SourceRow(index.Row);
		return ((mSource != null) && (sourceRow >= 0)) ? mSource.IdOf(mSource.Index(sourceRow, index.Column)) : NoItem;
	}

	public override bool IsEditable(ModelIndex index)
	{
		let sourceRow = SourceRow(index.Row);
		return (mSource != null) && (sourceRow >= 0) && mSource.IsEditable(MakeModelIndex(sourceRow, index.Column));
	}

	public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value)
	{
		let sourceRow = SourceRow(index.Row);
		return (mSource != null) && (sourceRow >= 0) && mSource.SetData(MakeModelIndex(sourceRow, index.Column), value);
	}

	private void Rebuild()
	{
		let n = (mSource != null) ? mSource.RowCount() : 0;
		mRowMap.Clear();
		for (int i = 0; i < n; i++)
			mRowMap.Add((int32)i);
		if ((mSource != null) && (mSortColumn >= 0) && (mOrder != .None))
			StableSort();
	}

	// Stable insertion sort of mRowMap by the sort column's Variant order.
	private void StableSort()
	{
		let ascending = mOrder == .Ascending;
		for (int a = 1; a < mRowMap.Count; a++)
		{
			let key = mRowMap[a];
			int b = a;
			while ((b > 0) && ShouldPrecede(key, mRowMap[b - 1], ascending))
			{
				mRowMap[b] = mRowMap[b - 1];
				b--;
			}
			mRowMap[b] = key;
		}
	}

	// True if source row `lhs` should sort before `rhs` (strictly; equal keeps order = stable).
	private bool ShouldPrecede(int32 lhs, int32 rhs, bool ascending)
	{
		let a = mSource.Data(MakeModelIndex(lhs, mSortColumn), .Sort);
		let b = mSource.Data(MakeModelIndex(rhs, mSortColumn), .Sort);
		let cmp = a.Compare(b);
		if (cmp == 0)
			return false;
		return ascending ? (cmp < 0) : (cmp > 0);
	}
}
