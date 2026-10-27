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
	public static void ACategoryWhoseRowsAreAllHiddenHasNoHeaderAndHasOneAgainWhenOneShows()
	{
		let bed = scope GridBed();
		bed.Add("name", .String, Sedulous.GUI.Variant("Lamp"));
		bed.Add("warning", .String, Sedulous.GUI.Variant(""), "Check").Visible = false;
		bed.Add("intensity", .Float, Sedulous.GUI.Variant(1.0), "Light");
		bed.Show();
		Test.Assert(bed.PathsAre("name #Light intensity"));
		bed.Bag.FindInfo("warning").Visible = true;
		bed.Bag.PropertiesChanged();
		Test.Assert(bed.PathsAre("name #Check warning #Light intensity"));
	}

	// The first chevron in `node`'s subtree (depth first), or null.
	private static Node Chevron(Node node)
	{
		if (node == null)
			return null;
		if (node is TreeArrow)
			return node;
		for (int i = 0; i < node.ChildCount; ++i)
		{
			let found = Chevron(node.GetChildAt(i));
			if (found != null)
				return found;
		}
		return null;
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

		// The chevron: one fold per click (its press folds; the click after it does not reach the
		// header, which would unfold it again).
		var arrow = Chevron(bed.Grid.RowForItem(0));
		Test.Assert(arrow != null);
		bed.D.InjectMouseDown(GridBed.Centre(arrow), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(arrow), .Left);
		Test.Assert(!bed.Grid.IsOpen("#Physics"));
		bed.Frame();
		arrow = Chevron(bed.Grid.RowForItem(0));
		Test.Assert(arrow != null);
		bed.D.InjectMouseDown(GridBed.Centre(arrow), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(arrow), .Left);
		Test.Assert(bed.Grid.IsOpen("#Physics"));
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
	public static void ABagsOwnerIsToldOfEachPreviewAndOfAGestureGivenUp()
	{
		let bag = scope Sedulous.GUI.PropertyBag();
		bag.Add("rough", .Float, Sedulous.GUI.Variant(0.25));
		let told = scope List<String>();
		defer { ClearAndDeleteItems!(told); }
		bag.SetOnPreview(new [&] (path) =>
			{
				var value = bag.GetValue(path, 0);
				defer value.Dispose();
				told.Add(new String()..AppendF("preview {}=", path)..Append(value.ToString(.. scope String())));
			});
		bag.SetOnCancel(new [&] (path) =>
			{
				var value = bag.GetValue(path, 0);
				defer value.Dispose();
				told.Add(new String()..AppendF("cancel {}=", path)..Append(value.ToString(.. scope String())));
			});
		bag.BeginEdit("rough");
		bag.PreviewEdit("rough", PropertyWrite(Sedulous.GUI.Variant(0.5)));
		bag.CancelEdit("rough");
		Test.Assert(told.Count == 2);
		Test.Assert(told[0] == "preview rough=0.5");
		Test.Assert(told[1] == "cancel rough=0.25"); // the value back by then
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
		let previews = scope List<double>(); // what an owner showing them live reads
		bed.Bag.SetOnPreview(new [&] (path) => { previews.Add(FloatOf(bed.Bag, path, 0)); });
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
		Test.Assert(previews.Count == 2); // told of each preview as it went
		CheckNear(previews[0], 4.0);
		CheckNear(previews[1], 6.0);
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
	public static void ABagsListOfGroupsEachElementItsFieldsAddedEditedMovedAndRemovedWhole()
	{
		let bed = scope GridBed(1);
		let info = bed.Bag.AddList("variants", .Group, .());
		info.MaxCount = 3;
		let clip = bed.Bag.AddElementField("variants", "clip", .String, Sedulous.GUI.Variant(""));
		let weight = bed.Bag.AddElementField("variants", "weight", .Float, Sedulous.GUI.Variant(1.0));
		Test.Assert(clip != null);
		Test.Assert(weight != null);
		weight.HasRange = true;
		weight.Max = 100.0;
		Test.Assert(bed.Bag.AddElementField("nothing", "x", .Float) == null); // no such list
		bed.Bag.ResizeList("variants", 0, 2);
		Test.Assert(bed.Bag.ElementCount("variants", 0) == 2);
		Test.Assert(IntOf(bed.Bag, "variants", 0) == 2);
		bed.Bag.SetValue("variants.0.clip", 0, Sedulous.GUI.Variant("step"));
		bed.Bag.SetValue("variants.1.clip", 0, Sedulous.GUI.Variant("scuff"));
		bed.Bag.SetValue("variants.1.weight", 0, Sedulous.GUI.Variant(3.0));

		// An element is a group; its fields are its rows, each with what it says.
		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		bed.Bag.GetProperties("variants", elements);
		Test.Assert(elements.Count == 2);
		Test.Assert(elements[1].Kind == .Group);
		let fields = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(fields); }
		bed.Bag.GetProperties("variants.1", fields);
		Test.Assert(fields.Count == 2);
		Test.Assert(fields[0].Name == "clip");
		Test.Assert(fields[1].HasRange);
		CheckNear(FloatOf(bed.Bag, "variants.1.weight", 0), 3.0);

		// The grid shows it as any list: the count with Add, an element a group of its rows.
		bed.Show();
		Test.Assert(bed.Grid.FindEditor("variants") is ListPropertyEditor);

		// A field edited as the grid commits one.
		bed.Bag.BeginEdit("variants.0.weight");
		bed.Bag.CommitEdit("variants.0.weight", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		CheckNear(FloatOf(bed.Bag, "variants.0.weight", 0), 5.0);

		// Added with its fields' new values; moved and removed whole.
		Test.Assert(bed.Bag.EditList("variants", scope ListEdit(.Insert, 2)));
		Test.Assert(bed.Bag.ElementCount("variants", 0) == 3);
		CheckNear(FloatOf(bed.Bag, "variants.2.weight", 0), 1.0);
		Test.Assert(!bed.Bag.EditList("variants", scope ListEdit(.Insert, 3))); // its most
		Test.Assert(bed.Bag.EditList("variants", scope ListEdit(.Move, 1, 0)));
		Test.Assert(TextIs(bed.Bag, "variants.0.clip", 0, "scuff"));
		CheckNear(FloatOf(bed.Bag, "variants.0.weight", 0), 3.0);
		Test.Assert(TextIs(bed.Bag, "variants.1.clip", 0, "step"));
		Test.Assert(bed.Bag.EditList("variants", scope ListEdit(.Remove, 0)));
		Test.Assert(bed.Bag.ElementCount("variants", 0) == 2);
		Test.Assert(TextIs(bed.Bag, "variants.0.clip", 0, "step"));
		CheckNear(FloatOf(bed.Bag, "variants.0.weight", 0), 5.0);
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

	[Test]
	public static void TheToolkitsSheetGivesTheRowBeingEditedTheQuietRowToneNotTheViewsFallbackBlue()
	{
		let bed = scope GridBed();
		bed.Add("speed", .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		let styles = scope StyleManager();
		let sheet = scope StyleSheet();
		let theme = scope String()..AppendF("{}\n{}\n:root {{ --row-hover: #102030; }}", Theme.DefaultThemeCSS, ToolkitSheetCSS());
		CSSParser.Parse(theme, sheet);
		styles.UserAgentSheet = sheet;
		styles.ApplyTree(bed.Root);
		let current = bed.Grid.GetPartStyle("selection");
		Test.Assert(current.HasBackground);
		CheckNear(current.Box.BackgroundColor.R, 0x10 / 255.0f, 0.01);
		CheckNear(current.Box.BackgroundColor.G, 0x20 / 255.0f, 0.01);
		CheckNear(current.Box.BackgroundColor.B, 0x30 / 255.0f, 0.01);
	}

	[Test]
	public static void TheRowWhoseEditorTakesTheFocusIsTheCurrentOneWhateverTheEditor()
	{
		let bed = scope GridBed();
		bed.Add("name", .String, Sedulous.GUI.Variant("Crate"));
		bed.Add("speed", .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		// A text field's editor, a number field's: both are text fields underneath.
		Node Field(StringView path)
		{
			let editor = bed.Grid.FindEditor(path);
			Test.Assert(editor != null);
			for (int i = 0; i < editor.ChildCount; ++i)
			{
				if (let field = editor.GetChildAt(i) as TextField)
					return field;
			}
			Test.FatalError("no text field");
			return null;
		}
		int32 RowOf(StringView path)
		{
			for (int32 i = 0; i < (int32)bed.Grid.RowCount; ++i)
			{
				if (bed.Grid.GetRow(i).Path == path)
					return i;
			}
			return -1;
		}
		Test.Assert(!bed.Grid.IsItemSelected(RowOf("name")));
		Field("name").RequestFocus();
		Test.Assert(bed.Grid.IsItemSelected(RowOf("name")));
		Field("speed").RequestFocus();
		Test.Assert(bed.Grid.IsItemSelected(RowOf("speed")));
		Test.Assert(!bed.Grid.IsItemSelected(RowOf("name")));
	}

	[Test]
	public static void AReferenceIsItsGuidsTextByDefaultAPasteTakesAGuidOrNothing()
	{
		let bed = scope GridBed();
		bed.Add("mesh", .Reference, Sedulous.GUI.Variant(""));
		bed.Show();
		Test.Assert(bed.Grid.FindEditor("mesh") is StringPropertyEditor); // an application registers its slot
		let reason = scope String();
		Test.Assert(bed.Bag.PasteValue("mesh", " 00001234-0000-0000-0000-000000005678 ", reason));
		Test.Assert(TextIs(bed.Bag, "mesh", 0, "00001234-0000-0000-0000-000000005678"));
		Test.Assert(!bed.Bag.PasteValue("mesh", "wood", reason));
		Test.Assert(reason == "\"wood\" is no guid");
		Test.Assert(bed.Bag.PasteValue("mesh", "", reason)); // nothing: cleared
		Test.Assert(TextIs(bed.Bag, "mesh", 0, ""));
	}

	[Test]
	public static void TheApplicationAddsToARowsMenuAfterTheGridsItemsAHeadersMenuIsItsAlone()
	{
		let bed = scope GridBed();
		bed.Add("intensity", .Float, Sedulous.GUI.Variant(1.0), "Light");
		bed.Show();
		let header = bed.Grid.FindRow("#Light");
		Test.Assert(header >= 0);
		Test.Assert(!bed.Grid.OpenRowMenu(header, .(20.0f, 20.0f))); // a header has no menu of its own

		let asked = scope String();
		bed.Grid.SetOnRowMenu(new [&] (menu, row) =>
			{
				let path = new String(row.Path);
				if (row.Category)
					menu.AddItem("Remove Component", new [=asked, =path] () => { asked.Set(path); } ~ delete path);
				else
					menu.AddItem("Inspect", new [=asked, =path] () => { asked.Set(path); } ~ delete path);
			});
		Test.Assert(bed.Grid.OpenRowMenu(header, .(20.0f, 20.0f)));
		GridBed.Activate(bed.Grid.RowMenu, "Remove Component");
		Test.Assert(asked == "#Light");

		Test.Assert(bed.Grid.OpenRowMenu(bed.Grid.FindRow("intensity"), .(20.0f, 20.0f)));
		let rowMenu = bed.Grid.RowMenu;
		MenuItem last = null;
		for (int i = 0; i < rowMenu.ChildCount; ++i)
		{
			if (let item = rowMenu.GetChildAt(i) as MenuItem)
				last = item;
		}
		Test.Assert(last != null);
		Test.Assert(last.Text == "Inspect"); // after Copy, Paste and Revert
		GridBed.Activate(rowMenu, "Inspect");
		Test.Assert(asked == "intensity");
	}

	[Test]
	public static void AValueBeingTypedIsKeptAsTheSourcesValuesRefreshAndReturnCommitsIt()
	{
		let bed = scope GridBed();
		bed.Add("speed", .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		let row = bed.Grid.RowForItem(0);
		Test.Assert(row != null);
		NumberField field = null;
		let stack = scope List<Node>();
		stack.Add(row);
		while ((stack.Count != 0) && (field == null))
		{
			let node = stack.PopBack();
			field = node as NumberField;
			for (int i = 0; (node != null) && (i < node.ChildCount); ++i)
				stack.Add(node.GetChildAt(i));
		}
		Test.Assert(field != null);
		bed.D.InjectMouseDown(GridBed.Centre(field), .Left);
		bed.D.InjectMouseUp(GridBed.Centre(field), .Left);
		bed.D.InjectKeyDown((uint32)KeyCode.A, KeyModCtrl);
		bed.D.InjectText("7.5");
		Test.Assert(field.IsEditing);
		// A refresh mid-typing (an inspector re-reads its values each frame): the text stays.
		bed.Bag.SetValue("speed", 0, Sedulous.GUI.Variant(1.0)); // the stored value, told again
		bed.Frame();
		Test.Assert(field.Text == "7.5");
		bed.D.InjectKeyDown((uint32)KeyCode.Return);
		bed.Frame();
		CheckNear(FloatOf(bed.Bag, "speed", 0), 7.5);
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

	[Test]
	public static void ASheetSetsTheColumnARowKeepsForAGroupsArrow()
	{
		let bed = scope GridBed();
		bed.Add("speed", .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		let styles = scope StyleManager();
		let sheet = scope StyleSheet();
		CSSParser.Parse("propertygrid { arrow-size: 10px; }", sheet);
		styles.StyleSheet = sheet;
		styles.ApplyTree(bed.Root);
		bed.Frame();
		CheckNear(bed.Grid.ArrowSize, 10.0f);
		let editor = bed.Grid.FindEditor("speed");
		Test.Assert(editor != null);
		let content = editor.Parent as PropertyRowContent;
		Test.Assert(content != null);
		let name = content.Label;
		Test.Assert(name.Tag == "propertyname");
		// The name after the 10 px column and its 2 px gap.
		CheckNear(name.ScreenBounds.X - content.ScreenBounds.X - content.Padding.Left, 12.0f);
	}

	[Test]
	public static void ANameLongerThanItsColumnEndsInAnEllipsisInsideTheColumn()
	{
		let bed = scope GridBed();
		bed.Add("aVeryLongPropertyNameThatCannotFitItsColumn", .Float, Sedulous.GUI.Variant(1.0));
		bed.Show();
		let editor = bed.Grid.FindEditor("aVeryLongPropertyNameThatCannotFitItsColumn");
		Test.Assert(editor != null);
		let content = editor.Parent as PropertyRowContent;
		Test.Assert(content != null);
		let name = content.Label;
		Test.Assert(name.Tag == "propertyname");
		Test.Assert(name.TextOverflow == .Ellipsis);
		// Its box ends before the editor starts.
		Test.Assert(name.ScreenBounds.X + name.ScreenBounds.Width <= editor.ScreenBounds.X);
	}
}
