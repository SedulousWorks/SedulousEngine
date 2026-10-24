using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A grid 300 by 240 in a root 400 by 300, over a bag of `objects` objects. The root goes with it.
class GridBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public PropertyGrid Grid = new .() ~ _.ReleaseRef();
	public Sedulous.GUI.PropertyBag Bag ~ delete _;

	public this(int objects = 1)
	{
		Bag = new Sedulous.GUI.PropertyBag(objects);
		Root = NewRoot(400.0f, 300.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Grid.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Height = LayoutLength.Px(240.0f);
			});
		Root.AddChild(Grid);
	}

	public ~this()
	{
		Grid.Source = null;
	}

	public PropertyInfo Add(StringView path, PropertyKind kind, Sedulous.GUI.Variant value, StringView category = "")
	{
		let info = Bag.Add(path, kind, value);
		info.Category.Set(category);
		return info;
	}

	public PropertyInfo Add(StringView path, PropertyKind kind) => Add(path, kind, .());

	public void Show()
	{
		Grid.Source = Bag;
		Frame();
	}

	public void Frame()
	{
		Root.UpdateLayout();
	}

	/// The rows' paths, joined by spaces, appended to `outText`.
	public void Paths(String outText)
	{
		for (int32 i = 0; i < (int32)Grid.RowCount; ++i)
		{
			if (outText.Length != 0)
				outText.Append(" ");
			outText.Append(Grid.GetRow(i).Path);
		}
	}

	public bool PathsAre(StringView expected)
	{
		let paths = Paths(.. scope String());
		if (paths != expected)
		{
			Console.WriteLine("the rows: \"{}\"", paths);
			return false;
		}
		return true;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public static Float2 Centre(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	/// The list's elements' values, as text, joined by spaces.
	public void Elements(StringView list, int object, String outText)
	{
		for (int i = 0; i < Bag.ElementCount(list, object); ++i)
		{
			if (outText.Length != 0)
				outText.Append(" ");
			var value = Bag.GetValue(scope String()..AppendF("{}.{}", list, i), object);
			value.ToString(outText);
			value.Dispose();
		}
	}

	/// Activates the item of `menu` saying `text`.
	public static void Activate(Sedulous.GUI.Menu menu, StringView text)
	{
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
			{
				if (item.Text == text)
				{
					item.HandleActivate();
					return;
				}
			}
		}
		Test.FatalError("no such item");
	}
}

/// The property grid: a source's properties as rows, categories first-seen and groups folded by
/// path, a search keeping what holds a match, only the rows in view realised, one label split
/// dragged at any row, the wheel scrolling and never editing, and an edit as the source's gesture,
/// its row not rebound from its own previews.
class PropertyGridTests
{
	[Test]
	public static void WhatHasNoCategoryFirstThenCategoriesAsTheyFirstComeGroupsStartFolded()
	{
		let bed = scope GridBed();
		bed.Add("name", .String, Sedulous.GUI.Variant("Lamp"));
		bed.Add("intensity", .Float, Sedulous.GUI.Variant(1.0), "Light");
		bed.Add("position", .Group, .(), "Transform");
		bed.Add("position.x", .Float, Sedulous.GUI.Variant(0.0));
		bed.Add("position.y", .Float, Sedulous.GUI.Variant(0.0));
		bed.Add("color", .Float, Sedulous.GUI.Variant(0.5), "Light");
		bed.Add("secret", .Bool, Sedulous.GUI.Variant(false)).Visible = false;
		bed.Show();
		Test.Assert(bed.PathsAre("name #Light intensity color #Transform position"));
		Test.Assert(bed.Grid.GetRow(1).Category);
		Test.Assert(bed.Grid.GetRow(5).HasChildren);
		Test.Assert(!bed.Grid.GetRow(5).Open);
		Test.Assert(bed.Grid.FindEditor("intensity") != null);

		// A group opened shows its parts a level in; the folding is by path, so it stays when the
		// source's properties are read again.
		bed.Grid.SetOpen("position", true);
		Test.Assert(bed.PathsAre("name #Light intensity color #Transform position position.x position.y"));
		Test.Assert(bed.Grid.GetRow(6).Depth == 1);
		bed.Bag.Add("scale", .Float, Sedulous.GUI.Variant(1.0)).Category.Set("Transform");
		bed.Bag.PropertiesChanged(); // its category, set after it was added
		Test.Assert(bed.PathsAre("name #Light intensity color #Transform position position.x position.y scale"));

		// A category closed hides what is in it.
		bed.Grid.SetOpen("#Light", false);
		Test.Assert(bed.PathsAre("name #Light #Transform position position.x position.y scale"));
	}

