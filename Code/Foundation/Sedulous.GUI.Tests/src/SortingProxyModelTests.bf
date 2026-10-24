using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// SortingProxyModel: reorder a source model's rows by a column (numeric by value, strings
/// lexically), toggle asc/desc, map proxy rows to source, and re-sort + notify on source changes.
class SortingProxyModelTests
{
	// Rows: (name, value) = (b,2) (a,10) (c,1).
	private static void FillBAC(TableModel model)
	{
		StringView[2] columns = .("Name", "Value");
		model.SetColumns(columns);
		StringView[3] names = .("b", "a", "c");
		int64[3] values = .(2, 10, 1);
		for (int i = 0; i < 3; i++)
		{
			Sedulous.GUI.Variant[2] row = .(.(names[i]), .(values[i]));
			model.AddRow(row);
		}
	}

	[Test]
	public static void ANumericColumnSortsByValueAscendingAndDescending()
	{
		let source = scope TableModel();
		FillBAC(source);
		let proxy = scope SortingProxyModel(source);

		proxy.Sort(1, .Ascending); // values 2,10,1 -> 1,2,10
		Test.Assert(proxy.RowCount() == 3);
		Test.Assert(proxy.Data(MakeModelIndex(0, 1)).AsInt == 1);
		Test.Assert(proxy.Data(MakeModelIndex(1, 1)).AsInt == 2);
		Test.Assert(proxy.Data(MakeModelIndex(2, 1)).AsInt == 10);
		Test.Assert(proxy.Data(MakeModelIndex(0, 0)).AsString == "c"); // row with value 1
		Test.Assert(proxy.SourceRow(0) == 2);

		proxy.Sort(1, .Descending); // 10,2,1
		Test.Assert(proxy.Data(MakeModelIndex(0, 1)).AsInt == 10);
		Test.Assert(proxy.Data(MakeModelIndex(2, 1)).AsInt == 1);
	}

	[Test]
	public static void AStringColumnSortsLexically()
	{
		let source = scope TableModel();
		FillBAC(source);
		let proxy = scope SortingProxyModel(source);

		proxy.Sort(0, .Ascending); // b,a,c -> a,b,c
		Test.Assert(proxy.Data(MakeModelIndex(0, 0)).AsString == "a");
		Test.Assert(proxy.Data(MakeModelIndex(1, 0)).AsString == "b");
		Test.Assert(proxy.Data(MakeModelIndex(2, 0)).AsString == "c");
	}

	[Test]
	public static void ToggleSortCyclesOrderAndSwitchesColumns()
	{
		let source = scope TableModel();
		FillBAC(source);
		let proxy = scope SortingProxyModel(source);

		proxy.ToggleSort(1);
		Test.Assert(proxy.SortColumn == 1);
		Test.Assert(proxy.SortOrder == .Ascending);
		proxy.ToggleSort(1); // same column -> descending
		Test.Assert(proxy.SortOrder == .Descending);
		proxy.ToggleSort(0); // new column -> ascending
		Test.Assert(proxy.SortColumn == 0);
		Test.Assert(proxy.SortOrder == .Ascending);
	}

	[Test]
	public static void ASourceChangeResortsAndNotifiesTheProxysClients()
	{
		let source = scope TableModel();
		FillBAC(source);
		let proxy = scope SortingProxyModel(source);
		proxy.Sort(1, .Ascending);

		let client = scope CountingClient();
		proxy.AddClient(client);

		Sedulous.GUI.Variant[2] row = .(.("z"), .((int64)0)); // value 0 -> should sort to the front
		source.AddRow(row);

		Test.Assert(client.Updates == 1); // source change propagated
		Test.Assert(proxy.RowCount() == 4);
		Test.Assert(proxy.Data(MakeModelIndex(0, 1)).AsInt == 0); // re-sorted with the new row first
	}

	[Test]
	public static void ARowKeepsItsSourceRowsIdWhenSortedSoASelectionFollowsIt()
	{
		let source = scope TableModel();
		FillBAC(source);
		let proxy = scope SortingProxyModel(source);
		let first = proxy.IdOf(MakeModelIndex(0));
		let name = proxy.Data(MakeModelIndex(0, 0)); // a view of the source's cell, which sorting leaves
		Test.Assert(proxy.Sort(1, .Descending));
		let moved = proxy.IndexOfId(first);
		Test.Assert(moved.IsValid);
		Test.Assert(proxy.Data(MakeModelIndex(moved.Row, 0)).Compare(name) == 0);
	}

	/// No order is the source's; names, edits and a proxy without a source pass through or are
	/// empty; an edit through the proxy lands on its source row and re-sorts.
	[Test]
	public static void NoOrderIsTheSourcesAndAnEditLandsOnTheSourceRow()
	{
		let source = scope TableModel();
		FillBAC(source);
		let proxy = scope SortingProxyModel(source);
		proxy.Sort(1, .Ascending);
		proxy.Sort(1, .None);
		Test.Assert(proxy.Data(MakeModelIndex(0, 0)).AsString == "b");
		Test.Assert(proxy.SourceRow(2) == 2);
		Test.Assert(proxy.SourceRow(3) == -1);
		let column = scope String();
		proxy.ColumnName(1, column);
		Test.Assert(column == "Value");
		Test.Assert(proxy.ColumnCount() == 2);

		proxy.Sort(1, .Ascending); // c(1) b(2) a(10)
		Test.Assert(!proxy.IsEditable(MakeModelIndex(0, 1)));
		source.Editable = true;
		Test.Assert(proxy.IsEditable(MakeModelIndex(0, 1)));
		Test.Assert(proxy.SetData(MakeModelIndex(0, 1), .("5"))); // c: 1 -> 5
		Test.Assert(source.Cell(2, 1).AsInt == 5);
		Test.Assert(proxy.Data(MakeModelIndex(1, 1)).AsInt == 5, "re-sorted: 2, 5, 10");
		Test.Assert(proxy.Data(MakeModelIndex(1, 0)).AsString == "c");

		let alone = scope SortingProxyModel();
		Test.Assert(alone.RowCount() == 0);
		Test.Assert(alone.ColumnCount() == 0);
		Test.Assert(alone.Data(MakeModelIndex(0, 0)).IsEmpty);
		Test.Assert(alone.IdOf(MakeModelIndex(0)) == NoItem);
	}

	/// A proxy leaves its source's clients when it goes, so the source's next change reaches no
	/// proxy that is gone.
	[Test]
	public static void AProxyStopsListeningWhenItGoes()
	{
		let source = scope TableModel();
		FillBAC(source);
		{
			let proxy = scope SortingProxyModel(source);
			Test.Assert(proxy.RowCount() == 3);
		}
		let client = scope CountingClient();
		source.AddClient(client);
		Sedulous.GUI.Variant[2] row = .(.("d"), .((int64)4));
		source.AddRow(row);
		Test.Assert(client.Updates == 1);
		Test.Assert(source.RowCount() == 4);
	}
}
