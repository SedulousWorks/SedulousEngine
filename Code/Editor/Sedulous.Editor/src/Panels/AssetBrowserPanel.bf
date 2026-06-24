namespace Sedulous.Editor;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.Shell;
using Sedulous.Resources;
using Sedulous.Editor.Core;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// The asset browser dockable panel.
/// Shows mounted entries (left tree) and their contents (right list).
/// Manages mount/create/unmount and persists extra mounts in .sedproj.
class AssetBrowserPanel : IEditorPanel
{
	private EditorContext mEditorContext;
	private View mContentView;
	private AssetBrowserBuilder.BuildResult mBuildResult;

	/// Extra mounts created by the user (not builtin/project).
	/// These are persisted in .sedproj and restored on project open.
	private List<MountedExtraInfo> mExtraMounts = new .() ~ {
		for (let info in _)
		{
			delete info.Scheme;
			delete info.RootPath;
			delete info.IndexLocator;
		}
		delete _;
	};

	private struct MountedExtraInfo
	{
		public String Scheme;
		public String RootPath;
		public String IndexLocator;  // mount-relative locator where the index lives
		public FileSystemMount Mount;
		public InMemoryResourceIndex Index;
		public MountEntry Entry;     // Lives in EditorContext.MountEntries (not owned here)
	}

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;

		// Restore extra mounts from project settings before building UI
		RestoreExtras();

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

	/// Active content adapter (current folder + active mount). Used by
	/// the drag-drop-from-OS path to dispatch dropped files into the
	/// folder the user is currently viewing.
	public AssetContentAdapter ActiveContentAdapter => mBuildResult.ListAdapter;

	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	/// Refreshes the mount tree (e.g. after mount/unmount).
	public void RefreshRegistries()
	{
		mBuildResult.TreeAdapter.Refresh(mEditorContext.MountEntries);
	}

	/// Refreshes the content view (e.g. after import or file changes).
	public void RefreshContent()
	{
		mBuildResult.ListAdapter.Rebuild();
		mBuildResult.GridAdapter.Rebuild();
	}

	/// Navigates the content view to a folder. If the folder doesn't exist,
	/// walks up to the closest existing parent.
	public void NavigateToFolder(StringView relativePath)
	{
		let entry = mBuildResult.ListAdapter.ActiveEntry;
		if (entry == null) return;

		let fsMount = entry.Mount as FileSystemMount;
		let rootPath = (fsMount != null) ? fsMount.RootPath : StringView();

		// Walk up until we find an existing folder (or reach root)
		let folder = scope String(relativePath);
		while (folder.Length > 0)
		{
			let absPath = scope String();
			Path.InternalCombine(absPath, rootPath, folder);
			if (Directory.Exists(absPath))
				break;

			let lastSlash = folder.LastIndexOf('/');
			if (lastSlash >= 0)
				folder.RemoveToEnd(lastSlash);
			else
				folder.Clear();
		}

		mBuildResult.ListAdapter.SetFolder(entry, folder);
		mBuildResult.GridAdapter.SetFolder(entry, folder);
		mBuildResult.Breadcrumb.SetPath(entry.Scheme, folder);
	}

	/// If the content view is currently inside the given folder, navigates
	/// to the closest existing parent. Otherwise just refreshes.
	public void NavigateAwayFromDeletedFolder(StringView deletedRelPath)
	{
		let currentFolder = mBuildResult.ListAdapter.CurrentFolder;

		bool isInside = StringView(currentFolder) == deletedRelPath ||
			(currentFolder.Length > deletedRelPath.Length &&
			 currentFolder.StartsWith(deletedRelPath) &&
			 currentFolder[deletedRelPath.Length] == '/');

		if (isInside)
		{
			// Navigate to parent of the deleted folder
			let parentFolder = scope String(deletedRelPath);
			let lastSlash = parentFolder.LastIndexOf('/');
			if (lastSlash >= 0)
				parentFolder.RemoveToEnd(lastSlash);
			else
				parentFolder.Clear();

			NavigateToFolder(parentFolder);
		}
		else
		{
			RefreshContent();
		}
	}

