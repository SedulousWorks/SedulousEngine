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
	public static BuildResult Build(EditorContext editorContext)
	{
		let resourceSystem = editorContext.ResourceSystem;

		// === Create adapters ===
		let treeAdapter = new RegistryTreeAdapter();
		let contentAdapter = new AssetContentAdapter();

		// Populate tree from current registries
		let registries = scope List<IResourceRegistry>();
		resourceSystem.GetRegistries(registries);
		treeAdapter.SetRegistries(registries);

		// === Left pane: Registry tree ===
		let leftPane = new LinearLayout();
		leftPane.Orientation = .Vertical;

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
