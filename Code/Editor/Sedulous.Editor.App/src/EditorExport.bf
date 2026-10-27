using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// What an EditorExport works over. The services are borrowed for its life; the strings and
/// the delegate are its own.
class EditorExportServices
{
	/// Where it says what happened (Notify, SetStatus), and the scene stager and reference
	/// scanner, when wired.
	public EditorContext Context = null;
	public EditorCookService Cook = null;
	public EditorJobService Jobs = null;
	public BuilderRegistry Builders = null;
	/// The per-user editor settings: the templates root override. Null reads as no override.
	public Settings UserSettings = null;
	/// The engine data root; the shader cook reads <DataRoot>/Shaders.
	public String DataRoot = new .() ~ delete _;
	/// The export was written to `folder` (the application offers to open it). Owned.
	public delegate void(StringView folder) OnExported ~ delete _;
}

/// Project > Export, out of the application (Raptor's editor-gui spec, 5.1, layer 3): the same
/// ExportOne and ExportAll the export CLI calls, in two phases so the UI never freezes. An
/// export asked for waits for a background cook through the cook service; once it is done the
/// scenes' text sources are transcoded to the wire and, when a preset prunes to what is
/// reachable, the reachable closure found, both on the main thread (they load scenes), then
/// the cook-free pack, stage and player copy run as a job, reader-only. It also keeps the
/// presets the Export dialog edits, finds the templates (the user's override, else the
/// environment's, else the user data's) and reports the resource manager's live products to
/// the log.
///
/// The running job reads this object's scene streams and presets, so the owner shuts the job
/// service down, or stops pumping it, before this goes.
class EditorExport
{
	/// An export waiting on its pre-cook: Run records it, Pump submits the job once the cook
	/// finishes.
	private class Pending
	{
		public String PresetName = new .() ~ delete _;
		public bool All = false;
		public bool WaitingCook = false;
		public bool Active = false;
	}

	private EditorExportServices mServices ~ delete _;
	/// Borrowed: the session's.
	private EditorProject mProject = null;
	private Pending mPending = new .() ~ delete _;
	/// Backs the Export dialog.
	private ExportPresetsController mPresetsController = new .() ~ delete _;
	/// The running job's transcoded scenes; the map owns its lists.
	private Dictionary<Guid, List<uint8>> mSceneStreams = new .() ~ { for (let e in _) delete e.value; delete _; };
	/// The running job's presets, loaded on the main thread.
	private ExportPresetSet mPresets = new .() ~ delete _;
	/// The running job's reachable closure.
	private List<Guid> mReachableRoots = new .() ~ delete _;
	/// True when the pre-scan ran; otherwise no pruning this run.
	private bool mReachableValid = false;

	/// TAKES OWNERSHIP of the services.
	public this(EditorExportServices services)
	{
		mServices = services;
	}

	/// The project it exports; null between projects.
	public void SetProject(EditorProject project)
	{
		mProject = project;
	}

	/// Exports `presetName`, or every preset when `all`: a background cook first, then the
	/// job, which Pump submits once the cook is done.
	public void Run(StringView presetName, bool all)
	{
		let context = mServices.Context;
		if (mProject == null)
		{
			context.Notify(.Info, "Open a project first.");
			return;
		}
		if (mServices.Jobs.IsBusy || mPending.Active)
		{
			context.Notify(.Info, "An export is already in progress.");
			return;
		}
		mPending.PresetName.Set(presetName);
		mPending.All = all;
		mPending.WaitingCook = true;
		mPending.Active = true;
		context.Notify(.Info, "Cooking before export...");
		mServices.Cook.RequestCook(false); // the safe background cook; Pump submits the job after it
	}

	/// An export asked for and not yet handed to the jobs.
	public bool IsPending => mPending.Active;

