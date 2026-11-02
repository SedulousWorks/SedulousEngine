using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// Importing files into the project (Raptor's editor-gui spec, 5.2, layer 7): one import of one file
// or many (a drop, Import...), into one group. Each file gets the importers that take its extension
// (one no importer takes is said and left out), the first chosen; its options; and its review plan,
// what the import would create, each resource kept or not and named (described at once by a light
// importer, after reading the file on a worker by a heavy one, its previous import's choices in that
// group laid over it). The import waits until every file kept is read and described, saying why;
// then each is imported (its bulk writes flushed on a worker), the editor is told, and the group's
// assets are cooked. Nothing changes the databases while a cook reads them: an import waits for it,
// saying so. The group is held by its picker key and found again when it is used, so one deleted
// meanwhile is never reached. A name another asset holds (ImportPaths.FindImportClash) is said on
// the file: one of another type must be renamed; another file's of its type is replaced or kept
// beside as the user chooses. The import window is its view.

/// What an AssetImport works over.
class AssetImportServices
{
	/// The project, its importers, and where what happened is said. Borrowed.
	public EditorContext Context = null;
	/// The cook an import waits for and asks of; null: nothing waits (a test). Borrowed.
	public EditorCookService Cook = null;
	/// Where a heavy file is read and an import's bulk writes are flushed; null: everything on
	/// this thread (a test). Borrowed.
	public EditorJobService Jobs = null;
}

class AssetImport
{
	public enum FileState
	{
		/// A heavy importer reads it on a worker.
		Reading,
		/// Described: its plan is what the import would create.
		Ready,
		/// It could not be read.
		Failed
	}

	/// One file of an import.
	public class File
	{
		public String Path = new .() ~ delete _;
		/// Those that take its extension, in the registry's order. Borrowed: the registry owns them.
		public List<IFileImporter> Importers = new .() ~ delete _;
		/// The one chosen.
		public int ImporterIndex = 0;
		/// Its options, a bare set when its importer has none: they carry the plan's choices. Owned.
		public ImportOptions Options = null ~ delete _;
		/// What a worker read, for the import. Owned.
		public Object Prepared = null ~ delete _;
		/// What it would create, each resource kept and named. Owned.
		public ImportPlan Plan = new .() ~ delete _;
		/// In the import.
		public bool Kept = true;
		public FileState State = .Reading;
		/// Bumped by each describe: a read for an importer since replaced is let go.
		public uint64 Generation = 0;
		/// What it does over another file's asset of its type under its name (ClashOf): Refuse
		/// until the user chooses.
		public ImportConflictChoice OnConflict = .Refuse;
		/// Settings to start from, as an earlier import recorded them (a reimport); empty: none.
		public String Settings = new .() ~ delete _;

		public IFileImporter Importer => (ImporterIndex < Importers.Count) ? Importers[ImporterIndex] : null;
		public StringView Name => ImportPaths.FileNameOf(Path);
	}

	/// One import: its files and the group they go in. The window holds a reference while it
	/// shows, a read on a worker another until it arrives.
	public class Session : RefCounted
	{
		public List<File> Files = new .() ~ DeleteContainerAndItems!(_);
		/// Where they go, by its group picker key ("Content", "Content/Town").
		public String GroupKey = new .() ~ delete _;
		/// A file's state or plan changed (a worker's read arrived): its view shows it again. Owned.
		public delegate void(int file) OnChanged ~ delete _;
		/// The window went: a read that arrives after is let go.
		public bool Closed = false;
		/// Imported: what the files' options and reads held went with the import, so it runs once.
		public bool Committed = false;
		/// The project's import ledger (ImportPaths.ImportLedgerPath).
		public String LedgerPath = new .() ~ delete _;
		/// The group they go in found again (AssetImport.GroupOf), for the clash check. Owned.
		public delegate Group() FindGroup ~ delete _;
	}

	/// One file's import under way: what it needs, taken from its session's file, alive across
	/// a wait for the cook and through the flush of its bulk writes, which borrow from what was
	/// read. Each holder (the call, a wait, a job's delegates) keeps a reference.
	private class Pending : RefCounted
	{
		public String Path = new .() ~ delete _;
		/// Borrowed: the registry owns it.
		public IFileImporter Importer = null;
		public ImportOptions Options = null ~ delete _;
		public Object Prepared = null ~ delete _;
		public String GroupKey = new .() ~ delete _;
		public ImportConflictChoice OnConflict = .Refuse;
		public String LedgerPath = new .() ~ delete _;
		public List<DeferredImportWrite> Writes = new .() ~ DeleteContainerAndItems!(_);
	}

