namespace Sedulous.Editor;

using System;
using System.Collections;
using System.IO;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.VG.Renderer;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Editor.Core;
using Sedulous.Editor.Pages;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine.Render;
using Sedulous.Engine;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Geometry.Resources;
using Sedulous.Engine.App;

/// Manages project open/close, scene creation, save operations,
/// asset browser file drops, and related project-level actions.
class EditorProjectManager
{
	private EditorApplication mEditor;
	private bool mProjectLoaded;
	private View mProjectPickerView;
	private int32 mNewSceneCounter;

	public this(EditorApplication editor)
	{
		mEditor = editor;
	}

	/// Whether a project is currently loaded.
	public bool ProjectLoaded => mProjectLoaded;

	/// The project picker view (shown before a project is opened).
	public View ProjectPickerView => mProjectPickerView;

	// ==================== Project Picker ====================

	public void BuildProjectPicker()
	{
		let picker = new Panel();
		picker.SetStyle(.Background, new ColorDrawable(.(30, 32, 40, 255)));
		picker.Padding = .(40);

		let center = new FlexLayout();
		center.Direction = .Vertical;
		center.Spacing = 16;

		let title = new Label();
		title.SetText("Sedulous Editor");
		title.FontSize.Value = 24;
		title.HAlign.Value = .Center;
		center.AddView(title, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(32))
		});

		let subtitle = new Label();
		subtitle.SetText("Select a project to get started");
		subtitle.FontSize.Value = 13;
		subtitle.HAlign.Value = .Center;
		center.AddView(subtitle, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(20))
		});

		// Button row
		let btnRow = new FlexLayout();
		btnRow.Direction = .Horizontal;
		btnRow.Spacing = 12;

		let newBtn = new Button("New Project...");
		newBtn.OnClick.Add(new (b) => {
			mEditor.Shell.Dialogs.ShowFolderDialog(new (paths) => {
				if (paths.Length > 0 && paths[0].Length > 0)
				{
					let path = scope String(paths[0]);
					mEditor.Project.Open(path);
					mEditor.Project.Save();
					OpenProject(path);
				}
			}, default, mEditor.Window);
		});
		btnRow.AddView(newBtn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(32)) });

		let openBtn = new Button("Open Project...");
		openBtn.OnClick.Add(new (b) => {
			mEditor.Shell.Dialogs.ShowFolderDialog(new (paths) => {
				if (paths.Length > 0 && paths[0].Length > 0)
					OpenProject(paths[0]);
			}, default, mEditor.Window);
		});
		btnRow.AddView(openBtn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(32)) });

		center.AddView(btnRow, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Recent projects list
		if (mEditor.RecentProjects.Count > 0)
		{
			let recentLabel = new Label();
			recentLabel.SetText("Recent Projects:");
			recentLabel.FontSize.Value = 12;
			center.AddView(recentLabel, new FlexLayout.LayoutParams() {
				Width = .Match, Height = .Fixed(.Px(20))
			});

			for (int i = 0; i < mEditor.RecentProjects.Count; i++)
			{
				let idx = i;
				let btn = new Button(mEditor.RecentProjects.Get(i));
				btn.OnClick.Add(new (b) => {
					if (idx < mEditor.RecentProjects.Count)
					{
						var path = mEditor.RecentProjects.Get(idx);
						OpenProject(path);
					}
				});
				center.AddView(btn, new FlexLayout.LayoutParams() {
					Width = .Match, Height = .Fixed(.Px(28))
				});
			}
		}

		picker.AddView(center, new LayoutParams() {
			Width = .Wrap, Height = .Wrap
		});

		mProjectPickerView = picker;
		mEditor.MainRoot.AddView(picker, new LayoutParams() {
			Width = .Match, Height = .Match
		});
	}

	// ==================== Project Open ====================

	public void OpenProject(StringView path)
	{
		String pathToOpen = scope String(path);
		if (mEditor.Project.Open(pathToOpen) case .Err)
		{
			mEditor.Logger.Log(.Error, "Failed to open project: {}", pathToOpen);
			return;
		}

		// Editor-side per-asset state (preview rig assignments, anim
		// graph node positions, etc.). Lives next to the project under
		// .editor/ so it travels with the repo if checked in, and is
		// cheap to wipe if not.
		mEditor.EditorContext.AssetCache?.Open(pathToOpen);

		mEditor.RecentProjects.Add(pathToOpen);
		mProjectLoaded = true;
		mEditor.Logger.Log(.Information, scope $"Project opened: {pathToOpen}");

		// Mount the project directory under "project://" and load its identity index
		let projectDir = scope String();
		projectDir.Set(mEditor.Project.ProjectDirectory);

		// Point the thumbnail disk cache at this project's .editor/thumbnails/.
		mEditor.EditorContext.Thumbnails?.SetProjectDirectory(projectDir);

		// Load project_settings.oddl from the project's assets dir, if
		// present. Standalone reads the same file at boot via
		// EngineApplication; the editor's "Project Target" preview mode
		// reads this same data, so both stay in sync. Missing file is
		// silent - ProjectSettings keeps its in-memory defaults.
		mEditor.EditorContext.ProjectSettings = .();
		ProjectSettingsIO.Load(mEditor.ProjectAssetDirectory,
			mEditor.ResourceSystem.SerializerProvider, ref mEditor.EditorContext.ProjectSettings).IgnoreError();

		mEditor.UnmountProject();

		let projectMount = new FileSystemMount(projectDir);
		mEditor.MountProject(projectMount);

		let projectIndex = new InMemoryResourceIndex();
		if (projectMount.Exists("project.registry"))
		{
			let regStream = projectMount.Open("project.registry");
			if (regStream case .Ok(let s))
			{
				defer delete s;
				projectIndex.DeserializeFrom(s);
			}
		}
		mEditor.SetProjectIndex(projectIndex);
		// Insert project at the front so it lists before builtin everywhere
		// that iterates MountEntries in order (asset browser tree, asset
		// picker) - the project mount is what's interacted with most.
		mEditor.EditorContext.MountEntries.Insert(0, new MountEntry(
			"project", projectMount, projectIndex, "project.registry", true));
		mEditor.Logger.Log(.Information, scope String()..AppendF("Project registry loaded ({} entries)", projectIndex.Count));

		// Defer view switch - the button that triggered this is inside the picker.
		// Deleting immediately would use-after-free in Button.FireClick.
		if (mProjectPickerView != null)
		{
			let pickerToRemove = mProjectPickerView;
			mProjectPickerView = null;
			mEditor.UIContext.MutationQueue.QueueAction(new () => {
				mEditor.MainRoot.RemoveView(pickerToRemove, true);
				mEditor.BuildEditorShell();
			});
		}
	}

	// ==================== Scene Creation ====================

	public void OnNewScene()
	{
		// Create scene through RuntimeContext's SceneSubsystem so ISceneAware
		// subsystems (RenderSubsystem) inject their component managers.
		let sceneSub = mEditor.RuntimeContext.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null)
		{
			mEditor.Logger.Log(.Error, "No SceneSubsystem in RuntimeContext");
			return;
		}

		mNewSceneCounter++;
		let sceneName = scope String();
		sceneName.AppendF("Untitled {}", mNewSceneCounter);
		let scene = sceneSub.CreateScene(sceneName);

		// Editor mode: disable simulation so physics, animation, particles don't tick.
		// Play mode (future) will re-enable via scene.Start().
		scene.SimulationEnabled = false;

		// Create default camera
		let cameraEntity = scene.CreateEntity("Main Camera");
		scene.SetLocalTransform(cameraEntity, .() {
			Position = .(0, 2, 5),
			Rotation = .Identity,
			Scale = .One
		});

		// Add CameraComponent
		let cameraMgr = scene.GetModule<CameraComponentManager>();
		if (cameraMgr != null)
		{
			let camHandle = cameraMgr.CreateComponent(cameraEntity);
			if (let cam = cameraMgr.Get(camHandle))
				cam.IsActiveCamera = true;
		}

		// Create default directional light
		let lightEntity = scene.CreateEntity("Directional Light");
		scene.SetLocalTransform(lightEntity, .() {
			Position = .(0, 5, 0),
			Rotation = .Identity,
			Scale = .One
		});

		let lightMgr = scene.GetModule<LightComponentManager>();
		if (lightMgr != null)
		{
			let lightHandle = lightMgr.CreateComponent(lightEntity);
			if (let light = lightMgr.Get(lightHandle))
			{
				light.Type = .Directional;
				light.Intensity = 2.0f;
			}
		}

		// Load primitive meshes from disk (generated by EnsureDefaultAssets)
		let meshMgr = scene.GetModule<MeshComponentManager>();

		// Ground plane
		let planeEntity = scene.CreateEntity("Ground");
		scene.SetLocalTransform(planeEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		if (meshMgr != null)
		{
			if (mEditor.ResourceSystem.LoadResource<StaticMeshResource>("builtin://primitives/plane.mesh") case .Ok(var handle))
			{
				var planeRef = ResourceRef(handle.Resource.Id, "builtin://primitives/plane.mesh");
				let planeComp = meshMgr.CreateComponent(planeEntity);
				if (let comp = meshMgr.Get(planeComp))
					comp.SetMeshRef(planeRef);
				planeRef.Dispose();
				handle.Release();
			}
		}

		// Cube
		let cubeEntity = scene.CreateEntity("Cube");
		scene.SetLocalTransform(cubeEntity, .() { Position = .(0, 0.5f, 0), Rotation = .Identity, Scale = .One });

		if (meshMgr != null)
		{
			if (mEditor.ResourceSystem.LoadResource<StaticMeshResource>("builtin://primitives/cube.mesh") case .Ok(var handle))
			{
				var cubeRef = ResourceRef(handle.Resource.Id, "builtin://primitives/cube.mesh");
				let cubeComp = meshMgr.CreateComponent(cubeEntity);
				if (let comp = meshMgr.Get(cubeComp))
					comp.SetMeshRef(cubeRef);
				cubeRef.Dispose();
				handle.Release();
			}
		}

		// Create page with layout
		let page = new SceneEditorPage(scene, "", mEditor.EditorContext);

		let sceneRenderer = mEditor.RuntimeContext.GetSubsystemByInterface<ISceneRenderer>();
		let content = ScenePageBuilder.Build(page, mEditor.EditorContext, mEditor.Device, mEditor.VGRenderer,
			sceneRenderer, mEditor.Shell.InputManager.Keyboard);
		page.SetContentView(content);

		mEditor.EditorContext.PageManager.AddPage(page);
		mEditor.Logger.Log(.Information, "Created new scene");
	}

	// ==================== File Open / Save ====================

	public void OnOpenScene()
	{
		let defaultPath = scope String();
		if (mEditor.Project.ProjectDirectory.Length > 0)
			defaultPath.Set(mEditor.Project.ProjectDirectory);

		mEditor.Shell.Dialogs.ShowOpenFileDialog(
			new (paths) => {
				if (paths.Length > 0)
					OpenSceneFile(paths[0]);
			},
			scope StringView[]("*.scene"),
			defaultPath, false, mEditor.Window);
	}

	public void OnSave()
	{
		let page = mEditor.EditorContext.PageManager.ActivePage;
		if (page == null) return;

		// Empty extension = page is read-only; menu items are still wired
		// (file menu, shortcuts) so we just no-op rather than show a dialog.
		if (page.SaveFileExtension.Length == 0) return;

		if (page.FilePath.Length == 0)
			OnSaveAs();
		else
		{
			page.Save();
			mEditor.LayoutManager.SyncDockPanelTitle(page);
			mEditor.LayoutManager.RegisterInProjectRegistry(page);
		}
	}

	public void OnSaveAs()
	{
		let page = mEditor.EditorContext.PageManager.ActivePage;
		if (page == null) return;

		let ext = page.SaveFileExtension;
		if (ext.Length == 0) return; // read-only page

		let defaultPath = scope String();
		if (mEditor.Project.ProjectDirectory.Length > 0)
			defaultPath.Set(mEditor.Project.ProjectDirectory);

		let filter = scope String()..AppendF("*{}", ext);

		mEditor.Shell.Dialogs.ShowSaveFileDialog(
			new (paths) => {
				if (paths.Length > 0)
				{
					let extCopy = scope String(ext); // captured into the dialog callback
					let savePath = scope String(paths[0]);
					if (!savePath.EndsWith(extCopy, .OrdinalIgnoreCase))
						savePath.Append(extCopy);
					page.SaveAs(savePath);
					mEditor.LayoutManager.SyncDockPanelTitle(page);
					mEditor.LayoutManager.RegisterInProjectRegistry(page);
				}
			},
			scope StringView[](filter),
			defaultPath, mEditor.Window);
	}

	/// Saves every open page that's dirty and savable. Pages with no FilePath
	/// (untitled) are skipped silently - the user can save them individually
	/// via the Save/Save As menu items.
	public void OnSaveAll()
	{
		if (mEditor.EditorContext?.PageManager == null) return;

		int savedCount = 0;
		for (let page in mEditor.EditorContext.PageManager.OpenPages)
		{
			if (page.SaveFileExtension.Length == 0) continue;  // read-only
			if (!page.IsDirty) continue;
			if (page.FilePath.Length == 0) continue;  // untitled - need Save As

			page.Save();
			mEditor.LayoutManager.SyncDockPanelTitle(page);
			mEditor.LayoutManager.RegisterInProjectRegistry(page);
			savedCount++;
		}

		mEditor.Logger?.Log(.Information, scope String()..AppendF("Save All: saved {} page(s)", savedCount));
	}

	public void OpenSceneFile(StringView path)
	{
		let page = mEditor.EditorContext.PageManager.OpenWithContext(path, mEditor.EditorContext);
		if (page != null)
			mEditor.Logger.Log(.Information, scope String()..AppendF("Opened scene: {}", path));
		else
			mEditor.Logger.Log(.Error, scope String()..AppendF("Failed to open: {}", path));
	}

	// ==================== Game / Project Settings ====================

	public void OnOpenGamePage()
	{
		// Asset-only editor sessions are fully supported - Open Game is a
		// no-op when no module is loaded. The Game menu item stays visible
		// so users see the feature exists; first cut just logs and bails.
		if (mEditor.App == null)
		{
			mEditor.Logger.Log(.Information,
				"Open Game: no application module loaded - editor is running in asset-only mode.");
			return;
		}

		// If a Game page is already open, activate it instead of double-opening.
		for (let page in mEditor.EditorContext.PageManager.OpenPages)
		{
			if (page is GameEditorPage)
			{
				mEditor.EditorContext.PageManager.SetActive(page);
				return;
			}
		}

		let page = new GameEditorPage(mEditor.EditorContext);
		let sceneRenderer = mEditor.RuntimeContext.GetSubsystemByInterface<ISceneRenderer>();
		let screenRenderer = mEditor.RuntimeContext.GetSubsystemByInterface<IScreenRenderer>();
		let content = GamePageBuilder.Build(page, mEditor.EditorContext, mEditor.Device, mEditor.VGRenderer,
			sceneRenderer, screenRenderer);
		page.SetContentView(content);
		mEditor.EditorContext.PageManager.AddPage(page);
	}

	public void OnOpenProjectSettings()
	{
		// Project Settings authoring is meaningful only when a project is
		// loaded - asset-only sessions without a project dir would have
		// nowhere to write the .oddl. Log instead of silently doing
		// nothing so users know why the menu seems to do nothing.
		if (mEditor.Project == null || !mEditor.Project.IsLoaded)
		{
			mEditor.Logger.Log(.Information,
				"Project Settings: no project loaded - open a project before editing settings.");
			return;
		}

		// Singleton page - activate the existing tab if it's already open
		// rather than double-stacking.
		for (let page in mEditor.EditorContext.PageManager.OpenPages)
		{
			if (page is ProjectSettingsPage)
			{
				mEditor.EditorContext.PageManager.SetActive(page);
				return;
			}
		}

		let page = new ProjectSettingsPage(mEditor.EditorContext);
		let content = ProjectSettingsPageBuilder.Build(page);
		page.SetContentView(content);
		mEditor.EditorContext.PageManager.AddPage(page);
	}

	// ==================== Default Assets ====================

	/// Ensures default builtin assets exist on disk. Generates them on
	/// first run if missing, then loads the identity index and registers
	/// it with ResourceSystem. The `builtin://` mount itself is created
	/// by the base Application class before this runs.
	///
	/// Asset content lives in `BuiltinAssets.GenerateAll` - this method
	/// owns only the gate (skip when `builtin.registry` exists) and the
	/// index lifecycle. New default assets should be added to
	/// `BuiltinAssets`, not here.
	public void EnsureDefaultAssets()
	{
		let assetRoot = scope String();
		mEditor.GetAssetPath("", assetRoot);

		// Use the mount owned by this editor instance. We generate
		// and persist through this same mount so saves go through VFS.

		bool needsGeneration = !mEditor.BuiltinMount.Exists("builtin.registry");
		let tempIndex = scope InMemoryResourceIndex();

		if (needsGeneration)
		{
			mEditor.Logger.Log(.Information, "Generating default builtin assets...");

			BuiltinAssets.GenerateAll(mEditor.BuiltinMount, tempIndex,
				mEditor.ResourceSystem.SerializerProvider, assetRoot, mEditor.Logger);

			let indexStream = scope MemoryStream();
			if (tempIndex.SerializeTo(indexStream) case .Ok)
			{
				indexStream.Position = 0;
				mEditor.BuiltinMount.Save("builtin.registry", indexStream);
			}
			mEditor.Logger.Log(.Information, "Default builtin assets generated.");
		}

		// Load the persisted identity index
		mEditor.LoadBuiltinIndex();
	}

	// ==================== File Drops ====================

	public void ProcessFileDrops()
	{
		let input = mEditor.Shell.InputManager;
		if (input.DroppedFileCount == 0 || mEditor.AssetBrowserPanel == null) return;

		let panelView = mEditor.AssetBrowserPanel.ContentView;
		if (panelView == null || panelView.Context == null) return;

		let adapter = mEditor.AssetBrowserPanel.ActiveContentAdapter;
		let entry = adapter?.ActiveEntry;
		if (entry == null) return;
		let writable = entry.Mount as IWritableMount;
		if (writable == null) return;

		// SDL drops report window-relative *physical* pixels; UI views
		// live in logical pixels. Divide by ContentScale once.
		let scale = mEditor.Window.ContentScale;
		let dpiScale = (scale > 0.0001f) ? scale : 1.0f;

		let topLeft = panelView.LocalToScreen(.Zero);
		let panelRect = Sedulous.Core.Mathematics.RectangleF(
			topLeft.X, topLeft.Y, panelView.Width, panelView.Height);

		for (int i = 0; i < input.DroppedFileCount; i++)
		{
			let path = input.GetDroppedFile(i);
			if (path.IsEmpty) continue;

			float dropX, dropY;
			if (!input.TryGetDroppedFilePosition(i, out dropX, out dropY)) continue;
			let logicalX = dropX / dpiScale;
			let logicalY = dropY / dpiScale;

			if (!panelRect.Contains(logicalX, logicalY)) continue;

			AssetBrowserBuilder.DispatchImportFile(mEditor.EditorContext, adapter,
				mEditor.AssetBrowserPanel, entry, writable, path);
		}
	}
}
