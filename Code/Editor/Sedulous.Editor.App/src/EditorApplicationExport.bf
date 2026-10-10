using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App;

/// Export: a fresh template registry and presets run through the shared driver, the same
/// ExportOne and ExportAll the export CLI calls, in two safe phases so the UI never freezes:
/// a cook through the cook service, then, once it finishes, a background job that packs,
/// stages and copies the player, reader-only. Plus the two dialogs over the driver: Export
/// (the presets) and Export Templates, each given what it needs through its seams.
extension EditorApplication
{
	private void RunExport(StringView presetName, bool all)
	{
		if (mProject == null)
		{
			mContext.Notify(.Info, "Open a project first.");
			return;
		}
		if (mJobService.IsBusy || mPendingExport.Active)
		{
			mContext.Notify(.Info, "An export is already in progress.");
			return;
		}
		mPendingExport.PresetName.Set(presetName);
		mPendingExport.All = all;
		mPendingExport.WaitingCook = true;
		mPendingExport.Active = true;
		mContext.Notify(.Info, "Cooking before export...");
		mCookService.RequestCook(false); // the safe background cook; OnUpdate fires the job after it
	}

	/// The editor's export templates root: the EditorExportSettings override when set, else
	/// the environment, else the user-data default, the same order as the CLI.
	private void TemplatesRoot(String outPath)
	{
		StringView overrideRoot = "";
		if (let s = mEditorSettings.Find<EditorExportSettings>())
			overrideRoot = s.TemplatesRoot;
		ExportTemplates.ResolveRoot(overrideRoot, outPath);
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
			for (let p in mExportPresets.Presets)
			{
				if (p.PruneToReachable)
					return true;
			}
			return false;
		}
		let p = mExportPresets.Find(presetName);
		return (p != null) && p.PruneToReachable;
	}

	/// Phase two: pack, stage and player as a background job, the cook having already run.
	/// File I/O only, no database mutation, so it is safe alongside the main thread's reads.
	private void SubmitExportJob(StringView presetName, bool all)
	{
		let project = mProject;
		let builders = mBuilders;

		// The main-thread pre-pass: scene and prefab text sources transcode to the binary wire,
		// since the stager needs the scene subsystem. One export at a time, so the member map
		// stays valid for the job's lifetime.
		for (let e in mExportSceneStreams)
			delete e.value;
		mExportSceneStreams.Clear();
		if (mContext.SceneStreamStager != null)
			ExportDriver.CollectSceneStreams(mProject.SourceDb.RootGroup, mContext.SceneStreamStager, mExportSceneStreams);

		// The presets load on the main thread: the pre-scan needs to know whether pruning is
		// requested, and the job reuses this copy.
		ClearAndDeleteItems(mExportPresets.Presets);
		{
			let projectFs = scope NativeFileSystem(project.Directory);
			if (ExportPresetsFile.Load(projectFs, mExportPresets) case .Err)
				ExportPresetsFile.Defaults(mExportPresets);
		}

		// The main-thread reachability pre-scan: pruning needs the scene-to-asset edges, which
		// means loading scenes, unsafe off the main thread. When a preset prunes and the scene
		// editor supplied a scanner, the reachable closure expands now and the guid set goes
		// to the job. Without a scanner the job packs everything.
		mExportReachableRoots.Clear();
		mExportReachableValid = false;
		if (AnyPresetPrunes(all, presetName) && (mContext.SceneRefScanner != null))
		{
			SceneReferenceScanner adapter = scope (inst, db, refs) => { mContext.SceneRefScanner(inst, db, refs.Resources, refs.Prefabs); };
			let seeds = scope List<ExportRoot>();
			defer ClearAndDeleteItems(seeds); // the caller owns the roots
			ExportDriver.CollectExportRoots(project, seeds);
			ExportDriver.ExpandReachableRoots(project, seeds, adapter, mExportReachableRoots);
			mExportReachableValid = true;
		}
		let reachableRoots = mExportReachableValid ? mExportReachableRoots : null;
		let presets = mExportPresets;
		let sceneStreams = mExportSceneStreams;

		let toolDir = new String();
		GetExecutableDirectory(toolDir);
		let templatesRoot = new String();
		TemplatesRoot(templatesRoot); // resolved on the main thread, it reads settings
		let dataRoot = new String(mConfig.DataRoot); // the shader cook reads <dataRoot>/Shaders
		let outRoot = new String();
		Absolutize(PathJoin(mProject.Directory, "Dist", .. scope .()), outRoot);
		let name = new String(presetName);

		mJobService.Submit(all ? "Export All" : "Export",
			new [=project, =builders, =toolDir, =templatesRoot, =dataRoot, =name, =all, =outRoot, =sceneStreams, =reachableRoots, =presets](ctx) =>
			{
				let registry = scope TemplateRegistry();
				registry.Refresh(templatesRoot, BuildLayout.PlayerDirectoryBeside(toolDir, .. scope .()));
				ExportProgress onProgress = scope (step, frac) =>
					{
						ctx.SetStep(step);
						ctx.SetFraction(frac);
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
			},
			new [=toolDir, =templatesRoot, =dataRoot, =name, =outRoot, =this](result) => // main thread
			{
				defer { delete toolDir; delete templatesRoot; delete dataRoot; delete name; delete outRoot; }
				if (result case .Err)
				{
					mContext.Notify(.Error, "Export failed (see Console).");
					return;
				}
				mContext.SetStatus("Export complete.");
				// A sticky success toast with a button that reveals the Dist folder in the OS
				// file manager; the click dismisses the toast.
				if (mToastHost != null)
				{
					let revealPath = new String(outRoot);
					var request = ToastRequest("Export complete.", .Success);
					request.DurationSeconds = 0.0f;
					request.ActionLabel = "Open Folder";
					request.OnAction = new [=revealPath, =this]() =>
						{
							GlobalLog(.Debug, "Editor: Open Folder clicked, reveal '{}'", revealPath);
							if ((mHost != null) && (mHost.Shell != null) && (mHost.Shell.Dialogs != null))
								mHost.Shell.Dialogs.OpenPath(revealPath);
							else
								GlobalLog(.Warning, "Editor: Open Folder: no shell dialog service available");
						} ~ delete revealPath;
					mToastHost.Show(request);
				}
			});
	}

	/// A template registry on the main thread: the host template beside this editor plus
	/// the imported and created bundles under the configured templates root.
	private void BuildTemplateRegistryMainThread(TemplateRegistry outRegistry)
	{
		let toolDir = GetExecutableDirectory(.. scope .());
		outRegistry.Refresh(TemplatesRoot(.. scope .()), BuildLayout.PlayerDirectoryBeside(toolDir, .. scope .()));
	}

	/// Persists the in-memory preset set to the project's export_presets.xml.
	private void SavePresetsController()
	{
		if (mProject == null)
			return;
		let projectFs = scope NativeFileSystem(mProject.Directory);
		if (mPresetsController.Save(projectFs) case .Err)
			mContext.Notify(.Error, "Saving export presets FAILED (see console).");
	}

	/// The export templates dialog, over whatever is open; null with no UI. The dialog is the
	/// context's once shown.
	private Dialog OpenTemplatesManager()
	{
		if (mUiHost == null)
			return null;
		let seams = new TemplatesDialogSeams();
		seams.TemplatesRoot = new [=this](outRoot) => { TemplatesRoot(outRoot); };
		seams.Refresh = new [=this](registry) => { BuildTemplateRegistryMainThread(registry); };
		seams.PickFolder = new [=this](chosen) =>
			{
				if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Dialogs == null))
				{
					mContext.Notify(.Error, "File dialogs are unavailable.");
					chosen(default);
					delete chosen;
					return;
				}
				mHost.Shell.Dialogs.ShowOpenFolder(new [=chosen](paths) =>
					{
						chosen((paths.Length > 0) ? StringView(paths[0]) : default);
						delete chosen;
					}, "", false, 0);
			};
		seams.RevealFolder = new [=this](folder) =>
			{
				if ((mHost != null) && (mHost.Shell != null) && (mHost.Shell.Dialogs != null))
					mHost.Shell.Dialogs.OpenPath(folder);
			};
		let dialog = new TemplatesDialog(mContext, seams);
		dialog.Show(mUiHost.Context);
		return dialog;
	}

	/// The export dialog over the project's presets, reloaded from export_presets.xml.
	private void OpenExportPresetsPanel()
	{
		if (mProject == null)
		{
			mContext.Notify(.Info, "Open a project first.");
			return;
		}
		if (mUiHost == null)
			return;
		{
			let projectFs = scope NativeFileSystem(mProject.Directory);
			mPresetsController.Load(projectFs);
		}
		let seams = new ExportDialogSeams();
		seams.Refresh = new [=this](registry) => { BuildTemplateRegistryMainThread(registry); };
		seams.Save = new [=this]() => { SavePresetsController(); };
		seams.RunExport = new [=this](preset, all) => { RunExport(preset, all); };
		seams.OpenTemplates = new [=this]() => OpenTemplatesManager();
		seams.PickFiles = new [=this](chosen) =>
			{
				if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Dialogs == null))
				{
					mContext.Notify(.Error, "File dialogs are unavailable.");
					chosen(.());
					delete chosen;
					return;
				}
				mHost.Shell.Dialogs.ShowOpenFile(new [=chosen](paths) =>
					{
						chosen(paths);
						delete chosen;
					}, .(), "", true, 0);
			};
		seams.HostPlatform.Set(BuildLayout.HostPlatformName);
		Absolutize(PathJoin(mProject.Directory, "Dist", .. scope .()), seams.OutputRoot);
		let dialog = new ExportDialog(mContext, mPresetsController, seams);
		dialog.Show(mUiHost.Context);
	}
}