	/// What a worker read, handed from the job to its completion; deleted with the completion
	/// unless the completion took it (a read let go, or never run, goes with it).
	private class ReadSlot
	{
		public Object Value = null ~ delete _;
	}

	private AssetImportServices mServices ~ delete _;

	/// TAKES OWNERSHIP of the services.
	public this(AssetImportServices services)
	{
		mServices = services;
	}

	/// An import of `paths` into `into`: each file with the importers that take it (one none takes
	/// is said and left out), each described or being read, its settings starting from `settings`
	/// when given (as an earlier import recorded them). Null when none is left; else the caller's
	/// reference (ReleaseRef when done with it).
	public Session Begin(Span<StringView> paths, Group into, StringView settings = default)
	{
		let session = new Session();
		GroupPicker.KeyOf(into, session.GroupKey);
		session.FindGroup = new [=this, =session] () => GroupOf(session);
		if (let project = Context.Project)
			ImportPaths.ImportLedgerPath(project.CacheRoot(.. scope .()), session.LedgerPath);
		for (let path in paths)
		{
			let file = new File();
			Context.Importers.FindAllFor(ImportPaths.ExtensionLower(path, .. scope .()), file.Importers);
			if (file.Importers.IsEmpty)
			{
				delete file;
				Context.Notify(.Warning, scope $"Nothing imports {ImportPaths.FileNameOf(path)}.");
				continue;
			}
			file.Path.Set(path);
			file.Settings.Set(settings);
			session.Files.Add(file);
		}
		if (session.Files.IsEmpty)
		{
			session.ReleaseLastRef();
			return null;
		}
		for (int i < session.Files.Count)
			Describe(session, i);
		return session;
	}

	/// What reimporting an asset takes: the file it came from (the OS file the ledger names, while it
	/// is there, else its copy in Sources/), the group the import goes in, and the settings its
	/// import recorded.
	public class Reimport
	{
		public String Path = new .() ~ delete _;
		/// Borrowed: the project's.
		public Group Group = null;
		public String Settings = new .() ~ delete _;
	}

