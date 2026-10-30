using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The export templates dialog over its markup (Data/Editor/Templates.gml) and a scratch templates
/// root: it lists what the root holds and the host build, shows the selected one's details (its
/// engine version, warned when not this editor's), installs a bundle from a folder, and removes one
/// after asking (from its button or Delete on the list), never the host build. Then what Sedulous
/// adds so each behaviour has a test: a row built for another engine warned of and one built for
/// this editor not, its Engine detail marked; an empty detail left out, caption and all; Remove's
/// question over the host build never asked, by its button or by Delete.
class TemplatesDialogTests
{
	/// A template bundle in `dir`: its manifest and a player file.
	private static void WriteBundle(StringView dir, StringView id, StringView name, StringView engineVersion)
	{
		Test.Assert(CreateDirectory(dir));
		let template = scope ExportTemplate();
		template.Id.Set(id);
		template.Name.Set(name);
		template.Platform.Set("Linux64");
		template.Config.Set("Release");
		template.EngineVersion.Set(engineVersion);
		template.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
		template.Sidecars.Add(new .("libwgpu_native.so"));
		template.Notes.Set("for the test");
		Test.Assert(ExportTemplates.SaveManifest(scope NativeFileSystem(dir), template) case .Ok);
		let player = "#!player\n";
		Test.Assert(WriteFile(PathJoin(dir, "Sedulous.Engine.Player.Desktop", .. scope .()), .((uint8*)player.Ptr, player.Length)) case .Ok);
	}

	/// A dialog's markup read from the repository's Data with the elements the editor's window
	/// registers (Export's grid is the toolkit's); its one reference is the caller's.
	public static Node LoadDialog(StringView path)
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, path, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	private class Fixture
	{
		public String Root = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_templates_dialog_root", .. new .()) ~ delete _;
		public String Source = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_templates_dialog_source", .. new .()) ~ delete _;
		public String HostDir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_templates_dialog_host", .. new .()) ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public SceneRoot Ui;
		/// What the folder picker answers; empty is a cancel.
		public String Picked = new .() ~ delete _;
		public List<String> Revealed = new .() ~ DeleteContainerAndItems!(_);
		public TemplatesDialog Dialog = null;

		public this()
		{
			Clean();
			Test.Assert(CreateDirectory(Root));
			WriteBundle(PathJoin(Root, "t-linux", .. scope .()), "t-linux", "Linux Release", EngineVersion.String);
			WriteBundle(PathJoin(Root, "t-old", .. scope .()), "t-old", "Old Linux", "0.0.1");
			// The host build: a player beside the (pretend) editor.
			Test.Assert(CreateDirectory(HostDir));
			let player = "#!player\n";
			let playerPath = PathJoin(HostDir, BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .()), .. scope .());
			Test.Assert(WriteFile(playerPath, .((uint8*)player.Ptr, player.Length)) case .Ok);
			let gui = new GUIContext();
			Ui = new SceneRoot(gui);
			gui.ReleaseRef(); // the root's keeps it
			Ui.Size = .(1000.0f, 700.0f);
		}

		public ~this()
		{
			delete Dialog; // closed while the root is there
			Ui.ReleaseRef();
			Clean();
		}

		private void Clean()
		{
			RemoveDirectoryRecursive(Root);
			RemoveDirectoryRecursive(Source);
			RemoveDirectoryRecursive(HostDir);
		}

		public TemplatesDialogSeams Seams()
		{
			let seams = new TemplatesDialogSeams();
			seams.TemplatesRoot = new [=this](outRoot) => { outRoot.Set(Root); };
			seams.Refresh = new [=this](registry) => { registry.Refresh(Root, HostDir); };
			seams.PickFolder = new [=this](chosen) =>
				{
					chosen(Picked);
					delete chosen;
				};
			seams.RevealFolder = new [=this](folder) => { Revealed.Add(new .(folder)); };
			return seams;
		}

