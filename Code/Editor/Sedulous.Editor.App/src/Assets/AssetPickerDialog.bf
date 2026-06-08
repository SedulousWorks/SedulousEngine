namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Resources;

using internal Sedulous.UI;

/// Modal dialog for selecting a resource from mounted registries.
/// Shows registry tree (left) + content list/grid (right) with only
/// registered items visible. Optional extension filter.
///
/// Usage:
///   let picker = new AssetPickerDialog(editorContext, ".mesh",
///       new (path, id) => { /* use selected asset */ });
///   picker.Show(ctx);
class AssetPickerDialog : Dialog
{
	private EditorContext mEditorContext;
	private delegate void(StringView, Guid) mOnSelected ~ delete _;
	private Button mSelectBtn;

	// Adapters (owned by this dialog, not by views - views are deleted by Dialog)
	private RegistryTreeAdapter mTreeAdapter ~ delete _;
	private AssetContentAdapter mListAdapter ~ delete _;
	private AssetContentAdapter mGridAdapter ~ delete _;

	// Content views (for selection tracking)
	private ListView mContentList;
	private GridContentView mContentGrid;
	private bool mGridMode;

	public this(EditorContext editorContext, StringView extensionFilter,
		delegate void(StringView protocolPath, Guid id) onSelected)
		: base("Select Asset")
	{
		mEditorContext = editorContext;
		mOnSelected = onSelected;

		MinWidth.Value = 500;
		MinHeight.Value = 400;
		MaxWidth.Value = 700;
		MaxHeight.Value = 550;

		BuildContent(extensionFilter);

		mSelectBtn = AddButton("Select", .OK);
		AddButton("Cancel", .Cancel);

		OnClosed.Add(new (dialog, result) => {
			if (result == .OK)
				ConfirmSelection();
		});
	}

