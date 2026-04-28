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
	/// Result of building the browser — contains references to key components
	/// so the panel can wire events and manage state.
	public struct BuildResult
	{
		public View RootView;
		public TreeView RegistryTree;
		public RegistryTreeAdapter TreeAdapter;
		public ListView ContentList;
		public AssetContentAdapter ContentAdapter;
		public BreadcrumbBar Breadcrumb;
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

		// === Right pane: Breadcrumb + content list ===
		let rightPane = new LinearLayout();
		rightPane.Orientation = .Vertical;

		// Breadcrumb bar
		let breadcrumb = new BreadcrumbBar();
		rightPane.AddView(breadcrumb, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		// Separator
		let sep = new Panel();
		sep.Background = new ColorDrawable(.(50, 55, 65, 255));
		rightPane.AddView(sep, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 1
		});

		// Content list
		let contentList = new ListView();
		contentList.ItemHeight = 24;
		contentList.Adapter = contentAdapter;
		contentList.Selection.Mode = .Single;
		contentAdapter.OwnerListView = contentList;

		rightPane.AddView(contentList, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		// === Wire tree selection -> content view ===
		treeAdapter.OnFolderSelected.Add(new (registry, relativePath) => {
			contentAdapter.SetFolder(registry, relativePath);

			// Update breadcrumb
			breadcrumb.SetPath(registry.Name, relativePath);
		});

		// Wire tree item click -> select node
		treeView.OnItemClick.Add(new (clickInfo) => {
			treeAdapter.SelectNode(clickInfo.NodeId);
		});

		// Wire content list double-click -> navigate into folder or open asset
		contentList.OnItemClicked.Add(new (position, clickCount, x, y) => {
			if (clickCount == 2)
			{
				let item = contentAdapter.GetItem(position);
				if (item == null) return;

				if (item.IsFolder)
				{
					contentAdapter.NavigateInto(item.Name);
					breadcrumb.SetPath(
						contentAdapter.ActiveRegistry?.Name ?? "",
						contentAdapter.CurrentFolder);
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
				ShowFolderItemContextMenu(ctx, screenCoords.x, screenCoords.y, item, contentAdapter, editorContext, panel, breadcrumb);
			else
				ShowItemContextMenu(ctx, screenCoords.x, screenCoords.y, item, contentAdapter, editorContext, panel);
		});

		// Wire right-click on empty space -> background context menu
		contentList.OnBackgroundRightClicked.Add(new [=contentAdapter, =editorContext, =contentList, =breadcrumb, =panel] (localX, localY) => {
			let ctx = contentList.Context;
			if (ctx == null) return;

			let screenCoords = ToScreenCoords(contentList, localX, localY);
			ShowBackgroundContextMenu(ctx, screenCoords.x, screenCoords.y,
				contentAdapter.CurrentFolder, contentAdapter, editorContext, panel, breadcrumb);
		});

		// Wire breadcrumb navigation — deferred via mutation queue because
		// SetPath destroys the button that fired the click event.
		breadcrumb.OnSegmentClicked.Add(new [=contentAdapter, =breadcrumb] (segmentIndex) => {
			let ctx = breadcrumb.Context;
			if (ctx == null) return;

			ctx.MutationQueue.QueueAction(new [=segmentIndex, =contentAdapter, =breadcrumb] () => {
				let registry = contentAdapter.ActiveRegistry;
				if (registry == null) return;

				if (segmentIndex == 0)
				{
					contentAdapter.SetFolder(registry, "");
				}
				else
				{
					let newPath = scope String();
					breadcrumb.BuildPathToSegment(segmentIndex, newPath);
					contentAdapter.SetFolder(registry, newPath);
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
			ContentAdapter = contentAdapter,
			Breadcrumb = breadcrumb
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
		AssetContentItem item, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel)
	{
		let menu = new ContextMenu();
		let registry = adapter.ActiveRegistry;

		// Rename
		menu.AddItem("Rename", new [=item, =adapter, =panel] () => {
			// TODO: inline rename (Phase 4c polish)
		}, enabled: false);

		// Delete
		menu.AddItem("Delete", new [=item, =adapter, =registry, =panel] () => {
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
		AssetContentItem folderItem, AssetContentAdapter adapter,
		EditorContext editorContext, AssetBrowserPanel panel, BreadcrumbBar breadcrumb)
	{
		let menu = new ContextMenu();
		let registry = adapter.ActiveRegistry;

		// The target folder for creating assets is the right-clicked folder
		let targetFolder = scope String(folderItem.RelativePath);

		// Create New submenu — assets go into the right-clicked folder
		AddCreateNewSubmenu(menu, targetFolder, registry, editorContext, adapter, panel);

		// Create Folder inside this folder
		menu.AddItem("Create Folder", new [=folderItem, =panel] () => {
			CreateSubfolder(folderItem.AbsolutePath);
			panel.RefreshContent();
		});

		menu.AddSeparator();

		// Delete folder
		menu.AddItem("Delete", new [=folderItem, =panel] () => {
			if (folderItem.AbsolutePath != null && System.IO.Directory.Exists(folderItem.AbsolutePath))
				System.IO.Directory.DelTree(folderItem.AbsolutePath);
			panel.RefreshContent();
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

		// Create New submenu — assets go into the current folder
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
				defer { delete preview; }

				// Build output directory (current folder in the active registry)
				let outputDir = scope String();
				if (adapter.CurrentFolder.Length > 0)
					System.IO.Path.InternalCombine(outputDir, registry.RootPath, adapter.CurrentFolder);
				else
					outputDir.Set(registry.RootPath);

				// Run import
				if (let concreteReg = registry as ResourceRegistry)
				{
					let serializer = editorContext.ResourceSystem?.SerializerProvider;
					if (serializer != null && importer.Import(preview, outputDir, concreteReg, serializer) case .Ok)
						Console.WriteLine("Imported: {} ({} items)", sourcePath, preview.Items.Count);
					else
						Console.WriteLine("Import failed: {}", sourcePath);
				}
			}

			panel.RefreshContent();
		}, filters, default, true);
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
