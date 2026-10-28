using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Importing files over a scratch project and importers of the test's own: a file no importer
/// takes left out, said; each file described with what it would create, a previous import's
/// choices laid over it; another importer chosen describing it again; the import waiting for a
/// file kept, saying why; the commit creating what is kept under the names chosen; and a file
/// that needs no review. Then what Sedulous adds so each behaviour has a test: a heavy file read
/// on a worker, a read for a replaced importer or a closed window let go, a failed read; the
/// bulk writes flushed on a worker before the editor is told; the cook of the group asked for;
/// and an import waiting for a cook, its group found again when it runs.
static class AssetImportTests
{
	/// Takes ".crate": would make a mesh and a material, each kept or not and named as chosen.
	class CrateImporter : IFileImporter
	{
		private String mLabel = new .() ~ delete _;

		public this(StringView label)
		{
			mLabel.Set(label);
		}

		public StringView Label => mLabel;
		public bool Accepts(StringView ext) => ext == "crate";

		public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared, ImportPlan outPlan)
		{
			outPlan.Add(new ImportPlanEntry(.Mesh, "Body", "Body"));
			outPlan.Add(new ImportPlanEntry(.Material, mLabel, mLabel));
		}

		public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		{
			if (group.GetInstance("Kept") != null) // a previous import here renamed the body
				outPlan.Add(new ImportPlanEntry(.Mesh, "Body", "Hull"));
		}

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
		{
			Instance primary = null;
			Make(group, options, .Mesh, "Body", ref primary);
			Make(group, options, .Material, mLabel, ref primary);
			return primary;
		}

