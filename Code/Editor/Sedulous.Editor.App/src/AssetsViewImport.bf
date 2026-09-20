using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The import flow: one review session per drop. A single unambiguous file keeps the
/// focused single-file review; several files, or any importer ambiguity, open the batch
/// dialog. Slow importers split: the parse runs on the job worker so the UI stays live, and
/// only the fast database fan-out lands back on the main thread in CommitImport.
extension AssetsView
{
	/// The worker's prepared payload, handed from the job to its completion.
	private class PreparedSlot
	{
		public Object Value = null;
	}

	/// Whether a review dialog confirmed, shared by its Import and Closed handlers.
	private class ReviewState
	{
		public bool Imported = false;
	}

	/// Imports one OS file.
	public void ImportFile(StringView path)
	{
		ImportFiles(scope StringView[](path));
	}

	/// Imports a drop of OS files into the selected group.
	public void ImportFiles(Span<StringView> paths)
	{
		if ((mContext.Project == null) || (Context == null))
			return;
		// Each file's importer candidates; unclaimed files drop with a notice.
		let files = new List<BatchImportFile>();
		for (let path in paths)
		{
			let ext = ImportPaths.ExtensionLower(path, .. scope .());
			let matches = scope List<IFileImporter>();
			mContext.Importers.FindAllFor(ext, matches);
			if (matches.IsEmpty)
			{
				mContext.Notify(.Warning, scope $"No importer for '{ImportPaths.FileNameOf(path)}'.");
				continue;
			}
			let entry = new BatchImportFile();
			entry.Path.Set(path);
			entry.Candidates.AddRange(matches);
			files.Add(entry);
		}
		if (files.IsEmpty)
		{
			delete files;
			return;
		}
		if ((files.Count == 1) && (files[0].Candidates.Count == 1))
		{
			let path = scope String(files[0].Path);
			let importer = files[0].Candidates[0];
			DeleteContainerAndItems!(files);
			ImportWith(path, importer);
			return;
		}
		ShowBatchImport(files);
	}

	/// Takes ownership of the file list.
	private void ShowBatchImport(List<BatchImportFile> files)
	{
		let group = (mSelectedGroup != null) ? mSelectedGroup : mContext.Project.SourceDb.RootGroup;
		mImportTargetGroup = group;

		for (let entry in files)
		{
			entry.Options = entry.Importer.CreateOptions();
			if (entry.Options == null)
				entry.Options = new ImportOptions(); // a bare selection carrier, so option-less importers still honour renames
		}
		let dialog = new BatchImportDialog(group.GetPath(.. scope .()), files);

		// Inline describe for light importers; worker-prepare importers land through the jobs
		// below instead, since describing them inline would stall the UI on a full parse.
		let describeGroup = group; // re-import memory reads the initial target
		dialog.DescribeFile = new [=describeGroup](entry) =>
			{
				let importer = entry.Importer;
				if (!importer.WantsWorkerPrepare)
				{
					importer.DescribeImport(entry.Path, entry.Options, null, entry.Plan);
					let stored = scope ImportPlan();
					importer.StoredSelection(describeGroup, entry.Path, stored);
					entry.Plan.MergeStoredSelection(stored);
					entry.Described = true;
				}
			};
		for (let entry in dialog.Files)
			dialog.DescribeFile(entry);

		// Worker prepares queue on the job service and stream into the open dialog, which
		// holds a reference for each in-flight job.
		for (int i < dialog.Files.Count)
		{
			let entry = dialog.Files[i];
			let importer = entry.Importer;
			if (!importer.WantsWorkerPrepare || (mJobs == null))
				continue;
			let file = new String(entry.Path);
			let slot = new PreparedSlot();
			dialog.AddRef();
			mJobs.Submit(scope $"Reading {ImportPaths.FileNameOf(entry.Path)}",
				new [=importer, =file, =slot](job) =>
				{
					job.SetStep("loading + decoding", 1, 2);
					slot.Value = importer.PrepareOnWorker(file);
					return (slot.Value != null) ? .Ok : .Err(.InvalidArgument);
				},
				new [=dialog, =i, =importer, =file, =slot, =this](result) =>
				{
					defer { delete file; delete slot; dialog.ReleaseRef(); }
					let prepared = slot.Value;
					slot.Value = null;
					if (i >= dialog.Files.Count)
					{
						delete prepared;
						return;
					}
					let e = dialog.Files[i];
					// The user may have switched this row's importer while the job ran: a
					// stale payload must not describe the wrong importer.
					if (e.Importer !== importer)
					{
						delete prepared;
						return;
					}
					if (result case .Err)
					{
						delete prepared;
						e.Enabled = false; // unreadable: dropped from the commit
						mContext.Notify(.Error, scope $"Import failed: '{ImportPaths.FileNameOf(e.Path)}' (see Console).");
					}
					else
					{
						delete e.Prepared;
						e.Prepared = prepared;
						delete e.Plan;
						e.Plan = new ImportPlan();
						importer.DescribeImport(e.Path, e.Options, prepared, e.Plan);
						if (mImportTargetGroup != null)
						{
							let stored = scope ImportPlan();
							importer.StoredSelection(mImportTargetGroup, e.Path, stored);
							e.Plan.MergeStoredSelection(stored);
						}
						e.Described = true;
					}
					dialog.OnFilePrepared(i);
				});
		}

		dialog.OnChangeDestination = new [=dialog, =this]() => { ShowImportDestinationPicker(new (g) => { dialog.SetDestination(g); }); };
		dialog.OnImport = new [=dialog, =this]() =>
			{
				for (let entry in dialog.Files)
				{
					if (!entry.Enabled || !entry.Described)
						continue;
					let options = entry.Options;
					entry.Options = null;
					if (options != null)
					{
						delete options.Selection;
						options.Selection = entry.Plan;
						entry.Plan = new ImportPlan();
					}
					let prepared = entry.Prepared;
					entry.Prepared = null;
					CommitImport(entry.Path, entry.Importer, options, prepared);
				}
			};
		dialog.Show(Context);
	}