		/// The dialog open over the root, laid out.
		public TemplatesDialog Open()
		{
			Dialog = new TemplatesDialog(Context, Seams(), LoadDialog(TemplatesDialog.cMarkupPath));
			Test.Assert(Dialog.Open(Ui));
			Ui.UpdateLayout();
			return Dialog;
		}

		public static int IndexOf(TemplatesDialog dialog, StringView id)
		{
			for (int i < dialog.TemplateCount)
			{
				if (dialog.TemplateAt(i).Id == id)
					return i;
			}
			return -1;
		}

		public static int HostIndex(TemplatesDialog dialog)
		{
			for (int i < dialog.TemplateCount)
			{
				if (dialog.TemplateAt(i).IsHost)
					return i;
			}
			return -1;
		}

		/// The list a fixed 290 by 300, as the editor's sheet makes it, so it realises its rows.
		public void SizeList()
		{
			Dialog.List.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(290.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			Ui.UpdateLayout();
			Ui.UpdateLayout();
		}

		/// The row showing template `index`; asserted realised.
		public TemplateRow RowOf(int index)
		{
			let row = Dialog.List.RowForItem((int32)index);
			Test.Assert(row != null, "realised");
			let shown = row.Content as TemplateRow;
			Test.Assert(shown != null);
			return shown;
		}

		public bool PressDelete() => Ui.EventDispatcher.InjectKeyDown((uint32)KeyCode.Delete);
	}

	/// The root's templates and the host build are listed; the selected one's details show, a
	/// template built for another engine says so, and the host build is never removable.
	[Test]
	public static void ListsTheRootsTemplatesAndTheHostBuildTheSelectedOnesDetails()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(dialog.TemplateCount == 3, "two installed, the host build");
		Test.Assert(dialog.Selected != null, "the first, selected on open");

		let linuxIndex = Fixture.IndexOf(dialog, "t-linux");
		Test.Assert(linuxIndex >= 0);
		dialog.Select(linuxIndex);
		Test.Assert(dialog.DetailText("Platform") == "Linux64");
		Test.Assert(dialog.DetailText("Engine") == EngineVersion.String);
		Test.Assert(dialog.DetailText("Runtime files") == "libwgpu_native.so");
		Test.Assert(dialog.DetailText("Notes") == "for the test");
		Test.Assert(dialog.RemoveButton.Enabled);
		Test.Assert(dialog.RevealButton.HandleActivate());
		Test.Assert(f.Revealed.Count == 1);
		Test.Assert(f.Revealed[0].EndsWith("t-linux"));

		// Built for another engine: it says so, and that an export still runs.
		dialog.Select(Fixture.IndexOf(dialog, "t-old"));
		Test.Assert(dialog.DetailText("Engine").StartsWith("0.0.1 (this editor is"));

