using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// What the operations run on: the application's services for the open project. Every
/// reference is borrowed for the project's life; the strings are resolved on the main thread.
class EditorProjectOperationsSeams
{
	public EditorProject Project = null;
	/// SceneStreamStager and SceneRefScanner, when wired.
	public EditorContext Context = null;
	public EditorCookService Cook = null;
	public EditorJobService Jobs = null;
	public BuilderRegistry Builders = null;
	/// The player and its sidecars beside the executable: the host template.
	public String PlayerDir = new .() ~ delete _;
	/// The resolved templates root (reading it reads settings: main thread).
	public String TemplatesRoot = new .() ~ delete _;
	/// The engine data root; the shader cook reads <DataRoot>/Shaders.
	public String DataRoot = new .() ~ delete _;
	/// A step still running past this answers with an error.
	public double TimeoutSeconds = 600.0;
}

/// The editor host's IProjectOperations. The cook rides the cook service (requested, then
/// awaited by revision); the import runs the editor's two phase path (the worker prepare and
/// the deferred write flush on the job service, the cheap main thread placement between them,
/// held while a cook reads the databases); the export cooks through the cook service and then
/// runs the one export entry point on the job service: the same paths the menus take, so the
/// editor stays live while an agent's call waits. Every step is re-entered from the host's
/// pump: the first call starts the work, later calls poll it, and a step that outlives the
/// timeout answers with an error instead of waiting forever.
class EditorProjectOperations : IProjectOperations
{
	/// A cook requested and awaited: finished once the service's revision has moved past the
	/// one seen at the request and the service is idle again (a request that arrived mid cook
	/// is remembered by the service and lands one cook later).
	private struct CookWait
	{
		public bool Active = false;
		public uint64 SinceRevision = 0;
		public int64 StartedMicros = 0;
	}

	/// The state an import job shares with the delegates it hands the job service: ref counted
	/// so a job still running when these operations go away keeps it alive.
	private class ImportShared : RefCounted
	{
		/// The worker's payload, OWNED, alive through the flush: the writes borrow from it.
		public Object Prepared ~ delete _;
		public List<DeferredImportWrite> Writes = new .() ~ DeleteContainerAndItems!(_);
		/// Worker written before completion, main read after it.
		public int64 PrepareMs = 0;
		public int64 FlushMs = 0;
		/// Set on the main thread by the job's completion.
		public bool JobDone = false;
		public bool JobOk = true;
	}

	private enum ImportPhase
	{
		Idle,
		Preparing,
		Placing,
		Flushing
	}

	private class ExportShared : RefCounted
	{
		public ExportPreset Preset = new .() ~ delete _;
		public String OutRoot = new .() ~ delete _;
		public Dictionary<Guid, List<uint8>> SceneStreams = new .() ~ { for (let entry in _) delete entry.value; delete _; };
		public List<Guid> ReachableRoots = new .() ~ delete _;
		public bool ReachableValid = false;
		public ExportResult Result = new .() ~ delete _;
		public bool JobDone = false;
		public bool JobOk = true;
	}

	private enum ExportPhase
	{
		Idle,
		Cooking,
		Running
	}

	private EditorProjectOperationsSeams mSeams ~ delete _;
	private CookWait mCook = .();

	private ImportPhase mImportPhase = .Idle;
	private int64 mImportStarted = 0;
	private ImportShared mImport = null;
	private ImportOutcome mImportOutcome = new .() ~ delete _;

	private ExportPhase mExportPhase = .Idle;
	private int64 mExportStarted = 0;
	private CookWait mExportCook = .();
	private ExportShared mExport = null;

	/// OWNERSHIP of the seams transfers.
	public this(EditorProjectOperationsSeams seams)
	{
		mSeams = seams;
	}

	public ~this()
	{
		if (mImport != null)
			mImport.ReleaseRef();
		if (mExport != null)
			mExport.ReleaseRef();
	}

	private bool TimedOut(int64 startedMicros)
	{
		return (double)(Stopwatch.GetTimestamp() - startedMicros) / 1000000.0 > mSeams.TimeoutSeconds;
	}