	/// Runs the import for one resolved importer: its options dialog when it has options or a
	/// plan, else immediately.
	private void ImportWith(StringView path, IFileImporter importer)
	{
		if ((mContext.Project == null) || (Context == null) || (importer == null))
			return;
		// This import defaults to the active group, fresh each time so a cancelled prior
		// import cannot leave a stale target; the dialog's Change... may retarget it.
		let group = (mSelectedGroup != null) ? mSelectedGroup : mContext.Project.SourceDb.RootGroup;
		mImportTargetGroup = group;

		var options = importer.CreateOptions();

		// Review-capable importers invert the order: the slow parse runs first on the worker,
		// the dialog then lists every resource the import would create, and commit reuses
		// the prepared payload, so nothing loads twice.
		if (importer.WantsWorkerPrepare && (mJobs != null))
		{
			if (options == null)
				options = new ImportOptions(); // a bare selection carrier; the renames travel on the base
			let file = new String(path);
			let slot = new PreparedSlot();
			mJobs.Submit(scope $"Reading {ImportPaths.FileNameOf(path)}",
				new [=importer, =file, =slot](job) =>
				{
					job.SetStep("loading + decoding", 1, 2);
					slot.Value = importer.PrepareOnWorker(file);
					return (slot.Value != null) ? .Ok : .Err(.InvalidArgument);
				},
				new [=file, =importer, =options, =slot, =this](result) =>
				{
					defer { delete file; delete slot; }
					let prepared = slot.Value;
					slot.Value = null;
					if (result case .Err)
					{
						delete prepared;
						delete options;
						mContext.Notify(.Error, scope $"Import failed: '{ImportPaths.FileNameOf(file)}' (see Console).");
						return;
					}
					ShowImportReview(file, importer, options, prepared);
				});
			return;
		}

		// Inline importers describe here, a cheap parse. Importers with no options and no
		// plan still import immediately; everything else opens the review dialog, so even a
		// single texture gets its rename row.
		let plan = new ImportPlan();
		importer.DescribeImport(path, options, null, plan);
		if ((options == null) && plan.IsEmpty)
		{
			delete plan;
			ExecuteImport(path, importer, null);
			return;
		}
		let stored = scope ImportPlan();
		importer.StoredSelection(group, path, stored);
		plan.MergeStoredSelection(stored);
		if (options == null)
			options = new ImportOptions();
		ShowReviewDialog(path, group, importer, options, plan, null);
	}