	// ==================== Mount Management ====================

	/// Mount an existing .registry file via file dialog.
	public void MountRegistry()
	{
		let dialogService = mEditorContext.DialogService;
		if (dialogService == null) return;

		StringView[1] filters = .("Registry Files|registry");
		dialogService.ShowOpenFileDialog(new (paths) => {
			if (paths.Length == 0) return;

			let filePath = scope String(paths[0]);

			// Derive scheme name and root from file path
			let rootDir = scope String();
			Path.GetDirectoryPath(filePath, rootDir);

			let scheme = scope String();
			Path.GetFileNameWithoutExtension(filePath, scheme);

			let indexLocator = scope String();
			Path.GetFileName(filePath, indexLocator);

			// Check not already mounted
			for (let info in mExtraMounts)
			{
				if (StringView(info.Scheme) == scheme)
					return; // Already mounted
			}

			// Create and register the mount + index
			let mount = new FileSystemMount(rootDir);
			let index = new InMemoryResourceIndex();
			{
				let stream = mount.Open(indexLocator);
				if (stream case .Ok(let s))
				{
					defer delete s;
					index.DeserializeFrom(s);
				}
			}
			mEditorContext.ResourceSystem.Mount(scheme, mount);
			mEditorContext.ResourceSystem.AddIndex(index);

			let entry = new MountEntry(scheme, mount, index, indexLocator, false);
			entry.OwnsResources = true;
			mEditorContext.MountEntries.Add(entry);

			// Track for persistence
			mExtraMounts.Add(.()
			{
				Scheme = new String(scheme),
				RootPath = new String(rootDir),
				IndexLocator = new String(indexLocator),
				Mount = mount,
				Index = index,
				Entry = entry
			});

			SaveExtrasToProject();
			RefreshRegistries();
			SelectEntry(entry);
		}, filters);
	}

	/// Create a new mount in a user-selected folder.
	public void CreateRegistry()
	{
		let dialogService = mEditorContext.DialogService;
		if (dialogService == null) return;

		dialogService.ShowFolderDialog(new (paths) => {
			if (paths.Length == 0) return;

			let folderPath = scope String(paths[0]);

			// Derive scheme name from folder name
			let scheme = scope String();
			Path.GetFileName(folderPath, scheme);
			if (scheme.Length == 0)
				scheme.Set("registry");

			let indexLocator = scope String();
			indexLocator.AppendF("{}.registry", scheme);

			// Create mount + empty index, persist the index immediately
			let mount = new FileSystemMount(folderPath);
			let index = new InMemoryResourceIndex();
			{
				let memStream = scope MemoryStream();
				if (index.SerializeTo(memStream) case .Ok)
				{
					memStream.Position = 0;
					mount.Save(indexLocator, memStream);
				}
			}
			mEditorContext.ResourceSystem.Mount(scheme, mount);
			mEditorContext.ResourceSystem.AddIndex(index);

			let entry = new MountEntry(scheme, mount, index, indexLocator, false);
			entry.OwnsResources = true;
			mEditorContext.MountEntries.Add(entry);

			// Track for persistence
			mExtraMounts.Add(.()
			{
				Scheme = new String(scheme),
				RootPath = new String(folderPath),
				IndexLocator = new String(indexLocator),
				Mount = mount,
				Index = index,
				Entry = entry
			});

			SaveExtrasToProject();
			RefreshRegistries();
			SelectEntry(entry);
		});
	}

