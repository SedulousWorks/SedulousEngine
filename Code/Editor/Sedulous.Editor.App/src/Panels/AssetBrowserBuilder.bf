namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Resources;
using Sedulous.Editor.Core;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// Builds the asset browser panel layout:
///   Mount tree (left) | Content view (right)
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
		public EditorBreadcrumbBar Breadcrumb;
		public Panel ContentContainer;  // Holds the active content view (list or grid)
	}

	/// Builds the complete asset browser layout.
	public static BuildResult Build(EditorContext editorContext, AssetBrowserPanel panel)
	{
		// === Create adapters ===
		let treeAdapter = new RegistryTreeAdapter();
		let contentAdapter = new AssetContentAdapter();
		contentAdapter.Thumbnails = editorContext.Thumbnails;

		// Populate tree from current mount entries
		treeAdapter.SetEntries(editorContext.MountEntries);

		// === Left pane: Registry toolbar + tree ===
		let leftPane = new FlexLayout();
		leftPane.Direction = .Vertical;

		// Registry management toolbar
		let regToolbar = new Toolbar();
		let mountBtn = regToolbar.AddButton("Mount");
		let createBtn = regToolbar.AddButton("Create");
		let unmountBtn = regToolbar.AddButton("Unmount");

		mountBtn.OnClick.Add(new [=panel] (btn) => { panel.MountRegistry(); });
		createBtn.OnClick.Add(new [=panel] (btn) => { panel.CreateRegistry(); });
		unmountBtn.OnClick.Add(new [=panel] (btn) => { panel.UnmountSelectedRegistry(); });

		leftPane.AddView(regToolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Separator below toolbar
		let toolbarSep = new Panel();
		toolbarSep.Background = new ColorDrawable(.(50, 55, 65, 255));
		leftPane.AddView(toolbarSep, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(1))
		});

		let treeView = new TreeView();
		treeView.ItemHeight = 22;
		treeView.IndentWidth = 16;
		treeView.SetAdapter(treeAdapter);

		leftPane.AddView(treeView, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// === Right pane: Toolbar + Breadcrumb + content (list or grid) ===
		let rightPane = new FlexLayout();
		rightPane.Direction = .Vertical;

		// Two adapters sharing the same data - one for list, one for grid
		let listAdapter = contentAdapter;
		listAdapter.ViewMode = .List;

		let gridAdapter = new AssetContentAdapter();
		gridAdapter.ViewMode = .Grid;
		gridAdapter.Thumbnails = editorContext.Thumbnails;

		// Navigation bar: breadcrumbs (left, fills) + view mode toggles (right)
		let navBar = new FlexLayout();
		navBar.Direction = .Horizontal;
		navBar.Padding = .(0, 0, 4, 0);

		let breadcrumb = new EditorBreadcrumbBar();
		navBar.AddView(breadcrumb, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

		let listBtn = new ToggleButton("List");
		listBtn.IsChecked = true;
		let gridBtn = new ToggleButton("Grid");

		navBar.AddView(listBtn, new FlexLayout.LayoutParams() { Height = .Match });
		navBar.AddView(gridBtn, new FlexLayout.LayoutParams() { Height = .Match });

		rightPane.AddView(navBar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Separator
		let sep = new Panel();
		sep.Background = new ColorDrawable(.(50, 55, 65, 255));
		rightPane.AddView(sep, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(1))
		});

		// Content container - holds the active view (list or grid)
		let contentContainer = new Panel();
		rightPane.AddView(contentContainer, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// List view (default, visible)
		let contentList = new ListView();
		contentList.ItemHeight = 24;
		contentList.Adapter = listAdapter;
		contentList.Selection.Mode = .Single;
		listAdapter.OwnerListView = contentList;
		contentContainer.AddView(contentList, new LayoutParams() {
			Width = .Match, Height = .Match
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
			Width = .Match, Height = .Match
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
		treeAdapter.OnFolderSelected.Add(new (entry, relativePath) => {
			contentAdapter.SetFolder(entry, relativePath);
			gridAdapter.SetFolder(entry, relativePath);

			// Update breadcrumb
			breadcrumb.SetPath(entry.Scheme, relativePath);
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
			let entry = treeAdapter.GetEntryForNode(nodeId);
			let isLocked = treeAdapter.IsNodeLocked(nodeId);
			let isRoot = treeAdapter.IsMountRoot(nodeId);

			ShowTreeContextMenu(ctx, screenCoords.x, screenCoords.y, nodeId, entry,
				isRoot, isLocked, treeAdapter, contentAdapter, gridAdapter, editorContext, panel, breadcrumb);
		});

		// Wire rename commit -> rename file on disk and update index
		listAdapter.OnItemRenamed.Add(new (item, newName) => {
			HandleRename(item, newName, listAdapter, gridAdapter, editorContext);
		});

		// Wire F2 key -> inline rename on selected item
		contentList.OnItemKeyDown.Add(new [=listAdapter] (position, e) => {
			if (e.Key == .F2)
			{
				listAdapter.StartRename(position);
				e.Handled = true;
			}
		});

		// Wire grid adapter rename commit -> rename file on disk and update index
		gridAdapter.OnItemRenamed.Add(new (item, newName) => {
			HandleRename(item, newName, listAdapter, gridAdapter, editorContext);
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
							contentAdapter.ActiveEntry?.Scheme ?? "",
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
						contentAdapter.ActiveEntry?.Scheme ?? "",
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
				let entry = contentAdapter.ActiveEntry;
				if (entry == null) return;

				if (segmentIndex == 0)
				{
					contentAdapter.SetFolder(entry, "");
					gridAdapter.SetFolder(entry, "");
				}
				else
				{
					let newPath = scope String();
					breadcrumb.BuildPathToSegment(segmentIndex, newPath);
					contentAdapter.SetFolder(entry, newPath);
					gridAdapter.SetFolder(entry, newPath);
				}
				breadcrumb.SetPath(entry.Scheme, contentAdapter.CurrentFolder);
			});
		});

		// === Split view ===
		let split = new SplitView(.Horizontal);
		split.SetPanes(leftPane, rightPane);
		split.SplitRatio = 0.25f;

		// Select first mount entry by default if available
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

	// === Mount-routed file ops ===
	//
	// The editor never touches the filesystem directly for asset lifecycle
	// (rename / delete / mkdir / existence). Each op resolves the absolute
	// path to its writable mount + mount-relative locator and goes through
	// IWritableMount, so non-disk writable mounts work and the mount keeps
	// its own state coherent. Asset browser items always live under a
	// mounted entry, so a failed resolve means "not performed" (the op is
	// skipped) rather than a silent raw-IO fallback.

	private static bool MountExists(EditorContext editorContext, StringView absPath)
	{
		if (editorContext == null) return false;
		IMount mount = null;
		let loc = scope String();
		if (!MountResolver.TryResolveAbsolute(editorContext.MountEntries, absPath, out mount, loc))
			return false;
		return mount.Exists(loc);
	}

	/// The writable mount that owns `item` (null if none / read-only).
	private static IWritableMount WritableMountOf(AssetContentItem item)
	{
		if (item == null || item.Entry == null) return null;
		return item.Entry.Mount as IWritableMount;
	}

	private static bool MountDelete(EditorContext editorContext, StringView absPath)
	{
		if (editorContext == null) return false;
		IWritableMount mount = null;
		let loc = scope String();
		if (!MountResolver.TryResolveAbsoluteWritable(editorContext.MountEntries, absPath, out mount, loc))
			return false;
		return mount.Delete(loc) case .Ok;
	}

	/// Joins a mount-relative folder locator and a file name into a
	/// forward-slash locator. Empty folder -> just the file name.
	private static void BuildLocator(String dst, StringView folder, StringView fileName)
	{
		dst.Clear();
		if (folder.Length > 0)
			dst.AppendF("{}/{}", folder, fileName);
		else
			dst.Set(fileName);
	}

	private static bool MountCreateDir(EditorContext editorContext, StringView absPath)
	{
		if (editorContext == null) return false;
		IWritableMount mount = null;
		let loc = scope String();
		if (!MountResolver.TryResolveAbsoluteWritable(editorContext.MountEntries, absPath, out mount, loc))
			return false;
		return mount.CreateDirectory(loc) case .Ok;
	}

	/// Renames an item through its mount and updates the active index if
	/// the item is registered. Pure (mount, locator) - no absolute paths,
	/// no MountResolver round-trips (the item already carries its owning
	/// mount and locator).
	private static void HandleRename(AssetContentItem item, StringView newName,
		AssetContentAdapter listAdapter, AssetContentAdapter gridAdapter,
		EditorContext editorContext)
	{
		if (item.Entry == null || newName.Length == 0) return;
		let mount = item.Entry.Mount as IWritableMount;
		if (mount == null) return;

		let oldLocator = scope String(item.Locator);
		if (oldLocator.Length == 0) return;

		// New locator = old locator's parent folder + new name.
		let newLocator = scope String();
		let lastSlash = oldLocator.LastIndexOf('/');
		if (lastSlash >= 0)
			newLocator.AppendF("{}/{}", oldLocator.Substring(0, lastSlash), newName);
		else
			newLocator.Set(newName);

		// Don't rename onto an existing entry.
		if (mount.Exists(newLocator))
			return;

		// Cache is URI-keyed; re-key (not evict) so the loaded resource
		// keeps its single cache slot + Shutdown teardown anchor, and a
		// later open of the renamed file reuses the same instance.
		let oldUri = scope String()..AppendF("{}://{}", item.Entry.Scheme, oldLocator);
		let newUri = scope String()..AppendF("{}://{}", item.Entry.Scheme, newLocator);

		if (mount.Move(oldLocator, newLocator) case .Err)
			return;

		// Move the conventional "<locator>.bin" pixel/PCM sidecar with the
		// asset so the derived-name loader still finds it (no metadata).
		let oldBin = scope String()..AppendF("{}.bin", oldLocator);
		if (mount.Exists(oldBin))
			mount.Move(oldBin, scope String()..AppendF("{}.bin", newLocator)).IgnoreError();

		if (item.IsRegistered && item.Entry.Index != null)
		{
			item.Entry.Index.Register(item.RegistryId, newUri);
			PersistIndex(item.Entry);
		}

		editorContext?.ResourceSystem?.RecacheUri(oldUri, newUri);

		// Refresh both views
		listAdapter.Rebuild();
		gridAdapter.Rebuild();
	}

	/// Serializes a MountEntry's index back through its mount, if both an
	/// index and a writable mount + index locator are present.
	private static void PersistIndex(MountEntry entry)
	{
		if (entry == null || entry.Index == null || entry.IndexLocator.IsEmpty)
			return;
		let writable = entry.Mount as IWritableMount;
		if (writable == null)
			return;
		let stream = scope MemoryStream();
		if (entry.Index.SerializeTo(stream) case .Err)
			return;
		stream.Position = 0;
		writable.Save(entry.IndexLocator, stream);
	}

	// ==================== Context Menus ====================

	/// Context menu for a file/asset item.
	private static void ShowItemContextMenu(UIContext ctx, float x, float y,
		AssetContentItem item, int32 position, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel)
	{
		let menu = new ContextMenu();
		let entry = adapter.ActiveEntry;

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
		menu.AddItem("Delete", new () => {
			let confirmMsg = scope String();
			confirmMsg.AppendF("Delete '{}'?", item.Name);
			let dialog = Dialog.Confirm("Confirm Delete", confirmMsg);
			dialog.OnClosed.Add(new [=item, =entry, =panel] (dlg, result) => {
				if (result != .OK) return;

				if (let m = WritableMountOf(item))
				{
					m.Delete(item.Locator).IgnoreError();
					// Remove the conventional "<locator>.bin" sidecar too,
					// if this asset has one.
					let bin = scope String()..AppendF("{}.bin", item.Locator);
					if (m.Exists(bin))
						m.Delete(bin).IgnoreError();
				}

				// Unregister from index and save
				if (item.IsRegistered && entry != null && entry.Index != null)
				{
					entry.Index.Unregister(item.RegistryId);
					PersistIndex(entry);
				}

				panel.RefreshContent();
			});
			dialog.Show(ctx);
		});

		menu.AddSeparator();

		// Copy Path (URI)
		if (item.IsRegistered && entry != null)
		{
			menu.AddItem("Copy Path", new [=item, =entry, =ctx] () => {
				let uri = scope String();
				if (entry.Scheme.Length > 0)
					uri.AppendF("{}://{}", entry.Scheme, item.RelativePath);
				else
					uri.Set(item.RelativePath);

				ctx.Clipboard?.SetText(uri);
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

		// Show in Explorer - OS shell action, only meaningful for a real
		// filesystem mount (non-disk mounts have no AbsolutePath).
		if (item.Entry != null && item.Entry.Mount is FileSystemMount && item.AbsolutePath != null)
		{
			menu.AddItem("Show in Explorer", new [=item, =editorContext] () => {
				let dirPath = scope String();
				Path.GetDirectoryPath(item.AbsolutePath, dirPath);
				editorContext.Shell?.RevealInFileManager(dirPath);
			});
		}

		menu.Show(ctx, x, y);
	}

	/// Context menu for a folder item in the content view.
	private static void ShowFolderItemContextMenu(UIContext ctx, float x, float y,
		AssetContentItem folderItem, int32 position, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel, EditorBreadcrumbBar breadcrumb)
	{
		let menu = new ContextMenu();
		let entry = adapter.ActiveEntry;

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
		AddCreateNewSubmenu(menu, targetFolder, entry, editorContext, adapter, panel);

		// Create Folder inside this folder
		menu.AddItem("Create Folder", new [=folderItem, =panel, =editorContext] () => {
			CreateSubfolder(editorContext, folderItem.AbsolutePath);
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

				if (let m = WritableMountOf(folderItem))
					m.Delete(folderItem.Locator).IgnoreError();

				panel.NavigateAwayFromDeletedFolder(deletedRelPath);
				delete deletedRelPath;
			});
			dialog.Show(ctx);
		});

		menu.AddSeparator();

		// Show in Explorer - OS shell action, disk mounts only.
		if (folderItem.Entry != null && folderItem.Entry.Mount is FileSystemMount && folderItem.AbsolutePath != null)
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
		EditorContext editorContext, AssetBrowserPanel panel, EditorBreadcrumbBar breadcrumb)
	{
		let menu = new ContextMenu();
		let entry = adapter.ActiveEntry;

		// Create New submenu - assets go into the current folder
		AddCreateNewSubmenu(menu, targetFolder, entry, editorContext, adapter, panel);

		// Create Folder in current directory
		let currentAbsDir = new String();
		if (entry != null)
		{
			let fsMount = entry.Mount as FileSystemMount;
			if (fsMount != null)
			{
				if (targetFolder.Length > 0)
					Path.InternalCombine(currentAbsDir, fsMount.RootPath, targetFolder);
				else
					currentAbsDir.Set(fsMount.RootPath);
			}
		}
		menu.AddOwnedObject(currentAbsDir);

		menu.AddItem("Create Folder", new () => {
			CreateSubfolder(editorContext, currentAbsDir);
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
		MountEntry entry, EditorContext editorContext,
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
					CreateAssetInFolder(creator, folderCopy, entry, editorContext, panel);
				});
			}
		}
	}

	/// Creates a new subfolder with a unique name inside parentDir, through
	/// the resolved writable mount.
	private static void CreateSubfolder(EditorContext editorContext, StringView parentDir)
	{
		if (parentDir.Length == 0) return;

		let newDir = scope String();
		Path.InternalCombine(newDir, parentDir, "New Folder");

		if (MountExists(editorContext, newDir))
		{
			for (int i = 1; i < 100; i++)
			{
				newDir.Clear();
				Path.InternalCombine(newDir, parentDir, scope $"New Folder ({i})");
				if (!MountExists(editorContext, newDir))
					break;
			}
		}

		MountCreateDir(editorContext, newDir);
	}

	/// Creates an asset in a specific folder and registers it in the index.
	/// targetFolder is the locator within the mount (e.g. "models" or "").
	private static void CreateAssetInFolder(IAssetCreator creator,
		StringView targetFolder, MountEntry entry,
		EditorContext editorContext, AssetBrowserPanel panel)
	{
		if (entry == null) return;
		let writable = entry.Mount as IWritableMount;
		if (writable == null) return;

		// All paths here are mount-relative locators (forward-slash). The
		// creator writes through the mount; nothing touches the filesystem
		// directly, so this works for any writable mount.

		// Ensure the target folder exists in locator space.
		if (targetFolder.Length > 0)
			writable.CreateDirectory(targetFolder);

		// Generate a unique locator within the target folder.
		let baseName = scope String()..AppendF("New {}", creator.DisplayName);
		let fileName = scope String()..AppendF("{}{}", baseName, creator.Extension);
		let locator = scope String();
		BuildLocator(locator, targetFolder, fileName);

		if (writable.Exists(locator))
		{
			for (int i = 1; i < 100; i++)
			{
				fileName.Clear();
				fileName.AppendF("{} ({}){}", baseName, i, creator.Extension);
				locator.Clear();
				BuildLocator(locator, targetFolder, fileName);
				if (!writable.Exists(locator))
					break;
			}
		}

		// Create the asset through the mount.
		if (creator.Create(writable, locator, editorContext) case .Ok(let resourceId))
		{
			// Register in the active index.
			if (entry.Index != null)
			{
				let uri = scope String();
				uri.AppendF("{}://{}", entry.Scheme, locator);
				entry.Index.Register(resourceId, uri);

				PersistIndex(entry);
			}

			panel.RefreshContent();
		}
	}

	/// Opens a file dialog for importing source assets, then runs the import pipeline.
	private static void TriggerImportDialog(EditorContext editorContext,
		AssetContentAdapter adapter, AssetBrowserPanel panel)
	{
		let entry = adapter.ActiveEntry;
		if (entry == null) return;
		let writable = entry.Mount as IWritableMount;
		if (writable == null) return;

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

		dialogService.ShowOpenFileDialog(new [=editorContext, =adapter, =panel, =entry, =writable] (paths) => {
			if (paths.Length == 0) return;

			for (let sourcePath in paths)
				DispatchImportFile(editorContext, adapter, panel, entry, writable, sourcePath);
		}, filters, default, true);
	}

	/// Runs the importer-lookup + preview + ImportDialog flow for a single
	/// source file in the context of `panel`. Shared between the manual
	/// "Import..." button (which iterates paths from the OS file picker)
	/// and the drag-drop-from-OS path in EditorApplication. Both call sites
	/// already have the entry / writable mount resolved; pass them in to
	/// avoid double-resolving.
	public static void DispatchImportFile(EditorContext editorContext,
		AssetContentAdapter adapter, AssetBrowserPanel panel,
		MountEntry entry, IWritableMount writable, StringView sourcePath)
	{
		// Find importer for this file
		let ext = scope String();
		Path.GetExtension(sourcePath, ext);

		let importer = editorContext.GetImporterForExtension(ext);
		if (importer == null)
		{
			editorContext.Logger?.LogWarning("No importer found for extension: {}", ext);
			return;
		}

		// Create preview
		ImportPreview preview;
		if (importer.CreatePreview(sourcePath) case .Ok(let p))
			preview = p;
		else
		{
			editorContext.Logger?.LogError("Failed to create import preview for: {}", sourcePath);
			return;
		}

		// Build base locator (current folder in the active mount, with trailing slash)
		let baseLocator = scope String();
		if (adapter.CurrentFolder.Length > 0)
		{
			baseLocator.Append(adapter.CurrentFolder);
			baseLocator.Append('/');
		}

		// URI prefix: "scheme://baseLocator"
		let uriPrefix = scope String();
		uriPrefix.AppendF("{}://{}", entry.Scheme, baseLocator);

		// Show import dialog
		let serializer = editorContext.ResourceSystem?.SerializerProvider;
		if (serializer != null)
		{
			let ctx = panel.ContentView?.Context;
			if (ctx != null)
			{
				// Dialog takes ownership of preview and is deleted by PopupLayer on close
				let importDialog = new ImportDialog(preview, importer, writable, baseLocator,
					entry.Index, uriPrefix, entry.IndexLocator, serializer, panel,
					editorContext.Logger, editorContext);
				importDialog.Show(ctx);
				return; // Don't delete preview - dialog owns it now
			}
		}

		// Fallback: delete preview if dialog wasn't shown
		delete preview;
	}

	/// Context menu for the mount tree view nodes.
	private static void ShowTreeContextMenu(UIContext ctx, float x, float y,
		int32 nodeId, MountEntry entry, bool isRoot, bool isLocked,
		RegistryTreeAdapter treeAdapter, AssetContentAdapter contentAdapter,
		AssetContentAdapter gridAdapter, EditorContext editorContext,
		AssetBrowserPanel panel, EditorBreadcrumbBar breadcrumb)
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
			AddCreateNewSubmenu(menu, relPath, entry, editorContext, contentAdapter, panel);

			// Create Folder
			menu.AddItem("Create Folder", new [=absPathOwned, =panel, =editorContext] () => {
				CreateSubfolder(editorContext, absPathOwned);
				panel.RefreshRegistries();
				panel.RefreshContent();
			});

			menu.AddSeparator();

			// Delete folder - copy paths for the confirm dialog since absPathOwned
			// is deleted when the context menu closes (before the dialog callback fires).
			let deleteRelPath = new String(relPath);
			menu.AddOwnedObject(deleteRelPath);
			menu.AddItem("Delete", new [=absPathOwned, =deleteRelPath, =panel, =ctx, =editorContext] () => {
				let pathCopy = new String(absPathOwned);
				let relPathCopy = new String(deleteRelPath);
				let dialog = Dialog.Confirm("Confirm Delete", "Delete this folder and all its contents?");
				dialog.OnClosed.Add(new [=pathCopy, =relPathCopy, =panel, =editorContext] (dlg, result) => {
					if (result != .OK) { delete pathCopy; delete relPathCopy; return; }

					MountDelete(editorContext, pathCopy);

					panel.NavigateAwayFromDeletedFolder(relPathCopy);
					panel.RefreshRegistries();
					delete pathCopy;
					delete relPathCopy;
				});
				dialog.Show(ctx);
			});

			menu.AddSeparator();

			// Show in Explorer - disk mounts only (the node's AbsolutePath
			// is empty for non-filesystem mounts).
			if (!absPathOwned.IsEmpty)
			{
				menu.AddItem("Show in Explorer", new [=absPathOwned, =editorContext] () => {
					editorContext.Shell?.RevealInFileManager(absPathOwned);
				});
			}
		}
		else
		{
			// Mount root node - limited actions

			// Create New submenu (at mount root)
			AddCreateNewSubmenu(menu, "", entry, editorContext, contentAdapter, panel);

			// Create Folder at root
			menu.AddItem("Create Folder", new [=absPathOwned, =panel, =editorContext] () => {
				CreateSubfolder(editorContext, absPathOwned);
				panel.RefreshRegistries();
				panel.RefreshContent();
			});

			menu.AddSeparator();

			// Import
			menu.AddItem("Import...", new [=editorContext, =contentAdapter, =panel] () => {
				TriggerImportDialog(editorContext, contentAdapter, panel);
			});

			menu.AddSeparator();

			// Show in Explorer - disk mounts only (the node's AbsolutePath
			// is empty for non-filesystem mounts).
			if (!absPathOwned.IsEmpty)
			{
				menu.AddItem("Show in Explorer", new [=absPathOwned, =editorContext] () => {
					editorContext.Shell?.RevealInFileManager(absPathOwned);
				});
			}

			// Unmount (only for non-locked entries)
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
/// Displays: [Scheme] > [Folder] > [SubFolder]
/// Each segment is clickable to navigate to that level.
class EditorBreadcrumbBar : FlexLayout
{
	private List<String> mSegments = new .() ~ DeleteContainerAndItems!(_);
	public Event<delegate void(int32 segmentIndex)> OnSegmentClicked ~ _.Dispose();

	public this()
	{
		Direction = .Horizontal;
		Spacing = 0;
		Padding = .(6, 3, 6, 3);
	}

	/// Sets the breadcrumb path from a scheme name and relative path.
	public void SetPath(StringView schemeName, StringView relativePath)
	{
		// Clear old segments and views
		ClearInternal();

		// Scheme name as first segment
		mSegments.Add(new String(schemeName));

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
				AddView(arrow, new FlexLayout.LayoutParams() { Height = .Match });
			}

			let segIndex = i;
			let btn = new Button(mSegments[i]);
			btn.FontSize = 11;
			btn.Background = null;
			btn.OnClick.Add(new (b) => {
				OnSegmentClicked(segIndex);
			});
			AddView(btn, new FlexLayout.LayoutParams() { Height = .Match });
		}

		Invalidate();
	}

	/// Reconstructs a relative path from segments 1..segmentIndex (0 is scheme name).
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
		RemoveAllViews(true);
	}
}