	/// Review-capable importers, after the worker prepare: every resource the import would
	/// create, the commit reusing the prepared payload. Takes ownership of options and prepared.
	private void ShowImportReview(StringView path, IFileImporter importer, ImportOptions options, Object prepared)
	{
		if ((mContext.Project == null) || (Context == null))
		{
			delete options;
			delete prepared;
			return;
		}
		let group = (mImportTargetGroup != null) ? mImportTargetGroup : mContext.Project.SourceDb.RootGroup;
		let plan = new ImportPlan();
		importer.DescribeImport(path, options, prepared, plan);
		// Re-import memory: a previous import of this source into this group seeds the plan.
		let stored = scope ImportPlan();
		importer.StoredSelection(group, path, stored);
		plan.MergeStoredSelection(stored);
		ShowReviewDialog(path, group, importer, options, plan, prepared);
	}

	/// The single-file review dialog. Takes ownership of options, plan and prepared; they
	/// travel to CommitImport on Import and are freed on Cancel.
	private void ShowReviewDialog(StringView path, Group group, IFileImporter importer, ImportOptions options, ImportPlan plan, Object prepared)
	{
		let dialog = new ImportOptionsDialog(path, group.GetPath(.. scope .()), options, plan);
		let file = new String(path);
		let state = new ReviewState();
		dialog.OnChangeDestination = new [=dialog, =this]() => { ShowImportDestinationPicker(new (g) => { dialog.SetDestination(g); }); };
		dialog.OnImport = new [=dialog, =file, =importer, =options, =prepared, =state, =this]() =>
			{
				state.Imported = true;
				delete options.Selection;
				options.Selection = dialog.TakePlan();
				if (prepared != null)
					CommitImport(file, importer, options, prepared);
				else
					ExecuteImport(file, importer, options);
			};
		dialog.OnClosed.Add(new [=file, =options, =prepared, =state](d, result) =>
			{
				if (!state.Imported)
				{
					delete options;
					delete prepared;
				}
				delete file;
				delete state;
			});
		dialog.Show(Context);
	}

	/// The Change... destination chooser: the group-tree picker with the current destination
	/// preselected; picking one retargets the import and updates the dialog's shown path.
	/// Takes ownership of the delegate.
	private void ShowImportDestinationPicker(delegate void(StringView path) onChanged)
	{
		if ((mContext.Project == null) || (Context == null))
		{
			delete onChanged;
			return;
		}
		let root = mContext.Project.SourceDb.RootGroup;
		if (root == null)
		{
			delete onChanged;
			return;
		}
		let picker = new GroupPickerDialog("Select destination group", root, mImportTargetGroup);
		picker.OnPicked = new [=onChanged, =this](g) =>
			{
				if (g != null)
				{
					mImportTargetGroup = g;
					onChanged(g.GetPath(.. scope .()));
				}
			} ~ delete onChanged;
		picker.Show(Context);
	}

	/// Runs the import after the dialog. Slow importers prepare on the worker so the UI
	/// stays live, with the status-bar progress; the database fan-out lands on the main
	/// thread in CommitImport. Takes ownership of options.
	private void ExecuteImport(StringView path, IFileImporter importer, ImportOptions options)
	{
		if (mContext.Project == null)
		{
			delete options;
			return;
		}
		if (importer.WantsWorkerPrepare && (mJobs != null))
		{
			let file = new String(path);
			let slot = new PreparedSlot();
			mJobs.Submit(scope $"Importing {ImportPaths.FileNameOf(path)}",
				new [=importer, =file, =slot](job) =>
				{
					job.SetStep("loading + decoding", 1, 2);
					slot.Value = importer.PrepareOnWorker(file);
					return (slot.Value != null) ? .Ok : .Err(.InvalidArgument);
				},
				new [=file, =importer, =options, =slot, =this](result) =>
				{
					defer { delete file; delete slot; }
					let prepared = slot.Value;
					slot.Value = null;
					if (result case .Err)
					{
						delete prepared;
						delete options;
						mContext.Notify(.Error, scope $"Import failed: '{ImportPaths.FileNameOf(file)}' (see Console).");
						return;
					}
					CommitImport(file, importer, options, prepared);
				});
			return;
		}
		CommitImport(path, importer, options, null);
	}