	private void BeginCook(ref CookWait wait, bool force)
	{
		wait.Active = true;
		wait.SinceRevision = mSeams.Cook.Revision;
		wait.StartedMicros = Stopwatch.GetTimestamp();
		mSeams.Cook.RequestCook(force); // remembered by the service if one is in flight
	}

	/// Finished, still cooking (NotYet), or Failed once the wait outlives the timeout.
	private OperationStep PollCook(ref CookWait wait, String outError)
	{
		if ((mSeams.Cook.Revision > wait.SinceRevision) && mSeams.Cook.IsIdle)
		{
			wait.Active = false;
			return .Finished;
		}
		if (TimedOut(wait.StartedMicros))
		{
			wait.Active = false;
			outError.AppendF("the cook did not finish within {} s - read log_read (category Cook) for where it stands", (int64)mSeams.TimeoutSeconds);
			return .Failed;
		}
		return .NotYet;
	}

	public OperationStep Cook(bool force, ref CookOutcome outOutcome, String outError)
	{
		if (!mSeams.Cook.IsReady)
		{
			outError.Set("the editor has no cook service for the open project");
			return .Failed;
		}
		if (!mCook.Active)
			BeginCook(ref mCook, force);
		let step = PollCook(ref mCook, outError);
		if (step != .Finished)
			return step;
		let summary = mSeams.Cook.LastCookSummary;
		outOutcome.Planned = summary.Planned;
		outOutcome.Cooked = summary.Cooked;
		outOutcome.Failed = summary.Failed;
		outOutcome.OrphansSwept = summary.OrphansSwept;
		outOutcome.UpToDate = summary.UpToDate;
		outOutcome.Unbuildable = summary.Unbuildable;
		return .Finished;
	}

	private void ResetImport()
	{
		mImportPhase = .Idle;
		if (mImport != null)
		{
			mImport.ReleaseRef();
			mImport = null;
		}
		delete mImportOutcome;
		mImportOutcome = new .();
	}

	private OperationStep FailImport(String outError, StringView message)
	{
		ResetImport();
		outError.Set(message);
		return .Failed;
	}

	private void SubmitImportFlush(StringView source)
	{
		let shared = mImport;
		shared.JobDone = false;
		shared.AddRef();
		shared.AddRef();
		let name = new String(source);
		mSeams.Jobs.Submit(scope $"Writing {ImportPaths.FileNameOf(source)}",
			new [=shared, =name](job) =>
			{
				// Pure mount IO on the worker; the job lock keeps cooks out meanwhile.
				Result<void, ErrorCode> result = .Ok;
				let started = Stopwatch.GetTimestamp();
				let writes = shared.Writes;
				for (int i < writes.Count)
				{
					job.SetStep(writes[i].Label, i + 1, writes.Count);
					job.SetFraction((float)i / (float)writes.Count);
					if (writes[i].Execute() case .Err(let error))
					{
						GlobalLog(.Error, "Import: '{}': deferred write failed: '{}'", ImportPaths.FileNameOf(name), writes[i].Label);
						result = .Err(error);
					}
				}
				shared.FlushMs = (Stopwatch.GetTimestamp() - started) / 1000;
				return result;
			} ~ { shared.ReleaseRef(); delete name; },
			new [=shared](result) =>
			{
				shared.JobOk = (result case .Ok);
				shared.JobDone = true;
			} ~ shared.ReleaseRef());
	}

