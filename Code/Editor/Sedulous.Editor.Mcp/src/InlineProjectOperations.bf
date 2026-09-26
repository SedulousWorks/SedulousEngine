using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// The stdio host's operations: everything runs on the calling thread and every step answers
/// at once. The cook is the driver's plan and execute over second mounts on Sources/ and
/// .cache/ with its own job system (so its timings mean what the editor's would); the import
/// is the editor's two phase path run inline (the worker prepare, the main thread placement,
/// the deferred flush), timed apart so the tool reports what the editor's interface thread
/// would have paid; the export is RunExport. The player directory and the data
/// root are the export's.
class InlineProjectOperations : IProjectOperations
{
	private ProjectSession mSession;
	private BuilderRegistry mBuilders;
	private String mPlayerDir = new .() ~ delete _;
	private String mDataRoot = new .() ~ delete _;

	/// playerDir is where the player beside the host lives, the export's host template;
	/// dataRoot the engine data root whose Shaders the export cooks.
	public this(ProjectSession session, BuilderRegistry builders, StringView playerDir, StringView dataRoot)
	{
		mSession = session;
		mBuilders = builders;
		mPlayerDir.Set(playerDir);
		mDataRoot.Set(dataRoot);
	}

	public OperationStep Cook(bool force, ref CookOutcome outOutcome, String outError)
	{
		let project = mSession.Project;
		// Second mounts on Sources/ and .cache/: the cook driver hashes source files and
		// persists its records through these; the source and cooked databases are open already.
		let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		// The driver fans its asset batch out over these, and hands them to every build
		// through the context so a texture's block rows and mip rows split too.
		let jobs = scope JobSystem();
		let driver = scope CookDriver(project.SourceDb, project.CookedDb, mBuilders,
			sourcesMount, cacheMount, jobs);
		let plan = scope CookPlan();
		driver.Plan(plan, force);
		let stats = scope CookStats();
		driver.Execute(plan, stats);
		outOutcome.Planned = plan.Dirty.Count;
		outOutcome.Cooked = stats.Cooked;
		outOutcome.Failed = stats.Failed;
		outOutcome.OrphansSwept = stats.OrphansSwept;
		outOutcome.UpToDate = plan.UpToDate;
		outOutcome.Unbuildable = plan.Unbuildable;
		return .Finished;
	}

	public OperationStep Import(ImportRequest request, ImportOutcome outOutcome, String outError)
	{
		let project = mSession.Project;
		let group = McpTools.ResolveGroupPath(project.SourceDb.RootGroup, request.GroupPath);
		let importContext = scope ImportContext(project.SourcesRoot(.. scope .()));
		let importer = request.Importer;

		var started = Stopwatch.GetTimestamp();
		let prepared = importer.WantsWorkerPrepare ? importer.PrepareOnWorker(request.Source) : null;
		defer { if (prepared != null) delete prepared; }
		outOutcome.PrepareMs = (Stopwatch.GetTimestamp() - started) / 1000;

		// The writes borrow from the prepared payload, so they go before it.
		let deferred = scope List<DeferredImportWrite>();
		defer ClearAndDeleteItems(deferred);
		started = Stopwatch.GetTimestamp();
		let imported = importer.Import(request.Source, importContext, group, null, prepared, deferred);
		outOutcome.MainMs = (Stopwatch.GetTimestamp() - started) / 1000;
		if (imported case .Err(let error))
		{
			outError.AppendF("import of '{}' failed ({})", request.Source, error);
			return .Failed;
		}

		started = Stopwatch.GetTimestamp();
		for (let write in deferred)
		{
			if (write.Execute() case .Err)
			{
				outError.AppendF("import of '{}': deferred write '{}' failed", request.Source, write.Label);
				return .Failed;
			}
		}
		outOutcome.FlushMs = (Stopwatch.GetTimestamp() - started) / 1000;
		outOutcome.DeferredWrites = deferred.Count;
		outOutcome.SetIdentity(imported.Get());
		return .Finished;
	}

	public OperationStep Export(ExportRequest request, ExportResult outResult, String outError)
	{
		return RunExport(mSession, mBuilders, mPlayerDir, mDataRoot, request, outResult, outError);
	}

	/// The INLINE export: what the stdio host runs on the calling thread and what the export
	/// CLI does. Templates from the shared root plus the player beside the host, scene streams
	/// pre-transcoded over the full composition, the reachability scanner over the same scan
	/// asset_uses runs, then ExportOne with the cook folded in.
	public static OperationStep RunExport(ProjectSession session, BuilderRegistry builders,
		StringView playerDir, StringView dataRoot, ExportRequest request, ExportResult outResult, String outError)
	{
		let project = session.Project;
		let templates = scope TemplateRegistry();
		templates.Refresh(ExportTemplates.ResolveRoot("", .. scope .()), playerDir);
		let sceneStreams = scope Dictionary<Guid, List<uint8>>();
		defer { for (let entry in sceneStreams) delete entry.value; }
		SceneExportSupport.CollectSceneStreams(project.SourceDb.RootGroup, sceneStreams);
		SceneReferenceScanner scanner = scope (instance, db, outReferences) =>
			{
				SceneExportSupport.ScanSceneReferences(instance, db, outReferences.Resources, outReferences.Prefabs);
			};
		if (ExportDriver.ExportOne(project, request.Preset, templates, builders, request.OutRoot, dataRoot,
			request.Rebuild, outResult, null, true, sceneStreams, scanner) case .Err)
		{
			outError.AppendF("export of preset '{}' failed - read log_read (category Export/Cook) for the failing step", request.Preset.Name);
			return .Failed;
		}
		return .Finished;
	}
}
