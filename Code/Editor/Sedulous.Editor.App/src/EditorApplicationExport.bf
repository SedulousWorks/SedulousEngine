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

namespace Sedulous.Editor.App;

/// Export: a fresh template registry and presets run through the shared driver, the same
/// ExportOne and ExportAll the export CLI calls, in two safe phases so the UI never freezes:
/// a cook through the cook service, then, once it finishes, a background job that packs,
/// stages and copies the player, reader-only. Plus the two management surfaces over the
/// driver: the templates manager and the export-presets panel with its preset-editor form,
/// every view-destroying action deferred through the UI mutation queue.
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

	/// A labelled form row, fixed-width label plus the field growing to fill; answers the row
	/// so a caller can append trailing controls. Consumes the field reference.
	private FlexLayout AddFormRow(FlexLayout column, StringView label, View field)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8;
		let text = new Label(label);
		var narrow = LayoutStyle();
		narrow.Width = SizeSpec.Fixed(Unit.Dp(120));
		narrow.AlignSelf = .Center;
		row.AddView(text, narrow);
		if (field != null)
		{
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(field, grow);
		}
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(row, match);
		return row;
	}

	/// Swaps the open management dialog for a freshly built one: closes the current and runs
	/// open, on the mutation queue. Takes ownership of the delegate.
	private void QueueReplaceDialog(Dialog current, delegate void() open)
	{
		mUiHost.Context.MutationQueue.QueueAction(new [=current, =open]() =>
			{
				if (current != null)
					current.Close();
				open();
			} ~ delete open);
	}

	private void ReopenExportPresetsPanel(Dialog current) => QueueReplaceDialog(current, new () => { OpenExportPresetsPanel(); });
	private void ReopenTemplatesManager(Dialog current) => QueueReplaceDialog(current, new () => { OpenTemplatesManager(); });

	/// Persists the in-memory preset set to the project's export_presets.xml.
	private void SavePresetsController()
	{
		if (mProject == null)
			return;
		let projectFs = scope NativeFileSystem(mProject.Directory);
		if (mPresetsController.Save(projectFs) case .Err)
			mContext.Notify(.Error, "Saving export presets FAILED (see console).");
	}

	/// The additional-files list as the ";"-separated text of the Extra Files field.
	private static void JoinSemicolons(List<String> items, String outText)
	{
		for (int i < items.Count)
		{
			if (i > 0)
				outText.Append(";");
			outText.Append(items[i]);
		}
	}

	private static void SplitSemicolons(StringView text, List<String> outItems)
	{
		for (var part in text.Split(';'))
		{
			part.Trim();
			if (!part.IsEmpty)
				outItems.Add(new String(part));
		}
	}

	/// The native multi-select open file dialog appends the chosen paths to the Extra Files
	/// field; the field survives even if the form closes before the async dialog resolves.
	private void PickAdditionalFiles(EditText target)
	{
		if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Dialogs == null))
		{
			mContext.Notify(.Error, "File dialogs are unavailable.");
			return;
		}
		target.AddRef();
		mHost.Shell.Dialogs.ShowOpenFile(new [=target](paths) =>
			{
				defer target.ReleaseRef();
				if (paths.Length == 0)
					return; // cancelled
				let text = scope String(target.Text);
				for (let path in paths)
				{
					if (!text.IsEmpty && !text.EndsWith(";"))
						text.Append(";");
					text.Append(path);
				}
				target.SetText(text);
			}, .(), "", true, 0);
	}

	/// Imports a template bundle, a folder with a template.xml, into the templates root, then
	/// rebuilds the manager.
	private void ImportTemplateThenRefresh(Dialog current)
	{
		if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Dialogs == null))
		{
			mContext.Notify(.Error, "File dialogs are unavailable.");
			return;
		}
		mHost.Shell.Dialogs.ShowOpenFolder(new [=current, =this](paths) =>
			{
				if (paths.Length == 0)
					return; // cancelled: the manager stays open
				let id = scope String();
				if (ExportTemplates.Import(paths[0], TemplatesRoot(.. scope .()), id) case .Ok)
					mContext.Notify(.Success, scope $"Imported template '{id}'.");
				else
					mContext.Notify(.Error, "Import failed - the folder has no valid template.xml.");
				ReopenTemplatesManager(current);
			}, "", false, 0);
	}

	/// Creates a template bundle from a build directory holding the player and its runtime
	/// libraries, installing it into the templates root, then rebuilds the manager.
	private void CreateTemplateThenRefresh(Dialog current)
	{
		if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Dialogs == null))
		{
			mContext.Notify(.Error, "File dialogs are unavailable.");
			return;
		}
		mHost.Shell.Dialogs.ShowOpenFolder(new [=current, =this](paths) =>
			{
				if (paths.Length == 0)
					return;
				let id = scope String();
				let dir = scope String();
				if (ExportTemplates.Create(paths[0], TemplatesRoot(.. scope .()), .Install, id, dir) case .Ok)
					mContext.Notify(.Success, scope $"Created template '{id}'.");
				else
					mContext.Notify(.Error, "Create failed - pick a build dir containing the player.");
				ReopenTemplatesManager(current);
			}, "", false, 0);
	}

	/// The templates manager: every registry template with its platform, config and engine
	/// version and a soft engine-mismatch note; Import, Create and Remove (non-host only)
	/// mutate the templates root and rebuild this dialog.
	private void OpenTemplatesManager()
	{
		if (mUiHost == null)
			return;
		let registry = scope TemplateRegistry();
		BuildTemplateRegistryMainThread(registry);

		let dialog = new Dialog("Manage Export Templates");
		dialog.MinWidth.Value = 560.0f;
		dialog.MaxWidth.Value = 780.0f;
		dialog.MinHeight.Value = 240.0f;
		dialog.MaxHeight.Value = 560.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;
		column.AddView(new Label("Installed export templates (the host build is always available):"));

		for (int i < registry.Count)
		{
			let t = registry.At(i);
			if (t == null)
				continue;
			let text = scope String();
			text.AppendF("{}  [{}/{}]", t.Name, t.Platform, t.EffectiveConfig);
			if (!t.EngineVersion.IsEmpty)
				text.AppendF("  v{}", t.EngineVersion);
			if (t.IsHost)
				text.Append("  (host)");
			if (!ExportTemplates.EngineMatches(t))
				text.Append("  (!) engine mismatch");

			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 8;
			let label = new Label(text);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(label, grow);
			if (!t.IsHost) // the host template is synthesised, never on disk, so not removable
			{
				let id = new String(t.Id);
				let remove = new Button("Remove");
				remove.OnClick.Add(new [=dialog, =id, =this](b) =>
					{
						if (ExportTemplates.Remove(TemplatesRoot(.. scope .()), id) case .Ok)
							mContext.Notify(.Success, scope $"Removed template '{id}'.");
						else
							mContext.Notify(.Error, "Remove failed (see console).");
						ReopenTemplatesManager(dialog);
					} ~ delete id);
				row.AddView(remove);
			}
			column.AddView(row);
		}
		dialog.SetContent(column);

		let import = dialog.AddButton("Import...", .None);
		import.OnClick.Add(new [=dialog, =this](b) => { ImportTemplateThenRefresh(dialog); });
		let create = dialog.AddButton("Create...", .None);
		create.OnClick.Add(new [=dialog, =this](b) => { CreateTemplateThenRefresh(dialog); });
		dialog.AddButton("Close", .Cancel);
		dialog.Show(mUiHost.Context);
	}

	/// The export presets panel: the project's export_presets.xml reloaded into the
	/// controller, each preset with Export, Edit, Duplicate and Delete, plus Add, Export All
	/// and Manage Templates in the footer.
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
			mPresetsController.Load(projectFs); // reflects edits the form persisted
		}

		let dialog = new Dialog("Export");
		dialog.MinWidth.Value = 600.0f;
		dialog.MaxWidth.Value = 820.0f;
		dialog.MinHeight.Value = 220.0f;
		dialog.MaxHeight.Value = 560.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;
		column.AddView(new Label("Export presets (output directory: <project>/Dist):"));

		for (int i < mPresetsController.Count)
		{
			let p = mPresetsController.At(i);
			let text = scope String();
			text.AppendF("{}  [{}/{}]", p.Name, p.Platform.IsEmpty ? "?" : StringView(p.Platform), p.EffectiveConfig);

			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6;
			let label = new Label(text);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(label, grow);
			let name = new String(p.Name);
			let index = i;
			let export = new Button("Export");
			export.OnClick.Add(new [=dialog, =name, =this](b) =>
				{
					RunExport(name, false);
					dialog.Close(.OK);
				} ~ delete name);
			row.AddView(export);
			let edit = new Button("Edit");
			edit.OnClick.Add(new [=dialog, =index, =this](b) =>
				{
					let current = new ExportPreset();
					mPresetsController.At(index).CopyTo(current);
					QueueReplaceDialog(dialog, new [=current, =index, =this]() => { OpenPresetEditor(current, index); } ~ delete current);
				});
			row.AddView(edit);
			let duplicate = new Button("Duplicate");
			duplicate.OnClick.Add(new [=dialog, =index, =this](b) =>
				{
					mPresetsController.Duplicate(index);
					SavePresetsController();
					ReopenExportPresetsPanel(dialog);
				});
			row.AddView(duplicate);
			let remove = new Button("Delete");
			remove.OnClick.Add(new [=dialog, =index, =this](b) =>
				{
					mPresetsController.Remove(index);
					SavePresetsController();
					ReopenExportPresetsPanel(dialog);
				});
			row.AddView(remove);
			column.AddView(row);
		}
		dialog.SetContent(column);

		let add = dialog.AddButton("Add...", .None);
		add.OnClick.Add(new [=dialog, =this](b) =>
			{
				let fresh = new ExportPreset();
				fresh.Name.Set("New Preset");
				fresh.Platform.Set(BuildLayout.HostPlatformName);
				QueueReplaceDialog(dialog, new [=fresh, =this]() => { OpenPresetEditor(fresh, -1); } ~ delete fresh);
			});
		let exportAll = dialog.AddButton("Export All", .None);
		exportAll.OnClick.Add(new [=dialog, =this](b) =>
			{
				RunExport("", true);
				dialog.Close(.OK);
			});
		let templates = dialog.AddButton("Manage Templates...", .None);
		templates.OnClick.Add(new [=dialog, =this](b) => { QueueReplaceDialog(dialog, new () => { OpenTemplatesManager(); }); });
		dialog.AddButton("Close", .Cancel);
		dialog.Show(mUiHost.Context);
	}

	/// The preset-editor form: name, a template dropdown (setting the template id and
	/// deriving platform and config) or the explicit platform and config when "resolve by"
	/// is chosen, player name, output subdir, extra files with a native picker, and the
	/// symbols and prune toggles. Save writes through the controller, Add or Update, persists,
	/// and returns to the panel; Cancel just returns. Borrows the initial preset.
	private void OpenPresetEditor(ExportPreset initial, int editIndex)
	{
		if (mUiHost == null)
			return;
		let registry = scope TemplateRegistry();
		BuildTemplateRegistryMainThread(registry);

		let dialog = new Dialog((editIndex < 0) ? "Add Export Preset" : "Edit Export Preset");
		dialog.MinWidth.Value = 600.0f;
		dialog.MaxWidth.Value = 820.0f;
		dialog.MinHeight.Value = 340.0f;
		dialog.MaxHeight.Value = 640.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		let nameEdit = new EditText();
		nameEdit.SetText(initial.Name);
		AddFormRow(column, "Name", nameEdit);

		// The template dropdown: index 0 resolves by platform and config; each later item maps
		// to a concrete template id with its platform and config, in the parallel lists.
		let templateCombo = new ComboBox();
		templateCombo.AddItem("(resolve by platform + config below)");
		let comboIds = new List<String>();
		let comboPlatforms = new List<String>();
		let comboConfigs = new List<String>();
		comboIds.Add(new String());
		comboPlatforms.Add(new String());
		comboConfigs.Add(new String());
		int32 selectedCombo = 0;
		for (int i < registry.Count)
		{
			let t = registry.At(i);
			if (t == null)
				continue;
			let item = scope String();
			item.AppendF("{} [{}/{}]", t.Name, t.Platform, t.EffectiveConfig);
			if (t.IsHost)
				item.Append(" (host)");
			let idx = templateCombo.AddItem(item);
			comboIds.Add(new String(t.Id));
			comboPlatforms.Add(new String(t.Platform));
			comboConfigs.Add(new String(t.EffectiveConfig));
			if (!initial.TemplateId.IsEmpty && (initial.TemplateId == t.Id))
				selectedCombo = idx;
		}
		templateCombo.SetSelectedIndex(selectedCombo);
		AddFormRow(column, "Template", templateCombo);

		let platformEdit = new EditText();
		platformEdit.SetText(initial.Platform);
		platformEdit.Placeholder.Value.Set(BuildLayout.HostPlatformName);
		AddFormRow(column, "Platform", platformEdit);

		let configEdit = new EditText();
		configEdit.SetText(initial.Config);
		configEdit.Placeholder.Value.Set("Release");
		AddFormRow(column, "Config", configEdit);

		let playerEdit = new EditText();
		playerEdit.SetText(initial.PlayerName);
		playerEdit.Placeholder.Value.Set("(template default)");
		AddFormRow(column, "Player name", playerEdit);

		let subdirEdit = new EditText();
		subdirEdit.SetText(initial.OutputSubdir);
		subdirEdit.Placeholder.Value.Set("(sanitized name)");
		AddFormRow(column, "Output subdir", subdirEdit);

		let filesEdit = new EditText();
		filesEdit.SetText(JoinSemicolons(initial.AdditionalFiles, .. scope .()));
		filesEdit.Placeholder.Value.Set("icon.ico;config.xml");
		let filesRow = AddFormRow(column, "Extra files", filesEdit);
		let browse = new Button("Add Files...");
		browse.OnClick.Add(new [=filesEdit, =this](b) => { PickAdditionalFiles(filesEdit); });
		filesRow.AddView(browse);

		let symbolsCheck = new CheckBox("Stage debug symbols into the dist", initial.StageSymbols);
		column.AddView(symbolsCheck);
		let pruneCheck = new CheckBox("Prune to reachable content only", initial.PruneToReachable);
		column.AddView(pruneCheck);
		dialog.SetContent(column);
		dialog.OnClosed.Add(new [=comboIds, =comboPlatforms, =comboConfigs](d, result) =>
			{
				DeleteContainerAndItems!(comboIds);
				DeleteContainerAndItems!(comboPlatforms);
				DeleteContainerAndItems!(comboConfigs);
			});

		let save = dialog.AddButton("Save", .None);
		save.OnClick.Add(new [=dialog, =editIndex, =nameEdit, =templateCombo, =platformEdit, =configEdit, =playerEdit, =subdirEdit,
			=filesEdit, =symbolsCheck, =pruneCheck, =comboIds, =comboPlatforms, =comboConfigs, =this](b) =>
			{
				let result = scope ExportPreset();
				result.Name.Set(nameEdit.Text);
				let sel = templateCombo.SelectedIndex;
				if ((sel > 0) && (sel < comboIds.Count))
				{
					result.TemplateId.Set(comboIds[sel]);
					result.Platform.Set(comboPlatforms[sel]);
					result.Config.Set(comboConfigs[sel]);
				}
				else
				{
					result.Platform.Set(platformEdit.Text);
					result.Config.Set(configEdit.Text);
				}
				result.PlayerName.Set(playerEdit.Text);
				result.OutputSubdir.Set(subdirEdit.Text);
				result.StageSymbols = symbolsCheck.IsChecked.Value;
				result.PruneToReachable = pruneCheck.IsChecked.Value;
				SplitSemicolons(filesEdit.Text, result.AdditionalFiles);

				if (editIndex < 0)
					mPresetsController.Add(result);
				else
					mPresetsController.Update(editIndex, result);
				SavePresetsController();
				ReopenExportPresetsPanel(dialog);
			});
		let cancel = dialog.AddButton("Cancel", .None);
		cancel.OnClick.Add(new [=dialog, =this](b) => { ReopenExportPresetsPanel(dialog); });
		dialog.Show(mUiHost.Context);
	}
}