	/// Finds what reimporting asset `id` takes, into `outFound`; false, with why in `outWhy`, when it
	/// cannot be: no such asset, an asset made from no file of its own (a model's mesh: reimport its
	/// model), or a file nothing imports.
	public bool FindReimport(Guid id, Reimport outFound, String outWhy)
	{
		let project = Context.Project;
		let instance = (project != null) ? project.SourceDb.GetInstance(id) : null;
		if (instance == null)
		{
			outWhy.Set("There is no such asset.");
			return false;
		}
		let object = instance.ReadObject();
		defer delete object;
		let asset = (object != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Sedulous.Pipeline.Core.Asset : null;
		if ((asset == null) || asset.FileName.IsEmpty)
		{
			outWhy.Set(scope $"{instance.Name} was not imported from a file of its own.");
			return false;
		}
		let sourcesName = asset.FileName.Value;
		let ledger = ImportPaths.ImportLedgerPath(project.CacheRoot(.. scope .()), .. scope .());
		let origin = ImportPaths.ImportOriginOf(ledger, sourcesName, .. scope .());
		outFound.Path.Clear();
		if (!origin.IsEmpty && FileExists(origin))
			outFound.Path.Set(origin);
		else
			PathJoin(project.SourcesRoot(.. scope .()), sourcesName, outFound.Path);
		if (!FileExists(outFound.Path))
		{
			outWhy.Set(scope $"Its file, {sourcesName}, is missing.");
			return false;
		}
		let importers = scope List<IFileImporter>();
		Context.Importers.FindAllFor(ImportPaths.ExtensionLower(outFound.Path, .. scope .()), importers);
		if (importers.IsEmpty)
		{
			outWhy.Set(scope $"Nothing imports {ImportPaths.FileNameOf(outFound.Path)}.");
			return false;
		}
		outFound.Group = instance.OwningGroup;
		if (importers[0].ImportsIntoItsOwnGroup && (outFound.Group.Parent != null))
			outFound.Group = outFound.Group.Parent;
		outFound.Settings.Clear();
		ImportPaths.RecordedImportSettings(instance, outFound.Settings);
		return true;
	}

	/// Starts a reimport of asset `id`: its file, into its group, its settings as its import
	/// recorded them and its choices as it made them. Null, with why in `outWhy`, when it cannot be;
	/// else the caller's reference.
	public Session BeginReimport(Guid id, String outWhy)
	{
		let found = scope Reimport();
		if (!FindReimport(id, found, outWhy))
			return null;
		let session = Begin(scope StringView[](found.Path), found.Group, found.Settings);
		if (session == null)
			outWhy.Set(scope $"Nothing imports {ImportPaths.FileNameOf(found.Path)}.");
		return session;
	}

	/// Whether `session` needs no review: one file whose one importer has no options and plans
	/// nothing (a script, a UI document), imported at once.
	public static bool NeedsNoReview(Session session)
	{
		if (session.Files.Count != 1)
			return false;
		let file = session.Files[0];
		if ((file.State != .Ready) || !file.Plan.IsEmpty || (file.Options == null) || (file.Importers.Count != 1))
			return false;
		return !file.Options.HasSettings && ImportPaths.ImportClashAllows(ClashOf(session, file, .. scope .()), .Refuse);
	}

	/// The name clash a file's import would meet in the session's group under its plan's names,
	/// into `outClash` (none while it is being read).
	public static void ClashOf(Session session, File file, ImportClash outClash)
	{
		outClash.Clear();
		if ((file.State != .Ready) || (file.Importer == null) || (session.FindGroup == null))
			return;
		let group = session.FindGroup();
		if (group != null)
			file.Importer.FindClash(group, file.Path, file.Plan, session.LedgerPath, outClash);
	}

	/// Chooses another importer for a file: its options anew, described again.
	public void SetImporter(Session session, int fileIndex, int importerIndex)
	{
		if ((fileIndex >= session.Files.Count) || (importerIndex >= session.Files[fileIndex].Importers.Count)
			|| (session.Files[fileIndex].ImporterIndex == importerIndex))
			return;
		session.Files[fileIndex].ImporterIndex = importerIndex;
		Describe(session, fileIndex);
	}

	/// Moves the import to another group: a previous import's choices there laid over each plan.
	public void SetGroup(Session session, Group group)
	{
		session.GroupKey.Clear();
		GroupPicker.KeyOf(group, session.GroupKey);
		for (let file in session.Files)
		{
			if ((file.State == .Ready) && (file.Importer != null))
				LayStoredOver(session, file);
		}
	}

	/// The group the import goes in, found by its key; null when it is gone (or no project is open).
	public Group GroupOf(Session session)
	{
		let sources = Sources;
		return (sources != null) ? GroupPicker.Find(sources, session.GroupKey) : null;
	}

	/// The open project's source content, whose groups an import goes in (the import window's
	/// group picker lists them); null with no project.
	public ContentDatabase Sources
	{
		get
		{
			let project = Context.Project;
			return (project != null) ? project.SourceDb : null;
		}
	}

	/// How the import's group is named to the user, "Content" or its path, appended to `outName`.
	public static void ShownGroup(Session session, String outName)
	{
		// The key is the top's name, or that, a slash and the group's path (GroupPicker.KeyOf).
		let key = StringView(session.GroupKey);
		if (key.Length > GroupPicker.cTop.Length)
			outName.Append(key.Substring(GroupPicker.cTop.Length + 1));
		else
			outName.Append(key);
	}

	/// Whether the import can run now, what it does appended to `outWhy`; when not, why (a file
	/// still being read, one that failed, nothing kept).
	public static bool CanImport(Session session, String outWhy)
	{
		int kept = 0;
		for (let file in session.Files)
		{
			if (!file.Kept)
				continue;
			kept++;
			if (file.State == .Reading)
			{
				outWhy.AppendF("Reading {}...", file.Name);
				return false;
			}
			if (file.State == .Failed)
			{
				outWhy.AppendF("{} could not be read: leave it out.", file.Name);
				return false;
			}
			let clash = ClashOf(session, file, .. scope .());
			if (!ImportPaths.ImportClashAllows(clash, file.OnConflict))
			{
				ImportPaths.DescribeImportClash(clash, outWhy);
				return false;
			}
		}
		if (kept == 0)
		{
			outWhy.Append("No file is kept.");
			return false;
		}
		let into = ShownGroup(session, .. scope .());
		if (session.Files.Count == 1)
			outWhy.AppendF("Into {}.", into);
		else
			outWhy.AppendF("{} of {} files into {}.", kept, session.Files.Count, into);
		return true;
	}

	/// Imports every file kept, each under its plan as chosen; false when it cannot (yet, or
	/// again), the group gone said.
	public bool Commit(Session session)
	{
		if (session.Committed || !CanImport(session, scope .()))
			return false;
		if (GroupOf(session) == null)
		{
			Context.Notify(.Warning, "The group the import goes in is gone: choose another.");
			return false;
		}
		session.Committed = true;
		for (let file in session.Files)
		{
			if (!file.Kept)
				continue;
			let pending = new Pending();
			pending.Path.Set(file.Path);
			pending.Importer = file.Importer;
			pending.GroupKey.Set(session.GroupKey);
			pending.OnConflict = file.OnConflict;
			pending.LedgerPath.Set(session.LedgerPath);
			// The options and what was read go with the import, the plan's choices on the options.
			pending.Options = file.Options;
			file.Options = null;
			CopyPlan(file.Plan, pending.Options.Selection);
			pending.Prepared = file.Prepared;
			file.Prepared = null;
			ImportOne(pending);
			pending.ReleaseRef();
		}
		return true;
	}

	/// What follows any finished import (this one's, or an agent's asset_import): the editor told
	/// (its import listeners, a model's prefab among them), and the assets of the primary's group,
	/// all the way down, cooked: a re-import of the same bytes copies nothing a watcher would
	/// notice, so without it what was made would stay uncooked. `options` null is the importer's
	/// defaults.
	public void AfterImport(Instance primary, ImportOptions options)
	{
		Context.NotifyImported(primary, options);
		if (mServices.Cook == null)
			return;
		let ids = scope List<Guid>();
		AssetOperations.CollectAssets(primary.OwningGroup, ids);
		mServices.Cook.RequestCookFor(ids, false);
	}

	private EditorContext Context => mServices.Context;

	// A file described at once (a light importer), or read on a worker first (a heavy one).
	private void Describe(Session session, int index)
	{
		let file = session.Files[index];
		let importer = file.Importer;
		delete file.Options;
		file.Options = importer.CreateOptions();
		if (file.Options == null)
			file.Options = new ImportOptions(); // a bare one carries the plan's choices
		importer.InitializeOptions(file.Path, file.Options); // as the importer chooses for this file
		if (!file.Settings.IsEmpty)
			file.Options.ReadSettingsText(file.Settings); // then as it was imported before
		DeleteAndNullify!(file.Prepared);
		ClearAndDeleteItems!(file.Plan.Entries);
		let generation = ++file.Generation;
		if (!importer.WantsWorkerPrepare || (mServices.Jobs == null))
		{
			importer.DescribeImport(file.Path, file.Options, null, file.Plan);
			LayStoredOver(session, file);
			file.State = .Ready;
			return;
		}
		file.State = .Reading;
		let path = new String(file.Path);
		let slot = new ReadSlot();
		session.AddRef();
		mServices.Jobs.Submit(scope $"Reading {file.Name}",
			new [=importer, =path, =slot] (job) =>
			{
				job.SetStep("loading and decoding", 1, 2);
				slot.Value = importer.PrepareOnWorker(path);
				return (slot.Value != null) ? .Ok : .Err(.InvalidArgument);
			} ~ delete path,
			new [=this, =session, =index, =generation, =slot] (result) =>
			{
				if (session.Closed || (index >= session.Files.Count) || (session.Files[index].Generation != generation))
					return; // the window went, or another importer was chosen meanwhile: the read goes with the slot
				let read = session.Files[index];
				if (result case .Err)
				{
					read.State = .Failed;
					read.Kept = false;
					Context.Notify(.Error, scope $"{read.Name} could not be read (see the Console).");
				}
				else
				{
					read.Prepared = slot.Value;
					slot.Value = null;
					read.Importer.DescribeImport(read.Path, read.Options, read.Prepared, read.Plan);
					LayStoredOver(session, read);
					read.State = .Ready;
				}
				if (session.OnChanged != null)
					session.OnChanged(index);
			} ~ { delete slot; session.ReleaseRef(); });
	}

	/// Describes file `index` again with its settings as they are now (one changed: a model without
	/// textures makes none), keeping what was read and the choices made on its plan.
	public void RefreshPlan(Session session, int index)
	{
		if ((index < 0) || (index >= session.Files.Count))
			return;
		let file = session.Files[index];
		let importer = file.Importer;
		if ((importer == null) || (file.State != .Ready))
			return;
		let chosen = scope ImportPlan();
		CopyPlan(file.Plan, chosen);
		ClearAndDeleteItems!(file.Plan.Entries);
		importer.DescribeImport(file.Path, file.Options, file.Prepared, file.Plan);
		LayStoredOver(session, file);
		file.Plan.MergeStoredSelection(chosen); // what was chosen here wins
	}

	// A previous import's choices in the session's group, laid over the file's plan.
	private void LayStoredOver(Session session, File file)
	{
		let group = GroupOf(session);
		if (group == null)
			return;
		let stored = scope ImportPlan();
		file.Importer.StoredSelection(group, file.Path, stored);
		file.Plan.MergeStoredSelection(stored);
	}

	// `plan` copied into `outCopy`, what was there let go: the session's file keeps its own.
	private static void CopyPlan(ImportPlan plan, ImportPlan outCopy)
	{
		ClearAndDeleteItems!(outCopy.Entries);
		for (let entry in plan.Entries)
		{
			let copy = new ImportPlanEntry(entry.Kind, entry.SourceName, entry.TargetName);
			copy.Enabled = entry.Enabled;
			outCopy.Add(copy);
		}
	}

	// One file into its group, found again by its key: waiting for a cook; its bulk writes flushed
	// on a worker. Borrows `pending`; whatever outlives the call takes its own reference.
	private void ImportOne(Pending pending)
	{
		let project = Context.Project;
		if (project == null)
			return;
		if ((mServices.Cook != null) && mServices.Cook.MutationLocked)
		{
			pending.AddRef();
			mServices.Cook.RunWhenIdle(new [=this, =pending] () => { ImportOne(pending); } ~ pending.ReleaseRef());
			Context.Notify(.Info, "The import waits for the cook to finish.");
			return;
		}
		let name = ImportPaths.FileNameOf(pending.Path);
		let group = GroupPicker.Find(project.SourceDb, pending.GroupKey);
		if (group == null)
		{
			Context.Notify(.Warning, scope $"{name} was not imported: its group is gone.");
			return;
		}
		let started = Stopwatch.GetTimestamp();
		let context = scope ImportContext(project.SourcesRoot(.. scope .()));
		context.OnConflict = pending.OnConflict;
		context.LedgerPath.Set(pending.LedgerPath);
		let imported = pending.Importer.Import(pending.Path, context, group, pending.Options, pending.Prepared,
			(mServices.Jobs != null) ? pending.Writes : null);
		GlobalLog(.Information, "Import: '{}': {} ms on the main thread, {} deferred write(s)", name,
			(Stopwatch.GetTimestamp() - started) / 1000, pending.Writes.Count);
		Instance primary = null;
		if (imported case .Ok(let instance))
			primary = instance;
		if (primary == null)
		{
			Context.Notify(.Error, scope $"{name} could not be imported (see the Console).");
			return;
		}
		if (pending.Writes.IsEmpty || (mServices.Jobs == null))
		{
			Finish(primary, pending);
			return;
		}
		// The bulk writes on a worker (pure file IO; the job keeps cooks out), what was read kept
		// alive with the pending import for the writes that borrow from it.
		let primaryId = primary.Id;
		pending.AddRef();
		pending.AddRef();
		mServices.Jobs.Submit(scope $"Writing {name}",
			new [=pending] (job) =>
			{
				Result<void, ErrorCode> result = .Ok;
				let writes = pending.Writes;
				for (int i < writes.Count)
				{
					job.SetStep(writes[i].Label, i + 1, writes.Count);
					job.SetFraction((float)i / (float)writes.Count);
					if (writes[i].Execute() case .Err(let error))
					{
						GlobalLog(.Error, "Import: a deferred write failed: '{}'", writes[i].Label);
						result = .Err(error);
					}
				}
				return result;
			} ~ pending.ReleaseRef(),
			new [=this, =pending, =primaryId] (result) =>
			{
				let now = Context.Project;
				let written = (now != null) ? now.SourceDb.GetInstance(primaryId) : null;
				if ((result case .Err) || (written == null))
				{
					Context.Notify(.Error, "The import's data could not be written (see the Console).");
					return;
				}
				Finish(written, pending);
			} ~ pending.ReleaseRef());
	}

	// Said, then what follows any import.
	private void Finish(Instance primary, Pending pending)
	{
		ImportPaths.RecordImportSettings(primary, pending.Options); // a reimport starts from them
		Context.Notify(.Success, scope $"Imported {primary.Name} ({pending.Importer.Label}).");
		AfterImport(primary, pending.Options);
	}
}
