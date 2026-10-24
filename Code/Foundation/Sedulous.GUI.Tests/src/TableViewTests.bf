using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// TableModel + TableView tests: multi-column data, virtualized rows with a header, single
// selection (mouse + keyboard), and header-click reporting (for sorting).

/// A table model's columns, rows and typed cells (the view's tests wait for TableView).
class TableViewTests
{
	// A 2-column model (Name, Age) with `count` rows.
	private static void FillPeople(TableModel model, int count)
	{
		StringView[2] columns = .("Name", "Age");
		model.SetColumns(columns);
		for (int i = 0; i < count; i++)
		{
			Sedulous.GUI.Variant[2] row = .(.((StringView)"Person"), .((int64)(20 + i)));
			model.AddRow(row);
		}
	}

	[Test]
	public static void TableModelColumnsRowsAndTypedCells()
	{
		let model = scope TableModel();
		FillPeople(model, 3);

		Test.Assert(model.ColumnCount() == 2);
		Test.Assert(model.RowCount() == 3);
		let name = scope String();
		model.ColumnName(0, name);
		Test.Assert(name == "Name");
		name.Clear();
		model.ColumnName(1, name);
		Test.Assert(name == "Age");
		Test.Assert(model.Data(MakeModelIndex(0, 0)).AsString == "Person");
		Test.Assert(model.Data(MakeModelIndex(1, 1)).AsInt == 21);
		Test.Assert(model.Data(MakeModelIndex(1, 1)).ToString(.. scope String()) == "21");
		Test.Assert(model.Data(MakeModelIndex(9, 0)).IsEmpty); // out of range
	}
}
