namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.Shell;
using Sedulous.Resources;
using Sedulous.Editor.Core;

/// The asset browser dockable panel.
/// Shows mounted registries (left tree) and their contents (right list).
/// Manages registry mount/create/unmount and persists extra registries in .sedproj.
class AssetBrowserPanel : IEditorPanel
{
	private EditorContext mEditorContext;
	private View mContentView;
	private AssetBrowserBuilder.BuildResult mBuildResult;

	/// Extra registries mounted by the user (not builtin/project).
	/// These are persisted in .sedproj and restored on project open.
	private List<MountedRegistryInfo> mExtraRegistries = new .() ~ {
		for (let info in _)
		{
			delete info.Name;
			delete info.RootPath;
			delete info.FilePath;
			delete info.Registry;
		}
		delete _;
	};

	private struct MountedRegistryInfo
	{
		public String Name;
		public String RootPath;
		public String FilePath;
		public ResourceRegistry Registry;
	}

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;

		// Restore extra registries from project settings before building UI
		RestoreRegistries();

		mBuildResult = AssetBrowserBuilder.Build(editorContext, this);
		mContentView = mBuildResult.RootView;
	}

	public ~this()
	{
		// Tree adapter and content adapters are owned by the tree/list/grid views
		// which are owned by the layout, which is owned by the dock panel.
		// We only need to clean up the adapters we created.
		delete mBuildResult.TreeAdapter;
		delete mBuildResult.ListAdapter;
		delete mBuildResult.GridAdapter;
	}

	public StringView PanelId => "AssetBrowser";
	public StringView Title => "Assets";
	public View ContentView => mContentView;

	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	/// Refreshes the registry tree (e.g. after mount/unmount).
	public void RefreshRegistries()
	{
		let registries = scope List<IResourceRegistry>();
		mEditorContext.ResourceSystem.GetRegistries(registries);
		mBuildResult.TreeAdapter.Refresh(registries);
	}

	/// Refreshes the content view (e.g. after import or file changes).
	public void RefreshContent()
	{
		mBuildResult.ListAdapter.Rebuild();
		mBuildResult.GridAdapter.Rebuild();
	}

	// ==================== Registry Management ====================

	/// Mount an existing .registry file via file dialog.
	public void MountRegistry()
	{
		let dialogService = mEditorContext.DialogService;
		if (dialogService == null) return;

		StringView[1] filters = .("Registry Files|registry");
		dialogService.ShowOpenFileDialog(new (paths) => {
			if (paths.Length == 0) return;

			let filePath = scope String(paths[0]);

			// Derive name and root from file path
			let rootDir = scope String();
			Path.GetDirectoryPath(filePath, rootDir);

			let fileName = scope String();
			Path.GetFileNameWithoutExtension(filePath, fileName);

			// Check not already mounted
			for (let info in mExtraRegistries)
			{
				if (StringView(info.FilePath) == filePath)
					return; // Already mounted
			}

			// Create and mount the registry
			let registry = new ResourceRegistry(fileName, rootDir);
			registry.LoadFromFile(filePath);
			mEditorContext.ResourceSystem.AddRegistry(registry);

			// Track for persistence
			mExtraRegistries.Add(.()
			{
				Name = new String(fileName),
				RootPath = new String(rootDir),
				FilePath = new String(filePath),
				Registry = registry
			});

			SaveRegistriesToProject();
			RefreshRegistries();
			SelectRegistry(registry);
		}, filters);
	}

	/// Create a new registry in a user-selected folder.
	public void CreateRegistry()
	{
		let dialogService = mEditorContext.DialogService;
		if (dialogService == null) return;

		dialogService.ShowFolderDialog(new (paths) => {
			if (paths.Length == 0) return;

			let folderPath = scope String(paths[0]);

			// Derive name from folder name
			let folderName = scope String();
			Path.GetFileName(folderPath, folderName);
			if (folderName.Length == 0)
				folderName.Set("registry");

			let registryFile = scope String();
			Path.InternalCombine(registryFile, folderPath, scope $"{folderName}.registry");

			// Create empty registry file
			let registry = new ResourceRegistry(folderName, folderPath);
			registry.SaveToFile(registryFile);
			mEditorContext.ResourceSystem.AddRegistry(registry);

			// Track for persistence
			mExtraRegistries.Add(.()
			{
				Name = new String(folderName),
				RootPath = new String(folderPath),
				FilePath = new String(registryFile),
				Registry = registry
			});

			SaveRegistriesToProject();
			RefreshRegistries();
			SelectRegistry(registry);
		});
	}

	/// Unmount the currently selected registry (if not locked).
	public void UnmountSelectedRegistry()
	{
		let selectedId = mBuildResult.TreeAdapter.SelectedNodeId;
		if (selectedId < 0) return;

		// Cannot unmount locked registries (builtin, project)
		if (mBuildResult.TreeAdapter.IsNodeLocked(selectedId))
			return;

		let registry = mBuildResult.TreeAdapter.GetRegistryForNode(selectedId);
		if (registry == null) return;

		// Find and remove from extra registries
		for (int i = 0; i < mExtraRegistries.Count; i++)
		{
			if (mExtraRegistries[i].Registry == registry)
			{
				let info = mExtraRegistries[i];
				mEditorContext.ResourceSystem.RemoveRegistry(info.Registry);
				delete info.Name;
				delete info.RootPath;
				delete info.FilePath;
				delete info.Registry;
				mExtraRegistries.RemoveAt(i);
				break;
			}
		}

		SaveRegistriesToProject();
		RefreshRegistries();

		// Clear content view since the selected registry was removed
		mBuildResult.ListAdapter.SetFolder(null, "");
		mBuildResult.GridAdapter.SetFolder(null, "");
		mBuildResult.Breadcrumb.SetPath("", "");
	}

	/// Selects a registry's root node in the tree and shows its content.
	private void SelectRegistry(IResourceRegistry registry)
	{
		let nodeId = mBuildResult.TreeAdapter.GetRootNodeForRegistry(registry);
		if (nodeId >= 0)
			mBuildResult.TreeAdapter.SelectNode(nodeId);
	}

	// ==================== Persistence ====================

	/// Saves extra registry mount points to .sedproj.
	private void SaveRegistriesToProject()
	{
		let project = mEditorContext.Project;
		if (project == null || !project.IsLoaded) return;

		project.SetSetting("registry.count", scope $"{mExtraRegistries.Count}");
		for (int i = 0; i < mExtraRegistries.Count; i++)
		{
			let info = mExtraRegistries[i];
			project.SetSetting(scope $"registry.{i}.name", info.Name);
			project.SetSetting(scope $"registry.{i}.root", info.RootPath);
			project.SetSetting(scope $"registry.{i}.file", info.FilePath);
		}
		project.Save();
	}

	/// Restores extra registry mount points from .sedproj.
	private void RestoreRegistries()
	{
		let project = mEditorContext.Project;
		if (project == null || !project.IsLoaded) return;

		let countStr = project.GetSetting("registry.count");
		if (countStr.Length == 0) return;

		int count = 0;
		if (int.Parse(countStr) case .Ok(let val))
			count = val;

		for (int i = 0; i < count; i++)
		{
			let name = project.GetSetting(scope $"registry.{i}.name");
			let rootPath = project.GetSetting(scope $"registry.{i}.root");
			let filePath = project.GetSetting(scope $"registry.{i}.file");

			if (name.Length == 0 || rootPath.Length == 0 || filePath.Length == 0)
				continue;

			// Don't mount duplicates
			bool alreadyMounted = false;
			for (let info in mExtraRegistries)
			{
				if (StringView(info.FilePath) == filePath)
				{
					alreadyMounted = true;
					break;
				}
			}
			if (alreadyMounted) continue;

			let registry = new ResourceRegistry(name, rootPath);
			if (File.Exists(filePath))
				registry.LoadFromFile(filePath);
			mEditorContext.ResourceSystem.AddRegistry(registry);

			mExtraRegistries.Add(.()
			{
				Name = new String(name),
				RootPath = new String(rootPath),
				FilePath = new String(filePath),
				Registry = registry
			});
		}
	}

	public void Dispose()
	{
	}
}