		private static void Make(Group group, ImportOptions options, ImportResourceKind kind, StringView source, ref Instance primary)
		{
			if ((options != null) && !options.SelectionEnabled(kind, source))
				return;
			let made = group.CreateInstance((options != null) ? options.SelectionName(kind, source) : source, "Tests.Imported");
			if (primary == null)
				primary = made;
		}
	}

	/// No options and nothing to review: one instance of its name.
	class ScriptImporter : IFileImporter
	{
		private String mLabel = new .() ~ delete _;
		private String mExt = new .() ~ delete _;
		private String mMakes = new .() ~ delete _;

		public this(StringView label, StringView ext, StringView makes)
		{
			mLabel.Set(label);
			mExt.Set(ext);
			mMakes.Set(makes);
		}

		public StringView Label => mLabel;
		public bool Accepts(StringView ext) => ext == mExt;

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
		{
			return group.CreateInstance(mMakes, "Tests.Imported");
		}
	}

	/// One checkbox, so a file with them is reviewed though it plans nothing.
	class ToggledOptions : ImportOptions
	{
		public bool Flip = true;

		public override void GetToggles(List<ImportToggle> outToggles)
		{
			outToggles.Add(.("Flip", "", &Flip));
		}
	}

	/// Takes ".cfg": options with a toggle, no plan.
	class ToggledImporter : IFileImporter
	{
		public StringView Label => "Config";
		public bool Accepts(StringView ext) => ext == "cfg";
		public ImportOptions CreateOptions() => new ToggledOptions();

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
		{
			return group.CreateInstance("Config", "Tests.Imported");
		}
	}

	/// What a heavy importer's worker read: whose read it was.
	class Payload
	{
		public String From = new .() ~ delete _;
	}

	/// A heavy importer: its file read on a worker (or failing to be), described from what was
	/// read, a body and a material named after it; its import parks one bulk write when it may,
	/// recording the thread that ran it.
	class HeavyImporter : IFileImporter
	{
		private String mLabel = new .() ~ delete _;
		private String mExt = new .() ~ delete _;
		private bool mFails;
		/// Worker written, main read after the job's completion.
		public int Prepares = 0;
		public int DescribedFromItsRead = 0;
		public int DescribedFromAnotherRead = 0;
		public bool ImportSawItsRead = false;
		public bool ImportGotWrites = false;
		public int FlushThread = 0;

		public this(StringView label, StringView ext, bool fails = false)
		{
			mLabel.Set(label);
			mExt.Set(ext);
			mFails = fails;
		}

		public StringView Label => mLabel;
		public bool Accepts(StringView ext) => ext == mExt;
		public bool WantsWorkerPrepare => true;

		public Object PrepareOnWorker(StringView sourcePath)
		{
			Prepares++;
			if (mFails)
				return null;
			let payload = new Payload();
			payload.From.Set(mLabel);
			return payload;
		}

		public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared, ImportPlan outPlan)
		{
			if (let payload = prepared as Payload)
			{
				if (payload.From == mLabel)
					DescribedFromItsRead++;
				else
					DescribedFromAnotherRead++;
			}
			outPlan.Add(new ImportPlanEntry(.Mesh, "Body", "Body"));
			outPlan.Add(new ImportPlanEntry(.Material, mLabel, mLabel));
		}

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
		{
			let payload = prepared as Payload;
			ImportSawItsRead = (payload != null) && (payload.From == mLabel);
			ImportGotWrites = (deferredWrites != null);
			let instance = group.CreateInstance((options != null) ? options.SelectionName(.Mesh, "Body") : "Body", "Tests.Imported");
			if (deferredWrites != null)
			{
				let write = new DeferredImportWrite();
				write.Instance = instance;
				write.StreamName.Set("bulk");
				write.Produce = new [=this] (bytes) =>
					{
						FlushThread = Thread.CurrentThreadId;
						bytes.Add(7);
						return .Ok;
					};
				deferredWrites.Add(write);
			}
			return instance;
		}
	}

	/// A scratch project open in an editor context, its importers registered: Paint (".crate"),
	/// Script (".as"), Document and Layout (both ".ui"), Config (".cfg"), Raw (".mesh", heavy) and
	/// Broken (".bad", heavy, its read failing); with `second`, Varnish (".crate") and Baked
	/// (".mesh", heavy) after them. The notices in Said, the imported primaries the editor was told
	/// of in Told. With jobs (`withJobs`) a heavy file is read and the bulk written on a worker; with
	/// a cook over no builders (`withCook`), its mutation lock the bed's Locked.
	class Bed
	{
		public String Dir = new .() ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .();
		public BuilderRegistry Builders = null;
		public EditorCookService Cook = null;
		public EditorJobService Jobs = null;
		public bool Locked = false;
		public AssetImport Import;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		public List<Guid> Told = new .() ~ delete _;
		public Group Top;
		// Borrowed: the context's registry owns them.
		public HeavyImporter Raw;
		public HeavyImporter Baked;

		public this(StringView dir, bool second = false, bool withJobs = false, bool withCook = false)
		{
			Dir.Set(dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Import") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Top = Project.SourceDb.RootGroup;
			Context.SetProject(Project);
			let bed = this;
			Context.OnNotice = new [=bed] (kind, message) => { bed.Said.Add(new String(message)); };
			Context.AddImportListener(new [=bed] (instance, options) => { bed.Told.Add(instance.Id); });
			let importers = Context.Importers;
			importers.Register(new CrateImporter("Paint"));
			importers.Register(new ScriptImporter("Script", "as", "Player"));
			importers.Register(new ScriptImporter("Document", "ui", "Hud"));
			importers.Register(new ScriptImporter("Layout", "ui", "Hud"));
			importers.Register(new ToggledImporter());
			Raw = new HeavyImporter("Raw", "mesh");
			importers.Register(Raw);
			importers.Register(new HeavyImporter("Broken", "bad", true));
			if (second)
			{
				importers.Register(new CrateImporter("Varnish"));
				Baked = new HeavyImporter("Baked", "mesh");
				importers.Register(Baked);
			}
			if (withJobs)
				Jobs = new .();
			if (withCook)
			{
				Builders = new .();
				Cook = new .();
				Cook.ExternalMutationLock = new [=bed] () => bed.Locked;
				Cook.Initialize(Project, Builders);
			}
			let services = new AssetImportServices();
			services.Context = Context;
			services.Cook = Cook;
			services.Jobs = Jobs;
			Import = new AssetImport(services);
		}

		public ~this()
		{
			// The cook and the jobs first (each drops what waits on it), then the import, the
			// context (its importers) before the project it borrows.
			if (Cook != null)
			{
				Cook.Shutdown();
				delete Cook;
			}
			delete Builders;
			if (Jobs != null)
			{
				Jobs.Shutdown();
				delete Jobs;
			}
			delete Import;
			Context.SetProject(null);
			delete Context;
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The editor's frames, the services' pumps, until `done` holds; false when it never did.
		public bool PumpUntil(delegate bool() done)
		{
			for (int i < 5000)
			{
				if (done())
					return true;
				if (Jobs != null)
					Jobs.Update();
				if (Cook != null)
					Cook.Update();
				Thread.Sleep(1);
			}
			return done();
		}

		public StringView LastSaid => Said.IsEmpty ? "" : Said.Back;
	}

	/// A file nothing takes is left out and said, an import of nothing but such files is none;
	/// each file is described; the commit makes what is kept, named as chosen, once; and again
	/// into the same group the previous choice is laid over the plan, in another group not, until
	/// the import moves back.
	[Test]
	public static void AFileNothingTakesIsLeftOutEachIsDescribedTheCommitMakesWhatIsKeptNamedAsChosen()
	{
		let bed = scope Bed("scratch_asset_import_commit");
		let session = bed.Import.Begin(scope StringView[]("/somewhere/box.crate", "/somewhere/notes.txt"), bed.Top);
		Test.Assert(session != null);
		defer session.ReleaseRef();
		Test.Assert(session.Files.Count == 1, "notes.txt: nothing imports it");
		Test.Assert(bed.LastSaid == "Nothing imports notes.txt.");
		let crate = session.Files[0];
		Test.Assert(crate.Name == "box.crate");
		Test.Assert(crate.State == .Ready);
		Test.Assert(crate.Plan.Entries.Count == 2);
		let why = scope String();
		Test.Assert(AssetImport.CanImport(session, why));
		Test.Assert(why == "Into Content.");
		Test.Assert(!AssetImport.NeedsNoReview(session));

		// The body renamed, the material left out.
		crate.Plan.Entries[0].TargetName.Set("Kept");
		crate.Plan.Entries[1].Enabled = false;
		Test.Assert(bed.Import.Commit(session));
		let kept = bed.Top.GetInstance("Kept");
		Test.Assert(kept != null);
		Test.Assert(bed.Top.GetInstance("Body") == null);
		Test.Assert(bed.Top.GetInstance("Paint") == null);
		Test.Assert(bed.LastSaid == "Imported Kept (Paint).");
		Test.Assert((bed.Told.Count == 1) && (bed.Told[0] == kept.Id), "the editor told of the primary");
		Test.Assert(!bed.Import.Commit(session), "an import runs once");
		Test.Assert(bed.Told.Count == 1);

		// Nothing left: no import.
		Test.Assert(bed.Import.Begin(scope StringView[]("/somewhere/notes.txt"), bed.Top) == null);

		// Again into the same group: the previous choice laid over the plan.
		let again = bed.Import.Begin(scope StringView[]("/somewhere/box.crate"), bed.Top);
		Test.Assert(again != null);
		defer again.ReleaseRef();
		Test.Assert(again.Files[0].Plan.Entries[0].TargetName == "Hull");

		// Into another group: nothing there to lay over, until the import moves back.
		let town = bed.Top.CreateGroup("Town");
		let elsewhere = bed.Import.Begin(scope StringView[]("/somewhere/box.crate"), town);
		Test.Assert(elsewhere != null);
		defer elsewhere.ReleaseRef();
		Test.Assert(elsewhere.Files[0].Plan.Entries[0].TargetName == "Body");
		why.Clear();
		Test.Assert(AssetImport.CanImport(elsewhere, why));
		Test.Assert(why == "Into Town.");
		bed.Import.SetGroup(elsewhere, bed.Top);
		Test.Assert(elsewhere.Files[0].Plan.Entries[0].TargetName == "Hull");
		Test.Assert(bed.Import.GroupOf(elsewhere) === bed.Top);
	}

	/// Another importer describes the file again; the import waits while nothing is kept; one
	/// file with one importer, no options and no plan needs no review and imports at once, but
	/// not two files, two importers, or options with a toggle.
	[Test]
	public static void AnotherImporterDescribesTheFileAgainTheImportWaitsForAFileKeptAScriptNeedsNoReview()
	{
		let bed = scope Bed("scratch_asset_import_choice", true);
		let session = bed.Import.Begin(scope StringView[]("/somewhere/box.crate"), bed.Top);
		Test.Assert(session != null);
		defer session.ReleaseRef();
		let file = session.Files[0];
		Test.Assert(file.Importers.Count == 2);
		Test.Assert(file.Plan.Entries[1].SourceName == "Paint");
		bed.Import.SetImporter(session, 0, 1);
		Test.Assert(file.Importer.Label == "Varnish");
		Test.Assert(file.Plan.Entries.Count == 2, "described anew, not added to");
		Test.Assert(file.Plan.Entries[1].SourceName == "Varnish");

		file.Kept = false;
		let why = scope String();
		Test.Assert(!AssetImport.CanImport(session, why));
		Test.Assert(why == "No file is kept.");
		Test.Assert(!bed.Import.Commit(session));
		Test.Assert(bed.Top.GetInstance("Body") == null);

		let quick = bed.Import.Begin(scope StringView[]("/somewhere/player.as"), bed.Top);
		Test.Assert(quick != null);
		defer quick.ReleaseRef();
		Test.Assert(AssetImport.NeedsNoReview(quick));
		Test.Assert(bed.Import.Commit(quick));
		Test.Assert(bed.Top.GetInstance("Player") != null);

		let two = bed.Import.Begin(scope StringView[]("/somewhere/a.as", "/somewhere/b.as"), bed.Top);
		Test.Assert(two != null);
		defer two.ReleaseRef();
		Test.Assert(!AssetImport.NeedsNoReview(two), "two files are reviewed");
		why.Clear();
		Test.Assert(AssetImport.CanImport(two, why));
		Test.Assert(why == "2 of 2 files into Content.");
		two.Files[1].Kept = false;
		why.Clear();
		Test.Assert(AssetImport.CanImport(two, why));
		Test.Assert(why == "1 of 2 files into Content.");

		let chosen = bed.Import.Begin(scope StringView[]("/somewhere/hud.ui"), bed.Top);
		Test.Assert(chosen != null);
		defer chosen.ReleaseRef();
		Test.Assert(!AssetImport.NeedsNoReview(chosen), "two importers take it: one is chosen");

		let toggled = bed.Import.Begin(scope StringView[]("/somewhere/game.cfg"), bed.Top);
		Test.Assert(toggled != null);
		defer toggled.ReleaseRef();
		Test.Assert(toggled.Files[0].Options is ToggledOptions, "the importer's own options");
		Test.Assert(!AssetImport.NeedsNoReview(toggled), "its options are reviewed");
	}

	/// A heavy file is read on a worker, the import waiting, saying so; another importer chosen
	/// meanwhile lets the first read go and describes from its own; a read for a closed window is
	/// let go; a file that could not be read is said, left out, and waits the import when kept.
	[Test]
	public static void AHeavyFileIsReadOnAWorkerAReadForAReplacedImporterOrAClosedWindowIsLetGo()
	{
		let bed = scope Bed("scratch_asset_import_read", true, true);
		let session = bed.Import.Begin(scope StringView[]("/somewhere/rock.mesh"), bed.Top);
		Test.Assert(session != null);
		defer session.ReleaseRef();
		let file = session.Files[0];
		Test.Assert(file.State == .Reading);
		let why = scope String();
		Test.Assert(!AssetImport.CanImport(session, why));
		Test.Assert(why == "Reading rock.mesh...");
		Test.Assert(!bed.Import.Commit(session));
		int changed = 0;
		session.OnChanged = new [&changed] (index) => { changed++; };

		bed.Import.SetImporter(session, 0, 1); // Baked: Raw's read, already asked, is stale
		Test.Assert(file.State == .Reading);
		Test.Assert(bed.PumpUntil(scope [&] () => file.State != .Reading));
		Test.Assert(file.State == .Ready);
		Test.Assert((bed.Raw.Prepares == 1) && (bed.Baked.Prepares == 1), "both were read");
		Test.Assert((bed.Raw.DescribedFromItsRead == 0) && (bed.Raw.DescribedFromAnotherRead == 0), "Raw's read let go");
		Test.Assert((bed.Baked.DescribedFromItsRead == 1) && (bed.Baked.DescribedFromAnotherRead == 0));
		Test.Assert(file.Prepared != null);
		Test.Assert(file.Plan.Entries[1].SourceName == "Baked");
		Test.Assert(changed == 1, "only the read kept told the view");
		why.Clear();
		Test.Assert(AssetImport.CanImport(session, why));
		Test.Assert(why == "Into Content.");

		// The window went before the read arrived: the read is let go, nothing told.
		let closed = bed.Import.Begin(scope StringView[]("/somewhere/stone.mesh"), bed.Top);
		Test.Assert(closed != null);
		int heard = 0;
		closed.OnChanged = new [&heard] (index) => { heard++; };
		closed.Closed = true;
		let closedFile = closed.Files[0];
		Test.Assert(bed.PumpUntil(scope [&] () => !bed.Jobs.IsBusy));
		Test.Assert(closedFile.State == .Reading, "let go");
		Test.Assert(closedFile.Prepared == null);
		Test.Assert(heard == 0);
		closed.ReleaseRef();

		// A file that could not be read: said, left out; kept again, the import waits.
		let broken = bed.Import.Begin(scope StringView[]("/somewhere/broken.bad"), bed.Top);
		Test.Assert(broken != null);
		defer broken.ReleaseRef();
		let bad = broken.Files[0];
		Test.Assert(bed.PumpUntil(scope [&] () => bad.State != .Reading));
		Test.Assert(bad.State == .Failed);
		Test.Assert(!bad.Kept);
		Test.Assert(bed.LastSaid == "broken.bad could not be read (see the Console).");
		why.Clear();
		Test.Assert(!AssetImport.CanImport(broken, why));
		Test.Assert(why == "No file is kept.");
		bad.Kept = true;
		why.Clear();
		Test.Assert(!AssetImport.CanImport(broken, why));
		Test.Assert(why == "broken.bad could not be read: leave it out.");
	}

	/// The import runs under the plan with what the worker read, its bulk write flushed on a
	/// worker, and only then is the editor told; without jobs everything runs here, the importer
	/// writing inline.
	[Test]
	public static void TheImportRunsUnderItsPlanItsBulkWritesFlushedOnAWorkerBeforeTheEditorIsTold()
	{
		{
			let bed = scope Bed("scratch_asset_import_flush", false, true);
			let session = bed.Import.Begin(scope StringView[]("/somewhere/rock.mesh"), bed.Top);
			Test.Assert(session != null);
			defer session.ReleaseRef();
			let file = session.Files[0];
			Test.Assert(bed.PumpUntil(scope [&] () => file.State != .Reading));
			file.Plan.Entries[0].TargetName.Set("Boulder");
			Test.Assert(bed.Import.Commit(session));
			let boulder = bed.Top.GetInstance("Boulder");
			Test.Assert(boulder != null, "placed under its plan's name");
			Test.Assert(bed.Raw.ImportSawItsRead, "imported from what the worker read");
			Test.Assert(bed.Raw.ImportGotWrites);
			Test.Assert(bed.Told.IsEmpty, "told once the writes land");
			Test.Assert(bed.PumpUntil(scope [&] () => !bed.Told.IsEmpty));
			Test.Assert(bed.Told[0] == boulder.Id);
			Test.Assert(bed.LastSaid == "Imported Boulder (Raw).");
			Test.Assert((bed.Raw.FlushThread != 0) && (bed.Raw.FlushThread != Thread.CurrentThreadId), "flushed on a worker");
			let bulk = boulder.ReadData("bulk");
			Test.Assert(bulk != null);
			defer delete bulk;
			Test.Assert(bulk.Size() == 1);
		}
		{
			let bed = scope Bed("scratch_asset_import_inline");
			let session = bed.Import.Begin(scope StringView[]("/somewhere/rock.mesh"), bed.Top);
			Test.Assert(session != null);
			defer session.ReleaseRef();
			Test.Assert(session.Files[0].State == .Ready, "no jobs: described at once");
			Test.Assert(bed.Raw.Prepares == 0);
			Test.Assert(bed.Import.Commit(session));
			Test.Assert(!bed.Raw.ImportGotWrites, "no jobs: the importer writes inline");
			Test.Assert(bed.Told.Count == 1, "told at once");
		}
	}

	/// While a cook reads the databases the import waits, said, nothing made; once the cook is idle
	/// it runs into its group, found again by its key, and the group's assets are cooked. A group
	/// deleted meanwhile is never reached: said, nothing made; and an import into a group already
	/// gone is refused, saying so.
	[Test]
	public static void AnImportWaitsForACookThenRunsIntoItsGroupAndTheGroupIsCooked()
	{
		{
			let bed = scope Bed("scratch_asset_import_cook", false, false, true);
			let town = bed.Top.CreateGroup("Town");
			let session = bed.Import.Begin(scope StringView[]("/somewhere/box.crate"), town);
			Test.Assert(session != null);
			defer session.ReleaseRef();
			bed.Locked = true;
			Test.Assert(bed.Import.Commit(session));
			Test.Assert(bed.LastSaid == "The import waits for the cook to finish.");
			Test.Assert(town.GetInstance("Body") == null, "nothing changed while the cook reads");
			Test.Assert(bed.Told.IsEmpty);
			Test.Assert(!bed.Cook.IsCooking);

			bed.Locked = false;
			bed.Cook.Update();
			Test.Assert(town.GetInstance("Body") != null);
			Test.Assert(town.GetInstance("Paint") != null);
			Test.Assert(bed.Told.Count == 1);
			Test.Assert(bed.Cook.IsCooking, "the group's assets asked for");
		}
		{
			let bed = scope Bed("scratch_asset_import_gone", false, false, true);
			let town = bed.Top.CreateGroup("Town");
			let session = bed.Import.Begin(scope StringView[]("/somewhere/box.crate"), town);
			Test.Assert(session != null);
			defer session.ReleaseRef();
			bed.Locked = true;
			Test.Assert(bed.Import.Commit(session));
			Test.Assert(bed.Project.SourceDb.DeleteGroup(town) case .Ok);
			bed.Locked = false;
			bed.Cook.Update();
			Test.Assert(bed.LastSaid == "box.crate was not imported: its group is gone.");
			Test.Assert(bed.Told.IsEmpty);
			Test.Assert(bed.Top.GetInstance("Body") == null);

			let market = bed.Top.CreateGroup("Market");
			let late = bed.Import.Begin(scope StringView[]("/somewhere/box.crate"), market);
			Test.Assert(late != null);
			defer late.ReleaseRef();
			Test.Assert(bed.Project.SourceDb.DeleteGroup(market) case .Ok);
			Test.Assert(bed.Import.GroupOf(late) == null);
			Test.Assert(!bed.Import.Commit(late));
			Test.Assert(bed.LastSaid == "The group the import goes in is gone: choose another.");
			Test.Assert(!late.Committed, "it can go elsewhere");
		}
	}
}