	/// The main-thread tail: the database fan-out, plus the build-lock re-check so a cook
	/// that started while the dialog or worker was busy still queues instead of racing.
	/// Takes ownership of options and prepared.
	private void CommitImport(StringView path, IFileImporter importer, ImportOptions options, Object prepared)
	{
		if (mContext.Project == null)
		{
			delete options;
			delete prepared;
			return;
		}
		// A cook in flight reads instance pointers snapshotted at plan time, so creating
		// instances now is a race: queued, the cook service replays it when idle.
		if (mCook.MutationLocked)
		{
			let file = new String(path);
			mCook.RunWhenIdle(new [=file, =importer, =options, =prepared, =this]() => { CommitImport(file, importer, options, prepared); } ~ delete file);
			mContext.Notify(.Info, "Import queued until the current cook finishes.");
			return;
		}
		// The user's chosen destination, else the active group.
		let group = (mImportTargetGroup != null) ? mImportTargetGroup
			: ((mSelectedGroup != null) ? mSelectedGroup : mContext.Project.SourceDb.RootGroup);
		let deferred = new List<DeferredImportWrite>();
		let context = scope ImportContext(mContext.Project.SourcesRoot(.. scope .()));
		let imported = importer.Import(path, context, group, options, prepared, (mJobs != null) ? deferred : null);
		Instance primary = null;
		if (imported case .Ok(let instance))
			primary = instance;
		if (primary == null)
		{
			DeleteContainerAndItems!(deferred);
			delete options;
			delete prepared;
			mContext.Notify(.Error, scope $"Import failed: '{ImportPaths.FileNameOf(path)}' (see Console).");
			Rebuild();
			return;
		}

		if (deferred.IsEmpty || (mJobs == null))
		{
			delete deferred;
			FinishImport(primary, importer, options);
			delete options;
			delete prepared;
			return;
		}

		// The bulk stream writes flush on the worker, pure mount IO; the job lock keeps cooks
		// out and queues deletes. The prepared payload stays alive, since the views borrow
		// its decoded pixels.
		let primaryId = primary.Id;
		mJobs.Submit(scope $"Writing {ImportPaths.FileNameOf(path)}",
			new [=deferred](job) =>
			{
				Result<void, ErrorCode> result = .Ok;
				for (int i < deferred.Count)
				{
					let write = deferred[i];
					job.SetStep(write.Label, i + 1, deferred.Count);
					job.SetFraction((float)i / (float)deferred.Count);
					if (write.Execute() case .Err(let error))
					{
						GlobalLog(.Error, "Import: deferred write failed: '{}'", write.Label);
						result = .Err(error);
					}
				}
				return result;
			},
			new [=deferred, =importer, =options, =prepared, =primaryId, =this](result) =>
			{
				defer { DeleteContainerAndItems!(deferred); delete options; delete prepared; }
				let primary = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(primaryId) : null;
				if ((result case .Err) || (primary == null))
				{
					mContext.Notify(.Error, "Import data write FAILED (see Console).");
					Rebuild();
					return;
				}
				FinishImport(primary, importer, options);
			});
	}

	private void FinishImport(Instance primary, IFileImporter importer, ImportOptions options)
	{
		mContext.Notify(.Success, scope $"Imported '{primary.Name}' ({importer.Label}).");
		mContext.NotifyImported(primary, options);
		// The imported assets cook explicitly, scoped to the primary's group; the plan skips
		// anything clean. The Sources watcher triggers auto-cook off the provenance copy, but
		// a re-import of identical bytes skips that copy, so without this the new instances
		// would stay uncooked.
		let ids = scope List<Guid>();
		CollectInstanceIds(primary.OwningGroup, ids);
		mCook.RequestCookFor(ids, false);
		Rebuild();
	}
}
