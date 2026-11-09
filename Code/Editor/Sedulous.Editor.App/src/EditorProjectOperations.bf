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
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.Mcp;

namespace Sedulous.Editor.App;

/// What the operations run on: the application's services for the open project. Every
/// reference is borrowed for the project's life; the strings are resolved on the main thread.
class EditorProjectOperationsSeams
{
	public EditorProject Project = null;
	/// SceneStreamStager and SceneRefScanner, when wired.
	public EditorContext Context = null;
	public EditorCookService Cook = null;
	/// The pool and lane each step runs on (the context's build lane). Borrowed.
	public TaskPool Tasks = null;
	public TaskLane Lane = .Shared;
	public BuilderRegistry Builders = null;
	/// The application's project build service, which builds the player an export ships.
	/// Unset, an export is refused.
	public ProjectBuildService BuildService = null;
	/// The engine data root; the shader cook reads <DataRoot>/Shaders.
	public String DataRoot = new .() ~ delete _;
	/// After a creation: the editor's effects (a first scene as the default, the browser, the
	/// cook), the ones File > New has. Owned.
	public delegate void(AssetCreator creator, Instance instance) OnCreated ~ delete _;
	/// After an import: the editor's effects, the ones an import from the Assets browser has
	/// (the import listeners, a model's prefab among them; the cook of what it made; the
	/// browser). Owned.
	public delegate void(Instance primary, ImportOptions options) OnImported ~ delete _;
	/// An agent's delete, the browser's own (its page closed, the default scene and the
	/// browser kept honest). Unset falls back to the database's delete. Owned.
	public delegate bool(Guid id) OnDelete ~ delete _;
	/// A step still running past this answers with an error.
	public double TimeoutSeconds = 600.0;
}

/// The editor host's IProjectOperations. The cook rides the cook service (requested, then
/// awaited by revision); the import runs the editor's two phase path (the worker prepare and
/// the deferred write flush on the job service, the cheap main thread placement between them,
/// held while a cook reads the databases); the export cooks through the cook service and then
/// runs the one export entry point on the job service: the same paths the menus take, so the
/// editor stays live while an agent's call waits. Every step is re-entered from the host's
/// pump: the first entry starts the work, later entries poll it, and a step that outlives the
/// timeout answers with an error instead of waiting forever. Each call's progress is its own,
/// kept in the call's State, so two agents' imports (or cooks, or exports) run side by side.
class EditorProjectOperations : IProjectOperations
{
	/// A cook requested and awaited: finished once the service's revision has moved past the
	/// one seen at the request and the service is idle again (a request that arrived mid cook
	/// is remembered by the service and lands one cook later).
	private class CookWait
	{
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
		Preparing,
		Placing,
		Flushing
	}

	/// One import call's progress. The shared state is released with it: a job still running
	/// when the call ends (its caller left) keeps its own reference.
	private class ImportState
	{
		public ImportPhase Phase = .Placing;
		public int64 Started = Stopwatch.GetTimestamp();
		public ImportShared Shared = new .() ~ _.ReleaseRef();
		public ImportOutcome Outcome = new .() ~ delete _;
	}

	private class ExportShared : RefCounted
	{
		public ExportPreset Preset = new .() ~ delete _;
		public String OutRoot = new .() ~ delete _;
		public Dictionary<Guid, List<uint8>> SceneStreams = new .() ~ { for (let entry in _) delete entry.value; delete _; };
		public List<Guid> ReachableRoots = new .() ~ delete _;
		public bool ReachableValid = false;
		public ExportResult Result = new .() ~ delete _;
		/// False: the player the last build left ships, and no BeefBuild runs.
		public bool Build = true;
		public bool JobDone = false;
		public bool JobOk = true;
	}

	private enum ExportPhase
	{
		Cooking,
		Running
	}

	/// One export call's progress; its shared state released as an import's is.
	private class ExportState
	{
		public ExportPhase Phase = .Cooking;
		public int64 Started = Stopwatch.GetTimestamp();
		/// How long it may run, cook and job together; 0 is the seams' step timeout.
		public double TimeoutSeconds = 0;
		public CookWait Cook = new .() ~ delete _;
		public ExportShared Shared = new .() ~ _.ReleaseRef();
	}

	/// A creation waiting on the cook gate: when it first waited.
	private class CreateWait
	{
		public int64 Started = Stopwatch.GetTimestamp();
	}

	private EditorProjectOperationsSeams mSeams ~ delete _;

	/// OWNERSHIP of the seams transfers.
	public this(EditorProjectOperationsSeams seams)
	{
		mSeams = seams;
	}

	/// Whether what started at `startedMicros` has run past `timeoutSeconds` (0: the seams' step
	/// timeout).
	private bool TimedOut(int64 startedMicros, double timeoutSeconds = 0)
	{
		return (double)(Stopwatch.GetTimestamp() - startedMicros) / 1000000.0 > Limit(timeoutSeconds);
	}

