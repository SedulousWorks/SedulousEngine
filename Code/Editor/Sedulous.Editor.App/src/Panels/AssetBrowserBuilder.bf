namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Resources;
using Sedulous.Editor.Core;

/// Builds the asset browser panel layout:
///   Registry tree (left) | Content view (right)
///   with breadcrumb bar above the content view.
static class AssetBrowserBuilder
{
	/// Result of building the browser - contains references to key components
	/// so the panel can wire events and manage state.
	public struct BuildResult
	{
		public View RootView;
		public TreeView RegistryTree;
		public RegistryTreeAdapter TreeAdapter;
		public ListView ContentList;
		public GridContentView ContentGrid;
		public AssetContentAdapter ListAdapter;
		public AssetContentAdapter GridAdapter;
		public BreadcrumbBar Breadcrumb;
		public Panel ContentContainer;  // Holds the active content view (list or grid)
	}

	/// Builds the complete asset browser layout.
	public static BuildResult Build(EditorContext editorContext, AssetBrowserPanel panel)
	{
		let resourceSystem = editorContext.ResourceSystem;

		// === Create adapters ===
		let treeAdapter = new RegistryTreeAdapter();
		let contentAdapter = new AssetContentAdapter();

		// Populate tree from current registries
		let registries = scope List<IResourceRegistry>();
		resourceSystem.GetRegistries(registries);
		treeAdapter.SetRegistries(registries);

		// === Left pane: Registry toolbar + tree ===
		let leftPane = new LinearLayout();
		leftPane.Orientation = .Vertical;

		// Registry management toolbar
		let regToolbar = new Toolbar();
		let mountBtn = regToolbar.AddButton("Mount");
		let createBtn = regToolbar.AddButton("Create");
		let unmountBtn = regToolbar.AddButton("Unmount");

		mountBtn.OnClick.Add(new [=panel] (btn) => { panel.MountRegistry(); });
		createBtn.OnClick.Add(new [=panel] (btn) => { panel.CreateRegistry(); });
		unmountBtn.OnClick.Add(new [=panel] (btn) => { panel.UnmountSelectedRegistry(); });

		leftPane.AddView(regToolbar, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		// Separator below toolbar
		let toolbarSep = new Panel();
		toolbarSep.Background = new ColorDrawable(.(50, 55, 65, 255));
		leftPane.AddView(toolbarSep, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 1
		});

		let treeView = new TreeView();
		treeView.ItemHeight = 22;
		treeView.IndentWidth = 16;
		treeView.SetAdapter(treeAdapter);

		leftPane.AddView(treeView, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		// === Right pane: Toolbar + Breadcrumb + content (list or grid) ===
		let rightPane = new LinearLayout();
		rightPane.Orientation = .Vertical;

		// Two adapters sharing the same data - one for list, one for grid
		let listAdapter = contentAdapter;
		listAdapter.ViewMode = .List;

		let gridAdapter = new AssetContentAdapter();
		gridAdapter.ViewMode = .Grid;

		// Navigation bar: breadcrumbs (left, fills) + view mode toggles (right)
		let navBar = new LinearLayout();
		navBar.Orientation = .Horizontal;
		navBar.Padding = .(0, 0, 4, 0);

		let breadcrumb = new BreadcrumbBar();
		navBar.AddView(breadcrumb, new LinearLayout.LayoutParams() { Width = 0, Height = LayoutParams.MatchParent, Weight = 1 });

		let listBtn = new ToggleButton();
		listBtn.SetText("List");
		listBtn.IsChecked = true;
		let gridBtn = new ToggleButton();
		gridBtn.SetText("Grid");

		navBar.AddView(listBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
		navBar.AddView(gridBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

		rightPane.AddView(navBar, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		// Separator
		let sep = new Panel();
		sep.Background = new ColorDrawable(.(50, 55, 65, 255));
		rightPane.AddView(sep, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 1
		});

		// Content container - holds the active view (list or grid)
		let contentContainer = new Panel();
		rightPane.AddView(contentContainer, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		// List view (default, visible)
		let contentList = new ListView();
		contentList.ItemHeight = 24;
		contentList.Adapter = listAdapter;
		contentList.Selection.Mode = .Single;
		listAdapter.OwnerListView = contentList;
		contentContainer.AddView(contentList, new LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent
		});

		// Grid view (hidden initially)
		let contentGrid = new GridContentView();
		contentGrid.CellWidth = 80;
		contentGrid.CellHeight = 96;
		contentGrid.Adapter = gridAdapter;
		contentGrid.Selection.Mode = .Single;
		contentGrid.Visibility = .Gone;
		gridAdapter.OwnerGridView = contentGrid;
		contentContainer.AddView(contentGrid, new LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent
		});

		// View mode toggle wiring
		listBtn.OnCheckedChanged.Add(new [=contentList, =contentGrid, =gridBtn] (btn, val) => {
			if (val)
			{
				gridBtn.IsChecked = false;
				contentList.Visibility = .Visible;
				contentGrid.Visibility = .Gone;
			}
		});
		gridBtn.OnCheckedChanged.Add(new [=contentList, =contentGrid, =listBtn] (btn, val) => {
			if (val)
			{
				listBtn.IsChecked = false;
				contentList.Visibility = .Gone;
				contentGrid.Visibility = .Visible;
			}
		});

		// === Wire tree selection -> content view ===
		treeAdapter.OnFolderSelected.Add(new (registry, relativePath) => {
			contentAdapter.SetFolder(registry, relativePath);
			gridAdapter.SetFolder(registry, relativePath);

			// Update breadcrumb
			breadcrumb.SetPath(registry.Name, relativePath);
		});

		// Wire tree item click -> select node
		treeView.OnItemClick.Add(new (clickInfo) => {
			treeAdapter.SelectNode(clickInfo.NodeId);
		});

		// Wire tree right-click -> context menu
		treeView.OnItemRightClick.Add(new [=treeAdapter, =treeView, =editorContext, =panel, =contentAdapter, =gridAdapter, =breadcrumb] (nodeId, localX, localY) => {
			let ctx = treeView.Context;
			if (ctx == null) return;

			treeAdapter.SelectNode(nodeId);

			let screenCoords = ToScreenCoords(treeView, localX, localY);
			let registry = treeAdapter.GetRegistryForNode(nodeId);
			let isLocked = treeAdapter.IsNodeLocked(nodeId);
			let isRoot = treeAdapter.IsRegistryRoot(nodeId);

			ShowTreeContextMenu(ctx, screenCoords.x, screenCoords.y, nodeId, registry,
				isRoot, isLocked, treeAdapter, contentAdapter, gridAdapter, editorContext, panel, breadcrumb);
		});

		// Wire rename commit -> rename file on disk and update registry
		listAdapter.OnItemRenamed.Add(new [=listAdapter, =gridAdapter, =panel] (item, newName) => {
			if (item.AbsolutePath == null || newName.Length == 0) return;

			// Build new absolute path
			let dir = scope String();
			System.IO.Path.GetDirectoryPath(item.AbsolutePath, dir);
			let newAbsPath = scope String();
			System.IO.Path.InternalCombine(newAbsPath, dir, newName);

			// Don't rename if target already exists
			if (System.IO.File.Exists(newAbsPath) || System.IO.Directory.Exists(newAbsPath))
				return;

			// Rename file on disk
			if (System.IO.File.Exists(item.AbsolutePath))
				System.IO.File.Move(item.AbsolutePath, newAbsPath);
			else if (System.IO.Directory.Exists(item.AbsolutePath))
				System.IO.Directory.Move(item.AbsolutePath, newAbsPath);

			// Rename .meta sidecar if exists
			let oldMeta = scope String(item.AbsolutePath);
			oldMeta.Append(".meta");
			if (System.IO.File.Exists(oldMeta))
			{
				let newMeta = scope String(newAbsPath);
				newMeta.Append(".meta");
				System.IO.File.Move(oldMeta, newMeta);
			}

			// Update registry entry if registered
			if (item.IsRegistered)
			{
				let registry = listAdapter.ActiveRegistry;
				if (let concreteReg = registry as ResourceRegistry)
				{
					// Build new relative path
					let newRelPath = scope String();
					if (listAdapter.CurrentFolder.Length > 0)
						newRelPath.AppendF("{}/{}", listAdapter.CurrentFolder, newName);
					else
						newRelPath.Set(newName);

					concreteReg.Register(item.RegistryId, newRelPath);

					// Save registry
					let regFile = scope String();
					System.IO.Path.InternalCombine(regFile, registry.RootPath, scope $"{registry.Name}.registry");
					concreteReg.SaveToFile(regFile);
				}
			}

			// Refresh both views
			listAdapter.Rebuild();
			gridAdapter.Rebuild();
		});

		// Wire F2 key -> inline rename on selected item
		contentList.OnItemKeyDown.Add(new [=listAdapter] (position, e) => {
			if (e.Key == .F2)
			{
				listAdapter.StartRename(position);
				e.Handled = true;
			}
		});

		// Wire grid adapter rename commit -> rename file on disk and update registry
		gridAdapter.OnItemRenamed.Add(new [=listAdapter, =gridAdapter, =panel] (item, newName) => {
			if (item.AbsolutePath == null || newName.Length == 0) return;

			let dir = scope String();
			System.IO.Path.GetDirectoryPath(item.AbsolutePath, dir);
			let newAbsPath = scope String();
			System.IO.Path.InternalCombine(newAbsPath, dir, newName);

			if (System.IO.File.Exists(newAbsPath) || System.IO.Directory.Exists(newAbsPath))
				return;

			if (System.IO.File.Exists(item.AbsolutePath))
				System.IO.File.Move(item.AbsolutePath, newAbsPath);
			else if (System.IO.Directory.Exists(item.AbsolutePath))
				System.IO.Directory.Move(item.AbsolutePath, newAbsPath);

			let oldMeta = scope String(item.AbsolutePath);
			oldMeta.Append(".meta");
			if (System.IO.File.Exists(oldMeta))
			{
				let newMeta = scope String(newAbsPath);
				newMeta.Append(".meta");
				System.IO.File.Move(oldMeta, newMeta);
			}

			if (item.IsRegistered)
			{
				let registry = gridAdapter.ActiveRegistry;
				if (let concreteReg = registry as ResourceRegistry)
				{
					let newRelPath = scope String();
					if (gridAdapter.CurrentFolder.Length > 0)
						newRelPath.AppendF("{}/{}", gridAdapter.CurrentFolder, newName);
					else
						newRelPath.Set(newName);

					concreteReg.Register(item.RegistryId, newRelPath);

					let regFile = scope String();
					System.IO.Path.InternalCombine(regFile, registry.RootPath, scope $"{registry.Name}.registry");
					concreteReg.SaveToFile(regFile);
				}
			}

			listAdapter.Rebuild();
			gridAdapter.Rebuild();
		});

		// Wire F2 key -> inline rename on selected grid item
		contentGrid.OnItemKeyDown.Add(new [=gridAdapter] (position, e) => {
			if (e.Key == .F2)
			{
				gridAdapter.StartRename(position);
				e.Handled = true;
			}
		});

		// Wire content list double-click -> navigate into folder or open asset.
		// Deferred via mutation queue because NavigateInto triggers Rebuild which
		// recycles the view that's still processing the click event.
		contentList.OnItemClicked.Add(new (position, clickCount, x, y) => {
			if (clickCount == 2)
			{
				let item = contentAdapter.GetItem(position);
				if (item == null) return;

				if (item.IsFolder)
				{
					let folderName = new String(item.Name);
					contentList.Context?.MutationQueue.QueueAction(new [=contentAdapter, =gridAdapter, =breadcrumb, =folderName] () => {
						contentAdapter.NavigateInto(folderName);
						gridAdapter.NavigateInto(folderName);
						breadcrumb.SetPath(
							contentAdapter.ActiveRegistry?.Name ?? "",
							contentAdapter.CurrentFolder);
						delete folderName;
					});
				}
				else
				{
					// Open asset via page factory (e.g. .scene -> SceneEditorPage)
					if (editorContext.PageManager != null && item.AbsolutePath != null)
						editorContext.PageManager.OpenWithContext(item.AbsolutePath, editorContext);
				}
			}
		});

		// Wire content list right-click on item -> context menu
		contentList.OnItemRightClicked.Add(new [=contentAdapter, =editorContext, =contentList, =breadcrumb, =panel] (position, localX, localY) => {
			let item = contentAdapter.GetItem(position);
			let ctx = contentList.Context;
			if (ctx == null || item == null) return;

			let screenCoords = ToScreenCoords(contentList, localX, localY);

			if (item.IsFolder)
				ShowFolderItemContextMenu(ctx, screenCoords.x, screenCoords.y, item, position, contentAdapter, editorContext, panel, breadcrumb);
			else
				ShowItemContextMenu(ctx, screenCoords.x, screenCoords.y, item, position, contentAdapter, editorContext, panel);
		});

		// Wire right-click on empty space -> background context menu
		contentList.OnBackgroundRightClicked.Add(new [=contentAdapter, =editorContext, =contentList, =breadcrumb, =panel] (localX, localY) => {
			let ctx = contentList.Context;
			if (ctx == null) return;

			let screenCoords = ToScreenCoords(contentList, localX, localY);
			ShowBackgroundContextMenu(ctx, screenCoords.x, screenCoords.y,
				contentAdapter.CurrentFolder, contentAdapter, editorContext, panel, breadcrumb);
		});

		// Wire grid view double-click -> navigate into folder or open asset.
		// Deferred via mutation queue for same reason as list view.
		contentGrid.OnItemDoubleClicked.Add(new [=gridAdapter, =contentAdapter, =breadcrumb, =editorContext, =contentGrid] (position) => {
			let item = gridAdapter.GetItem(position);
			if (item == null) return;

			if (item.IsFolder)
			{
				let folderName = new String(item.Name);
				contentGrid.Context?.MutationQueue.QueueAction(new [=contentAdapter, =gridAdapter, =breadcrumb, =folderName] () => {
					contentAdapter.NavigateInto(folderName);
					gridAdapter.NavigateInto(folderName);
					breadcrumb.SetPath(
						contentAdapter.ActiveRegistry?.Name ?? "",
						contentAdapter.CurrentFolder);
					delete folderName;
				});
			}
			else
			{
				if (editorContext.PageManager != null && item.AbsolutePath != null)
					editorContext.PageManager.OpenWithContext(item.AbsolutePath, editorContext);
			}
		});

		// Wire grid view right-click on item -> context menu
		contentGrid.OnItemRightClicked.Add(new [=gridAdapter, =editorContext, =contentGrid, =breadcrumb, =panel] (position, localX, localY) => {
			let item = gridAdapter.GetItem(position);
			let ctx = contentGrid.Context;
			if (ctx == null || item == null) return;

			let screenCoords = ToScreenCoords(contentGrid, localX, localY);

			if (item.IsFolder)
				ShowFolderItemContextMenu(ctx, screenCoords.x, screenCoords.y, item, position, gridAdapter, editorContext, panel, breadcrumb);
			else
				ShowItemContextMenu(ctx, screenCoords.x, screenCoords.y, item, position, gridAdapter, editorContext, panel);
		});

		// Wire grid view right-click on empty space
		contentGrid.OnBackgroundRightClicked.Add(new [=gridAdapter, =editorContext, =contentGrid, =breadcrumb, =panel] (localX, localY) => {
			let ctx = contentGrid.Context;
			if (ctx == null) return;

			let screenCoords = ToScreenCoords(contentGrid, localX, localY);
			ShowBackgroundContextMenu(ctx, screenCoords.x, screenCoords.y,
				gridAdapter.CurrentFolder, gridAdapter, editorContext, panel, breadcrumb);
		});

		// Wire breadcrumb navigation - deferred via mutation queue because
		// SetPath destroys the button that fired the click event.
		breadcrumb.OnSegmentClicked.Add(new [=contentAdapter, =gridAdapter, =breadcrumb] (segmentIndex) => {
			let ctx = breadcrumb.Context;
			if (ctx == null) return;

			ctx.MutationQueue.QueueAction(new [=segmentIndex, =contentAdapter, =gridAdapter, =breadcrumb] () => {
				let registry = contentAdapter.ActiveRegistry;
				if (registry == null) return;

				if (segmentIndex == 0)
				{
					contentAdapter.SetFolder(registry, "");
					gridAdapter.SetFolder(registry, "");
				}
				else
				{
					let newPath = scope String();
					breadcrumb.BuildPathToSegment(segmentIndex, newPath);
					contentAdapter.SetFolder(registry, newPath);
					gridAdapter.SetFolder(registry, newPath);
				}
				breadcrumb.SetPath(registry.Name, contentAdapter.CurrentFolder);
			});
		});

		// === Split view ===
		let split = new SplitView(.Horizontal);
		split.SetPanes(leftPane, rightPane);
		split.SplitRatio = 0.25f;

		// Select first registry by default if available
		if (treeAdapter.RootCount > 0)
		{
			// Get first root's node ID from the flattened adapter
			let flatAdapter = treeView.FlatAdapter;
			if (flatAdapter != null && flatAdapter.ItemCount > 0)
			{
				let firstNodeId = flatAdapter.GetNodeId(0);
				treeAdapter.SelectNode(firstNodeId);
			}
		}

		return .()
		{
			RootView = split,
			RegistryTree = treeView,
			TreeAdapter = treeAdapter,
			ContentList = contentList,
			ContentGrid = contentGrid,
			ListAdapter = listAdapter,
			GridAdapter = gridAdapter,
			Breadcrumb = breadcrumb,
			ContentContainer = contentContainer
		};
	}

	// ==================== Helpers ====================


	/// Converts local coordinates to screen coordinates by walking up the view tree.
	private static (float x, float y) ToScreenCoords(View view, float localX, float localY)
	{
		float sx = localX;
		float sy = localY;
		View v = view;
		while (v != null)
		{
			sx += v.Bounds.X;
			sy += v.Bounds.Y;
			v = v.Parent;
		}
		return (sx, sy);
	}

	// ==================== Context Menus ====================

	/// Context menu for a file/asset item.
	private static void ShowItemContextMenu(UIContext ctx, float x, float y,
		AssetContentItem item, int32 position, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel)
	{
		let menu = new ContextMenu();
		let registry = adapter.ActiveRegistry;

		// Rename - double-deferred: the menu item action queues a first action,
		// which runs after ClosePopup/PopFocus, and then queues StartRename.
		// This ensures BeginEdit's SetFocus happens after PopFocus restores focus.
		menu.AddItem("Rename", new [=position, =adapter, =ctx] () => {
			ctx.MutationQueue.QueueAction(new [=position, =adapter, =ctx] () => {
				ctx.MutationQueue.QueueAction(new [=position, =adapter] () => {
					adapter.StartRename(position);
				});
			});
		});

		// Delete
		menu.AddItem("Delete", new [=item, =adapter, =registry, =panel, =ctx] () => {
			let confirmMsg = scope String();
			confirmMsg.AppendF("Delete '{}'?", item.Name);
			let dialog = Dialog.Confirm("Confirm Delete", confirmMsg);
			dialog.OnClosed.Add(new [=item, =registry, =panel] (dlg, result) => {
				if (result != .OK) return;

				if (item.AbsolutePath != null && System.IO.File.Exists(item.AbsolutePath))
					System.IO.File.Delete(item.AbsolutePath);

				// Unregister from registry
				if (item.IsRegistered)
				{
					if (let concreteReg = registry as ResourceRegistry)
						concreteReg.Unregister(item.RegistryId);
				}

				// Delete .meta sidecar if exists
				let metaPath = scope String(item.AbsolutePath);
				metaPath.Append(".meta");
				if (System.IO.File.Exists(metaPath))
					System.IO.File.Delete(metaPath);

				panel.RefreshContent();
			});
			dialog.Show(ctx);
		});

		menu.AddSeparator();

		// Copy Path (protocol path)
		if (item.IsRegistered && registry != null)
		{
			menu.AddItem("Copy Path", new [=item, =registry, =ctx] () => {
				let protocolPath = scope String();
				if (registry.Name.Length > 0)
					protocolPath.AppendF("{}://{}", registry.Name, item.RelativePath);
				else
					protocolPath.Set(item.RelativePath);

				ctx.Clipboard?.SetText(protocolPath);
			});
		}

		// Copy GUID
		if (item.IsRegistered)
		{
			menu.AddItem("Copy GUID", new [=item, =ctx] () => {
				let guidStr = scope String();
				item.RegistryId.ToString(guidStr);
				ctx.Clipboard?.SetText(guidStr);
			});
		}

		menu.AddSeparator();

		// Show in Explorer
		if (item.AbsolutePath != null)
		{
			menu.AddItem("Show in Explorer", new [=item, =editorContext] () => {
				let dirPath = scope String();
				System.IO.Path.GetDirectoryPath(item.AbsolutePath, dirPath);
				editorContext.Shell?.RevealInFileManager(dirPath);
			});
		}

		menu.Show(ctx, x, y);
	}

	/// Context menu for a folder item in the content view.
	private static void ShowFolderItemContextMenu(UIContext ctx, float x, float y,
		AssetContentItem folderItem, int32 position, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel, BreadcrumbBar breadcrumb)
	{
		let menu = new ContextMenu();
		let registry = adapter.ActiveRegistry;

		// The target folder for creating assets is the right-clicked folder
		let targetFolder = scope String(folderItem.RelativePath);

		// Rename folder - double-deferred for same reason as file rename
		menu.AddItem("Rename", new [=position, =adapter, =ctx] () => {
			ctx.MutationQueue.QueueAction(new [=position, =adapter, =ctx] () => {
				ctx.MutationQueue.QueueAction(new [=position, =adapter] () => {
					adapter.StartRename(position);
				});
			});
		});

		// Create New submenu - assets go into the right-clicked folder
		AddCreateNewSubmenu(menu, targetFolder, registry, editorContext, adapter, panel);

		// Create Folder inside this folder
		menu.AddItem("Create Folder", new [=folderItem, =panel] () => {
			CreateSubfolder(folderItem.AbsolutePath);
			panel.RefreshContent();
		});

		menu.AddSeparator();

		// Delete folder
		menu.AddItem("Delete", new [=folderItem, =panel, =ctx] () => {
			let confirmMsg = scope String();
			confirmMsg.AppendF("Delete folder '{}' and all its contents?", folderItem.Name);
			let dialog = Dialog.Confirm("Confirm Delete", confirmMsg);
			let deletedRelPath = new String(folderItem.RelativePath);
			dialog.OnClosed.Add(new [=folderItem, =panel, =deletedRelPath] (dlg, result) => {
				if (result != .OK) { delete deletedRelPath; return; }

				if (folderItem.AbsolutePath != null && System.IO.Directory.Exists(folderItem.AbsolutePath))
					System.IO.Directory.DelTree(folderItem.AbsolutePath);

				panel.NavigateAwayFromDeletedFolder(deletedRelPath);
				delete deletedRelPath;
			});
			dialog.Show(ctx);
		});

		menu.AddSeparator();

		// Show in Explorer
		if (folderItem.AbsolutePath != null)
		{
			menu.AddItem("Show in Explorer", new [=folderItem, =editorContext] () => {
				editorContext.Shell?.RevealInFileManager(folderItem.AbsolutePath);
			});
		}

		menu.Show(ctx, x, y);
	}

	/// Context menu for right-clicking empty space in the content view.
	private static void ShowBackgroundContextMenu(UIContext ctx, float x, float y,
		StringView targetFolder, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel, BreadcrumbBar breadcrumb)
	{
		let menu = new ContextMenu();
		let registry = adapter.ActiveRegistry;

		// Create New submenu - assets go into the current folder
		AddCreateNewSubmenu(menu, targetFolder, registry, editorContext, adapter, panel);

		// Create Folder in current directory
		let currentAbsDir = new String();
		if (registry != null)
		{
			if (targetFolder.Length > 0)
				System.IO.Path.InternalCombine(currentAbsDir, registry.RootPath, targetFolder);
			else
				currentAbsDir.Set(registry.RootPath);
		}
		menu.AddOwnedObject(currentAbsDir);

		menu.AddItem("Create Folder", new () => {
			CreateSubfolder(currentAbsDir);
			panel.RefreshContent();
		});

		menu.AddSeparator();

		// Import...
		menu.AddItem("Import...", new [=editorContext, =adapter, =panel] () => {
			TriggerImportDialog(editorContext, adapter, panel);
		});

		menu.Show(ctx, x, y);
	}

	/// Adds a "Create New" submenu populated from registered IAssetCreators.
	private static void AddCreateNewSubmenu(ContextMenu menu, StringView targetFolder,
		IResourceRegistry registry, EditorContext editorContext,
		AssetContentAdapter adapter, AssetBrowserPanel panel)
	{
		let createSub = menu.AddSubmenu("Create New");
		let creators = scope System.Collections.List<IAssetCreator>();
		editorContext.GetAssetCreators(creators);

		if (creators.Count > 0)
		{
			let categories = scope System.Collections.Dictionary<StringView, ContextMenu>();

			for (let creator in creators)
			{
				ContextMenu targetMenu;
				if (creator.Category.Length > 0)
				{
					if (!categories.TryGetValue(creator.Category, let existing))
					{
						let catSub = createSub.Submenu.AddSubmenu(creator.Category);
						categories[creator.Category] = catSub.Submenu;
						targetMenu = catSub.Submenu;
					}
					else
					{
						targetMenu = existing;
					}
				}
				else
				{
					targetMenu = createSub.Submenu;
				}

				let folderCopy = new String(targetFolder);
				menu.AddOwnedObject(folderCopy);
				targetMenu.AddItem(creator.DisplayName, new () => {
					CreateAssetInFolder(creator, folderCopy, registry, editorContext, panel);
				});
			}
		}
	}

	/// Creates a new subfolder with a unique name inside parentDir.
	private static void CreateSubfolder(StringView parentDir)
	{
		if (parentDir.Length == 0) return;

		let newDir = scope String();
		System.IO.Path.InternalCombine(newDir, parentDir, "New Folder");

		if (System.IO.Directory.Exists(newDir))
		{
			for (int i = 1; i < 100; i++)
			{
				newDir.Clear();
				System.IO.Path.InternalCombine(newDir, parentDir, scope $"New Folder ({i})");
				if (!System.IO.Directory.Exists(newDir))
					break;
			}
		}

		System.IO.Directory.CreateDirectory(newDir);
	}

	/// Creates an asset in a specific folder and registers it in the registry.
	/// targetFolder is the relative path within the registry (e.g. "models" or "").
	private static void CreateAssetInFolder(IAssetCreator creator,
		StringView targetFolder, IResourceRegistry registry,
		EditorContext editorContext, AssetBrowserPanel panel)
	{
		if (registry == null) return;

		// Build absolute output directory
		let absDir = scope String();
		if (targetFolder.Length > 0)
			System.IO.Path.InternalCombine(absDir, registry.RootPath, targetFolder);
		else
			absDir.Set(registry.RootPath);

		// Ensure directory exists
		if (!System.IO.Directory.Exists(absDir))
			System.IO.Directory.CreateDirectory(absDir);

		// Generate unique filename
		let baseName = scope String()..AppendF("New {}", creator.DisplayName);
		let fileName = scope String()..AppendF("{}{}", baseName, creator.Extension);
		let fullPath = scope String();
		System.IO.Path.InternalCombine(fullPath, absDir, fileName);

		if (System.IO.File.Exists(fullPath))
		{
			for (int i = 1; i < 100; i++)
			{
				fileName.Clear();
				fileName.AppendF("{} ({}){}", baseName, i, creator.Extension);
				fullPath.Clear();
				System.IO.Path.InternalCombine(fullPath, absDir, fileName);
				if (!System.IO.File.Exists(fullPath))
					break;
			}
		}

		// Create the asset
		if (creator.Create(fullPath, editorContext) case .Ok(let resourceId))
		{
			// Register in the active registry
			if (let concreteReg = registry as ResourceRegistry)
			{
				let relPath = scope String();
				if (targetFolder.Length > 0)
					relPath.AppendF("{}/{}", targetFolder, fileName);
				else
					relPath.Set(fileName);

				concreteReg.Register(resourceId, relPath);

				// Save registry to disk
				let regFile = scope String();
				System.IO.Path.InternalCombine(regFile, registry.RootPath, scope $"{registry.Name}.registry");
				concreteReg.SaveToFile(regFile);
			}

			panel.RefreshContent();
		}
	}

	/// Opens a file dialog for importing source assets, then runs the import pipeline.
	private static void TriggerImportDialog(EditorContext editorContext,
		AssetContentAdapter adapter, AssetBrowserPanel panel)
	{
		let registry = adapter.ActiveRegistry;
		if (registry == null) return;

		let dialogService = editorContext.DialogService;
		if (dialogService == null) return;

		// Build filter string from all registered importers
		let filterParts = scope List<String>();
		defer { for (let s in filterParts) delete s; }
		editorContext.GetAllImportExtensions(filterParts);

		// Build filter like "Importable Assets|gltf;glb;fbx;obj;png;jpg"
		let filterStr = scope String("Importable Assets|");
		for (int i = 0; i < filterParts.Count; i++)
		{
			if (i > 0) filterStr.Append(';');
			let ext = filterParts[i];
			// Strip leading dot for filter format
			if (ext.StartsWith('.'))
				filterStr.Append(ext[1...]);
			else
				filterStr.Append(ext);
		}
		StringView[1] filters = .(filterStr);

		dialogService.ShowOpenFileDialog(new [=editorContext, =adapter, =panel, =registry] (paths) => {
			if (paths.Length == 0) return;

			for (let sourcePath in paths)
			{
				// Find importer for this file
				let ext = scope String();
				System.IO.Path.GetExtension(sourcePath, ext);

				let importer = editorContext.GetImporterForExtension(ext);
				if (importer == null)
				{
					Console.WriteLine("No importer found for extension: {}", ext);
					continue;
				}

				// Create preview
				ImportPreview preview;
				if (importer.CreatePreview(sourcePath) case .Ok(let p))
					preview = p;
				else
				{
					Console.WriteLine("Failed to create import preview for: {}", sourcePath);
					continue;
				}

				// Build output directory (current folder in the active registry)
				let outputDir = scope String();
				if (adapter.CurrentFolder.Length > 0)
					System.IO.Path.InternalCombine(outputDir, registry.RootPath, adapter.CurrentFolder);
				else
					outputDir.Set(registry.RootPath);

				// Show import dialog
				if (let concreteReg = registry as ResourceRegistry)
				{
					let serializer = editorContext.ResourceSystem?.SerializerProvider;
					if (serializer != null)
					{
						let ctx = panel.ContentView?.Context;
						if (ctx != null)
						{
							// Dialog takes ownership of preview and is deleted by PopupLayer on close
							let importDialog = new ImportDialog(preview, importer, outputDir,
								concreteReg, serializer, panel);
							importDialog.Show(ctx);
							continue; // Don't delete preview - dialog owns it now
						}
					}
				}

				// Fallback: delete preview if dialog wasn't shown
				delete preview;
			}
		}, filters, default, true);
	}

	/// Context menu for the registry tree view nodes.
	private static void ShowTreeContextMenu(UIContext ctx, float x, float y,
		int32 nodeId, IResourceRegistry registry, bool isRoot, bool isLocked,
		RegistryTreeAdapter treeAdapter, AssetContentAdapter contentAdapter,
		AssetContentAdapter gridAdapter, EditorContext editorContext,
		AssetBrowserPanel panel, BreadcrumbBar breadcrumb)
	{
		let menu = new ContextMenu();

		// Single owned copy of the absolute path - shared by all lambdas, cleaned up by menu
		let absPathOwned = new String(treeAdapter.GetNodeAbsolutePath(nodeId));
		menu.AddOwnedObject(absPathOwned);

		if (!isRoot)
		{
			// Subdirectory node - can rename, delete, create in
			let relPath = treeAdapter.GetNodeRelativePath(nodeId);

			// Rename folder - placeholder until tree item inline rename is implemented
			menu.AddItem("Rename", new () => {
			}, enabled: false);

			// Create New submenu
			AddCreateNewSubmenu(menu, relPath, registry, editorContext, contentAdapter, panel);

			// Create Folder
			menu.AddItem("Create Folder", new [=absPathOwned, =panel] () => {
				CreateSubfolder(absPathOwned);
				panel.RefreshRegistries();
				panel.RefreshContent();
			});

			menu.AddSeparator();

			// Delete folder — copy paths for the confirm dialog since absPathOwned
			// is deleted when the context menu closes (before the dialog callback fires).
			let deleteRelPath = new String(relPath);
			menu.AddOwnedObject(deleteRelPath);
			menu.AddItem("Delete", new [=absPathOwned, =deleteRelPath, =panel, =ctx] () => {
				let pathCopy = new String(absPathOwned);
				let relPathCopy = new String(deleteRelPath);
				let dialog = Dialog.Confirm("Confirm Delete", "Delete this folder and all its contents?");
				dialog.OnClosed.Add(new [=pathCopy, =relPathCopy, =panel] (dlg, result) => {
					if (result != .OK) { delete pathCopy; delete relPathCopy; return; }

					if (System.IO.Directory.Exists(pathCopy))
						System.IO.Directory.DelTree(pathCopy);

					panel.NavigateAwayFromDeletedFolder(relPathCopy);
					panel.RefreshRegistries();
					delete pathCopy;
					delete relPathCopy;
				});
				dialog.Show(ctx);
			});

			menu.AddSeparator();

			// Show in Explorer
			menu.AddItem("Show in Explorer", new [=absPathOwned, =editorContext] () => {
				editorContext.Shell?.RevealInFileManager(absPathOwned);
			});
		}
		else
		{
			// Registry root node - limited actions

			// Create New submenu (at registry root)
			AddCreateNewSubmenu(menu, "", registry, editorContext, contentAdapter, panel);

			// Create Folder at root
			menu.AddItem("Create Folder", new [=absPathOwned, =panel] () => {
				CreateSubfolder(absPathOwned);
				panel.RefreshRegistries();
				panel.RefreshContent();
			});

			menu.AddSeparator();

			// Import
			menu.AddItem("Import...", new [=editorContext, =contentAdapter, =panel] () => {
				TriggerImportDialog(editorContext, contentAdapter, panel);
			});

			menu.AddSeparator();

			// Show in Explorer
			menu.AddItem("Show in Explorer", new [=absPathOwned, =editorContext] () => {
				editorContext.Shell?.RevealInFileManager(absPathOwned);
			});

			// Unmount (only for non-locked registries)
			if (!isLocked)
			{
				menu.AddSeparator();
				menu.AddItem("Unmount", new [=panel] () => {
					panel.UnmountSelectedRegistry();
				});
			}
		}

		menu.Show(ctx, x, y);
	}
}

/// Simple breadcrumb path bar for folder navigation.
/// Displays: [Registry] > [Folder] > [SubFolder]
/// Each segment is clickable to navigate to that level.
class BreadcrumbBar : LinearLayout
{
	private List<String> mSegments = new .() ~ DeleteContainerAndItems!(_);
	public Event<delegate void(int32 segmentIndex)> OnSegmentClicked ~ _.Dispose();

	public this()
	{
		Orientation = .Horizontal;
		Spacing = 0;
		Padding = .(6, 3, 6, 3);
	}

	/// Sets the breadcrumb path from a registry name and relative path.
	public void SetPath(StringView registryName, StringView relativePath)
	{
		// Clear old segments and views
		ClearInternal();

		// Registry name as first segment
		mSegments.Add(new String(registryName));

		// Split relative path into segments
		if (relativePath.Length > 0)
		{
			for (let part in relativePath.Split('/'))
			{
				if (part.Length > 0)
					mSegments.Add(new String(part));
			}
		}

		// Build view: clickable labels with separators
		for (int32 i = 0; i < mSegments.Count; i++)
		{
			if (i > 0)
			{
				let arrow = new Label();
				arrow.SetText("  >  ");
				arrow.FontSize = 10;
				arrow.TextColor = .(100, 105, 120, 255);
				AddView(arrow, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
			}

			let segIndex = i;
			let btn = new Button();
			btn.SetText(mSegments[i]);
			btn.FontSize = 11;
			btn.Background = null;
			btn.OnClick.Add(new (b) => {
				OnSegmentClicked(segIndex);
			});
			AddView(btn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
		}

		InvalidateLayout();
	}

	/// Reconstructs a relative path from segments 1..segmentIndex (0 is registry name).
	public void BuildPathToSegment(int32 segmentIndex, String outPath)
	{
		for (int32 i = 1; i <= segmentIndex && i < mSegments.Count; i++)
		{
			if (i > 1)
				outPath.Append('/');
			outPath.Append(mSegments[i]);
		}
	}

	private void ClearInternal()
	{
		for (let seg in mSegments)
			delete seg;
		mSegments.Clear();
		RemoveAllViews();
	}
}
