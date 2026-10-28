using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The import window over its markup (Data/Editor/Import.gml) and an import of the test's own: what
/// a file would create shown by kind, each kept or not and named; Import open with what it will do,
/// and waiting, saying why, while a file is being read or nothing is kept; the files listed when
/// there are several; Import making what is kept and closing. Keeps the 2026-09-21 regression:
/// Import opens once inline files are described (it once stayed shut, "click Import, nothing
/// happens"). Then what Sedulous adds so each behaviour has a test: a file being read but not kept
/// keeps nothing waiting; a failed file's box off and its detail saying so; a row's name choosing
/// its file; the group field picking another group; the importer's choice describing the file
/// again; a kind's box keeping or leaving all of it, and mixed when its entries are; a rename in
/// place; the options' boxes writing through (one pointing at nothing shown not); Import and
/// Cancel by their buttons; and the editor's one import, at once when nothing needs review, else in
/// the window, a second refused while one is open.
static class ImportDialogTests
{
	/// Takes ".box": would make a mesh and two textures, each kept or not and named as chosen.
	private class BoxImporter : IFileImporter
	{
		public StringView Label => "Box";
		public bool Accepts(StringView ext) => ext == "box";

		public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared, ImportPlan outPlan)
		{
			outPlan.Add(new ImportPlanEntry(.Mesh, "Box", "Box"));
			outPlan.Add(new ImportPlanEntry(.Texture, "Wood", "Wood"));
			outPlan.Add(new ImportPlanEntry(.Texture, "Rust", "Rust"));
		}

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
		{
			Instance primary = null;
			for (let entry in options.Selection.Entries)
			{
				if (!entry.Enabled)
					continue;
				let made = group.CreateInstance(options.SelectionName(entry.Kind, entry.SourceName), "Tests.WindowThing");
				if (primary == null)
					primary = made;
			}
			return primary;
		}
	}

	/// Takes ".kit": as Kit one mesh, as Parts two meshes and a material.
	private class KitImporter : IFileImporter
	{
		private String mLabel = new .() ~ delete _;

		public this(StringView label)
		{
			mLabel.Set(label);
		}

		public StringView Label => mLabel;
		public bool Accepts(StringView ext) => ext == "kit";

		public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared, ImportPlan outPlan)
		{
			if (mLabel == "Kit")
			{
				outPlan.Add(new ImportPlanEntry(.Mesh, "Kit", "Kit"));
				return;
			}
			outPlan.Add(new ImportPlanEntry(.Mesh, "Left", "Left"));
			outPlan.Add(new ImportPlanEntry(.Mesh, "Right", "Right"));
			outPlan.Add(new ImportPlanEntry(.Material, "Paint", "Paint"));
		}

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
			=> group.CreateInstance(mLabel, "Tests.WindowThing");
	}

	/// No options and nothing to review: one instance of its name, imported at once.
	private class ScriptImporter : IFileImporter
	{
		public StringView Label => "Script";
		public bool Accepts(StringView ext) => ext == "as";

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
			=> group.CreateInstance("Player", "Tests.WindowThing");
	}

	/// A box that writes through to its field, and one that points at nothing.
	private class ToggledOptions : ImportOptions
	{
		public bool Flip = true;

		public override void GetToggles(List<ImportToggle> outToggles)
		{
			outToggles.Add(.("Flip", "Flips it", &Flip));
			outToggles.Add(.("Ghost", "", null));
		}
	}

	/// Takes ".cfg": options with toggles, no plan.
	private class ToggledImporter : IFileImporter
	{
		public StringView Label => "Config";
		public bool Accepts(StringView ext) => ext == "cfg";
		public ImportOptions CreateOptions() => new ToggledOptions();

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
			=> group.CreateInstance("Config", "Tests.WindowThing");
	}

	/// A scratch project (Content, Models) open in an editor context, its importers registered; the
	/// window over its markup in a root of 1000 by 700, its group field opening the picker over its
	/// own markup. The notices in Said.
	private class Bed
	{
		public String Dir = new .() ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .();
		public AssetImport Import;
		public SceneRoot Root;
		public Picker Groups;
		public ImportWindow Window;
		public Group Top;
		public Group Models;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		/// How often Run asked for the window.
		public int Asked = 0;

		public this(StringView dir)
		{
			Dir.Set(dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Window") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Top = Project.SourceDb.RootGroup;
			Models = Top.CreateGroup("Models");
			Test.Assert(Models != null);
			Context.SetProject(Project);
			let bed = this;
			Context.OnNotice = new [=bed] (kind, message) => { bed.Said.Add(new String(message)); };
			let importers = Context.Importers;
			importers.Register(new BoxImporter());
			importers.Register(new KitImporter("Kit"));
			importers.Register(new KitImporter("Parts"));
			importers.Register(new ScriptImporter());
			importers.Register(new ToggledImporter());
			let services = new AssetImportServices();
			services.Context = Context;
			Import = new AssetImport(services);
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1000.0f, 700.0f);
			Groups = new Picker(PagesBed.LoadMarkup(Picker.cMarkupPath));
			Test.Assert(Groups.Content != null);
			Window = new ImportWindow(Import, Groups, PagesBed.LoadMarkup(ImportWindow.cMarkupPath));
			Test.Assert(Window.Window != null);
		}

		public ~this()
		{
			// The window (closed, its session let go) while the root and the picker are there; the
			// import before the context (its importers), the context before the project it borrows.
			DeleteAndNullify!(Window);
			DeleteAndNullify!(Groups);
			delete Import;
			Context.SetProject(null);
			delete Context;
			Root.ReleaseRef();
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// An import of `paths` into the top, open in the window and laid out. The caller's
		/// reference (the window holds its own).
		public AssetImport.Session Open(Span<StringView> paths)
		{
			let session = Import.Begin(paths, Top);
			Test.Assert(session != null);
			Test.Assert(Window.Open(Root, session));
			Layout();
			return session;
		}

		/// The editor's one import of `paths` into the top, over the bed's window.
		public void Run(Span<StringView> paths)
		{
			ImportWindow.Run(Import, Context, paths, Top, Root, scope [&] () =>
				{
					Asked++;
					return Window;
				});
			Layout();
		}

		/// Twice: a popup is sized by what it holds, then what it holds is placed in it.
		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		/// What the window asked to do after the event (a rebuild), done.
		public void Drain()
		{
			Root.MutationQueue.Drain();
			Layout();
		}

		/// As the user types into `field`: over what is there.
		public void Type(TextField field, StringView text)
		{
			field.RequestFocus();
			field.SelectAll();
			Root.EventDispatcher.InjectText(text);
		}

		public StringView LastSaid => Said.IsEmpty ? "" : Said.Back;
	}

	private static int Count<T>(Node node) where T : Node
	{
		int count = ((node as T) != null) ? 1 : 0;
		for (int i < node.ChildCount)
			count += Count<T>(node.GetChildAt(i));
		return count;
	}

	/// Every T under `node`, in tree order.
	private static void Collect<T>(Node node, List<T> outFound) where T : Node
	{
		if (let found = node as T)
			outFound.Add(found);
		for (int i < node.ChildCount)
			Collect<T>(node.GetChildAt(i), outFound);
	}

	/// Whether a label under `node` says `text`.
	private static bool Says(Node node, StringView text)
	{
		let labels = scope List<Sedulous.GUI.Label>();
		Collect<Sedulous.GUI.Label>(node, labels);
		for (let label in labels)
		{
			if (label.Text == text)
				return true;
		}
		return false;
	}

	/// The files' row `index`: its box, its name, its state.
	private static Node FileRow(ImportWindow window, int index)
	{
		let row = window.Files.GetChildAt(index);
		Test.Assert(row != null);
		return row;
	}

	[Test]
	public static void AFilesPlanByKindEachKeptAndNamedImportOpenSayingWhatItDoesImportMakesWhatIsKeptAndCloses()
	{
		let bed = scope Bed("scratch_import_window_plan");
		let session = bed.Open(scope StringView[]("/somewhere/crate.box"));
		defer session.ReleaseRef();
		Test.Assert(bed.Window.IsOpen);
		Test.Assert(bed.Window.Window.Title == "Import");
		Test.Assert(!bed.Window.FilesScroll.Displayed, "one file: no list of them");
		Test.Assert(bed.Window.GroupField.Text == "Content");
		// Two kinds' boxes, three entries' boxes and names (no option toggles here).
		let detail = bed.Window.Detail;
		Test.Assert(Count<Sedulous.GUI.CheckBox>(detail) == 5);
		Test.Assert(Count<TextField>(detail) == 3);
		Test.Assert(Says(detail, "crate.box"), "its title");
		Test.Assert(Count<ComboBox>(detail) == 0, "one importer: no choice");
		Test.Assert(bed.Window.ImportButton.Enabled, "the regression: open once described");
		Test.Assert(bed.Window.Why == "Into Content.");
		Test.Assert(!bed.Window.WhyLine.HasClass("refused"));

		session.Files[0].Plan.Entries[2].Enabled = false; // Rust left out
		Test.Assert(bed.Window.Import());
		Test.Assert(!bed.Window.IsOpen);
		Test.Assert(bed.Top.GetInstance("Box") != null);
		Test.Assert(bed.Top.GetInstance("Wood") != null);
		Test.Assert(bed.Top.GetInstance("Rust") == null);
		Test.Assert(session.Closed, "the window let go of it");
		Test.Assert(bed.Window.Session == null);
		Test.Assert(session.OnChanged == null, "it is told no more");
	}

	[Test]
	public static void ImportWaitsWhileAFileIsReadSayingSoAndOpensWhenItIsReadySeveralFilesAreListedNoneKeptWaits()
	{
		let bed = scope Bed("scratch_import_window_reading");
		let session = bed.Open(scope StringView[]("/somewhere/a.box", "/somewhere/b.box"));
		defer session.ReleaseRef();
		Test.Assert(bed.Window.ImportButton.Enabled);
		Test.Assert(bed.Window.Why == "2 of 2 files into Content.");
		Test.Assert(bed.Window.FilesScroll.Displayed);
		Test.Assert(bed.Window.Files.ChildCount == 2);
		Test.Assert(Says(FileRow(bed.Window, 1), "b.box"));
		Test.Assert(Says(FileRow(bed.Window, 1), "Ready"));
		Test.Assert((FileRow(bed.Window, 0) as UIWidget).HasClass("selected"));
		Test.Assert(!(FileRow(bed.Window, 1) as UIWidget).HasClass("selected"));

		// As a heavy importer's file while the worker reads it, then told it is ready.
		session.Files[1].State = .Reading;
		session.OnChanged(1);
		Test.Assert(!bed.Window.ImportButton.Enabled);
		Test.Assert(bed.Window.Why == "Reading b.box...");
		Test.Assert(bed.Window.WhyLine.HasClass("refused"), "the line and Import wait together");
		Test.Assert(Says(FileRow(bed.Window, 1), "Reading"));
		Test.Assert(!bed.Window.Import(), "it stays");
		Test.Assert(bed.Window.IsOpen);
		Test.Assert(bed.Top.GetInstance("Box") == null);
		// Its row's name chooses it: its detail says it is being read.
		Test.Assert((FileRow(bed.Window, 1).GetChildAt(1) as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(bed.Window.Selected == 0, "not under the click");
		bed.Drain();
		Test.Assert(bed.Window.Selected == 1);
		Test.Assert((FileRow(bed.Window, 1) as UIWidget).HasClass("selected"));
		Test.Assert(Says(bed.Window.Detail, "Reading b.box..."));
		Test.Assert(Count<ProgressBar>(bed.Window.Detail) == 1);
		Test.Assert(Count<TextField>(bed.Window.Detail) == 0, "no plan while it is read");
		session.Files[1].State = .Ready;
		session.OnChanged(1);
		Test.Assert(bed.Window.ImportButton.Enabled);
		Test.Assert(!bed.Window.WhyLine.HasClass("refused"));
		Test.Assert(Count<TextField>(bed.Window.Detail) == 3, "the chosen file's detail shown again");

		// A file read but not kept keeps nothing waiting: only a kept file must be ready.
		Test.Assert((FileRow(bed.Window, 1).GetChildAt(0) as Sedulous.GUI.CheckBox).HandleActivate());
		Test.Assert(!session.Files[1].Kept);
		Test.Assert(bed.Window.Why == "1 of 2 files into Content.");
		session.Files[1].State = .Reading;
		session.OnChanged(1);
		Test.Assert(bed.Window.ImportButton.Enabled);

		session.Files[0].Kept = false;
		session.OnChanged(0);
		Test.Assert(!bed.Window.ImportButton.Enabled);
		Test.Assert(bed.Window.Why == "No file is kept.");
		bed.Window.Close();
		Test.Assert(session.Closed);
	}

	[Test]
	public static void AFailedFilesBoxIsOffItsStateAndDetailSayingSo()
	{
		let bed = scope Bed("scratch_import_window_failed");
		let session = bed.Open(scope StringView[]("/somewhere/a.box", "/somewhere/b.box"));
		defer session.ReleaseRef();
		Test.Assert((FileRow(bed.Window, 1).GetChildAt(0) as Sedulous.GUI.CheckBox).Enabled);
		// As AssetImport leaves a read that failed: failed, left out.
		session.Files[1].State = .Failed;
		session.Files[1].Kept = false;
		session.OnChanged(1);
		let failed = FileRow(bed.Window, 1).GetChildAt(0) as Sedulous.GUI.CheckBox;
		Test.Assert(!failed.Enabled, "a failed file cannot be kept");
		Test.Assert(!failed.Checked);
		Test.Assert((FileRow(bed.Window, 0).GetChildAt(0) as Sedulous.GUI.CheckBox).Enabled);
		Test.Assert(Says(FileRow(bed.Window, 1), "Failed"));
		Test.Assert(bed.Window.ImportButton.Enabled);
		Test.Assert(bed.Window.Why == "1 of 2 files into Content.");
		bed.Window.Select(1);
		Test.Assert(Says(bed.Window.Detail, "It could not be read; the Console says why."));
		Test.Assert(Count<Sedulous.GUI.CheckBox>(bed.Window.Detail) == 0);
	}

	[Test]
	public static void TheGroupFieldPicksAnotherGroupTheImportGoesThere()
	{
		let bed = scope Bed("scratch_import_window_group");
		let session = bed.Open(scope StringView[]("/somewhere/crate.box"));
		defer session.ReleaseRef();
		let field = bed.Window.GroupField;
		Test.Assert(field.Text == "Content");
		Test.Assert(field.HandleActivate());
		Test.Assert(bed.Groups.IsOpen, "the group picker");
		bed.Layout();
		Test.Assert(bed.Groups.LitKey == "Content", "the import's group checked and lit");
		bed.Groups.SetQuery("models");
		bed.Groups.PickLit();
		Test.Assert(!bed.Groups.IsOpen);
		Test.Assert(session.GroupKey == "Content/Models");
		Test.Assert(field.Text == "Models");
		Test.Assert(bed.Window.Why == "Into Models.");
		Test.Assert(bed.Window.ImportButton.HandleActivate(), "Import by its button");
		Test.Assert(!bed.Window.IsOpen);
		Test.Assert(bed.Models.GetInstance("Box") != null);
		Test.Assert(bed.Top.GetInstance("Box") == null);
	}

	[Test]
	public static void ChoosingAnotherImporterDescribesTheFileAgain()
	{
		let bed = scope Bed("scratch_import_window_importer");
		let session = bed.Open(scope StringView[]("/somewhere/set.kit"));
		defer session.ReleaseRef();
		let combos = scope List<ComboBox>();
		Collect<ComboBox>(bed.Window.Detail, combos);
		Test.Assert(combos.Count == 1, "two importers take it: a choice");
		Test.Assert(combos[0].ItemCount == 2);
		Test.Assert(combos[0].SelectedText == "Kit");
		Test.Assert(Says(bed.Window.Detail, "Import as"));
		Test.Assert(Count<TextField>(bed.Window.Detail) == 1);
		combos[0].SelectByUser(1);
		Test.Assert(session.Files[0].ImporterIndex == 1);
		Test.Assert(session.Files[0].Plan.Entries.Count == 3, "described again");
		bed.Drain(); // the detail made again, not under the combo's own event
		Test.Assert(Count<TextField>(bed.Window.Detail) == 3);
		Test.Assert(Says(bed.Window.Detail, "Meshes (2)"));
		Test.Assert(Says(bed.Window.Detail, "Materials (1)"));
		combos.Clear();
		Collect<ComboBox>(bed.Window.Detail, combos);
		Test.Assert((combos.Count == 1) && (combos[0].SelectedText == "Parts"));
		Test.Assert(bed.Window.Import());
		Test.Assert(bed.Top.GetInstance("Parts") != null);
		Test.Assert(bed.Top.GetInstance("Kit") == null);
	}

	[Test]
	public static void AKindsBoxKeepsOrLeavesAllOfItMixedWhenItsEntriesAre()
	{
		let bed = scope Bed("scratch_import_window_kinds");
		let session = bed.Open(scope StringView[]("/somewhere/crate.box"));
		defer session.ReleaseRef();
		let entries = session.Files[0].Plan.Entries;
		// [Meshes (1)][Box][Textures (2)][Wood][Rust], in the kinds' order.
		let boxes = scope List<Sedulous.GUI.CheckBox>();
		Collect<Sedulous.GUI.CheckBox>(bed.Window.Detail, boxes);
		Test.Assert(boxes.Count == 5);
		Test.Assert(boxes[0].Text == "Meshes (1)");
		Test.Assert(boxes[2].Text == "Textures (2)");
		Test.Assert(boxes[2].Checked && !boxes[2].Indeterminate);

		// The textures' box leaves both, not the mesh.
		Test.Assert(boxes[2].HandleActivate());
		Test.Assert(entries[0].Enabled);
		Test.Assert(!entries[1].Enabled && !entries[2].Enabled);
		bed.Drain();
		boxes.Clear();
		Collect<Sedulous.GUI.CheckBox>(bed.Window.Detail, boxes);
		Test.Assert(!boxes[2].Checked && !boxes[3].Checked && !boxes[4].Checked);

		// One kept again: the kind's box mixed; pressed, it keeps all.
		Test.Assert(boxes[3].HandleActivate());
		Test.Assert(entries[1].Enabled && !entries[2].Enabled);
		bed.Drain();
		boxes.Clear();
		Collect<Sedulous.GUI.CheckBox>(bed.Window.Detail, boxes);
		Test.Assert(boxes[2].Indeterminate);
		Test.Assert(boxes[2].HandleActivate());
		Test.Assert(entries[1].Enabled && entries[2].Enabled);
	}

	[Test]
	public static void ANameIsEditedInPlaceAndImportedSoCancelImportsNothing()
	{
		let bed = scope Bed("scratch_import_window_rename");
		let session = bed.Open(scope StringView[]("/somewhere/crate.box"));
		defer session.ReleaseRef();
		let fields = scope List<TextField>();
		Collect<TextField>(bed.Window.Detail, fields);
		Test.Assert(fields.Count == 3);
		Test.Assert((fields[0].Text == "Box") && (fields[0].Placeholder == "Box"));
		bed.Type(fields[0], "Hull");
		Test.Assert(session.Files[0].Plan.Entries[0].TargetName == "Hull");
		Test.Assert(session.Files[0].Plan.Entries[1].TargetName == "Wood", "untouched entries keep their names");
		Test.Assert(bed.Window.ImportButton.HandleActivate());
		Test.Assert(!bed.Window.IsOpen);
		Test.Assert(bed.Top.GetInstance("Hull") != null);
		Test.Assert(bed.Top.GetInstance("Box") == null);

		// Cancel closes, importing nothing.
		let again = bed.Open(scope StringView[]("/somewhere/other.kit"));
		defer again.ReleaseRef();
		Test.Assert((bed.Window.Window.FindElement("import-cancel") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(!bed.Window.IsOpen);
		Test.Assert(again.Closed);
		Test.Assert(bed.Top.GetInstance("Kit") == null);
	}

	[Test]
	public static void TheOptionsBoxesWriteThroughToTheirFields()
	{
		let bed = scope Bed("scratch_import_window_options");
		let session = bed.Open(scope StringView[]("/somewhere/game.cfg"));
		defer session.ReleaseRef();
		let boxes = scope List<Sedulous.GUI.CheckBox>();
		Collect<Sedulous.GUI.CheckBox>(bed.Window.Detail, boxes);
		Test.Assert(boxes.Count == 1, "Ghost points at nothing: not shown");
		Test.Assert(boxes[0].Text == "Flip");
		Test.Assert(boxes[0].Tooltip == "Flips it");
		Test.Assert(boxes[0].Checked);
		Test.Assert(Says(bed.Window.Detail, "It makes one asset, named after the file."));
		Test.Assert(boxes[0].HandleActivate());
		Test.Assert(!(session.Files[0].Options as ToggledOptions).Flip);
	}

	[Test]
	public static void TheEditorsImportIsAtOnceWhenNothingNeedsReviewElseInTheWindowASecondRefusedWhileOneIsOpen()
	{
		let bed = scope Bed("scratch_import_window_run");
		bed.Run(scope StringView[]("/somewhere/player.as"));
		Test.Assert(bed.Top.GetInstance("Player") != null, "imported at once");
		Test.Assert(bed.Asked == 0, "no window asked for");
		Test.Assert(!bed.Window.IsOpen);

		bed.Run(scope StringView[]("/somewhere/crate.box"));
		Test.Assert(bed.Asked == 1);
		Test.Assert(bed.Window.IsOpen);
		let first = bed.Window.Session;
		Test.Assert((first != null) && (first.Files[0].Name == "crate.box"));
		Test.Assert(bed.Top.GetInstance("Box") == null, "waiting for its review");

		bed.Run(scope StringView[]("/somewhere/set.kit"));
		Test.Assert(bed.LastSaid == "An import is open already: finish it first.");
		Test.Assert(bed.Window.Session == first, "the open one kept");
		Test.Assert(bed.Window.Import());
		Test.Assert(bed.Top.GetInstance("Box") != null);
		Test.Assert(bed.Top.GetInstance("Kit") == null, "the refused one imported nothing");

		// Nothing anything takes: no import, no window.
		bed.Run(scope StringView[]("/somewhere/notes.txt"));
		Test.Assert(bed.LastSaid == "Nothing imports notes.txt.");
		Test.Assert(!bed.Window.IsOpen);
	}
}