	/// `timeoutSeconds`, or the seams' step timeout for 0.
	private double Limit(double timeoutSeconds) => (timeoutSeconds > 0) ? timeoutSeconds : mSeams.TimeoutSeconds;

	private void BeginCook(CookWait wait, bool force)
	{
		wait.SinceRevision = mSeams.Cook.Revision;
		wait.StartedMicros = Stopwatch.GetTimestamp();
		mSeams.Cook.RequestCook(force); // remembered by the service if one is in flight
	}

	/// Finished, still cooking (NotYet), or Failed once the wait outlives `timeoutSeconds` (0:
	/// the seams' step timeout).
	private OperationStep PollCook(CookWait wait, String outError, double timeoutSeconds = 0)
	{
		if ((mSeams.Cook.Revision > wait.SinceRevision) && mSeams.Cook.IsIdle)
			return .Finished;
		if (TimedOut(wait.StartedMicros, timeoutSeconds))
		{
			outError.AppendF("the cook did not finish within {} s - read log_read (category Cook) for where it stands", (int64)Limit(timeoutSeconds));
			return .Failed;
		}
		return .NotYet;
	}

	public OperationStep Cook(ToolCall call, bool force, ref CookOutcome outOutcome, String outError)
	{
		if (!mSeams.Cook.IsReady)
		{
			outError.Set("the editor has no cook service for the open project");
			return .Failed;
		}
		var wait = call.State as CookWait;
		if (wait == null)
		{
			wait = new CookWait();
			call.State = wait;
			BeginCook(wait, force);
		}
		let step = PollCook(wait, outError);
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

	private static OperationStep FailImport(String outError, StringView message)
	{
		outError.Set(message);
		return .Failed;
	}

	private void SubmitImportFlush(ImportShared shared, StringView source)
	{
		shared.JobDone = false;
		shared.AddRef();
		shared.AddRef();
		let name = new String(source);
		mSeams.Tasks.Submit(scope $"Writing {ImportPaths.FileNameOf(source)}",
			new [=shared, =name](task) =>
			{
				// Pure mount IO on the worker; the build lane keeps cooks out meanwhile.
				Result<void, ErrorCode> result = .Ok;
				let started = Stopwatch.GetTimestamp();
				let writes = shared.Writes;
				for (int i < writes.Count)
				{
					task.SetStep(writes[i].Label, i + 1, writes.Count);
					task.SetFraction((float)i / (float)writes.Count);
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
			} ~ shared.ReleaseRef(), mSeams.Lane);
	}

	public OperationStep Import(ToolCall call, ImportRequest request, ImportOutcome outOutcome, String outError)
	{
		var import = call.State as ImportState;
		if (import == null)
		{
			import = new ImportState();
			call.State = import;
			if (request.Importer.WantsWorkerPrepare)
			{
				// Phase 1, the load, on the worker: the bulk of a mesh or texture import.
				import.Phase = .Preparing;
				let shared = import.Shared;
				shared.AddRef();
				shared.AddRef();
				let importer = request.Importer;
				let source = new String(request.Source);
				mSeams.Tasks.Submit(scope $"Reading {ImportPaths.FileNameOf(request.Source)}",
					new [=shared, =importer, =source](task) =>
					{
						task.SetStep("loading + decoding", 1, 2);
						let started = Stopwatch.GetTimestamp();
						shared.Prepared = importer.PrepareOnWorker(source);
						shared.PrepareMs = (Stopwatch.GetTimestamp() - started) / 1000;
						return (shared.Prepared != null) ? .Ok : .Err(.InvalidArgument);
					} ~ { shared.ReleaseRef(); delete source; },
					new [=shared](result) =>
					{
						shared.JobOk = (result case .Ok);
						shared.JobDone = true;
					} ~ shared.ReleaseRef(), mSeams.Lane);
				return .NotYet;
			}
		}
		if (import.Phase == .Preparing)
		{
			if (!import.Shared.JobDone)
			{
				if (TimedOut(import.Started))
					return FailImport(outError, scope $"import of '{request.Source}': reading the file did not finish within {(int64)mSeams.TimeoutSeconds} s");
				return .NotYet;
			}
			if (!import.Shared.JobOk)
				return FailImport(outError, scope $"import of '{request.Source}' failed: the file could not be read (see log_read, category Import)");
			import.Phase = .Placing;
		}
		if (import.Phase == .Placing)
		{
			// Phase 2, the cheap main thread fan out, but never while a cook (or an export job)
			// reads the databases: the worker holds instance references snapshotted at plan time.
			if (mSeams.Cook.MutationLocked)
			{
				if (TimedOut(import.Started))
					return FailImport(outError, scope $"import of '{request.Source}': the databases stayed locked by a cook or export for {(int64)mSeams.TimeoutSeconds} s");
				return .NotYet;
			}
			let project = mSeams.Project;
			let group = McpTools.ResolveGroupPath(project.SourceDb.RootGroup, request.GroupPath);
			let context = scope ImportContext(project.SourcesRoot(.. scope .()));
			context.OnConflict = request.OnConflict;
			ImportPaths.ImportLedgerPath(project.CacheRoot(.. scope .()), context.LedgerPath);
			let placeStarted = Stopwatch.GetTimestamp();
			let imported = request.Importer.Import(request.Source, context, group, request.Options, import.Shared.Prepared, import.Shared.Writes);
			import.Outcome.MainMs = (Stopwatch.GetTimestamp() - placeStarted) / 1000;
			if (imported case .Err(let error))
				return FailImport(outError, scope $"import of '{request.Source}' failed ({error}) - see log_read, category Import");
			let instance = imported.Get();
			if (instance == null)
				return FailImport(outError, scope $"import of '{request.Source}' failed - see log_read, category Import");
			import.Outcome.SetIdentity(instance);
			import.Outcome.DeferredWrites = import.Shared.Writes.Count;
			import.Outcome.PrepareMs = import.Shared.PrepareMs;
			if (import.Shared.Writes.IsEmpty)
				return FinishImport(import, outOutcome, request.Options);
			// Phase 3, the bulk stream writes, on the worker.
			import.Phase = .Flushing;
			SubmitImportFlush(import.Shared, request.Source);
			return .NotYet;
		}
		// Flushing.
		if (!import.Shared.JobDone)
		{
			if (TimedOut(import.Started))
				return FailImport(outError, scope $"import of '{request.Source}': writing its data did not finish within {(int64)mSeams.TimeoutSeconds} s");
			return .NotYet;
		}
		if (!import.Shared.JobOk)
			return FailImport(outError, scope $"import of '{request.Source}': a deferred write failed (see log_read, category Import)");
		return FinishImport(import, outOutcome, request.Options);
	}

	private OperationStep FinishImport(ImportState import, ImportOutcome outOutcome, ImportOptions options)
	{
		import.Outcome.FlushMs = import.Shared.FlushMs;
		import.Outcome.CopyTo(outOutcome);
		// Every write has landed: the import is whole, so what follows an import runs now, its
		// settings recorded first (a reimport starts from them).
		if (mSeams.Project != null)
		{
			if (let primary = mSeams.Project.SourceDb.GetInstance(outOutcome.Id))
			{
				ImportPaths.RecordImportSettings(primary, options);
				if (mSeams.OnImported != null)
					mSeams.OnImported(primary, options);
			}
		}
		return .Finished;
	}

	private static OperationStep FailExport(String outError, StringView message)
	{
		outError.Set(message);
		return .Failed;
	}

	private void SubmitExportJob(ExportShared shared)
	{
		shared.JobDone = false;
		shared.AddRef();
		shared.AddRef();
		let project = mSeams.Project;
		let builders = mSeams.Builders;
		let buildService = mSeams.BuildService;
		let dataRoot = new String(mSeams.DataRoot);
		let hooks = (mSeams.Context != null) ? mSeams.Context.ExportHooks : null;
		let plugins = (mSeams.Context != null) ? mSeams.Context.Plugins : null;
		mSeams.Tasks.Submit(scope $"Export {shared.Preset.Name}",
			new [=shared, =project, =builders, =buildService, =dataRoot, =hooks, =plugins](task) =>
			{
				if ((buildService == null) && shared.Build)
				{
					shared.Result.Refusal.Set("this host has no project build service to build the player with");
					return .Err(.NotSupported);
				}
				// The player builds here, on the build lane, cancelled with the lane's task; or, with
				// no build asked for, the last build ships.
				let players = scope ProjectPlayerBuilder(buildService, dataRoot, task.Token, !shared.Build);
				ExportProgress onProgress = scope (step, fraction) =>
					{
						task.SetStep(step);
						task.SetFraction(fraction);
					};
				// The cook already ran through the cook service (cook false); the scene streams
				// and the reachable set were computed on the main thread.
				return ExportDriver.ExportOne(project, shared.Preset, players, builders, shared.OutRoot, dataRoot,
					false, shared.Result, onProgress, false, shared.SceneStreams, null,
					shared.ReachableValid ? shared.ReachableRoots : null, hooks, plugins);
			} ~ { shared.ReleaseRef(); delete dataRoot; },
			new [=shared](result) =>
			{
				shared.JobOk = (result case .Ok);
				shared.JobDone = true;
			} ~ shared.ReleaseRef(), mSeams.Lane);
	}

	/// On the main thread, never while a cook or an export reads the databases (it waits, as a
	/// placement does); then the host's effects through OnCreated.
	public OperationStep Create(ToolCall call, CreateRequest request, CreateOutcome outOutcome, String outError)
	{
		if (mSeams.Cook.MutationLocked)
		{
			if (call.State == null)
				call.State = new CreateWait();
			if (TimedOut((call.State as CreateWait).Started))
			{
				outError.AppendF("create of a {}: the databases stayed locked by a cook or export for {} s", request.Creator.Label, (int64)mSeams.TimeoutSeconds);
				return .Failed;
			}
			return .NotYet;
		}
		let instance = AssetCreation.Run(mSeams.Project, request, outError);
		if (instance == null)
			return .Failed;
		if (mSeams.OnCreated != null)
			mSeams.OnCreated(request.Creator, instance);
		outOutcome.SetFrom(instance);
		return .Finished;
	}

	/// On the main thread, never while a cook or an export reads the databases (it waits, as
	/// a creation does); then the browser's own delete through OnDelete.
	public OperationStep Delete(ToolCall call, Guid id, String outError)
	{
		if (mSeams.Cook.MutationLocked)
		{
			if (call.State == null)
				call.State = new CreateWait();
			if (TimedOut((call.State as CreateWait).Started))
			{
				outError.AppendF("delete of asset {}: the databases stayed locked by a cook or export for {} s", id, (int64)mSeams.TimeoutSeconds);
				return .Failed;
			}
			return .NotYet;
		}
		let deleted = (mSeams.OnDelete != null) ? mSeams.OnDelete(id) : (mSeams.Project.SourceDb.DeleteInstance(id) case .Ok);
		if (!deleted)
		{
			outError.AppendF("could not delete asset {} (log_read says why)", id);
			return .Failed;
		}
		return .Finished;
	}

	public OperationStep Export(ToolCall call, ExportRequest request, ExportResult outResult, String outError)
	{
		var export = call.State as ExportState;
		if (export == null)
		{
			if (!mSeams.Cook.IsReady)
			{
				outError.Set("the editor has no cook service for the open project");
				return .Failed;
			}
			export = new ExportState();
			call.State = export;
			export.TimeoutSeconds = request.TimeoutSeconds;
			request.Preset.CopyTo(export.Shared.Preset);
			export.Shared.OutRoot.Set(request.OutRoot);
			export.Shared.Build = request.Build;
			// Cook first, through the cook service: what the Export menu does before its job.
			BeginCook(export.Cook, request.Rebuild);
		}
		if (export.Phase == .Cooking)
		{
			let polled = PollCook(export.Cook, outError, export.TimeoutSeconds);
			if (polled == .Failed)
				return .Failed;
			if (polled == .NotYet)
				return .NotYet;
			// The main thread pre-pass: scene streams over the full composition, and the
			// reachable closure when the preset prunes (both need the scene machinery only the
			// main thread may run). An unwired seam leaves that half out, as the menu does.
			let project = mSeams.Project;
			let context = mSeams.Context;
			if ((context != null) && (context.SceneStreamStager != null))
				ExportDriver.CollectSceneStreams(project.SourceDb.RootGroup, context.SceneStreamStager, export.Shared.SceneStreams);
			if (export.Shared.Preset.PruneToReachable && (context != null) && (context.SceneRefScanner != null))
			{
				SceneReferenceScanner adapter = scope (instance, db, refs) => { context.SceneRefScanner(instance, db, refs.Resources, refs.Prefabs); };
				let seeds = scope List<ExportRoot>();
				defer ClearAndDeleteItems(seeds);
				ExportDriver.CollectExportRoots(project, seeds);
				ExportDriver.ExpandReachableRoots(project, seeds, adapter, export.Shared.ReachableRoots);
				export.Shared.ReachableValid = true;
			}
			export.Phase = .Running;
			SubmitExportJob(export.Shared);
			return .NotYet;
		}
		// Running.
		if (!export.Shared.JobDone)
		{
			if (TimedOut(export.Started, export.TimeoutSeconds))
			{
				return FailExport(outError, scope $"export of preset '{request.Preset.Name}' did not finish within {(int64)Limit(export.TimeoutSeconds)} s; it goes on (build_status follows its player's build)");
			}
			return .NotYet;
		}
		if (!export.Shared.JobOk)
		{
			// Why it was refused, when it was (a plugin, the platform, the player's compile errors).
			let refusal = export.Shared.Result.Refusal;
			if (!refusal.IsEmpty)
				return FailExport(outError, scope $"export of preset '{request.Preset.Name}' refused: {refusal}");
			return FailExport(outError, scope $"export of preset '{request.Preset.Name}' failed - read log_read (category Export/Cook) for the failing step");
		}
		export.Shared.Result.CopyTo(outResult);
		return .Finished;
	}
}