	/// Each frame, after the cook service's Update: an export waiting on its cook goes to the
	/// jobs once the cook is done.
	public void Pump()
	{
		if (mPending.Active && mPending.WaitingCook && !mServices.Cook.IsCooking)
		{
			mPending.WaitingCook = false;
			SubmitJob(mPending.PresetName, mPending.All);
			mPending.Active = false; // the job owns it now
		}
	}

	/// The export templates root: the EditorExportSettings override when set, else the
	/// environment, else the user-data default, the same order as the CLI.
	public void TemplatesRoot(String outPath)
	{
		StringView overrideRoot = "";
		if (mServices.UserSettings != null)
		{
			if (let s = mServices.UserSettings.Find<EditorExportSettings>())
				overrideRoot = s.TemplatesRoot;
		}
		ExportTemplates.ResolveRoot(overrideRoot, outPath);
	}

	/// The templates as the main thread sees them (the Export dialog's list): the host
	/// template beside this editor plus the bundles under the templates root.
	public void BuildTemplateRegistry(TemplateRegistry outRegistry)
	{
		let toolDir = GetExecutableDirectory(.. scope .());
		outRegistry.Refresh(TemplatesRoot(.. scope .()), BuildLayout.PlayerDirectoryBeside(toolDir, .. scope .()));
	}

	/// The presets the Export dialog edits; SavePresets writes them to the project.
	public ExportPresetsController Presets => mPresetsController;

	/// Writes the dialog's presets to the project's export_presets.xml.
	public void SavePresets()
	{
		if (mProject == null)
			return;
		let projectFs = scope NativeFileSystem(mProject.Directory);
		if (mPresetsController.Save(projectFs) case .Err)
			mServices.Context.Notify(.Error, "Saving export presets FAILED (see console).");
	}

	/// The resource manager's live products by type, to the log (Project > Report Resource
	/// Memory); null, with no project open, is a line saying so.
	public static void ReportResourceMemory(ResourceManager resources)
	{
		if (resources == null)
		{
			GlobalLog(.Information, "Editor: resource report: no resource manager (no project open)");
			return;
		}
		let rows = scope List<LiveProductRow>();
		resources.ReportLiveProducts(rows);
		int totalLive = 0;
		int totalUnreferenced = 0;
		for (let row in rows)
		{
			GlobalLog(.Information, "Editor: resource report: type {:X}: live {}, pending {}, failed {}, unreferenced {}",
				row.ProductTypeId, row.Live, row.Pending, row.Failed, row.Unreferenced);
			totalLive += row.Live;
			totalUnreferenced += row.Unreferenced;
		}
		GlobalLog(.Information, "Editor: resource report: {} live products total, {} unreferenced (cache-only, what a purge would release)",
			totalLive, totalUnreferenced);
	}

	/// The absolute form of a path, resolved against the working directory: the project
	/// directory can be relative, but the folder reveal needs an absolute path.
	private static void Absolutize(StringView path, String outPath)
	{
		if (PathIsAbsolute(path))
			outPath.Set(path);
		else
			PathJoin(GetCurrentDirectory(.. scope .()), path, outPath);
	}

	/// Does this run include a preset that prunes to reachable? Decides whether the
	/// main-thread reachability pre-scan is worth running.
	private bool AnyPresetPrunes(bool all, StringView presetName)
	{
		if (all)
		{
			for (let p in mPresets.Presets)
			{
				if (p.PruneToReachable)
					return true;
			}
			return false;
		}
		let p = mPresets.Find(presetName);
		return (p != null) && p.PruneToReachable;
	}