	/// Unmount the currently selected entry (if not locked).
	public void UnmountSelectedRegistry()
	{
		let selectedId = mBuildResult.TreeAdapter.SelectedNodeId;
		if (selectedId < 0) return;

		// Cannot unmount locked entries (builtin, project)
		if (mBuildResult.TreeAdapter.IsNodeLocked(selectedId))
			return;

		let entry = mBuildResult.TreeAdapter.GetEntryForNode(selectedId);
		if (entry == null) return;

		// Find and remove from extra mounts
		for (int i = 0; i < mExtraMounts.Count; i++)
		{
			if (mExtraMounts[i].Entry == entry)
			{
				let info = mExtraMounts[i];

				// Unmount from ResourceSystem
				mEditorContext.ResourceSystem.RemoveIndex(info.Index);
				mEditorContext.ResourceSystem.Unmount(info.Scheme);

				// Remove from EditorContext (owns the entry)
				for (int j = mEditorContext.MountEntries.Count - 1; j >= 0; j--)
				{
					if (mEditorContext.MountEntries[j] == info.Entry)
					{
						delete mEditorContext.MountEntries[j];
						mEditorContext.MountEntries.RemoveAt(j);
						break;
					}
				}

				delete info.Mount;
				delete info.Index;
				delete info.Scheme;
				delete info.RootPath;
				delete info.IndexLocator;
				mExtraMounts.RemoveAt(i);
				break;
			}
		}

		SaveExtrasToProject();
		RefreshRegistries();

		// Clear content view since the selected entry was removed
		mBuildResult.ListAdapter.SetFolder(null, "");
		mBuildResult.GridAdapter.SetFolder(null, "");
		mBuildResult.Breadcrumb.SetPath("", "");
	}

	/// Selects a mount entry's root node in the tree and shows its content.
	private void SelectEntry(MountEntry entry)
	{
		let nodeId = mBuildResult.TreeAdapter.GetRootNodeForEntry(entry);
		if (nodeId >= 0)
			mBuildResult.TreeAdapter.SelectNode(nodeId);
	}

	// ==================== Persistence ====================

	/// Saves extra mount points to .sedproj.
	private void SaveExtrasToProject()
	{
		let project = mEditorContext.Project;
		if (project == null || !project.IsLoaded) return;

		project.SetSetting("registry.count", scope $"{mExtraMounts.Count}");
		for (int i = 0; i < mExtraMounts.Count; i++)
		{
			let info = mExtraMounts[i];
			project.SetSetting(scope $"registry.{i}.name", info.Scheme);
			project.SetSetting(scope $"registry.{i}.root", info.RootPath);
			project.SetSetting(scope $"registry.{i}.file", info.IndexLocator);
		}
		project.Save();
	}

	/// Restores extra mount points from .sedproj.
	private void RestoreExtras()
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
			let scheme = project.GetSetting(scope $"registry.{i}.name");
			let rootPath = project.GetSetting(scope $"registry.{i}.root");
			let indexLocator = project.GetSetting(scope $"registry.{i}.file");

			if (scheme.Length == 0 || rootPath.Length == 0 || indexLocator.Length == 0)
				continue;

			// Don't mount duplicates
			bool alreadyMounted = false;
			for (let info in mExtraMounts)
			{
				if (StringView(info.Scheme) == scheme)
				{
					alreadyMounted = true;
					break;
				}
			}
			if (alreadyMounted) continue;

			let mount = new FileSystemMount(rootPath);
			let index = new InMemoryResourceIndex();
			if (mount.Exists(indexLocator))
			{
				let stream = mount.Open(indexLocator);
				if (stream case .Ok(let s))
				{
					defer delete s;
					index.DeserializeFrom(s);
				}
			}
			mEditorContext.ResourceSystem.Mount(scheme, mount);
			mEditorContext.ResourceSystem.AddIndex(index);

			let entry = new MountEntry(scheme, mount, index, indexLocator, false);
			entry.OwnsResources = true;
			mEditorContext.MountEntries.Add(entry);

			mExtraMounts.Add(.()
			{
				Scheme = new String(scheme),
				RootPath = new String(rootPath),
				IndexLocator = new String(indexLocator),
				Mount = mount,
				Index = index,
				Entry = entry
			});
		}
	}

	public void Dispose()
	{
	}
}