	public OperationStep Import(ImportRequest request, ImportOutcome outOutcome, String outError)
	{
		if (mImportPhase == .Idle)
		{
			mImportStarted = Stopwatch.GetTimestamp();
			mImport = new ImportShared();
			if (request.Importer.WantsWorkerPrepare)
			{
				// Phase 1, the load, on the worker: the bulk of a mesh or texture import.
				mImportPhase = .Preparing;
				let shared = mImport;
				shared.AddRef();
				shared.AddRef();
				let importer = request.Importer;
				let source = new String(request.Source);
				mSeams.Jobs.Submit(scope $"Reading {ImportPaths.FileNameOf(request.Source)}",
					new [=shared, =importer, =source](job) =>
					{
						job.SetStep("loading + decoding", 1, 2);
						let started = Stopwatch.GetTimestamp();
						shared.Prepared = importer.PrepareOnWorker(source);
						shared.PrepareMs = (Stopwatch.GetTimestamp() - started) / 1000;
						return (shared.Prepared != null) ? .Ok : .Err(.InvalidArgument);
					} ~ { shared.ReleaseRef(); delete source; },
					new [=shared](result) =>
					{
						shared.JobOk = (result case .Ok);
						shared.JobDone = true;
					} ~ shared.ReleaseRef());
				return .NotYet;
			}
			mImportPhase = .Placing;
		}
		if (mImportPhase == .Preparing)
		{
			if (!mImport.JobDone)
			{
				if (TimedOut(mImportStarted))
					return FailImport(outError, scope $"import of '{request.Source}': reading the file did not finish within {(int64)mSeams.TimeoutSeconds} s");
				return .NotYet;
			}
			if (!mImport.JobOk)
				return FailImport(outError, scope $"import of '{request.Source}' failed: the file could not be read (see log_read, category Import)");
			mImportPhase = .Placing;
		}
		if (mImportPhase == .Placing)
		{
			// Phase 2, the cheap main thread fan out, but never while a cook (or an export job)
			// reads the databases: the worker holds instance references snapshotted at plan time.
			if (mSeams.Cook.MutationLocked)
			{
				if (TimedOut(mImportStarted))
					return FailImport(outError, scope $"import of '{request.Source}': the databases stayed locked by a cook or export for {(int64)mSeams.TimeoutSeconds} s");
				return .NotYet;
			}
			let project = mSeams.Project;
			let group = McpTools.ResolveGroupPath(project.SourceDb.RootGroup, request.GroupPath);
			let context = scope ImportContext(project.SourcesRoot(.. scope .()));
			let placeStarted = Stopwatch.GetTimestamp();
			let imported = request.Importer.Import(request.Source, context, group, null, mImport.Prepared, mImport.Writes);
			mImportOutcome.MainMs = (Stopwatch.GetTimestamp() - placeStarted) / 1000;
			if (imported case .Err(let error))
				return FailImport(outError, scope $"import of '{request.Source}' failed ({error}) - see log_read, category Import");
			let instance = imported.Get();
			if (instance == null)
				return FailImport(outError, scope $"import of '{request.Source}' failed - see log_read, category Import");
			mImportOutcome.SetIdentity(instance);
			mImportOutcome.DeferredWrites = mImport.Writes.Count;
			mImportOutcome.PrepareMs = mImport.PrepareMs;
			if (mImport.Writes.IsEmpty)
				return FinishImport(outOutcome);
			// Phase 3, the bulk stream writes, on the worker.
			mImportPhase = .Flushing;
			SubmitImportFlush(request.Source);
			return .NotYet;
		}
		// Flushing.
		if (!mImport.JobDone)
		{
			if (TimedOut(mImportStarted))
				return FailImport(outError, scope $"import of '{request.Source}': writing its data did not finish within {(int64)mSeams.TimeoutSeconds} s");
			return .NotYet;
		}
		if (!mImport.JobOk)
			return FailImport(outError, scope $"import of '{request.Source}': a deferred write failed (see log_read, category Import)");
		return FinishImport(outOutcome);
	}

	private OperationStep FinishImport(ImportOutcome outOutcome)
	{
		mImportOutcome.FlushMs = mImport.FlushMs;
		mImportOutcome.CopyTo(outOutcome);
		ResetImport();
		return .Finished;
	}

	private void ResetExport()
	{
		mExportPhase = .Idle;
		mExportCook = .();
		if (mExport != null)
		{
			mExport.ReleaseRef();
			mExport = null;
		}
	}

	private OperationStep FailExport(String outError, StringView message)
	{
		ResetExport();
		outError.Set(message);
		return .Failed;
	}

