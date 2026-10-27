using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The asset type of Create Asset's project.
[AlwaysInclude]
class CreateTestAsset
{
}

/// The group picker, the rule a new asset's name keeps, and Create Asset over its markup
/// (Data/Editor/AssetCreate.gml): the groups in the tree's order, each by name and what holds it, a
/// key finding its group again; a name refused when empty, holding what a file cannot, spaced at an
/// end or taken, saying why; Create waiting while refused, the line under the name saying why or
/// what it makes, the group field picking another group, and Create answering the group and the
/// name, then closing. Then what Sedulous adds so each behaviour has a test: every character a file
/// cannot hold, each end's space and the end's dot, the group picker's row as it shows (its glyph,
/// the current one checked and lit), the group picker opened below the group field, the refused
/// line red and the made one not, Create pressed while it waits making nothing, and Enter creating
/// (or waiting) as Create does.
static class AssetCreateTests
{
	/// A project of groups: Content (Crate), Models (Town (Barrel)), Sounds. Sounds is made before
	/// Models, so only the tree's order puts Models first.
	private class ProjectBed
	{
		public String Dir = new .("scratch_asset_create_project") ~ delete _;
		public EditorProject Project;
		public String TypeName = new .() ~ delete _;
		public Group Top;
		public Group Models;
		public Group Town;
		public Group Sounds;

		public this()
		{
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Create") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			typeof(CreateTestAsset).GetFullName(TypeName);
			Top = Project.SourceDb.RootGroup;
			Test.Assert(Top != null);
			Test.Assert(Top.CreateInstance("Crate", TypeName) != null);
			Sounds = Top.CreateGroup("Sounds");
			Models = Top.CreateGroup("Models");
			Town = Models.CreateGroup("Town");
			Test.Assert((Sounds != null) && (Models != null) && (Town != null));
			Test.Assert(Town.CreateInstance("Barrel", TypeName) != null);
		}

		public ~this()
		{
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public ContentDatabase Sources => Project.SourceDb;
	}

	/// A GUI scene of 800 by 600, the picker on its markup, and what Create answered.
	private class SceneBed
	{
		public SceneRoot Root;
		public Picker Groups;
		public Group MadeIn = null;
		public String MadeName = new .() ~ delete _;
		public int Made = 0;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			Groups = new Picker(PagesBed.LoadMarkup(Picker.cMarkupPath));
			Test.Assert(Groups.Content != null);
		}

		public ~this()
		{
			DeleteAndNullify!(Groups); // closed while the root is there
			Root.ReleaseRef();
		}

		/// Create Asset in `group`, the name `suggested`, what it makes into Made; laid out. The
		/// caller's.
		public AssetCreate Open(ProjectBed project, Group group, StringView suggested)
		{
			let dialog = AssetCreate.Open(Root, PagesBed.LoadMarkup(AssetCreate.cMarkupPath), project.Sources, group, "New Asset",
				suggested, Groups, new [=this] (target, name) =>
				{
					MadeIn = target;
					MadeName.Set(name);
					Made++;
				});
			Test.Assert(dialog != null);
			Layout();
			return dialog;
		}

		/// Twice: a popup is sized by what it holds, then what it holds is placed in it.
		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		/// As the user types into `field`: over what is there.
		public void Type(TextField field, StringView text)
		{
			field.RequestFocus();
			field.SelectAll();
			Root.EventDispatcher.InjectText(text);
		}
	}

	private static T Part<T>(AssetCreate dialog, StringView id) where T : Node
	{
		let found = dialog.Window.FindElement(id) as T;
		Test.Assert(found != null, scope $"{id} is in the markup");
		return found;
	}

	/// What AssetNames says to `name` in `group`, into `outWhy`.
	private static String Says(Group group, StringView name, String outWhy) => AssetNames.Refusal(group, name, .. outWhy);