	[Test]
	public static void TheChevronAHeadersClickAndLeftAndRightFoldAndUnfold()
	{
		let bed = scope GridBed();
		bed.Add("offset", .Group, .(), "Physics");
		bed.Add("offset.x", .Float, Sedulous.GUI.Variant(0.0));
		bed.Show();
		Test.Assert(bed.Grid.RowCount == 2);

		let header = bed.Grid.RowForItem(0);
		Test.Assert(header != null);
		bed.D.InjectMouseDown(GridBed.Centre(header), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(header), .Left);
		Test.Assert(!bed.Grid.IsOpen("#Physics"));
		Test.Assert(bed.Grid.RowCount == 1);
		bed.Grid.SetOpen("#Physics", true);
		bed.Frame();

		// The group's row selected, Right opens it and Left closes it.
		bed.Grid.SelectedItem = 1;
		bed.Grid.RequestFocus();
		bed.D.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(bed.Grid.IsOpen("offset"));
		Test.Assert(bed.Grid.RowCount == 3);
		bed.D.InjectKeyDown((uint32)KeyCode.Left);
		Test.Assert(!bed.Grid.IsOpen("offset"));
	}

	[Test]
	public static void ASearchKeepsMatchesByNameOrPathWithWhatHoldsThemOpenedTheFoldingStays()
	{
		let bed = scope GridBed();
		bed.Add("name", .String, Sedulous.GUI.Variant("Lamp"));
		bed.Add("position", .Group, .(), "Transform");
		bed.Add("position.x", .Float, Sedulous.GUI.Variant(0.0)).DisplayName.Set("Along");
		bed.Add("position.y", .Float, Sedulous.GUI.Variant(0.0));
		bed.Add("intensity", .Float, Sedulous.GUI.Variant(1.0), "Light");
		bed.Show();
		bed.Grid.SetOpen("#Light", false);

		bed.Grid.Filter = "ALONG"; // by shown name, either case
		Test.Assert(bed.PathsAre("#Transform position position.x"));
		bed.Grid.Filter = "position.y"; // by path
		Test.Assert(bed.PathsAre("#Transform position position.y"));
		bed.Grid.Filter = "inten"; // in a closed category: opened while searching
		Test.Assert(bed.PathsAre("#Light intensity"));
		bed.Grid.Filter = "position"; // a group that matches keeps its own folding
		Test.Assert(bed.PathsAre("#Transform position"));
		bed.Grid.Filter = "nothing";
		Test.Assert(bed.Grid.RowCount == 0);

		bed.Grid.Filter = "";
		Test.Assert(bed.PathsAre("name #Transform position #Light"));
	}

	[Test]
	public static void OnlyTheRowsInViewAreRealised()
	{
		let bed = scope GridBed();
		for (int32 i = 0; i < 500; ++i)
			bed.Bag.Add(scope String()..AppendF("p{}", i), .Float, Sedulous.GUI.Variant((double)i));
		bed.Show();
		Test.Assert(bed.Grid.RowCount == 500);
		Test.Assert(bed.Grid.VisibleRowCount > 5);
		Test.Assert(bed.Grid.VisibleRowCount < 20);
		Test.Assert(bed.Grid.FindEditor("p0") != null);
		Test.Assert(bed.Grid.FindEditor("p400") == null);
		bed.Grid.ScrollToItem(400);
		bed.Frame();
		Test.Assert(bed.Grid.FindEditor("p400") != null);
		let editor = bed.Grid.FindEditor("p400") as NumberPropertyEditor;
		Test.Assert(editor != null);
		CheckNear(editor.Field.Value, 400.0); // a pooled editor shows its row's value
	}