		// The host build is this editor's own: never removable.
		dialog.Select(Fixture.HostIndex(dialog));
		Test.Assert(dialog.Selected.IsHost);
		Test.Assert(!dialog.RemoveButton.Enabled);
		dialog.RemoveSelected(true);
		Test.Assert(dialog.TemplateCount == 3);
	}

	/// Install copies the picked folder's bundle in, lists and selects it; a cancelled pick does
	/// nothing; Remove asks first, from its button or Delete on the list, and its Remove deletes
	/// the folder and the row.
	[Test]
	public static void InstallsABundleFromAFolderAndRemovesOneTheListFollowing()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(dialog.TemplateCount == 3);

		// Install: the picked folder's bundle is copied into the root, listed and selected.
		WriteBundle(f.Source, "t-new", "New Linux", EngineVersion.String);
		f.Picked.Set(f.Source);
		dialog.InstallFromFolder();
		Test.Assert(dialog.TemplateCount == 4);
		Test.Assert((dialog.Selected != null) && (dialog.Selected.Id == "t-new"));
		Test.Assert(DirectoryExists(PathJoin(f.Root, "t-new", .. scope .())));

		// A cancelled pick does nothing.
		f.Picked.Clear();
		dialog.InstallFromFolder();
		Test.Assert(dialog.TemplateCount == 4);

		// Remove asks first; Cancel keeps it.
		Test.Assert(dialog.RemoveButton.HandleActivate());
		var question = PagesBed.FindBox(f.Ui);
		Test.Assert(question != null);
		question.RequestClose(); // Escape: its cancel
		Test.Assert(dialog.TemplateCount == 4);
		Test.Assert(DirectoryExists(PathJoin(f.Root, "t-new", .. scope .())));

		// Delete on the list asks the same; Remove: its folder goes, and so does its row.
		dialog.Select(Fixture.IndexOf(dialog, "t-new"));
		Test.Assert(dialog.Selected != null);
		dialog.List.RequestFocus();
		f.PressDelete();
		question = PagesBed.FindBox(f.Ui);
		Test.Assert(question != null);
		Test.Assert(question.ButtonAt(1) != null);
		Test.Assert(question.ButtonAt(1).HandleActivate(), "Remove");
		Test.Assert(dialog.TemplateCount == 3);
		Test.Assert(!DirectoryExists(PathJoin(f.Root, "t-new", .. scope .())));
		Test.Assert(Fixture.IndexOf(dialog, "t-new") < 0);
	}

	/// A row built for another engine carries the warning, one built for this editor none; the
	/// Engine detail is marked for the one and not the other.
	[Test]
	public static void ATemplateBuiltForAnotherEngineIsWarnedOfInItsRowAndItsDetail()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		f.SizeList();
		let linuxIndex = Fixture.IndexOf(dialog, "t-linux");
		let oldIndex = Fixture.IndexOf(dialog, "t-old");
		Test.Assert((linuxIndex >= 0) && (oldIndex >= 0));

		let old = f.RowOf(oldIndex);
		Test.Assert(old.ShownName == "Old Linux");
		Test.Assert(old.ShownSummary == "Linux64 · Release · 0.0.1");
		Test.Assert(old.ShowsWarning, "built for another engine");
		Test.Assert(!f.RowOf(linuxIndex).ShowsWarning, "built for this editor");
		Test.Assert(f.RowOf(Fixture.HostIndex(dialog)).ShownSummary.EndsWith(" · this editor's own"));

		dialog.Select(oldIndex);
		Test.Assert(dialog.DetailWarns("Engine"));
		dialog.Select(linuxIndex);
		Test.Assert(!dialog.DetailWarns("Engine"));
		Test.Assert(dialog.DetailText("Engine") == EngineVersion.String);
	}

	/// A detail with nothing to say is left out, its caption with it; one with something shows.
	[Test]
	public static void AnEmptyDetailIsLeftOutItsCaptionWithIt()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		dialog.Select(Fixture.IndexOf(dialog, "t-linux"));
		Test.Assert(dialog.Selected.Compiler.IsEmpty, "the bundle names no compiler");
		Test.Assert(!dialog.ShowsDetail("Compiler"));
		Test.Assert(dialog.DetailText("Compiler").IsEmpty);
		Test.Assert(dialog.ShowsDetail("Notes"));
		Test.Assert(dialog.ShowsDetail("Platform"));
		Test.Assert(!dialog.ShowsEmpty, "templates are listed");
	}

	/// The host build is never asked about: neither its Remove button (disabled) nor Delete on the
	/// list opens the question, and nothing is removed.
	[Test]
	public static void RemoveNeverAsksAboutTheHostBuildByItsButtonOrByDelete()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		dialog.Select(Fixture.HostIndex(dialog));
		Test.Assert(dialog.Selected.IsHost);
		dialog.RemoveSelected();
		Test.Assert(PagesBed.FindBox(f.Ui) == null, "not asked");
		dialog.List.RequestFocus();
		f.PressDelete();
		Test.Assert(PagesBed.FindBox(f.Ui) == null, "not asked by Delete either");
		Test.Assert(dialog.TemplateCount == 3);

		// An installed one is asked about, by its message.
		dialog.Select(Fixture.IndexOf(dialog, "t-old"));
		dialog.RemoveSelected();
		let question = PagesBed.FindBox(f.Ui);
		Test.Assert(question != null);
		Test.Assert(question.Message.StartsWith("Remove 'Old Linux'? Its folder is deleted"));
		question.RequestClose();
		Test.Assert(dialog.TemplateCount == 3);
	}

	/// A long folder wraps inside the details, never past their edge: a path has no spaces to
	/// break at, so the value breaks anywhere. Under the editor's sheet with its fonts, since
	/// without one text has no width and the overflow cannot show.
	[Test]
	public static void ALongFolderWrapsInsideTheDetailsNeverPastTheirEdge()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		let sheet = scope EditorSheet(true); // goes first, while the tree it styled is there
		dialog.Select(Fixture.IndexOf(dialog, "t-linux"));
		let folder = dialog.DetailValue("Folder");
		Test.Assert(folder != null);
		Test.Assert(dialog.DetailValue("Nowhere") == null);
		// One path with no spaces to break at, far wider than the window.
		let path = scope String("/home");
		for (int i < 40)
			path.Append("/averylongfoldername");
		folder.Text = path;
		sheet.Apply(f.Ui);
		f.Ui.UpdateLayout();
		let fields = folder.Parent as UIWidget;
		Test.Assert(fields != null);
		let edge = fields.ScreenBounds;
		let value = folder.ScreenBounds;
		Test.Assert(value.Width > 0.0f);
		Test.Assert(value.X + value.Width <= edge.X + edge.Width + 0.5f, "inside the details");
		Test.Assert(value.Height > 30.0f, "wrapped onto several lines");
	}

	/// A template's row under the editor's sheet: --space-l at its side and between its icon and
	/// its text, a 28-pixel icon, a gap (--space-xs) between its name and summary; two lines high
	/// with room above and below (the list's row, 52 pixels: the views' default one line had
	/// squeezed the rows into each other).
	[Test]
	public static void ATemplatesRowHasRoomAtItsSidesALargerIconAGapBetweenItsLines()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		let sheet = scope EditorSheet(true); // goes first, while the tree it styled is there
		sheet.Apply(f.Ui);
		f.SizeList();
		let row = f.RowOf(Fixture.IndexOf(dialog, "t-linux"));
		let icon = row.GetChildAt(0) as UIWidget;
		let text = row.GetChildAt(1) as UIWidget;
		Test.Assert(icon.HasClass("template-row-icon") && text.HasClass("template-row-text"));
		let name = text.GetChildAt(0) as UIWidget;
		let summary = text.GetChildAt(1) as UIWidget;
		Test.Assert(name.Size.Y > 0.0f, "laid out, with its font");
		let at = row.ConvertToRootSpace(.(0.0f, 0.0f));
		let iconAt = icon.ConvertToRootSpace(.(0.0f, 0.0f));
		let textAt = text.ConvertToRootSpace(.(0.0f, 0.0f));
		let nameAt = name.ConvertToRootSpace(.(0.0f, 0.0f));
		let summaryAt = summary.ConvertToRootSpace(.(0.0f, 0.0f));
		Test.Assert(row.Size.Y == dialog.List.RowHeight, "the list's row");
		Test.Assert(dialog.List.RowHeight == 52.0f, "two lines with room above and below");
		Test.Assert((icon.Size.X == 28.0f) && (icon.Size.Y == 28.0f), "a slightly larger icon");
		Test.Assert(iconAt.X - at.X == 12.0f, "--space-l at its side");
		Test.Assert(textAt.X - (iconAt.X + icon.Size.X) == 12.0f, "--space-l between icon and text");
		Test.Assert(summaryAt.Y - (nameAt.Y + name.Size.Y) == 2.0f, "--space-xs between the lines");
	}
}