	[Test]
	public static void GroupPickerTheGroupsInTheTreesOrderEachByNameAndWhatHoldsItAKeyFindsItsGroupAgain()
	{
		let bed = scope ProjectBed();
		let request = GroupPicker.Request(bed.Sources, bed.Town);
		defer delete request;
		Test.Assert(request.Items.Count == 4);
		Test.Assert(request.Items[0].Name == "Content");
		Test.Assert(request.Items[0].Detail.IsEmpty, "the top: nothing holds it");
		Test.Assert(request.Items[1].Name == "Models", "Models before Sounds, though made after it");
		Test.Assert(request.Items[1].Detail == "in Content");
		Test.Assert(request.Items[2].Name == "Town", "a group, then what is under it");
		Test.Assert(request.Items[2].Detail == "in Models");
		Test.Assert(request.Items[3].Name == "Sounds");
		Test.Assert(request.Items[3].Detail == "in Content");
		Test.Assert(request.Current == "Content/Models/Town");
		Test.Assert(request.Placeholder == "Search groups");
		for (let item in request.Items)
		{
			Test.Assert(item.Glyph == "Editor/Icons/folder.svg");
			Test.Assert(item.Section.IsEmpty, "one list, no headings");
		}

		// Each key finds its group again; one that names no group finds none.
		Test.Assert(request.Items[0].Key == "Content");
		Test.Assert(request.Items[2].Key == "Content/Models/Town");
		Test.Assert(GroupPicker.Find(bed.Sources, request.Items[2].Key) == bed.Town);
		Test.Assert(GroupPicker.Find(bed.Sources, request.Items[1].Key) == bed.Models);
		Test.Assert(GroupPicker.Find(bed.Sources, request.Items[3].Key) == bed.Sounds);
		Test.Assert(GroupPicker.Find(bed.Sources, "Content") == bed.Top);
		Test.Assert(GroupPicker.Find(bed.Sources, "Content/Nowhere") == null);
		Test.Assert(GroupPicker.Find(bed.Sources, "Elsewhere") == null);
		Test.Assert(GroupPicker.Find(bed.Sources, "Contents/Models") == null, "the top's word, then a slash");
		// A stray character after the top's word, though what follows names a real group.
		Test.Assert(GroupPicker.Find(bed.Sources, "Content#Models") == null, "only a slash goes below the top");
		Test.Assert(GroupPicker.ShownName(bed.Top, .. scope .()) == "Content");
		Test.Assert(GroupPicker.ShownName(bed.Town, .. scope .()) == "Models/Town");
		let none = GroupPicker.Request(bed.Sources, null);
		defer delete none;
		Test.Assert(none.Current.IsEmpty, "null: nothing checked");

		// In the picker: the current group checked and lit, and only it.
		let scene = scope SceneBed();
		Test.Assert(scene.Groups.Open(scene.Root, GroupPicker.Request(bed.Sources, bed.Town)));
		scene.Groups.List.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(400.0f);
				s.Height = LayoutLength.Px(400.0f);
			});
		scene.Layout();
		Test.Assert(scene.Groups.RowCount == 4);
		Test.Assert(scene.Groups.LitKey == "Content/Models/Town", "the current lit as it opens");
		for (int32 i < 4)
		{
			let row = scene.Groups.List.RowForItem(i);
			Test.Assert(row != null, "realised");
			let shown = row.Content as PickerRow;
			Test.Assert(shown != null);
			Test.Assert(shown.ShowsCheck == (shown.ShownName == "Town"));
		}
		Test.Assert((scene.Groups.List.RowForItem(2).Content as PickerRow).ShownDetail == "in Models");
		Test.Assert(scene.Groups.Hint == "Enter picks, Esc keeps Town");
		scene.Groups.SetQuery("Models");
		Test.Assert(scene.Groups.RowCount == 2, "by its name, or where it is: Models, and Town in it");
	}

	[Test]
	public static void AssetNamesRefusedWhenEmptyHoldingWhatAFileCannotSpacedAtAnEndOrTakenSayingWhy()
	{
		let bed = scope ProjectBed();
		Test.Assert(Says(bed.Top, "", scope .()) == "Enter a name.");
		Test.Assert(Says(bed.Top, "a/b", scope .()) == "A name cannot hold /.");
		Test.Assert(Says(bed.Top, "what?", scope .()) == "A name cannot hold ?.");
		// Every character a file cannot hold.
		for (int i < AssetNames.cRefused.Length)
		{
			let c = AssetNames.cRefused[i];
			let name = scope String()..AppendF("Lamp{}Post", c);
			Test.Assert(Says(bed.Top, name, scope .()) == scope String()..AppendF("A name cannot hold {}.", c), name);
		}
		Test.Assert(AssetNames.cRefused.Length == 9);
		Test.Assert(Says(bed.Top, " Crate", scope .()) == "A name cannot start or end with a space, or end with a dot.");
		Test.Assert(Says(bed.Top, "Lamp ", scope .()) == "A name cannot start or end with a space, or end with a dot.");
		Test.Assert(Says(bed.Top, "Crate.", scope .()) == "A name cannot start or end with a space, or end with a dot.");
		Test.Assert(Says(bed.Top, "Crate", scope .()) == "Crate is already in Content.");
		Test.Assert(Says(bed.Town, "Barrel", scope .()) == "Barrel is already in Models/Town.");
		Test.Assert(Says(bed.Town, "Crate", scope .()).IsEmpty, "in another group it is free");
		// What the rule leaves be: a space or a dot inside, and a group's name.
		Test.Assert(Says(bed.Top, "Old Crate.v2", scope .()).IsEmpty);
		Test.Assert(Says(bed.Top, "Models", scope .()).IsEmpty, "a group of the name is not an asset");
	}

	[Test]
	public static void CreateAssetCreateWaitsWhileTheNameIsRefusedSayingWhyTheGroupFieldPicksAnotherCreateAnswersAndCloses()
	{
		let bed = scope ProjectBed();
		let scene = scope SceneBed();
		let dialog = scene.Open(bed, bed.Top, "Crate");
		defer delete dialog;
		Test.Assert(dialog.IsOpen);
		Test.Assert(dialog.Window.Title == "New Asset");
		let name = Part<TextField>(dialog, "asset-create-name");
		let why = Part<Sedulous.GUI.Label>(dialog, "asset-create-why");
		let create = Part<Sedulous.GUI.Button>(dialog, "asset-create-create");
		let group = Part<Sedulous.GUI.Button>(dialog, "asset-create-group");
		Test.Assert(name.Text == "Crate", "the suggestion");
		Test.Assert(scene.Root.EventDispatcher.FocusNode === name, "the name focused");
		Test.Assert(group.Text == "Content");
		Test.Assert(!create.Enabled, "the suggestion is taken here");
		Test.Assert(why.Text == "Crate is already in Content.");
		Test.Assert(why.HasClass("refused"), "red");

		// Pressed while it waits, Create makes nothing and stays.
		Test.Assert(create.HandleActivate());
		Test.Assert(scene.Made == 0);
		Test.Assert(dialog.IsOpen);

		// Another group, through the picker below the field: the same name is free there. The field
		// given a height, as the editor's sheet would (no sheet is loaded here).
		group.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(24.0f); });
		scene.Layout();
		Test.Assert(group.HandleActivate());
		Test.Assert(scene.Groups.IsOpen);
		scene.Layout();
		let fieldAt = group.ConvertToRootSpace(.(0.0f, 0.0f));
		let pickerAt = scene.Groups.Content.ConvertToRootSpace(.(0.0f, 0.0f));
		Test.Assert(group.Size.Y > 0.0f, "laid out");
		Test.Assert(pickerAt.Y >= fieldAt.Y + group.Size.Y - 0.5f, "below the group field");
		Test.Assert(scene.Groups.LitKey == "Content", "the group now checked and lit");
		scene.Groups.SetQuery("town");
		scene.Groups.PickLit();
		Test.Assert(!scene.Groups.IsOpen);
		Test.Assert(dialog.TargetGroup == bed.Town);
		Test.Assert(group.Text == "Models/Town");
		Test.Assert(create.Enabled);
		Test.Assert(why.Text == "Makes Crate in Models/Town.");
		Test.Assert(!why.HasClass("refused"), "not red");

		scene.Type(name, "Barrel"); // taken in Town
		Test.Assert(name.Text == "Barrel");
		Test.Assert(!create.Enabled);
		Test.Assert(why.Text == "Barrel is already in Models/Town.");
		Test.Assert(why.HasClass("refused"));
		scene.Type(name, "Bar:rel");
		Test.Assert(!create.Enabled);
		Test.Assert(why.Text == "A name cannot hold :.");
		scene.Type(name, "Lamp");
		Test.Assert(create.Enabled);
		Test.Assert(why.Text == "Makes Lamp in Models/Town.");
		Test.Assert(create.HandleActivate());
		Test.Assert(scene.Made == 1);
		Test.Assert(scene.MadeIn == bed.Town);
		Test.Assert(scene.MadeName == "Lamp");
		Test.Assert(!dialog.IsOpen);
		Test.Assert(bed.Town.GetInstance("Lamp") == null, "its owner creates it, not it");
	}

	[Test]
	public static void EnterCreatesAsCreateDoesAndWaitsWhileTheNameIsRefusedCancelMakesNothing()
	{
		let bed = scope ProjectBed();
		let scene = scope SceneBed();
		let dialog = scene.Open(bed, bed.Top, "Crate");
		defer delete dialog;
		let name = Part<TextField>(dialog, "asset-create-name");
		let d = scene.Root.EventDispatcher;
		name.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Return, 0);
		Test.Assert(dialog.IsOpen, "taken: Enter waits as Create does");
		Test.Assert(scene.Made == 0);
		scene.Type(name, "Lamp");
		d.InjectKeyDown((uint32)KeyCode.Return, 0);
		Test.Assert(!dialog.IsOpen);
		Test.Assert(scene.Made == 1);
		Test.Assert((scene.MadeIn == bed.Top) && (scene.MadeName == "Lamp"));

		// Cancel closes, making nothing.
		let again = scene.Open(bed, bed.Models, "Lamp");
		defer delete again;
		Test.Assert(again.IsOpen);
		Test.Assert(Part<Sedulous.GUI.Button>(again, "asset-create-group").Text == "Models");
		Test.Assert(Part<Sedulous.GUI.Button>(again, "asset-create-cancel").HandleActivate());
		Test.Assert(!again.IsOpen);
		Test.Assert(scene.Made == 1);

		// Markup without its parts opens nothing.
		Test.Assert(AssetCreate.Open(scene.Root, new Sedulous.GUI.Panel(), bed.Sources, bed.Top, "New Asset", "Lamp", scene.Groups,
			new (target, made) => { }) == null);
		Test.Assert(AssetCreate.Open(scene.Root, null, bed.Sources, bed.Top, "New Asset", "Lamp", scene.Groups,
			new (target, made) => { }) == null);
	}
}