	private void BuildContent(StringView extensionFilter)
	{
		// Create adapters
		mTreeAdapter = new RegistryTreeAdapter();
		mListAdapter = new AssetContentAdapter();
		mListAdapter.ViewMode = .List;
		mListAdapter.RegistryOnly = true;
		mListAdapter.Thumbnails = mEditorContext.Thumbnails;
		mListAdapter.SetExtensionFilter(extensionFilter);

		mGridAdapter = new AssetContentAdapter();
		mGridAdapter.ViewMode = .Grid;
		mGridAdapter.RegistryOnly = true;
		mGridAdapter.Thumbnails = mEditorContext.Thumbnails;
		mGridAdapter.SetExtensionFilter(extensionFilter);

		// Populate tree from the editor's mount entries
		mTreeAdapter.SetEntries(mEditorContext.MountEntries);

		// === Layout ===
		let split = new SplitView(.Horizontal);
		split.SplitRatio = 0.3f;

		// Left: registry tree
		let treeView = new TreeView();
		treeView.ItemHeight = 22;
		treeView.IndentWidth.Value = 16;
		treeView.SetAdapter(mTreeAdapter);

		// Right: nav bar + content
		let rightPane = new FlexLayout();
		rightPane.Direction = .Vertical;

		// Nav bar: breadcrumb + view toggle
		let navBar = new FlexLayout();
		navBar.Direction = .Horizontal;
		navBar.Padding = .(0, 0, 4, 0);

		let breadcrumb = new EditorBreadcrumbBar();
		navBar.AddView(breadcrumb, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

		let listBtn = new ToggleButton("List");
		listBtn.IsChecked.Value = true;
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

		// Content container
		let contentContainer = new Panel();
		rightPane.AddView(contentContainer, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// List view (default)
		mContentList = new ListView();
		mContentList.ItemHeight.Value = 24;
		mContentList.Adapter = mListAdapter;
		mContentList.Selection.Mode = .Single;
		mListAdapter.OwnerListView = mContentList;
		contentContainer.AddView(mContentList, new LayoutParams() {
			Width = .Match, Height = .Match
		});

		// Grid view (hidden)
		mContentGrid = new GridContentView();
		mContentGrid.CellWidth = 80;
		mContentGrid.CellHeight = 96;
		mContentGrid.Adapter = mGridAdapter;
		mContentGrid.Selection.Mode = .Single;
		mContentGrid.Visibility = .Gone;
		mGridAdapter.OwnerGridView = mContentGrid;
		contentContainer.AddView(mContentGrid, new LayoutParams() {
			Width = .Match, Height = .Match
		});

		split.SetPanes(treeView, rightPane);

		// === Wire events ===

		// Tree click -> navigate
		treeView.OnItemClick.Add(new (clickInfo) => {
			mTreeAdapter.SelectNode(clickInfo.NodeId);
		});

		mTreeAdapter.OnFolderSelected.Add(new (entry, relativePath) => {
			mListAdapter.SetFolder(entry, relativePath);
			mGridAdapter.SetFolder(entry, relativePath);
			breadcrumb.SetPath(entry.Scheme, relativePath);
		});

		// List double-click -> navigate folder or select asset
		mContentList.OnItemClicked.Add(new (position, clickCount, x, y) => {
			if (clickCount == 2)
			{
				let item = mListAdapter.GetItem(position);
				if (item == null) return;

				if (item.IsFolder)
				{
					let folderName = new String(item.Name);
					mContentList.Context?.MutationQueue.QueueAction(new () => {
						mListAdapter.NavigateInto(folderName);
						mGridAdapter.NavigateInto(folderName);
						breadcrumb.SetPath(
							mListAdapter.ActiveEntry?.Scheme ?? "",
							mListAdapter.CurrentFolder);
						delete folderName;
					});
				}
				else if (item.IsRegistered)
				{
					ConfirmSelection();
					Close(.OK);
				}
			}
		});

		// Grid double-click -> navigate folder or select asset
		mContentGrid.OnItemDoubleClicked.Add(new (position) => {
			let item = mGridAdapter.GetItem(position);
			if (item == null) return;

			if (item.IsFolder)
			{
				let folderName = new String(item.Name);
				mContentGrid.Context?.MutationQueue.QueueAction(new () => {
					mListAdapter.NavigateInto(folderName);
					mGridAdapter.NavigateInto(folderName);
					breadcrumb.SetPath(
						mListAdapter.ActiveEntry?.Scheme ?? "",
						mListAdapter.CurrentFolder);
					delete folderName;
				});
			}
			else if (item.IsRegistered)
			{
				ConfirmSelection();
				Close(.OK);
			}
		});

		// View mode toggle
		listBtn.OnCheckedChanged.Add(new (btn, val) => {
			if (val)
			{
				gridBtn.IsChecked.Value = false;
				mContentList.Visibility = .Visible;
				mContentGrid.Visibility = .Gone;
				mGridMode = false;
			}
		});
		gridBtn.OnCheckedChanged.Add(new (btn, val) => {
			if (val)
			{
				listBtn.IsChecked.Value = false;
				mContentList.Visibility = .Gone;
				mContentGrid.Visibility = .Visible;
				mGridMode = true;
			}
		});

		// Breadcrumb navigation
		breadcrumb.OnSegmentClicked.Add(new (segmentIndex) => {
			let ctx = breadcrumb.Context;
			if (ctx == null) return;

			ctx.MutationQueue.QueueAction(new () => {
				let entry = mListAdapter.ActiveEntry;
				if (entry == null) return;

				if (segmentIndex == 0)
				{
					mListAdapter.SetFolder(entry, "");
					mGridAdapter.SetFolder(entry, "");
				}
				else
				{
					let newPath = scope String();
					breadcrumb.BuildPathToSegment(segmentIndex, newPath);
					mListAdapter.SetFolder(entry, newPath);
					mGridAdapter.SetFolder(entry, newPath);
				}
				breadcrumb.SetPath(entry.Scheme, mListAdapter.CurrentFolder);
			});
		});

		// Select first registry by default
		if (mTreeAdapter.RootCount > 0)
		{
			let flatAdapter = treeView.FlatAdapter;
			if (flatAdapter != null && flatAdapter.ItemCount > 0)
			{
				let firstNodeId = flatAdapter.GetNodeId(0);
				mTreeAdapter.SelectNode(firstNodeId);
			}
		}

		SetContent(split);
	}

	/// Gets the currently selected item from whichever view is active.
	private AssetContentItem GetSelectedItem()
	{
		if (mGridMode)
		{
			let sel = mContentGrid.Selection.FirstSelected;
			if (sel >= 0)
				return mGridAdapter.GetItem(sel);
		}
		else
		{
			let sel = mContentList.Selection.FirstSelected;
			if (sel >= 0)
				return mListAdapter.GetItem(sel);
		}
		return null;
	}

	/// Confirms the current selection and invokes the callback.
	private void ConfirmSelection()
	{
		let item = GetSelectedItem();
		if (item == null || !item.IsRegistered || item.IsFolder)
			return;

		let entry = mListAdapter.ActiveEntry;
		if (entry == null) return;

		// Build scheme-prefixed URI
		let uri = scope String();
		if (entry.Scheme.Length > 0)
			uri.AppendF("{}://{}", entry.Scheme, item.RelativePath);
		else
			uri.Set(item.RelativePath);

		mOnSelected?.Invoke(uri, item.RegistryId);
	}
}
