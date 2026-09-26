using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.App;

/// The project lifecycle: the built-in project manager opens and closes projects at runtime.
/// Native game modules are not supported: the manifest's NativeModule is left alone.
extension EditorApplication
{
	/// Loads the per-user editor settings from <user-data>/editor.settings.xml, registering
	/// the section types first. Absent on a first run, the store stays empty and the sections
	/// read as defaults.
	private void LoadEditorSettings()
	{
		EditorSerializables.RegisterAll();
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		if (EditorSettingsStore.LoadFromUserData(mEditorSettings) case .Err(let error))
		{
			// NotFound is fine; anything else means the store loaded partially, since Settings
			// aborts at the first uninstantiable section, and a later save would rewrite the
			// file from that gutted store, losing the dropped sections.
			if (error != .NotFound)
				GlobalLog(.Error, "Editor: editor.settings.xml load FAILED (partial store), check for unregistered section types; later saves may drop sections");
		}
	}

	/// Opens and wires a project end to end: the manifest (with the CLI scaffold fallback),
	/// favourites, resources late-attached to the embedded runtime, the cook service and
	/// assets view, the saved pages and dock layout, the recent-projects touch. Swaps the
	/// window to the editor shell when the manager was showing.
	private void OpenProjectAt(StringView directory)
	{
		if (directory.IsEmpty)
		{
			mContext.SetStatus("No project directory - pass one on the command line.");
			return;
		}

		mProject = EditorProject.Open(directory);
		if ((mProject == null) && !mConfig.StartInProjectManager)
		{
			// A CLI launch keeps the scaffold fallback: a bare directory becomes a fresh
			// project. The manager scaffolds only through its explicit New Project flow.
			if (EditorProject.Create(directory, mConfig.ProjectName) case .Ok)
			{
				mProject = EditorProject.Open(directory);
				mSeedAfterOpen = (mProject != null) && mConfig.SeedOnScaffold;
			}
		}

		if (mProject == null)
		{
			let message = scope $"Failed to open project: {directory}";
			mContext.SetStatus(message);
			if (mManagerView != null)
				mManagerView.SetStatus(message);
			return;
		}

		mContext.SetProject(mProject);
		{
			// The thumbnail cache under the project's gitignored .cache.
			let thumbsDir = scope String();
			PathJoin(mProject.CacheRoot(.. scope .()), "thumbs", thumbsDir);
			CreateDirectory(thumbsDir);
			let project = mProject;
			mThumbnailService.Configure(thumbsDir,
				new [=project](id) => project.SourceDb.GetInstance(id),
				mJobService,
				new (id) => mCookService.RecipeHashFor(id),
				mProject.SourcesRoot(.. scope .()));
		}

		// Showing the manager? The window swaps to the editor shell first, so the status bar
		// narrates the rest of the open.
		if (mInManagerMode)
		{
			if (let mainRw = mHost.MainRenderWindow)
			{
				mUiHost.DetachWindow(mainRw);
				mShell.Root.AddRef();
				mUiHost.AttachWindow(mainRw, mShell.Root);
			}
			mInManagerMode = false;
		}

		// The per-project editor-state store: one structured file for the dock layout,
		// favourites, open pages and per-page prefs. Absent on a fresh project.
		mProjectEditorSettings = new Settings();
		if (ProjectEditorSettings.Load(mProjectEditorSettings, mProject.EditorStateRoot(.. scope .())) case .Err(let error))
		{
			if (error != .NotFound)
				GlobalLog(.Error, "Editor: editor.project.settings.xml load FAILED (partial store), check for unregistered section types; later saves may drop sections");
		}
		mContext.ProjectEditorSettings = mProjectEditorSettings;
		delete mContext.OnProjectEditorSettingsSaveRequested;
		mContext.OnProjectEditorSettingsSaveRequested = new () =>
			{
				if ((mProject != null) && (mProjectEditorSettings != null))
					ProjectEditorSettings.Save(mProjectEditorSettings, mProject.EditorStateRoot(.. scope .())).IgnoreError();
			};

		// The per-user pinned assets; the browser and picker surface them first.
		ProjectEditorSettings.ApplyFavorites(mContext, mProjectEditorSettings);
		delete mContext.OnFavoritesChanged;
		mContext.OnFavoritesChanged = new () =>
			{
				if ((mProject != null) && (mProjectEditorSettings != null))
				{
					ProjectEditorSettings.CaptureFavorites(mContext, mProjectEditorSettings);
					mContext.RequestProjectEditorSettingsSave();
				}
			};

		// The per-project resources over the cooked database, late-attached to the embedded
		// runtime; the global job system serves async resource decode, null meaning sync.
		mResources = new ResourceManager(mProject.CookedDb, HasGlobalJobSystem() ? GlobalJobs() : null);
		for (let factory in mResourceFactories)
			mResources.AddFactory(factory);
		mContext.Resources = mResources;
		mEmbeddedApp.AttachResourceManager(mResources, mEmbeddedHost);

		// The GPU half of thumbnails, constructed after the resource manager exists since the
		// stage captures it. The host is the embedded one: scene and render subsystems live on
		// the embedded runtime context. Destroyed in CloseProject before the service resets.
		mThumbnailStage = new ThumbnailStage(mEmbeddedHost, mThumbnailService, mResources);
		// Scripted scene loads resolve scene and prefab content out of the project's source
		// database, the same one the Game tab's default-scene boot reads.
		mEmbeddedApp.SetContentDatabase(mProject.SourceDb);
		ApplyProjectUiDefaults();
		if ((mEmbeddedApp.UI != null) && !mProject.Settings.DefaultUiFontId.IsSet && ProjectHasFontAssets(mProject.SourceDb.RootGroup))
		{
			// A real project with fonts but no default set renders no game-UI text; the fix is
			// named.
			GlobalLog(.Warning, "UI: game UI has no default font, set Project Settings > Default UI font (the project has fonts, but none is the default, so game-UI text will not render)");
		}

		// Settings-derived session state re-applies on save.
		delete mContext.OnProjectSettingsChanged;
		mContext.OnProjectSettingsChanged = new () => { ApplyProjectUiDefaults(); };

		// The cook service and the real Assets panel.
		mCookService.Initialize(mProject, mBuilders);
		// Pages request re-cooks after saving builder-backed assets.
		delete mContext.OnCookRequested;
		mContext.OnCookRequested = new (rebuild) => { mCookService.RequestCook(rebuild); };
		// Cook-gated starts: busy is anything in flight or a remembered mid-cook request
		// still waiting to re-issue.
		delete mContext.CookBusy;
		mContext.CookBusy = new () => mCookService.IsReady && !mCookService.IsIdle;
		StartMcpHost(); // the agent surface over this project, if enabled
		// Background jobs read the source database structure and pack cooked files from their
		// worker: database mutations and new cooks hold off while one runs.
		delete mCookService.ExternalMutationLock;
		mCookService.ExternalMutationLock = new () => mJobService.IsBusy;
		mContext.Jobs = mJobService; // pages submit light work here
		// Ready thumbnails rebind the browser; inspector slots re-query per refresh.
		delete mThumbnailService.OnThumbnailReady;
		mThumbnailService.OnThumbnailReady = new (id) =>
			{
				if (mAssetsView != null)
					mAssetsView.RefreshThumbnail(id);
			};
		mAssetsView = new AssetsView(mContext, mCookService, mJobService);
		let assets = mAssetsView;
		mAssetsView.OnOpenInstance = new (instance) => { OpenInstancePage(instance); };
		// The asset-slot affordances: guid to instance to the same page path the browser's
		// double-click takes; a claimant may take the open first.
		delete mContext.RevealAsset;
		mContext.RevealAsset = new [=assets](id) => { assets.Reveal(id); };
		delete mContext.OpenAsset;
		mContext.OpenAsset = new (id) =>
			{
				if (mProject == null)
					return;
				if (let instance = mProject.SourceDb.GetInstance(id))
				{
					if (mContext.TryInterceptOpenAsset(instance))
						return;
					OpenInstancePage(instance);
				}
			};
		mAssetsView.OnCreate = new (creator, group) => { CreateAndOpen(creator, group); };
		// Import... in the browser menu: the native file dialog, then each picked file routes
		// through the import flow.
		mAssetsView.OnBrowseImport = new () =>
			{
				if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Dialogs == null))
				{
					mContext.Notify(.Error, "File dialogs are unavailable.");
					return;
				}
				mHost.Shell.Dialogs.ShowOpenFile(new (paths) =>
					{
						if (mAssetsView == null)
							return;
						let views = scope List<StringView>();
						for (let path in paths)
							views.Add(path);
						mAssetsView.ImportFiles(views);
					}, .(), "", true, 0);
			};
		// The delete-while-open policy: close, then delete. From a mutation-queue action, so
		// synchronous panel and page teardown is safe, the same pair the tab close triggers.
		mAssetsView.OnCloseInstancePage = new (id) =>
			{
				for (int i < mPagePanels.Count)
				{
					if (mPagePanels[i].Page.InstanceId == id)
					{
						let panel = mPagePanels[i].Panel;
						let page = mPagePanels[i].Page;
						mShell.Docks.ClosePanel(panel);
						ClosePage(page);
						return;
					}
				}
			};
		delete mCookService.OnCookFinished;
		mCookService.OnCookFinished = new [=assets, =this]() =>
			{
				mThumbnailService.InvalidateAll(); // recipe hashes moved; the disk absorbs unchanged
				assets.Rebuild();
				// The result toast: failures are sticky, the Console has the log; silent when the
				// cook was a no-op, since the watcher fires those constantly.
				let failed = mCookService.LastCookSummary.Failed;
				let cooked = mCookService.LastCookSummary.Cooked;
				if (failed > 0)
					ShowToast(.Error, scope $"Cook: {failed} failed, {cooked} cooked (see Console).");
				else if (cooked > 0)
					ShowToast(.Success, scope $"Cook finished: {cooked} asset(s).");
				// A finished cook may have created products the open-time bind missed.
				ApplyProjectUiDefaults();
				// Hot reload: rebuilt products swap in behind the proxy handles, live scenes
				// seeing the new resources with no reopen.
				if (mResources != null)
				{
					for (let product in mCookService.LastCookedProducts)
						mResources.Reload(product);
				}
			};
		mAssetsView.AddRef();
		mShell.SetAssetsContent(mAssetsView);

		// The pages from the last session reopen, falling back to the default document, then
		// the dock layout restores so page panels land back in their arrangement: the panels
		// carry guid persistence ids, and the layout only reconstitutes once they exist.
		{
			let pages = scope List<Guid>();
			if (ProjectEditorSettings.ApplyOpenPages(mProjectEditorSettings, pages, let activePage) case .Ok)
			{
				UIEditorPage toActivate = null;
				for (let id in pages)
				{
					if (let instance = mProject.SourceDb.GetInstance(id))
					{
						let page = OpenInstancePage(instance);
						if ((page != null) && (id == activePage))
							toActivate = page;
					}
				}
				if (toActivate != null)
					mContext.SetActivePage(toActivate);
			}
			else
			{
				// No saved page set, the first launch: the default scene, guid first, the
				// path mirror for guid-less manifests.
				Instance instance = null;
				if (mProject.Settings.DefaultSceneId.IsSet)
					instance = mProject.SourceDb.GetInstance(mProject.Settings.DefaultSceneId);
				if ((instance == null) && !mProject.Settings.DefaultScene.IsEmpty)
					instance = mProject.SourceDb.GetInstanceByPath(mProject.Settings.DefaultScene);
				if (instance != null)
					OpenInstancePage(instance);
			}
			mShell.RestoreLayout(mProjectEditorSettings).IgnoreError();
		}

		// The open records in the per-user registry, most recent first.
		mProjectManager.NoteOpened(directory, mProject.Name, mProject.Settings.EngineVersion);
		EditorSettingsStore.SaveToUserData(mEditorSettings).IgnoreError();

		// Starter content for a manager-created project: once, before the first cook pass
		// picks everything up.
		if (mSeedAfterOpen)
		{
			mSeedAfterOpen = false;
			if (mConfig.SeedNewProject != null)
			{
				mConfig.SeedNewProject(mContext, mProject);
				mProject.SaveSettings().IgnoreError(); // the seed set manifest defaults
				if (mAssetsView != null)
					mAssetsView.Rebuild();
				mCookService.RequestCook(false);
				mContext.SetStatus("Project created with starter content.");
			}
		}

		mContext.SetStatus(scope $"Project: {mProject.Name}  ({mProject.Directory})");
	}

	/// Does the source database hold any FontAsset, recursively? Answers "the project has
	/// fonts but none is the default", so the game UI can warn actionably.
	private static bool ProjectHasFontAssets(Group group)
	{
		if (group == null)
			return false;
		for (let instance in group.Instances)
		{
			if (instance.TypeName == "FontAsset")
				return true;
		}
		for (let child in group.Groups)
		{
			if (ProjectHasFontAssets(child))
				return true;
		}
		return false;
	}

	/// The MCP host rides the project: started, when the preference or --mcp enables it, once
	/// the project's services are up.
	private void StartMcpHost()
	{
		StopMcpHost();
		let settings = mEditorSettings.Section<EditorMcpSettings>();
		if (!(settings.Enabled || mConfig.McpEnabled) || (mProject == null))
			return;
		if (mConfig.LogBuffer == null)
		{
			GlobalLog(.Warning, "MCP: no log capture was installed, the host is not started");
			return;
		}
		if (settings.Token.IsEmpty)
		{
			// First enable: mint the secret once and keep it, so the token file and the
			// Preferences display stay valid across runs.
			EditorMcpSettings.GenerateToken(settings.Token);
			if (EditorSettingsStore.SaveToUserData(mEditorSettings) case .Err)
				GlobalLog(.Warning, "MCP: the minted token could not be saved to the editor settings; it changes on the next run");
		}
		let paths = scope EngineToolPaths();
		paths.LocateShippingDocs(scope StringView[](GetExecutableDirectory(.. scope .()), GetCurrentDirectory(.. scope .())));
		mMcpSession.Project = mProject;
		// The export stages the player from beside this executable and cooks shaders from the
		// data root: the same two things the stdio host hands its inline operations.
		mMcpOperations = new InlineProjectOperations(mMcpSession, mBuilders,
			BuildLayout.PlayerDirectoryBeside(GetExecutableDirectory(.. scope .()), .. scope .()), mConfig.DataRoot);
		mMcpHost = new EditorMcpHost(mMcpSession, mConfig.LogBuffer, mBuilders, mContext.Importers,
			paths, mMcpOperations, BuildStamp(.. scope .()));
		mMcpHost.OnToolFinished = new (tool, isError) =>
			{
				mContext.SetStatus(scope $"MCP: {tool} {isError ? "failed" : "done"}");
			};
		EditorMcpHostConfig config = .();
		config.Port = (uint16)((mConfig.McpPort != 0) ? mConfig.McpPort : settings.Port);
		config.Token = settings.Token;
		let userData = GetUserDataDirectory(.. scope .());
		config.TokenFileDirectory = userData;
		if (!mMcpHost.Start(config))
		{
			GlobalLog(.Warning, scope $"MCP: could not listen on 127.0.0.1:{config.Port}, another editor may hold the port; pass --mcp-port <n> or change it in Preferences");
			StopMcpHost();
			return;
		}
		GlobalLog(.Information, scope $"MCP: listening on 127.0.0.1:{mMcpHost.BoundPort} (the token is in <user-data>/{EditorMcpHost.cTokenFileName})");
		mContext.SetStatus(scope $"MCP host on 127.0.0.1:{mMcpHost.BoundPort}");
	}

	/// Stops and releases the host, before the project's services go; a waiting agent sees
	/// its connection close.
	private void StopMcpHost()
	{
		DeleteAndNullify!(mMcpHost);
		DeleteAndNullify!(mMcpOperations);
		mMcpSession.Project = null;
	}

	/// The inverse of OpenProjectAt: saves the layout and pages, closes every page, shuts
	/// the cook service down, detaches the resources from the embedded runtime, releases
	/// the project, and returns to the manager. Pages must already be clean or confirmed.
	private void CloseProject()
	{
		if (mProject == null)
		{
			EnterManagerMode();
			return;
		}
		StopMcpHost(); // no agent call may run against services that are going away
		mCookService.Shutdown(); // joins any in-flight cook before the databases go away
		DeleteAndNullify!(mThumbnailStage); // unstages and drops GPU objects while the renderer lives
		mThumbnailService.Reset(); // in-flight slots outlive harmlessly; entries drop
		SaveLayout();
		// Every page closes: the tab-close pair, panel then page, applied to all. ClosePage
		// erases the entry, so the drain runs from the front.
		while (!mPagePanels.IsEmpty)
		{
			let entry = mPagePanels[0];
			if ((mShell.Docks != null) && (entry.Panel != null))
				mShell.Docks.ClosePanel(entry.Panel);
			ClosePage(entry.Page);
		}
		mGamePage = null;
		mShell.SetAssetsContent(null);
		if (mAssetsView != null)
		{
			mAssetsView.ReleaseRef();
			mAssetsView = null;
		}
		DeleteAndNullify!(mContext.OnCookRequested);
		DeleteAndNullify!(mContext.CookBusy);
		DeleteAndNullify!(mContext.OnFavoritesChanged);
		// The per-project resources detach from the embedded runtime before they are
		// destroyed; its consumers are lazy and null-tolerant between projects.
		if (mEmbeddedApp != null)
		{
			mEmbeddedApp.AttachResourceManager(null, mEmbeddedHost);
			// The source database belongs to the project destroyed below; null is the safe
			// idle state between projects.
			mEmbeddedApp.SetContentDatabase(null);
			if (mEmbeddedApp.UI != null)
				mEmbeddedApp.UI.SetDefaultTheme(null);
		}
		mContext.Resources = null;
		DeleteAndNullify!(mResources);
		mContext.ProjectEditorSettings = null;
		DeleteAndNullify!(mContext.OnProjectEditorSettingsSaveRequested);
		DeleteAndNullify!(mProjectEditorSettings);
		mContext.SetProject(null);
		DeleteAndNullify!(mProject);
		mContext.SetStatus("Project closed.");
		EnterManagerMode();
	}

	/// Shows the manager screen, building it on first use; swaps the window root.
	private void EnterManagerMode()
	{
		let mainRw = (mHost != null) ? mHost.MainRenderWindow : null;
		if (mainRw == null)
			return;
		if (mManagerView == null)
		{
			mManagerView = new ProjectManagerView();
			// Open and Create swap the window's root, detaching the manager view whose button
			// is mid dispatch: deferred through the mutation queue, like Close Project.
			mManagerView.OnOpenProject = new (dir) =>
				{
					let path = new String(dir);
					mUiHost.Context.MutationQueue.QueueAction(new [=path, =this]() => { OpenFromManager(path); } ~ delete path);
				};
			mManagerView.OnCreateProject = new (dir, name) =>
				{
					let path = new String(dir);
					let projectName = new String(name);
					mUiHost.Context.MutationQueue.QueueAction(new [=path, =projectName, =this]() => { CreateFromManager(path, projectName); } ~ { delete path; delete projectName; });
				};
			mManagerView.OnStoreChanged = new () => { EditorSettingsStore.SaveToUserData(mEditorSettings).IgnoreError(); };
			mManagerView.Build(mProjectManager, mHost.Shell.Dialogs, mUiHost.Context, mainRw.Window.Width, mainRw.Window.Height);
		}
		else
		{
			mManagerView.Rebuild(); // returning from a project: the rows re-probe
		}
		if (!mInManagerMode)
		{
			mUiHost.DetachWindow(mainRw);
			mManagerView.Root.AddRef();
			mUiHost.AttachWindow(mainRw, mManagerView.Root);
			mInManagerMode = true;
		}
	}

	/// The controller decides (probe, version relation, prompt copy); this only renders the
	/// prompt gates and runs the open it owns.
	private void OpenFromManager(StringView directory)
	{
		let decision = scope ProjectOpenDecision();
		mProjectManager.DecideOpen(directory, decision);
		if (decision.Gate == .NotAProject)
		{
			if (mManagerView != null)
				mManagerView.SetStatus("Not a project (no Project.xml there).");
			return;
		}
		if (decision.Gate == .OpenDirectly)
		{
			OpenProjectAt(directory);
			return;
		}

		let dir = new String(directory);
		let dialog = new Dialog(decision.PromptTitle);
		let label = new Label(decision.PromptBody);
		label.WordWrap.Value = true;
		dialog.SetContent(label);
		dialog.OnClosed.Add(new [=dir](d, result) => { delete dir; });

		if (decision.Gate == .PromptNewerEngine)
		{
			let openAnyway = dialog.AddButton("Open Anyway", .None);
			openAnyway.OnClick.Add(new [=dialog, =dir, =this](b) =>
				{
					dialog.Close(.OK);
					OpenProjectAt(dir);
				});
		}
		else // PromptOlderBackup: the backup-and-upgrade prompt
		{
			let backupOpen = dialog.AddButton("Back Up & Open", .None);
			backupOpen.OnClick.Add(new [=dialog, =dir, =this](b) =>
				{
					dialog.Close(.OK);
					if (mProjectManager.BackupManifest(dir, scope .()) case .Err)
					{
						if (mManagerView != null)
							mManagerView.SetStatus("Backup FAILED - not opening.");
						return;
					}
					OpenProjectAt(dir);
					if (mProject != null)
						mProject.SaveSettings().IgnoreError(); // re-stamped to this engine
				});
			let openOnly = dialog.AddButton("Open Without Backup", .None);
			openOnly.OnClick.Add(new [=dialog, =dir, =this](b) =>
				{
					dialog.Close(.OK);
					OpenProjectAt(dir);
					if (mProject != null)
						mProject.SaveSettings().IgnoreError();
				});
		}
		dialog.AddButton("Cancel", .Cancel);
		dialog.Show(mUiHost.Context);
	}

	private void CreateFromManager(StringView directory, StringView name)
	{
		if (mProjectManager.Create(directory, name) case .Err(let error))
		{
			if (mManagerView != null)
				mManagerView.SetStatus((error == .AlreadyExists) ? "That directory is already a project." : "Create failed (path writable?).");
			return;
		}
		mSeedAfterOpen = true; // the starter content lands once the fresh project opens
		OpenProjectAt(directory);
	}

	/// File > Close Project: the dirty-pages prompt, then CloseProject, always queued since it
	/// destroys panels and pages.
	private void ConfirmCloseProjectThen()
	{
		if ((mProject == null) || mInManagerMode)
			return;
		let dirtyCount = DirtyPageCount();
		if (dirtyCount == 0)
		{
			QueueCloseProject();
			return;
		}
		let dialog = new Dialog("Unsaved changes");
		let label = new Label(DirtyMessage(dirtyCount, .. scope .()));
		label.WordWrap.Value = true;
		dialog.SetContent(label);
		let saveAll = dialog.AddButton("Save All & Close Project", .None);
		saveAll.OnClick.Add(new [=dialog, =this](b) =>
			{
				let allSaved = SaveAllDirtyPages();
				if (allSaved)
					QueueCloseProject();
				else
					mContext.Notify(.Error, "Save FAILED (see console) - staying open.");
				dialog.Close(allSaved ? .OK : .Cancel);
			});
		let discard = dialog.AddButton("Close Without Saving", .None);
		discard.OnClick.Add(new [=dialog, =this](b) =>
			{
				QueueCloseProject();
				dialog.Close(.OK);
			});
		dialog.AddButton("Cancel", .Cancel);
		dialog.Show(mUiHost.Context);
	}

	private void QueueCloseProject() => mUiHost.Context.MutationQueue.QueueAction(new () => { CloseProject(); });

	private int DirtyPageCount()
	{
		int count = 0;
		for (let entry in mPagePanels)
		{
			if (entry.Page.IsDirty)
				count++;
		}
		return count;
	}

	private static void DirtyMessage(int dirtyCount, String outMessage)
	{
		outMessage.AppendF("{} {}", dirtyCount, (dirtyCount == 1) ? "page has unsaved changes." : "pages have unsaved changes.");
	}

	private bool SaveAllDirtyPages()
	{
		bool allSaved = true;
		for (let entry in mPagePanels)
		{
			if (entry.Page.IsDirty && (entry.Page.Save() case .Err))
				allSaved = false;
		}
		return allSaved;
	}

	/// True when nothing is dirty and exit may proceed. Otherwise the exit prompt shows and
	/// its buttons finish the job: save all and exit, discard and exit, or cancel.
	private bool ConfirmExitAllowed()
	{
		let dirtyCount = DirtyPageCount();
		if (dirtyCount == 0)
			return true;
		let dialog = new Dialog("Unsaved changes");
		let label = new Label(DirtyMessage(dirtyCount, .. scope .()));
		label.WordWrap.Value = true;
		dialog.SetContent(label);
		let saveAll = dialog.AddButton("Save All & Exit", .None);
		saveAll.OnClick.Add(new [=dialog, =this](b) =>
			{
				let allSaved = SaveAllDirtyPages();
				if (allSaved)
					mHost.RequestExit();
				else
					mContext.Notify(.Error, "Save FAILED (see console) - staying open.");
				dialog.Close(allSaved ? .OK : .Cancel);
			});
		let discard = dialog.AddButton("Exit Without Saving", .None);
		discard.OnClick.Add(new [=dialog, =this](b) =>
			{
				mHost.RequestExit();
				dialog.Close(.OK);
			});
		dialog.AddButton("Cancel", .Cancel);
		dialog.Show(mUiHost.Context);
		return false;
	}

	/// File > New <creator>: creates the source instance, remembers it as the project's
	/// default document if none is set yet, opens it.
	private void CreateAndOpen(AssetCreator creator, Group group = null)
	{
		// The cook gate: the plan worker reads the databases with their structure frozen.
		if (mCookService.MutationLocked)
		{
			mCookService.RunWhenIdle(new [=creator, =group, =this]() => { CreateAndOpen(creator, group); });
			mContext.Notify(.Info, "Create queued until the current cook finishes.");
			return;
		}
		let instance = creator.Run(mContext, group);
		if (instance == null)
		{
			mContext.Notify(.Error, "Create failed (no project open?).");
			return;
		}
		if (creator.SetsDefaultScene && (mProject != null) && !mProject.Settings.DefaultSceneId.IsSet && mProject.Settings.DefaultScene.IsEmpty)
		{
			mProject.Settings.DefaultSceneId = instance.Id;
			instance.GetPath(mProject.Settings.DefaultScene..Clear());
			mProject.SaveSettings().IgnoreError();
		}
		// The new row surfaces immediately, since the File-menu path bypasses the assets
		// view's own rebuild, and cooks so builder-backed assets become pickable.
		if (mAssetsView != null)
			mAssetsView.Rebuild();
		if (mBuilders.FindByTypeName(instance.TypeName) != null)
			mCookService.RequestCook(false);
		OpenInstancePage(instance);
	}

	/// Save As: writes the page's current content to a new asset beside the original and
	/// rebinds the page to it. The original keeps its on-disk state.
	private void SaveActivePageAs()
	{
		let page = mContext.ActivePage;
		if ((page == null) || (mProject == null) || (mUiHost == null))
			return;
		let original = mProject.SourceDb.GetInstance(page.InstanceId);
		if (original == null)
		{
			mContext.Notify(.Warning, "This page has no source asset to copy.");
			return;
		}
		let group = original.OwningGroup;
		let typeName = new String(original.TypeName);
		let suggested = scope String(original.Name);
		suggested.Append(" Copy");
		while (group.GetInstance(suggested) != null)
			suggested.Append(" Copy");

		let dialog = new Dialog("Save As");
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6.0f;
		let label = new Label(scope $"New name (created next to '{original.Name}'):");
		label.WordWrap.Value = true;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(label, match);
		let nameEdit = new EditText();
		nameEdit.SetText(suggested);
		column.AddView(nameEdit, match);
		// The inline validation line: empty until a rejected attempt; the dialog stays up.
		let errorLabel = new Label();
		errorLabel.WordWrap.Value = true;
		errorLabel.TextColor.Value = Color(0.90f, 0.35f, 0.35f, 1.0f);
		column.AddView(errorLabel, match);
		dialog.SetContent(column);
		dialog.OnClosed.Add(new [=typeName](d, result) => { delete typeName; });

		let pageId = page.InstanceId;
		let save = dialog.AddButton("Save", .None);
		save.OnClick.Add(new [=pageId, =group, =typeName, =dialog, =nameEdit, =errorLabel, =this](b) =>
			{
				let newName = nameEdit.Text;
				if (newName.IsEmpty)
				{
					errorLabel.SetText("NOT saved: enter a name.");
					return;
				}
				if (group.GetInstance(newName) != null)
				{
					errorLabel.SetText("NOT saved: that name already exists in the group.");
					return;
				}
				// The page re-resolves: pages can close under the dialog.
				EditorPage target = null;
				for (let open in mContext.OpenPages)
				{
					if (open.InstanceId == pageId)
					{
						target = open;
						break;
					}
				}
				if (target == null)
				{
					dialog.Close(.Cancel);
					return;
				}
				let fresh = group.CreateInstance(newName, typeName);
				if (fresh == null)
				{
					mContext.Notify(.Error, "NOT saved: could not create the new asset.");
					return;
				}
				target.OnSavedAs(fresh);
				if (target.Save() case .Ok)
					mContext.Notify(.Success, scope $"Saved as '{fresh.Name}'.");
				else
					mContext.Notify(.Error, "Save As FAILED (see Console).");
				dialog.Close(.OK);
			});
		dialog.AddButton("Cancel", .Cancel);
		dialog.Show(mUiHost.Context);
	}

	private void ShowDirtyCloseDialog(UIEditorPage page, DockablePanel panel)
	{
		let dialog = new Dialog("Unsaved changes");
		let label = new Label(scope $"'{page.Title}' has unsaved changes.");
		label.WordWrap.Value = true;
		dialog.SetContent(label);
		let save = dialog.AddButton("Save", .None);
		save.OnClick.Add(new [=page, =panel, =dialog, =this](b) =>
			{
				if (page.Save() case .Ok)
				{
					panel.OnCloseRequested(panel);
					dialog.Close(.OK);
				}
				else
				{
					mContext.Notify(.Error, "Save FAILED (see console) - page stays open.");
					dialog.Close(.Cancel);
				}
			});
		let discard = dialog.AddButton("Discard", .None);
		discard.OnClick.Add(new [=panel, =dialog](b) =>
			{
				panel.OnCloseRequested(panel);
				dialog.Close(.OK);
			});
		dialog.AddButton("Cancel", .Cancel);
		dialog.Show(mUiHost.Context);
	}

	private void SaveLayout()
	{
		if ((mProject == null) || (mProjectEditorSettings == null))
			return;
		let pages = scope List<Guid>();
		Guid activePage = .Empty;
		for (let entry in mPagePanels)
		{
			// Instance-less pages, the Game tab, do not persist in the page set: an empty guid
			// would just fail the restore lookup.
			if (!entry.Page.InstanceId.IsSet)
				continue;
			pages.Add(entry.Page.InstanceId);
			if (mContext.ActivePage === entry.Page)
				activePage = entry.Page.InstanceId;
		}
		ProjectEditorSettings.CaptureOpenPages(mProjectEditorSettings, pages, activePage);
		if (mShell.Docks != null)
			mShell.SaveLayout(mProjectEditorSettings).IgnoreError();
		ProjectEditorSettings.Save(mProjectEditorSettings, mProject.EditorStateRoot(.. scope .())).IgnoreError();
	}
}