	/// Phase two: pack, stage and player as a background job, the cook having already run.
	/// File I/O only, no database mutation, so it is safe alongside the main thread's reads.
	private void SubmitJob(StringView presetName, bool all)
	{
		let project = mProject;
		let builders = mServices.Builders;
		let context = mServices.Context;

		// The main-thread pre-pass: scene and prefab text sources transcode to the binary wire,
		// since the stager needs the scene subsystem. One export at a time, so the member map
		// stays valid for the job's lifetime.
		for (let e in mSceneStreams)
			delete e.value;
		mSceneStreams.Clear();
		if (context.SceneStreamStager != null)
			ExportDriver.CollectSceneStreams(project.SourceDb.RootGroup, context.SceneStreamStager, mSceneStreams);

		// The presets load on the main thread: the pre-scan needs to know whether pruning is
		// requested, and the job reuses this copy.
		ClearAndDeleteItems(mPresets.Presets);
		{
			let projectFs = scope NativeFileSystem(project.Directory);
			if (ExportPresetsFile.Load(projectFs, mPresets) case .Err)
				ExportPresetsFile.Defaults(mPresets);
		}

		// The main-thread reachability pre-scan: pruning needs the scene-to-asset edges, which
		// means loading scenes, unsafe off the main thread. When a preset prunes and the scene
		// editor supplied a scanner, the reachable closure expands now and the guid set goes
		// to the job. Without a scanner the job packs everything.
		mReachableRoots.Clear();
		mReachableValid = false;
		if (AnyPresetPrunes(all, presetName) && (context.SceneRefScanner != null))
		{
			SceneReferenceScanner adapter = scope (inst, db, refs) => { context.SceneRefScanner(inst, db, refs.Resources, refs.Prefabs); };
			let seeds = scope List<ExportRoot>();
			defer ClearAndDeleteItems(seeds); // the caller owns the roots
			ExportDriver.CollectExportRoots(project, seeds);
			ExportDriver.ExpandReachableRoots(project, seeds, adapter, mReachableRoots);
			mReachableValid = true;
		}
		let reachableRoots = mReachableValid ? mReachableRoots : null;
		let presets = mPresets;
		let sceneStreams = mSceneStreams;

		// Resolved here, on the main thread (the templates root reads settings); the work
		// delegate owns its copies and the completion its own, so a job dropped at shutdown,
		// its completion never run, leaks nothing.
		let toolDir = new String();
		GetExecutableDirectory(toolDir);
		let templatesRoot = new String();
		TemplatesRoot(templatesRoot);
		let dataRoot = new String(mServices.DataRoot);
		let outRoot = new String();
		Absolutize(PathJoin(project.Directory, "Dist", .. scope .()), outRoot);
		let name = new String(presetName);
		let revealRoot = new String(outRoot);

		mServices.Jobs.Submit(all ? "Export All" : "Export",
			new [=project, =builders, =toolDir, =templatesRoot, =dataRoot, =name, =all, =outRoot, =sceneStreams, =reachableRoots, =presets](job) =>
			{
				let registry = scope TemplateRegistry();
				registry.Refresh(templatesRoot, BuildLayout.PlayerDirectoryBeside(toolDir, .. scope .()));
				ExportProgress onProgress = scope (step, fraction) =>
					{
						job.SetStep(step);
						job.SetFraction(fraction);
					};
				if (all)
				{
					return ExportDriver.ExportAll(project, presets.Presets, registry, builders, outRoot, dataRoot,
						false, onProgress, false, sceneStreams, null, reachableRoots);
				}
				let preset = presets.Find(name);
				if (preset == null)
					return .Err(.NotFound);
				return ExportDriver.ExportOne(project, preset, registry, builders, outRoot, dataRoot,
					false, null, onProgress, false, sceneStreams, null, reachableRoots);
			} ~ { delete toolDir; delete templatesRoot; delete dataRoot; delete name; delete outRoot; },
			new [=revealRoot, =this](result) => // main thread
			{
				if (result case .Err)
				{
					mServices.Context.Notify(.Error, "Export failed (see Console).");
					return;
				}
				mServices.Context.SetStatus("Export complete.");
				if (mServices.OnExported != null)
					mServices.OnExported(revealRoot);
			} ~ delete revealRoot);
	}
}