	private void SubmitExportJob()
	{
		let shared = mExport;
		shared.JobDone = false;
		shared.AddRef();
		shared.AddRef();
		let project = mSeams.Project;
		let builders = mSeams.Builders;
		let playerDir = new String(mSeams.PlayerDir);
		let templatesRoot = new String(mSeams.TemplatesRoot);
		let dataRoot = new String(mSeams.DataRoot);
		mSeams.Jobs.Submit(scope $"Export {shared.Preset.Name}",
			new [=shared, =project, =builders, =playerDir, =templatesRoot, =dataRoot](job) =>
			{
				let templates = scope TemplateRegistry();
				templates.Refresh(templatesRoot, playerDir);
				ExportProgress onProgress = scope (step, fraction) =>
					{
						job.SetStep(step);
						job.SetFraction(fraction);
					};
				// The cook already ran through the cook service (cook false); the scene streams
				// and the reachable set were computed on the main thread.
				return ExportDriver.ExportOne(project, shared.Preset, templates, builders, shared.OutRoot, dataRoot,
					false, shared.Result, onProgress, false, shared.SceneStreams, null,
					shared.ReachableValid ? shared.ReachableRoots : null);
			} ~ { shared.ReleaseRef(); delete playerDir; delete templatesRoot; delete dataRoot; },
			new [=shared](result) =>
			{
				shared.JobOk = (result case .Ok);
				shared.JobDone = true;
			} ~ shared.ReleaseRef());
	}

	public OperationStep Export(ExportRequest request, ExportResult outResult, String outError)
	{
		if (mExportPhase == .Idle)
		{
			if (!mSeams.Cook.IsReady)
			{
				outError.Set("the editor has no cook service for the open project");
				return .Failed;
			}
			mExportStarted = Stopwatch.GetTimestamp();
			mExport = new ExportShared();
			request.Preset.CopyTo(mExport.Preset);
			mExport.OutRoot.Set(request.OutRoot);
			// Cook first, through the cook service: what the Export menu does before its job.
			mExportPhase = .Cooking;
			BeginCook(ref mExportCook, request.Rebuild);
		}
		if (mExportPhase == .Cooking)
		{
			let polled = PollCook(ref mExportCook, outError);
			if (polled == .Failed)
			{
				ResetExport();
				return .Failed;
			}
			if (polled == .NotYet)
				return .NotYet;
			// The main thread pre-pass: scene streams over the full composition, and the
			// reachable closure when the preset prunes (both need the scene machinery only the
			// main thread may run). An unwired seam leaves that half out, as the menu does.
			let project = mSeams.Project;
			let context = mSeams.Context;
			if ((context != null) && (context.SceneStreamStager != null))
				ExportDriver.CollectSceneStreams(project.SourceDb.RootGroup, context.SceneStreamStager, mExport.SceneStreams);
			if (mExport.Preset.PruneToReachable && (context != null) && (context.SceneRefScanner != null))
			{
				SceneReferenceScanner adapter = scope (instance, db, refs) => { context.SceneRefScanner(instance, db, refs.Resources, refs.Prefabs); };
				let seeds = scope List<ExportRoot>();
				defer ClearAndDeleteItems(seeds);
				ExportDriver.CollectExportRoots(project, seeds);
				ExportDriver.ExpandReachableRoots(project, seeds, adapter, mExport.ReachableRoots);
				mExport.ReachableValid = true;
			}
			mExportPhase = .Running;
			SubmitExportJob();
			return .NotYet;
		}
		// Running.
		if (!mExport.JobDone)
		{
			if (TimedOut(mExportStarted))
				return FailExport(outError, scope $"export of preset '{request.Preset.Name}' did not finish within {(int64)mSeams.TimeoutSeconds} s");
			return .NotYet;
		}
		if (!mExport.JobOk)
			return FailExport(outError, scope $"export of preset '{request.Preset.Name}' failed - read log_read (category Export/Cook) for the failing step");
		mExport.Result.CopyTo(outResult);
		ResetExport();
		return .Finished;
	}
}
