using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Counts model-update notifications.
class CountingClient : IModelClient
{
	public int Updates = 0;

	public void OnModelReset() { Updates++; }
}

/// Records each range a model reports, as text.
class RangeClient : IModelClient
{
	public List<String> Seen = new .() ~ DeleteContainerAndItems!(_);

	public void OnModelReset() { Seen.Add(new String("reset")); }

	public void OnRowsInserted(ModelIndex parent, int32 first, int32 count)
	{
		Seen.Add(new String()..AppendF("insert {} {} {}", parent.InternalId, first, count));
	}

	public void OnRowsRemoved(ModelIndex parent, int32 first, int32 count)
	{
		Seen.Add(new String()..AppendF("remove {} {} {}", parent.InternalId, first, count));
	}

	public void OnRowsMoved(ModelIndex parent, int32 first, int32 count, int32 to)
	{
		Seen.Add(new String()..AppendF("move {} {} {} {}", parent.InternalId, first, count, to));
	}

	public void OnRowsChanged(ModelIndex parent, int32 first, int32 count)
	{
		Seen.Add(new String()..AppendF("change {} {} {}", parent.InternalId, first, count));
	}
}

/// The MVC data core: Variant (typed value, ToString, Compare, ownership), ModelIndex, the list,
/// table and tree models (rows, data, ids, edits, drops, client notification) and RowIds.
class ModelTests
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// Whether `value` displays as `expected`.
	private static bool Writes(Sedulous.GUI.Variant value, StringView expected)
	{
		let text = scope String();
		value.ToString(text);
		return text == expected;
	}

	[Test]
	public static void ModelIndexValidityAndEquality()
	{
		Test.Assert(!ModelIndex().IsValid); // default row -1
		Test.Assert(MakeModelIndex(0, 0).IsValid);
		Test.Assert(MakeModelIndex(3, 1) == MakeModelIndex(3, 1));
		Test.Assert(!(MakeModelIndex(3, 1) == MakeModelIndex(3, 2)));
	}

	[Test]
	public static void VariantTypesAccessorsToString()
	{
		Test.Assert(Sedulous.GUI.Variant().IsEmpty);
		Test.Assert(Sedulous.GUI.Variant(true).Kind == .Bool);
		Test.Assert(Sedulous.GUI.Variant((int64)42).AsInt == 42);
		Test.Assert(Sedulous.GUI.Variant("hi").AsString == "hi");

		Test.Assert(Writes(.((int64)-7), "-7"));
		Test.Assert(Writes(.((int64)0), "0"));
		Test.Assert(Writes(.(true), "true"));
		Test.Assert(Writes(.("text"), "text"));
		Test.Assert(Writes(.(1.5), "1.5"));
		Test.Assert(Writes(.(3.0), "3")); // trailing zeros trimmed
	}

	[Test]
	public static void VariantCompareOrdersNumbersAndStrings()
	{
		Test.Assert(Sedulous.GUI.Variant((int64)1).Compare(.((int64)2)) < 0);
		Test.Assert(Sedulous.GUI.Variant((int64)5).Compare(.((int64)5)) == 0);
		Test.Assert(Sedulous.GUI.Variant("apple").Compare(.("banana")) < 0);
		Test.Assert(Sedulous.GUI.Variant("pear").Compare(.("peach")) > 0);
		// An int against a float by value, not by type (a mixed numeric column sorts as numbers).
		Test.Assert(Sedulous.GUI.Variant((int64)3).Compare(.(2.5)) > 0);
		Test.Assert(Sedulous.GUI.Variant(1.5).Compare(.((int64)2)) < 0);
		Test.Assert(Sedulous.GUI.Variant((int64)2).Compare(.(2.0)) == 0);
	}

	[Test]
	public static void AColourIsWrittenAsItsHexCodeAndDifferingColoursNeverCompareEqual()
	{
		Test.Assert(Writes(.(Color(1.0f, 0.5f, 0.0f, 1.0f)), "#FF8000FF"));
		Test.Assert(Sedulous.GUI.Variant(Color(0.1f, 0.2f, 0.3f, 1.0f)).Compare(.(Color(0.1f, 0.2f, 0.3f, 1.0f))) == 0);
		Test.Assert(Sedulous.GUI.Variant(Color(0.1f, 0.2f, 0.3f, 1.0f)).Compare(.(Color(0.1f, 0.25f, 0.3f, 1.0f))) < 0);
		Test.Assert(Sedulous.GUI.Variant(Color(0.1f, 0.2f, 0.3f, 1.0f)).Compare(.(Color(0.1f, 0.2f, 0.3f, 0.5f))) > 0);
	}

	[Test]
	public static void ACurvesKeysAndAGradientAreOneValueEachEqualOnlyWhenEveryFieldIs()
	{
		CurveKey[2] keys = .(.(), .());
		keys[0].Time = 0.0f;
		keys[1].Time = 1.0f;
		keys[1].Value = 2.0f;
		// Its own copy: the keys change below.
		var curve = Sedulous.GUI.Variant.FromCurve(keys).Copy();
		defer curve.Dispose();
		Test.Assert(curve.Kind == .Curve);
		Test.Assert(curve.AsCurve.Length == 2);
		Test.Assert(curve.AsCurve[1].Value == 2.0f);
		Test.Assert(Writes(curve, "2 keys"));
		Test.Assert(curve.Compare(Sedulous.GUI.Variant.FromCurve(keys)) == 0);
		keys[1].TangentMode = .Flat;
		Test.Assert(curve.Compare(Sedulous.GUI.Variant.FromCurve(keys)) != 0);
		Test.Assert(curve.Compare(Sedulous.GUI.Variant.FromCurve(Span<CurveKey>(&keys[0], 1))) > 0); // more keys after
		Test.Assert(Sedulous.GUI.Variant(1.0).AsCurve.IsEmpty);

		let gradient = scope ColorGradient();
		gradient.Colors.Add(.(0.0f, Color(1.0f, 0.0f, 0.0f, 1.0f)));
		gradient.Alphas.Add(.(0.0f, 1.0f));
		gradient.Alphas.Add(.(1.0f, 0.0f));
		var value = Sedulous.GUI.Variant(gradient).Copy();
		defer value.Dispose();
		Test.Assert(value.Kind == .Gradient);
		Test.Assert(Writes(value, "1 colours, 2 alphas"));
		Test.Assert(value.AsGradient.Equals(gradient));
		Test.Assert(value.AsGradient !== gradient, "a copy holds its own gradient");
		Test.Assert(value.Compare(.(gradient)) == 0);
		let other = scope ColorGradient();
		other.Set(gradient);
		other.Interpolation = .OkLab;
		Test.Assert(value.Compare(.(other)) != 0);
		other.Set(gradient);
		other.Alphas[1].Alpha = 0.5f;
		Test.Assert(value.Compare(.(other)) < 0);
		Test.Assert(Near(gradient.Evaluate(0.5f).A, 0.5f));
	}

	/// A Variant built from text borrows it; a copy owns its own, and a view of the copy owns
	/// nothing, so disposing the view leaves the copy whole.
	[Test]
	public static void AVariantBorrowsWhatItIsBuiltFromAndACopyOwnsItsOwn()
	{
		let text = scope String("before");
		let view = Sedulous.GUI.Variant((StringView)text);
		Test.Assert(!view.IsOwner);
		Test.Assert(view.AsString.Ptr == text.Ptr, "a view, not a copy");

		var owned = view.Copy();
		defer owned.Dispose();
		Test.Assert(owned.IsOwner);
		Test.Assert(owned.AsString.Ptr != text.Ptr);
		text.Set("changed");
		Test.Assert(owned.AsString == "before");

		var borrowed = owned.View();
		Test.Assert(!borrowed.IsOwner);
		borrowed.Dispose(); // a view's: nothing freed
		Test.Assert(owned.AsString == "before");

		var temporary = owned.Copy();
		temporary.Dispose();
		Test.Assert(temporary.IsEmpty, "a disposed copy is left empty");
	}

	/// The conversions between kinds: an int reads as a float and a bool, a float as a truncated
	/// int, anything else as zero; a float writes at most three decimals.
	[Test]
	public static void AVariantReadsAcrossNumericKindsAndWritesAShortFloat()
	{
		Test.Assert(Sedulous.GUI.Variant((int64)3).AsFloat == 3.0);
		Test.Assert(Sedulous.GUI.Variant(2.9).AsInt == 2);
		Test.Assert(Sedulous.GUI.Variant(-2.9).AsInt == -2);
		Test.Assert(!Sedulous.GUI.Variant((int64)0).AsBool);
		Test.Assert(Sedulous.GUI.Variant((int64)4).AsBool);
		Test.Assert(!Sedulous.GUI.Variant(1.0).AsBool, "a float is no bool");
		Test.Assert(Sedulous.GUI.Variant("7").AsInt == 0, "text is no number");
		Test.Assert(Sedulous.GUI.Variant((int64)7).AsString.IsEmpty);
		Test.Assert(Writes(.(-2.25), "-2.25"));
		Test.Assert(Writes(.(0.1234), "0.123"));
		Test.Assert(Writes(.(), ""));
		Test.Assert(Writes(.(false), "false"));
	}

	/// Mixed kinds order by their kind's ordinal (empty, bool, int, float, string, ...), numbers
	/// apart; false sorts before true.
	[Test]
	public static void MixedKindsOrderByKindAndFalseBeforeTrue()
	{
		Test.Assert(Sedulous.GUI.Variant().Compare(.(false)) < 0);
		Test.Assert(Sedulous.GUI.Variant().Compare(.()) == 0);
		Test.Assert(Sedulous.GUI.Variant((int64)100).Compare(.("a")) < 0);
		Test.Assert(Sedulous.GUI.Variant("a").Compare(.(1.0)) > 0);
		Test.Assert(Sedulous.GUI.Variant(false).Compare(.(true)) < 0);
		Test.Assert(Sedulous.GUI.Variant(true).Compare(.(true)) == 0);
		Test.Assert(Sedulous.GUI.Variant("ab").Compare(.("abc")) < 0, "a prefix first");
	}

	[Test]
	public static void StringListModelRowsColumnsData()
	{
		StringView[2] items = .("Alpha", "Beta");
		let model = scope StringListModel(items);

		Test.Assert(model.RowCount() == 2);
		Test.Assert(model.ColumnCount() == 1);
		Test.Assert(model.Data(MakeModelIndex(0)).AsString == "Alpha");
		Test.Assert(model.Data(MakeModelIndex(1), .Sort).AsString == "Beta");

		// Out-of-range -> empty variant.
		Test.Assert(model.Data(MakeModelIndex(5)).IsEmpty);
		Test.Assert(!model.IsValidIndex(MakeModelIndex(2)));
	}

	[Test]
	public static void MutatingNotifiesRegisteredClients()
	{
		let model = scope StringListModel();
		let client = scope CountingClient();
		model.AddClient(client);

		model.AddItem("one");
		Test.Assert(client.Updates == 1);
		Test.Assert(model.RowCount() == 1);

		model.SetItems(.());
		Test.Assert(client.Updates == 2);
		Test.Assert(model.RowCount() == 0);

		model.RemoveClient(client);
		model.AddItem("ignored"); // no longer notified
		Test.Assert(client.Updates == 2);
	}

	[Test]
	public static void AListReportsInsertedRemovedMovedAndChangedRowsAndResetsForTheRest()
	{
		let model = scope StringListModel();
		let client = scope RangeClient();
		model.AddClient(client);
		model.AddItem("a");
		model.AddItem("c");
		model.InsertItem(1, "b");
		model.SetItem(2, "C");
		model.MoveItem(0, 2);
		model.RemoveItem(1);
		model.Clear();
		Test.Assert(client.Seen.Count == 7);
		Test.Assert(client.Seen[0] == "insert -1 0 1");
		Test.Assert(client.Seen[1] == "insert -1 1 1");
		Test.Assert(client.Seen[2] == "insert -1 1 1");
		Test.Assert(client.Seen[3] == "change -1 2 1");
		Test.Assert(client.Seen[4] == "move -1 0 1 2");
		Test.Assert(client.Seen[5] == "remove -1 1 1");
		Test.Assert(client.Seen[6] == "reset");
	}

	[Test]
	public static void AClientThatFollowsNoRangesTakesEachAsAReset()
	{
		let model = scope StringListModel();
		let client = scope CountingClient();
		model.AddClient(client);
		model.AddItem("a");
		model.SetItem(0, "b");
		model.RemoveItem(0);
		Test.Assert(client.Updates == 3);
	}

	[Test]
	public static void ARowKeepsItsIdWhileRowsAreInsertedMovedAndRemovedAroundIt()
	{
		let model = scope StringListModel();
		model.AddItem("a");
		model.AddItem("b");
		let b = model.IdOf(MakeModelIndex(1));
		model.InsertItem(0, "first");
		Test.Assert(model.IdOf(MakeModelIndex(2)) == b);
		model.MoveItem(2, 0);
		Test.Assert(model.IdOf(MakeModelIndex(0)) == b);
		model.RemoveItem(1);
		Test.Assert(model.IndexOfId(b).Row == 0);
		Test.Assert(model.IdOf(MakeModelIndex(1)) != b);
		Test.Assert(!model.IndexOfId(12345).IsValid);
	}

	[Test]
	public static void EditingIsACapabilityATableCellKeepsItsKind()
	{
		let list = scope StringListModel();
		list.AddItem("a");
		Test.Assert(!list.IsEditable(MakeModelIndex(0)));
		Test.Assert(!list.SetData(MakeModelIndex(0), .("b")));
		list.Editable = true;
		Test.Assert(list.SetData(MakeModelIndex(0), .("b")));
		Test.Assert(list.ItemAt(0) == "b");

		let table = scope TableModel();
		StringView[2] columns = .("Name", "Score");
		table.SetColumns(columns);
		Sedulous.GUI.Variant[2] row = .(.("Ada"), .((int64)3));
		table.AddRow(row);
		table.Editable = true;
		Test.Assert(table.SetData(MakeModelIndex(0, 1), .("42")));
		Test.Assert(table.Cell(0, 1).Kind == .Int);
		Test.Assert(table.Cell(0, 1).AsInt == 42);
		Test.Assert(!table.SetData(MakeModelIndex(0, 1), .("many"))); // not a number: refused
		Test.Assert(table.Cell(0, 1).AsInt == 42);
		Test.Assert(!table.Sort(1, .Ascending)); // a table alone cannot sort; a proxy can
	}

	/// A table keeps its own copies of names and cells, grows a row to the cell set past its end,
	/// keeps a float column's kind on an edit, and reports its rows' changes.
	[Test]
	public static void ATableKeepsItsOwnCellsAndReportsItsRows()
	{
		let table = scope TableModel();
		let client = scope RangeClient();
		table.AddClient(client);
		let name = scope String("Ada");
		StringView[2] columns = .("Name", "Weight");
		table.SetColumns(columns);
		Sedulous.GUI.Variant[2] row = .(.((StringView)name), .(1.5));
		table.AddRow(row);
		name.Set("Bob");
		Test.Assert(table.Cell(0, 0).AsString == "Ada", "the table's own copy");
		let column = scope String();
		table.ColumnName(1, column);
		Test.Assert(column == "Weight");
		table.ColumnName(5, column);
		Test.Assert(column == "Weight", "no name past the end");

		table.Editable = true;
		Test.Assert(table.SetData(MakeModelIndex(0, 1), .("2.25")));
		Test.Assert(table.Cell(0, 1).Kind == .Float);
		Test.Assert(table.Cell(0, 1).AsFloat == 2.25);
		Test.Assert(table.SetData(MakeModelIndex(0, 0), table.Data(MakeModelIndex(0, 0))), "a cell set to a view of itself");
		Test.Assert(table.Cell(0, 0).AsString == "Ada");

		table.SetCell(0, 3, .(true));
		Test.Assert(table.Cell(0, 2).IsEmpty, "grown with empty cells");
		Test.Assert(table.Cell(0, 3).AsBool);
		Test.Assert(table.Cell(1, 0).IsEmpty);
		table.RemoveRow(0);
		Test.Assert(table.RowCount() == 0);
		Test.Assert(client.Seen.Count == 6);
		Test.Assert(client.Seen[0] == "reset");
		Test.Assert(client.Seen[1] == "insert -1 0 1");
		Test.Assert(client.Seen[2] == "change -1 0 1");
		Test.Assert(client.Seen[3] == "change -1 0 1");
		Test.Assert(client.Seen[4] == "change -1 0 1");
		Test.Assert(client.Seen[5] == "remove -1 0 1");
	}

	[Test]
	public static void ATreeReportsRowsUnderTheirParentAndARemovedNodesIdIsNotReused()
	{
		let tree = scope TreeModel();
		let client = scope RangeClient();
		tree.AddClient(client);
		let a = tree.AddNode(TreeModel.Root, "A");
		let a1 = tree.AddNode(a, "A1");
		let a2 = tree.AddNode(a, "A2");
		tree.SetText(a2, "A two");
		tree.RemoveNode(a1);
		Test.Assert(client.Seen.Count == 5);
		Test.Assert(client.Seen[0] == "insert -1 0 1");
		Test.Assert(client.Seen[1] == scope String()..AppendF("insert {} 0 1", a));
		Test.Assert(client.Seen[2] == scope String()..AppendF("insert {} 1 1", a));
		Test.Assert(client.Seen[3] == scope String()..AppendF("change {} 1 1", a));
		Test.Assert(client.Seen[4] == scope String()..AppendF("remove {} 0 1", a));
		Test.Assert(tree.RowCount(tree.IndexOfNode(a)) == 1);
		Test.Assert(tree.IdOf(tree.Index(0, 0, tree.IndexOfNode(a))) == (ItemId)a2);
		let b = tree.AddNode(TreeModel.Root, "B");
		Test.Assert(b != a1);
		Test.Assert(!tree.IndexOfNode(a1).IsValid);
	}

	[Test]
	public static void AnIdsRowIsFoundAfterRowsAreInsertedMovedAndRemoved()
	{
		let ids = scope RowIds();
		ids.Reset(5); // ids 0..4 in rows 0..4
		Test.Assert(ids.RowOf(3) == 3);
		ids.Insert(0); // id 5 at the top
		Test.Assert(ids.RowOf(5) == 0);
		Test.Assert(ids.RowOf(3) == 4);
		ids.Move(4, 1); // id 3 to row 1
		Test.Assert(ids.RowOf(3) == 1);
		Test.Assert(ids.RowOf(1) == 3);
		ids.Remove(1);
		Test.Assert(ids.RowOf(3) == -1);
		Test.Assert(ids.RowOf(4) == 4);
		ids.InsertId(2, 3); // back, keeping its id
		Test.Assert(ids.RowOf(3) == 2);
		Test.Assert(ids.RowOf(99) == -1);
	}

	/// A list's drops: its own rows move between rows keeping their ids, another model's are
	/// copied in, text comes in as a row; onto a row is no place, a link is refused with a reason.
	[Test]
	public static void AListTakesRowsAndTextDroppedBetweenItsRows()
	{
		StringView[3] items = .("a", "b", "c");
		let model = scope StringListModel(items);
		let client = scope CountingClient();
		model.AddClient(client);
		let idA = model.IdOf(MakeModelIndex(0));

		ItemId[1] moving = .(idA);
		ModelDrop drop = .();
		drop.Source = model;
		drop.Ids = moving;
		drop.Index = MakeModelIndex(2);
		drop.Place = .After;
		drop.Effect = .Move;
		let reason = scope String();
		Test.Assert(model.CanDrop(drop, reason) == .Move);
		Test.Assert(model.Drop(drop));
		Test.Assert(model.RowCount() == 3);
		Test.Assert((model.ItemAt(0) == "b") && (model.ItemAt(1) == "c") && (model.ItemAt(2) == "a"));
		Test.Assert(model.IdOf(MakeModelIndex(2)) == idA, "a moved row keeps its id");
		Test.Assert(client.Updates == 1);

		drop.Place = .On;
		Test.Assert(model.CanDrop(drop, reason) == .None);
		Test.Assert(reason.IsEmpty, "no reason: the view tries between");
		drop.Place = .After;
		drop.Effect = .Link;
		Test.Assert(model.CanDrop(drop, reason) == .None);
		Test.Assert(reason == "A list cannot link its rows");
		Test.Assert(!model.Drop(drop));

		StringView[1] otherItems = .("x");
		let other = scope StringListModel(otherItems);
		ItemId[1] copying = .(other.IdOf(MakeModelIndex(0)));
		ModelDrop copy = .();
		copy.Source = other;
		copy.Ids = copying;
		copy.Effect = .Copy; // an invalid index: the end
		Test.Assert(model.Drop(copy));
		Test.Assert(model.RowCount() == 4);
		Test.Assert(model.ItemAt(3) == "x");
		Test.Assert(model.IdOf(MakeModelIndex(3)) != idA);
		Test.Assert(other.RowCount() == 1, "a copy leaves the source as it was");

		let payload = scope DragPayload();
		payload.Type.Set("text");
		payload.Value = TextVariant("hello");
		ModelDrop text = .();
		text.Payload = payload;
		text.Index = MakeModelIndex(0);
		text.Place = .Before;
		Test.Assert(model.CanDrop(text, reason) == .Copy);
		Test.Assert(model.Drop(text));
		Test.Assert(model.ItemAt(0) == "hello");

		ItemId[1] removing = .(model.IdOf(MakeModelIndex(0)));
		Test.Assert(model.RemoveIds(removing));
		Test.Assert(model.ItemAt(0) == "b");
		ItemId[1] none = .(12345);
		Test.Assert(!model.RemoveIds(none));
	}

	/// A tree's drops: a node moves onto another (its last child), never inside itself; text
	/// comes in as a new node where it is dropped.
	[Test]
	public static void ATreeMovesItsNodesOntoOthersButNeverInsideThemselves()
	{
		let tree = scope TreeModel();
		let a = tree.AddNode(TreeModel.Root, "A");
		let a1 = tree.AddNode(a, "A1");
		let b = tree.AddNode(TreeModel.Root, "B");
		Test.Assert(!tree.MoveNode(a, a1, 0), "inside itself");

		ItemId[1] movingA = .((ItemId)a);
		ModelDrop inside = .();
		inside.Source = tree;
		inside.Ids = movingA;
		inside.Index = tree.IndexOfNode(a1);
		inside.Place = .On;
		let reason = scope String();
		Test.Assert(tree.CanDrop(inside, reason) == .None);
		Test.Assert(reason == "A node cannot go inside itself");

		ItemId[1] movingB = .((ItemId)b);
		ModelDrop onto = .();
		onto.Source = tree;
		onto.Ids = movingB;
		onto.Index = tree.IndexOfNode(a);
		onto.Place = .On;
		Test.Assert(tree.CanDrop(onto, reason) == .Move);
		Test.Assert(tree.Drop(onto));
		Test.Assert(tree.RowCount() == 1);
		Test.Assert(tree.RowCount(tree.IndexOfNode(a)) == 2);
		Test.Assert(tree.ParentIndex(tree.IndexOfNode(b)) == tree.IndexOfNode(a));
		Test.Assert(tree.IndexOfNode(b).Row == 1, "its last child");

		let payload = scope DragPayload();
		payload.Type.Set("text");
		payload.Label.Set("T");
		ModelDrop text = .();
		text.Payload = payload; // no value: its label
		Test.Assert(tree.CanDrop(text, reason) == .Copy);
		Test.Assert(tree.Drop(text));
		Test.Assert(tree.RowCount() == 2);
		Test.Assert(tree.Data(tree.Index(1)).AsString == "T");
		Test.Assert(!tree.HasChildren(tree.Index(1)));
		Test.Assert(tree.HasChildren());
	}

	/// A list made in code: its edits reach the model's views as ranges; a row past the end reads
	/// empty; markup may build one by its tag.
	[Test]
	public static void AScriptsListEditsItsModelAndIsBuiltByItsTag()
	{
		let list = new ListModel();
		defer list.ReleaseRef();
		let client = scope RangeClient();
		list.Model.AddClient(client);
		list.Add("b");
		list.Insert(-3, "a"); // before the first
		list.Add("c");
		Test.Assert(list.Count == 3);
		Test.Assert(list.Get(0) == "a");
		list.Set(2, "C");
		Test.Assert(list.Get(2) == "C");
		Test.Assert(list.Get(5).IsEmpty);
		list.Remove(-1); // nothing
		list.Remove(1);
		Test.Assert(list.Count == 2);
		Test.Assert(list.Model.ItemAt(1) == "C");
		list.Clear();
		Test.Assert(list.Count == 0);
		Test.Assert(client.Seen.Count == 6);
		Test.Assert(client.Seen[0] == "insert -1 0 1");
		Test.Assert(client.Seen[1] == "insert -1 0 1");
		Test.Assert(client.Seen[2] == "insert -1 2 1");
		Test.Assert(client.Seen[3] == "change -1 2 1");
		Test.Assert(client.Seen[4] == "remove -1 1 1");
		Test.Assert(client.Seen[5] == "reset");

		let info = ListModel.StaticGuiType;
		Test.Assert(info.Tag == "ListModel");
		Test.Assert(info.OwnProperties.Length == 0);
		Test.Assert(info.CanCreate);
		let made = info.Create();
		Test.Assert(made is ListModel);
		(made as ListModel).ReleaseRef();
	}
}