	[Test]
	public static void AnEditIsOneGestureOfTheSourceItsRowKeepsItsEditorWhileItPreviews()
	{
		let bed = scope GridBed(2);
		let info = bed.Add("speed", .Float, Sedulous.GUI.Variant(2.0));
		info.Step = 1.0;
		bed.Bag.SetValue("speed", 1, Sedulous.GUI.Variant(5.0));
		let kept = scope KeptCommits();
		bed.Bag.SetOnCommit(new (commit) => { kept.Keep(commit); });
		let commits = kept.Commits;
		bed.Show();

		let editor = bed.Grid.FindEditor("speed") as NumberPropertyEditor;
		Test.Assert(editor != null);
		let field = editor.Field;
		Test.Assert(field.IsMixed);

		let centre = GridBed.Centre(field);
		let at = Float2(centre.X - 30.0f, centre.Y);
		bed.D.InjectMouseDown(at, .Left);
		bed.D.InjectMouseMove(.(at.X + 8.0f, at.Y));
		bed.Frame();
		Test.Assert(bed.Grid.EditPath == "speed");
		CheckNear(FloatOf(bed.Bag, "speed", 1), 4.0); // previewed on both
		bed.D.InjectMouseMove(.(at.X + 16.0f, at.Y));
		bed.Frame();
		CheckNear(field.Value, 6.0);
		bed.D.InjectMouseUp(.(at.X + 16.0f, at.Y), .Left);
		bed.Frame();
		Test.Assert(bed.Grid.EditPath.Length == 0);
		Test.Assert(commits.Count == 1);
		CheckNear(commits[0].Before[0].AsFloat, 2.0);
		CheckNear(commits[0].Before[1].AsFloat, 5.0);
		CheckNear(commits[0].After[1].AsFloat, 6.0);
		Test.Assert(!field.IsMixed);

		// A value changed elsewhere (an undo) shows.
		bed.Bag.SetValue("speed", 0, Sedulous.GUI.Variant(9.0));
		bed.Frame();
		Test.Assert(field.IsMixed);
	}

	[Test]
	public static void TheLabelSplitIsDraggedAtAnyRowForEveryRowMirroredRightToLeft()
	{
		let bed = scope GridBed();
		bed.Root.Padding = Thickness(50.0f, 30.0f, 0.0f, 0.0f); // the grid away from the origin
		bed.Add("a", .Float, Sedulous.GUI.Variant(1.0));
		bed.Add("b", .Float, Sedulous.GUI.Variant(2.0));
		bed.Show();
		let a = bed.Grid.FindEditor("a");
		let b = bed.Grid.FindEditor("b");
		Test.Assert(a != null);
		Test.Assert(b != null);
		let before = a.ScreenBounds.X;

		let row = b.Parent as PropertyRowContent;
		Test.Assert(row != null);
		let grip = GridBed.Centre(row.SplitHandle);
		bed.D.InjectMouseMove(grip);
		Test.Assert(bed.D.Cursor == .EwResize);
		bed.D.InjectMouseDown(grip, .Left);
		bed.D.InjectMouseMove(.(grip.X + 60.0f, grip.Y));
		bed.D.InjectMouseUp(.(grip.X + 60.0f, grip.Y), .Left);
		bed.Frame();
		// The split follows the pointer: 60 pixels further along the rows' width.
		let rows = bed.Grid.ContentBounds.Width;
		CheckNear(bed.Grid.LabelRatio, 0.4f + 60.0f / rows, 0.02);
		Test.Assert(a.ScreenBounds.X > before + 50.0f); // the other row's editor moved too

		bed.Grid.LabelRatio = 0.05f;
		CheckNear(bed.Grid.LabelRatio, 0.1f);

		// Right to left the labels are at the right, the editors at the left.
		bed.Grid.LabelRatio = 0.4f;
		bed.Root.SetLayoutDirection(.RightToLeft);
		bed.Frame();
		let @box = bed.Grid.ScreenBounds;
		Test.Assert(a.ScreenBounds.X < @box.X + 10.0f);
	}

	[Test]
	public static void TheWheelOverAnEditorScrollsTheGridAndNeverChangesAValue()
	{
		let bed = scope GridBed();
		for (int32 i = 0; i < 60; ++i)
			bed.Bag.Add(scope String()..AppendF("p{}", i), .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		let editor = bed.Grid.FindEditor("p0") as NumberPropertyEditor;
		Test.Assert(editor != null);
		editor.Field.RequestFocus();
		bed.D.InjectMouseWheel(GridBed.Centre(editor.Field), .(0.0f, -3.0f));
		bed.Frame();
		CheckNear(FloatOf(bed.Bag, "p0", 0), 1.0);
		Test.Assert(bed.Grid.ScrollOffset.Y > 0.0f);
	}

	[Test]
	public static void AnApplicationsEditorForAHintAHintNoneTakesAndMarkupMakesAGrid()
	{
		let bed = scope GridBed();
		bed.Add("look", .Float, Sedulous.GUI.Variant(1.0)).Hint.Set("toggle");
		bed.Show();
		Test.Assert(bed.Grid.FindEditor("look") is NumberPropertyEditor);
		bed.Grid.Editors.RegisterHint("toggle", new () => new BoolPropertyEditor());
		bed.Grid.Refresh();
		bed.Frame();
		Test.Assert(bed.Grid.FindEditor("look") is BoolPropertyEditor);

		// A group hinted for an editor no one registered says so (a hinted group with rows of its own
		// shows them instead); one with no hint has no editor.
		bed.Add("falloff", .Group).Hint.Set("curve");
		bed.Add("plain", .Group);
		bed.Frame();
		let unknown = bed.Grid.FindEditor("falloff") as UnknownPropertyEditor;
		Test.Assert(unknown != null);
		Test.Assert(unknown.Message == "No editor for curve");
		Test.Assert(bed.Grid.FindEditor("plain") == null);

		let made = Load("<PropertyGrid label-ratio=\"0.3\" indent-width=\"20\"/>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let grid = made as PropertyGrid;
		Test.Assert(grid != null);
		CheckNear(grid.LabelRatio, 0.3f);
		CheckNear(grid.IndentWidth, 20.0f);
	}

	[Test]
	public static void AFloat3IsOneRowOfAFieldPerPartEachMixedAndEditedOnItsOwn()
	{
		let bed = scope GridBed(2);
		bed.Add("position", .Group, .(), "Transform").Hint.Set("Float3");
		bed.Add("position.x", .Float, Sedulous.GUI.Variant(1.0)).DisplayName.Set("X");
		bed.Add("position.y", .Float, Sedulous.GUI.Variant(2.0)).DisplayName.Set("Y");
		bed.Add("position.z", .Float, Sedulous.GUI.Variant(3.0)).DisplayName.Set("Z");
		bed.Bag.SetValue("position.y", 1, Sedulous.GUI.Variant(7.0)); // the objects differ in Y alone
		let kept = scope KeptCommits();
		bed.Bag.SetOnCommit(new (commit) => { kept.Keep(commit); });
		let commits = kept.Commits;
		bed.Show();

		// One row, no chevron, nothing under it.
		Test.Assert(bed.PathsAre("#Transform position"));
		Test.Assert(!bed.Grid.GetRow(1).HasChildren);
		let editor = bed.Grid.FindEditor("position") as FloatsPropertyEditor;
		Test.Assert(editor != null);
		Test.Assert(editor.PartCount == 3);
		Test.Assert(editor.GetPartLabel(0).Text == "X");
		Test.Assert(editor.GetPartLabel(2).Text == "Z");
		let x = editor.GetPart(0).Field;
		Test.Assert(!x.IsMixed);
		CheckNear(x.Value, 1.0);
		Test.Assert(editor.GetPart(1).Field.IsMixed);
		Test.Assert(!editor.GetPart(2).Field.IsMixed);

		// A scrub of X writes X alone, on both, and keeps the row while it goes.
		x.Step = 1.0;
		let centre = GridBed.Centre(x);
		let at = Float2(centre.X - 10.0f, centre.Y);
		bed.D.InjectMouseDown(at, .Left);
		bed.D.InjectMouseMove(.(at.X + 8.0f, at.Y));
		bed.Frame();
		Test.Assert(bed.Grid.EditPath == "position.x");
		Test.Assert(bed.Grid.FindEditor("position") == editor);
		bed.D.InjectMouseUp(.(at.X + 8.0f, at.Y), .Left);
		bed.Frame();
		Test.Assert(commits.Count == 1);
		Test.Assert(commits[0].Path == "position.x");
		CheckNear(FloatOf(bed.Bag, "position.x", 1), 3.0);
		CheckNear(FloatOf(bed.Bag, "position.y", 1), 7.0); // Y kept its differences
		Test.Assert(editor.GetPart(1).Field.IsMixed);

		// A search for a part shows the row that holds it.
		bed.Grid.Filter = "position.z";
		Test.Assert(bed.PathsAre("#Transform position"));
	}

	[Test]
	public static void AListShowsItsElementsTheFewestAnyObjectHasAndItsCountMixed()
	{
		let bed = scope GridBed(2);
		bed.Bag.AddList("weights", .Float, Sedulous.GUI.Variant(0.5), 3);
		bed.Show();
		var list = bed.Grid.FindEditor("weights") as ListPropertyEditor;
		Test.Assert(list != null);
		Test.Assert(list.CountLabel.Text == "3 elements");
		Test.Assert(bed.PathsAre("weights")); // a list starts folded
		bed.Grid.SetOpen("weights", true);
		Test.Assert(bed.PathsAre("weights weights.0 weights.1 weights.2"));
		Test.Assert(bed.Grid.GetRow(1).Element);
		Test.Assert(bed.Grid.GetRow(1).Depth == 1);

		// The second object with one more: the count is mixed, and the three both have show.
		bed.Bag.ResizeList("weights", 1, 4);
		bed.Frame();
		list = bed.Grid.FindEditor("weights") as ListPropertyEditor;
		Test.Assert(list != null);
		Test.Assert(list.CountLabel.Text == MixedValueText());
		Test.Assert(bed.PathsAre("weights weights.0 weights.1 weights.2"));
	}

	[Test]
	public static void AddPutsAnElementAtTheEndOfEachObjectsListAndOpensItAFullListCannot()
	{
		let bed = scope GridBed(2);
		let info = bed.Bag.AddList("tags", .String, Sedulous.GUI.Variant("new"), 1);
		info.MaxCount = 3;
		bed.Show();
		var list = bed.Grid.FindEditor("tags") as ListPropertyEditor;
		Test.Assert(list != null);
		Test.Assert(list.CountLabel.Text == "1 element");
		bed.D.InjectMouseMove(GridBed.Centre(list.AddButton));
		bed.D.InjectMouseDown(GridBed.Centre(list.AddButton), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(list.AddButton), .Left);
		bed.Frame();
		Test.Assert(bed.Bag.ElementCount("tags", 0) == 2);
		Test.Assert(bed.Bag.ElementCount("tags", 1) == 2);
		Test.Assert(bed.Grid.IsOpen("tags"));
		Test.Assert(bed.Grid.FindRow("tags.1") >= 0);

		list = bed.Grid.FindEditor("tags") as ListPropertyEditor;
		Test.Assert(list != null);
		bed.D.InjectMouseDown(GridBed.Centre(list.AddButton), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(list.AddButton), .Left);
		bed.Frame();
		list = bed.Grid.FindEditor("tags") as ListPropertyEditor;
		Test.Assert(list != null);
		Test.Assert(bed.Bag.ElementCount("tags", 0) == 3);
		Test.Assert(!list.AddButton.Enabled); // its most
	}

	[Test]
	public static void AListOfSeveralTypesAddsTheOnePickedFromAMenu()
	{
		let bed = scope GridBed();
		let info = bed.Bag.AddList("effects", .String, Sedulous.GUI.Variant(""));
		info.ElementTypes.Add(new String("Flicker"));
		info.ElementTypes.Add(new String("Pulse"));
		let asked = scope String();
		bed.Bag.SetOnListEdited(new [&] (path, edit) => { asked.Set(edit.ElementType); });
		bed.Show();
		let list = bed.Grid.FindEditor("effects") as ListPropertyEditor;
		Test.Assert(list != null);
		bed.D.InjectMouseDown(GridBed.Centre(list.AddButton), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(list.AddButton), .Left);
		bed.Frame();
		Test.Assert(list.TypeMenu != null);
		GridBed.Activate(list.TypeMenu, "Pulse");
		Test.Assert(asked == "Pulse");
		Test.Assert(bed.Bag.ElementCount("effects", 0) == 1);
	}

	[Test]
	public static void AnElementsMenuInsertsRemovesAndMovesIt()
	{
		let bed = scope GridBed();
		bed.Bag.AddList("steps", .Integer, Sedulous.GUI.Variant((int64)0), 3);
		for (int64 i = 0; i < 3; ++i)
			bed.Bag.SetValue(scope String()..AppendF("steps.{}", i), 0, Sedulous.GUI.Variant(i + 1));
		bed.Show();
		bed.Grid.SetOpen("steps", true);
		bed.Frame();
		Test.Assert(bed.Elements("steps", 0, .. scope String()) == "1 2 3");

		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("steps.0"), .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Move down");
		Test.Assert(bed.Elements("steps", 0, .. scope String()) == "2 1 3");
		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("steps.2"), .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Remove");
		Test.Assert(bed.Elements("steps", 0, .. scope String()) == "2 1");
		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("steps.1"), .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Insert above");
		Test.Assert(bed.Elements("steps", 0, .. scope String()) == "2 0 1");

		// A list that may not move: its elements' Move items are disabled, and they show no grip.
		bed.Bag.FindInfo("steps").ListOps = PropertyListAdd | PropertyListRemove;
		bed.Bag.PropertiesChanged();
		bed.Frame();
		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("steps.0"), .(20.0f, 20.0f)));
		let menu = bed.Grid.RowMenu;
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
			{
				if (item.Text == "Move down")
					Test.Assert(!item.Enabled);
			}
		}
		let row = bed.Grid.RowForItem(bed.Grid.FindRow("steps.0"));
		Test.Assert(row != null);
		Test.Assert(!(row.Content as PropertyRowContent).Grip.Displayed);
	}

	[Test]
	public static void AnElementsGripDragsItToAnotherPlaceInItsList()
	{
		let bed = scope GridBed();
		bed.Bag.AddList("steps", .Integer, Sedulous.GUI.Variant((int64)0), 4);
		for (int64 i = 0; i < 4; ++i)
			bed.Bag.SetValue(scope String()..AppendF("steps.{}", i), 0, Sedulous.GUI.Variant(i + 1));
		bed.Show();
		bed.Grid.SetOpen("steps", true);
		bed.Frame();

		PropertyGrip Grip(StringView path)
		{
			let row = bed.Grid.RowForItem(bed.Grid.FindRow(path));
			Test.Assert(row != null);
			return (row.Content as PropertyRowContent).Grip;
		}
		Float2 Lower(StringView path)
		{
			let r = bed.Grid.RowForItem(bed.Grid.FindRow(path)).ScreenBounds;
			return .(r.X + 100.0f, r.Y + r.Height * 0.75f);
		}
		let first = Grip("steps.0");
		Test.Assert(first.Displayed);
		let from = GridBed.Centre(first);
		bed.D.InjectMouseMove(from);
		bed.D.InjectMouseDown(from, .Left);
		bed.D.InjectMouseMove(Lower("steps.2")); // below the third: it goes third
		Test.Assert(bed.Grid.ReorderTarget == 2);
		bed.D.InjectMouseUp(Lower("steps.2"), .Left);
		bed.Frame();
		Test.Assert(bed.Elements("steps", 0, .. scope String()) == "2 3 1 4");

		// Let go off the list: nothing moves.
		let last = Grip("steps.3");
		let lastAt = GridBed.Centre(last);
		bed.D.InjectMouseDown(lastAt, .Left);
		bed.D.InjectMouseMove(.(lastAt.X, 400.0f));
		Test.Assert(bed.Grid.ReorderTarget == -1);
		bed.D.InjectMouseUp(.(lastAt.X, 400.0f), .Left);
		Test.Assert(bed.Elements("steps", 0, .. scope String()) == "2 3 1 4");
	}

	[Test]
	public static void ARowDifferingFromItsDefaultIsMarkedSoIsWhatHoldsItAndRevertPutsEachObjectsBack()
	{
		let bed = scope GridBed(2);
		bed.Add("size", .Float, Sedulous.GUI.Variant(1.0));
		bed.Add("offset", .Group, .(), "Shape");
		bed.Add("offset.x", .Float, Sedulous.GUI.Variant(0.0));
		bed.Bag.SetDefault("size", Sedulous.GUI.Variant(1.0));
		bed.Bag.SetDefault("offset.x", Sedulous.GUI.Variant(0.0), 0);
		bed.Bag.SetDefault("offset.x", Sedulous.GUI.Variant(4.0), 1); // the second's default differs
		bed.Show();
		Test.Assert(!bed.Grid.IsRowChanged("size"));
		Test.Assert(bed.Grid.IsRowChanged("offset")); // the second object's x is not its default
		bed.Grid.SetOpen("offset", true);
		Test.Assert(bed.Grid.IsRowChanged("offset.x"));

		// Changed, the row's content says so.
		bed.Bag.SetValue("size", 0, Sedulous.GUI.Variant(3.0));
		bed.Frame();
		Test.Assert(bed.Grid.IsRowChanged("size"));
		let row = bed.Grid.RowForItem(bed.Grid.FindRow("size"));
		Test.Assert(row != null);
		Test.Assert((row.Content as PropertyRowContent).IsChanged);

		// The group's Revert puts back each object's own default.
		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("offset"), .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Revert to default");
		bed.Frame();
		CheckNear(FloatOf(bed.Bag, "offset.x", 1), 4.0);
		Test.Assert(!bed.Grid.IsRowChanged("offset"));

		// Unchanged, its Revert is disabled.
		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("offset.x"), .(20.0f, 20.0f)));
		let menu = bed.Grid.RowMenu;
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
				Test.Assert(!item.Enabled);
		}
	}

	[Test]
	public static void CopyAndPasteGoThroughTheSourceFromTheMenuOrTheKeysARefusalSaysWhy()
	{
		let bed = scope GridBed(2);
		let clipboard = scope MemoryClipboard();
		bed.D.Clipboard = clipboard;
		defer { bed.D.Clipboard = null; }
		bed.Add("speed", .Float, Sedulous.GUI.Variant(2.5));
		bed.Add("slow", .Float, Sedulous.GUI.Variant(0.5));
		bed.Add("name", .String, Sedulous.GUI.Variant("Lamp"));
		let said = scope String();
		bed.Grid.SetOnMessage(new [&] (text) => { said.Set(text); });
		int commits = 0;
		bed.Bag.SetOnCommit(new [&] (commit) => { ++commits; });
		bed.Show();

		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("speed"), .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Copy");
		Test.Assert(clipboard.Text == "2.5");
		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("slow"), .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Paste");
		CheckNear(FloatOf(bed.Bag, "slow", 1), 2.5); // into each object
		Test.Assert(commits == 1); // one undo entry

		// The keys on the focused row: Ctrl+C on the name, Ctrl+V on the speed, which refuses it.
		bed.Grid.SelectedItem = bed.Grid.FindRow("name");
		bed.Grid.RequestFocus();
		bed.D.InjectKeyDown((uint32)KeyCode.C, KeyModCtrl);
		Test.Assert(clipboard.Text == "Lamp");
		bed.Grid.SelectedItem = bed.Grid.FindRow("speed");
		bed.D.InjectKeyDown((uint32)KeyCode.V, KeyModCtrl);
		CheckNear(FloatOf(bed.Bag, "speed", 0), 2.5);
		Test.Assert(said == "\"Lamp\" is no number");
		Test.Assert(commits == 1);
	}

	// What no Raptor test covers: a category's row is a header with no editor, the folded state reads
	// back as toggled, and the indent widens with depth.
	[Test]
	public static void ACategoryRowIsAHeaderAndTheIndentWidensANestedRow()
	{
		let bed = scope GridBed();
		bed.Add("outer", .Group, .(), "Shape");
		bed.Add("outer.inner", .Group);
		bed.Add("outer.inner.x", .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		Test.Assert(bed.Grid.IsOpen("#Shape"));
		Test.Assert(!bed.Grid.IsOpen("outer"));
		bed.Grid.ToggleOpen("outer");
		bed.Grid.ToggleOpen("outer.inner");
		Test.Assert(bed.PathsAre("#Shape outer outer.inner outer.inner.x"));
		Test.Assert(bed.Grid.GetRow(3).Depth == 2);
		let header = bed.Grid.RowForItem(0);
		Test.Assert(header.Content is PropertyCategoryContent);
		Test.Assert(bed.Grid.FindEditor("#Shape") == null);
		bed.Grid.IndentWidth = -5.0f;
		CheckNear(bed.Grid.IndentWidth, 0.0f);
	}
}
