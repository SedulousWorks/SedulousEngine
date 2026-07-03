namespace Sedulous.Editor;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Resources;
using Sedulous.Editor.Core;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Core.Mathematics;

/// Represents one item in the asset browser content view.
class AssetContentItem
{
	public enum ItemKind { Folder, File }

	public String Name ~ delete _;              // Display name (filename or folder name)
	public String AbsolutePath ~ delete _;      // Full filesystem path (disk mounts only; derived)
	public String RelativePath ~ delete _;      // Path relative to mount root (locator)
	public String Extension ~ delete _;         // File extension (e.g. ".mesh"), empty for folders
	public ItemKind Kind;
	public Guid RegistryId;                     // GUID if registered, default Guid if not
	public bool IsRegistered;                   // Has a GUID in the active index
	public bool IsMissing;                      // Registered but absent from the mount (broken ref)

	/// The mount entry this item belongs to (non-owning). Provides the
	/// owning mount + scheme so consumers can address the item as
	/// (mount, locator) without round-tripping through MountResolver.
	public MountEntry Entry;

	public bool IsFolder => Kind == .Folder;

	/// Mount-relative locator for this item (alias of RelativePath - the
	/// (mount, locator) address key for the VFS migration).
	public StringView Locator => RelativePath;

	/// URI scheme of the owning mount ("" if unknown).
	public StringView Scheme => (Entry != null) ? Entry.Scheme : default;
}

/// List adapter for the asset browser content pane.
/// Shows files and folders in the selected directory, merged with index entries.
///
/// Items come from two sources:
///   1. Filesystem: files and subdirectories at the current path
///   2. Index: entries whose URI points into the current folder
///
/// Folders always sort before files. Within each group, items are sorted alphabetically.
class AssetContentAdapter : ListAdapterBase
{
	private List<AssetContentItem> mItems = new .() ~ DeleteContainerAndItems!(_);
	private MountEntry mEntry;
	private String mCurrentFolder = new .() ~ delete _;  // Locator within mount (e.g. "primitives")

	/// Optional thumbnail service. When set (non-null), grid and list cells
	/// request a thumbnail for their bound asset on Bind and swap their
	/// drawable when it arrives. When null, cells stay on their default icon.
	/// Non-owning - the EditorContext owns the service's lifetime.
	public ThumbnailService Thumbnails;

	/// When true, only shows items that have a GUID in the active index.
	/// Filesystem items without index entries are hidden.
	public bool RegistryOnly;

	/// When set (non-empty), only shows files whose extension matches.
	/// Folders are always shown regardless of filter.
	public String ExtensionFilter ~ delete _;

	/// Sets the extension filter. Pass empty/null to clear.
	public void SetExtensionFilter(StringView filter)
	{
		if (filter.Length > 0)
		{
			if (ExtensionFilter == null)
				ExtensionFilter = new String(filter);
			else
				ExtensionFilter.Set(filter);
		}
		else
		{
			delete ExtensionFilter;
			ExtensionFilter = null;
		}
	}

	/// Gets the number of items.
	public override int32 ItemCount => (int32)mItems.Count;

	/// Gets the item at a position.
	public AssetContentItem GetItem(int32 position)
	{
		if (position < 0 || position >= mItems.Count)
			return null;
		return mItems[position];
	}

	/// Gets the current folder path (relative to mount root).
	public StringView CurrentFolder => mCurrentFolder;

	/// Gets the active mount entry.
	public MountEntry ActiveEntry => mEntry;

	/// The owning ListView (set by AssetBrowserBuilder after construction).
	public ListView OwnerListView { get; set; }

	/// The owning GridContentView (set by AssetBrowserBuilder after construction).
	public GridContentView OwnerGridView { get; set; }

	/// Sets the active mount and navigates to a folder within it.
	public void SetFolder(MountEntry entry, StringView relativePath)
	{
		mEntry = entry;
		mCurrentFolder.Set(relativePath);

		Rebuild();

		// Reset scroll and selection when switching folders
		if (OwnerListView != null)
		{
			OwnerListView.ScrollToPosition(0);
			OwnerListView.Selection.ClearSelection();
		}
	}

	/// Navigates into a subfolder (relative to current).
	public void NavigateInto(StringView folderName)
	{
		if (mCurrentFolder.Length > 0)
			mCurrentFolder.AppendF("/{}", folderName);
		else
			mCurrentFolder.Set(folderName);

		Rebuild();
	}

	/// Navigates up one level. Returns false if already at root.
	public bool NavigateUp()
	{
		if (mCurrentFolder.Length == 0)
			return false;

		let lastSlash = mCurrentFolder.LastIndexOf('/');
		if (lastSlash >= 0)
			mCurrentFolder.RemoveToEnd(lastSlash);
		else
			mCurrentFolder.Clear();

		Rebuild();
		return true;
	}

	/// Rebuilds the item list from filesystem + index.
	public void Rebuild()
	{
		ClearItems();

		let enumMount = (mEntry != null) ? mEntry.Mount as IEnumerableMount : null;
		if (mEntry == null || enumMount == null)
		{
			NotifyDataSetChanged();
			return;
		}

		// Disk-backed mounts expose a real filesystem path, so items can
		// carry an AbsolutePath (platform "reveal in explorer"). Non-disk
		// mounts leave it null; addressing is otherwise (mount, locator).
		let fsMount = mEntry.Mount as FileSystemMount;

		// Mount enumeration is locator-space: "" for the root, "folder/"
		// for a subfolder (note the trailing slash, per IEnumerableMount).
		let folderLoc = scope String();
		if (mCurrentFolder.Length > 0)
		{
			folderLoc.Set(mCurrentFolder);
			folderLoc.Append('/');
		}

		// Collect index entries whose URI lives in this folder.
		// URI prefix matches "scheme://currentFolder/" for the active mount.
		let uriPrefix = scope String();
		uriPrefix.AppendF("{}://", mEntry.Scheme);
		if (mCurrentFolder.Length > 0)
		{
			uriPrefix.Append(mCurrentFolder);
			uriPrefix.Append('/');
		}

		// (guid, filename-within-folder) pairs for direct children only.
		let registryEntries = scope List<(Guid id, StringView path, StringView name)>();
		if (mEntry.Index != null)
		{
			let allEntries = scope List<(Guid id, StringView uri)>();
			mEntry.Index.GetEntries(allEntries);
			for (let e in allEntries)
			{
				let uri = e.uri;
				if (!uri.StartsWith(uriPrefix))
					continue;
				let remainder = uri[uriPrefix.Length...];
				if (remainder.Contains('/'))
					continue; // not a direct child

				// `path` slot: relative locator inside the mount (no scheme).
				let schemeSep = uri.IndexOf("://");
				let relPath = (schemeSep >= 0) ? uri[(schemeSep + 3)...] : uri;
				registryEntries.Add((e.id, relPath, remainder));
			}
		}

		// Build a set of indexed filenames for quick lookup
		let registryNames = scope Dictionary<StringView, Guid>();
		for (let entry in registryEntries)
			registryNames[entry.name] = entry.id;

		// Enumerate the current folder through the mount (locator-space).
		// Entries are full locators; directory entries end with '/'.
		let rawEntries = scope List<String>();
		defer { for (let s in rawEntries) delete s; }
		enumMount.Enumerate(folderLoc, rawEntries);

		let dirs = scope List<String>();
		defer { for (let s in dirs) delete s; }
		let files = scope List<String>();
		defer { for (let s in files) delete s; }
		for (let e in rawEntries)
		{
			bool isDir = e.EndsWith('/');
			var body = StringView(e);
			if (isDir)
				body = body.Substring(0, body.Length - 1);
			let slash = body.LastIndexOf('/');
			let name = (slash >= 0) ? body.Substring(slash + 1) : body;
			if (name.StartsWith("."))
				continue;
			if (isDir)
				dirs.Add(new String(name));
			else
			{
				// Skip .registry files from the content view
				if (name.EndsWith(".registry"))
					continue;
				files.Add(new String(name));
			}
		}
		dirs.Sort(scope (a, b) => a.CompareTo(b, true));
		files.Sort(scope (a, b) => a.CompareTo(b, true));

		for (let dirName in dirs)
		{
			let item = new AssetContentItem();
			item.Entry = mEntry;
			item.Name = new String(dirName);
			item.Kind = .Folder;
			item.Extension = new String();

			item.RelativePath = new String();
			if (mCurrentFolder.Length > 0)
				item.RelativePath.AppendF("{}/{}", mCurrentFolder, dirName);
			else
				item.RelativePath.Set(dirName);

			if (fsMount != null)
			{
				item.AbsolutePath = new String();
				Path.InternalCombine(item.AbsolutePath, fsMount.RootPath, item.RelativePath);
			}

			mItems.Add(item);
		}

		for (let fileName in files)
		{
			let item = new AssetContentItem();
			item.Entry = mEntry;
			item.Name = new String(fileName);
			item.Kind = .File;

			item.Extension = new String();
			let dotIdx = fileName.LastIndexOf('.');
			if (dotIdx >= 0)
				item.Extension.Set(fileName[dotIdx...]);

			item.RelativePath = new String();
			if (mCurrentFolder.Length > 0)
				item.RelativePath.AppendF("{}/{}", mCurrentFolder, fileName);
			else
				item.RelativePath.Set(fileName);

			if (fsMount != null)
			{
				item.AbsolutePath = new String();
				Path.InternalCombine(item.AbsolutePath, fsMount.RootPath, item.RelativePath);
			}

			// Check if this file is in the index
			if (registryNames.TryGetValueAlt(StringView(fileName), let guid))
			{
				item.IsRegistered = true;
				item.RegistryId = guid;
			}

			// RegistryOnly mode: skip files without an index entry
			if (RegistryOnly && !item.IsRegistered)
			{
				delete item;
				continue;
			}

			// Extension filter: skip files that don't match
			if (ExtensionFilter != null && !item.IsFolder &&
				!item.Extension.Equals(ExtensionFilter, .OrdinalIgnoreCase))
			{
				delete item;
				continue;
			}

			mItems.Add(item);
		}

		// Add index entries that point to missing files (warning items)
		for (let entry in registryEntries)
		{
			bool foundOnDisk = false;
			for (let item in mItems)
			{
				if (item.Name != null && StringView(item.Name) == entry.name)
				{
					foundOnDisk = true;
					break;
				}
			}

			if (!foundOnDisk)
			{
				// Extension filter: skip entries that don't match
				if (ExtensionFilter != null)
				{
					let dotIdx2 = entry.name.LastIndexOf('.');
					if (dotIdx2 >= 0)
					{
						let ext = entry.name[dotIdx2...];
						if (!ext.Equals(ExtensionFilter, true))
							continue;
					}
				}

				let item = new AssetContentItem();
				item.Entry = mEntry;
				item.Name = new String(entry.name);
				item.Kind = .File;

				item.Extension = new String();
				let dotIdx = entry.name.LastIndexOf('.');
				if (dotIdx >= 0)
					item.Extension.Set(entry.name[dotIdx...]);

				item.RelativePath = new String(entry.path);

				if (fsMount != null)
				{
					item.AbsolutePath = new String();
					Path.InternalCombine(item.AbsolutePath, fsMount.RootPath, entry.path);
				}

				item.IsRegistered = true;
				item.RegistryId = entry.id;
				// This item exists only in the index, not in the mount
				// enumeration above - it's a broken/missing reference.
				item.IsMissing = true;

				mItems.Add(item);
			}
		}

		NotifyDataSetChanged();
	}

	/// View mode for CreateView/BindView.
	public enum ContentViewMode { List, Grid }
	public ContentViewMode ViewMode = .List;

	/// Position of the item currently being renamed, or -1.
	private int32 mRenamingPosition = -1;

	/// Fired when a rename is committed. Args: (item, newName).
	public Event<delegate void(AssetContentItem, StringView)> OnItemRenamed ~ _.Dispose();

	/// Triggers inline rename on the item at the given position.
	/// Works in both list and grid view modes.
	public void StartRename(int32 position)
	{
		if (position < 0 || position >= mItems.Count) return;
		mRenamingPosition = position;

		// Find the active view for this position and trigger edit
		if (OwnerListView != null)
		{
			let view = OwnerListView.GetActiveView(position);
			if (let itemView = view as AssetContentItemView)
				itemView.NameLabel.BeginEdit();
		}

		if (OwnerGridView != null)
		{
			let view = OwnerGridView.GetActiveView(position);
			if (let gridCell = view as AssetGridCellView)
				gridCell.NameLabel.BeginEdit();
		}
	}

	// === ListAdapterBase ===

	public override View CreateView(int32 viewType)
	{
		if (ViewMode == .Grid)
		{
			let gridCell = new AssetGridCellView();
			gridCell.SetThumbnailService(Thumbnails);

			// Wire rename events
			gridCell.NameLabel.OnRenameCommitted.Add(new (label, newName) => {
				if (mRenamingPosition >= 0 && mRenamingPosition < mItems.Count)
				{
					let item = mItems[mRenamingPosition];
					OnItemRenamed(item, newName);
				}
				mRenamingPosition = -1;
			});

			gridCell.NameLabel.OnRenameCancelled.Add(new (label) => {
				mRenamingPosition = -1;
			});

			return gridCell;
		}

		let itemView = new AssetContentItemView();
		itemView.SetThumbnailService(Thumbnails);

		// Disable double-click-to-edit - double-click navigates into folders
		itemView.NameLabel.DoubleClickToEdit.Value = false;

		// Validate filenames: reject invalid filesystem characters
		itemView.NameLabel.ValidateRename = new (name) => {
			for (let c in name.RawChars)
			{
				if (c == '/' || c == '\\' || c == ':' || c == '*' ||
					c == '?' || c == '"' || c == '<' || c == '>' || c == '|')
					return false;
			}
			return true;
		};

		// Wire rename events
		itemView.NameLabel.OnRenameCommitted.Add(new (label, newName) => {
			if (mRenamingPosition >= 0 && mRenamingPosition < mItems.Count)
			{
				let item = mItems[mRenamingPosition];
				OnItemRenamed(item, newName);
			}
			mRenamingPosition = -1;
		});

		itemView.NameLabel.OnRenameCancelled.Add(new (label) => {
			mRenamingPosition = -1;
		});

		return itemView;
	}

	public override void BindView(View view, int32 position)
	{
		let item = GetItem(position);
		if (item == null) return;

		if (let gridCell = view as AssetGridCellView)
		{
			gridCell.Bind(item);

			// If this position is being renamed, enter edit mode
			if (position == mRenamingPosition)
				gridCell.NameLabel.BeginEdit();
		}
		else if (let listItem = view as AssetContentItemView)
		{
			listItem.Bind(item);

			// If this position is being renamed, enter edit mode
			if (position == mRenamingPosition)
				listItem.NameLabel.BeginEdit();
		}
	}

	// === Internal ===

	private void ClearItems()
	{
		for (let item in mItems)
			delete item;
		mItems.Clear();
	}
}

/// View for a single item in the asset browser content list.
/// Shows: [icon] [name (editable)] [registry badge]
/// Implements IDragSource so items can be dragged from the asset browser.
class AssetContentItemView : FlexLayout, IDragSource
{
	private DrawableView mIconView;
	private EditableLabel mNameLabel;
	private Label mBadgeLabel;

	private ThumbnailService mThumbnails;
	private ThumbnailRequest mPendingRequest;

	/// The currently bound item (non-owning, lives in adapter's item list).
	public AssetContentItem BoundItem;

	/// The editable name label - used by the adapter to trigger rename.
	public EditableLabel NameLabel => mNameLabel;

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4;
		Padding = .(4, 2, 4, 2);

		// Per-extension SVG icon (Phase 1 of thumbnail rollout - was a text
		// label with `[M]` / `[T]` / etc. placeholders before). Swapped to
		// a real thumbnail bitmap on Bind via the ThumbnailService when one
		// is available for the asset.
		mIconView = new DrawableView();
		AddView(mIconView, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(20)), Height = .Match });

		// Name (editable label - acts as plain label, switches to edit on BeginEdit)
		mNameLabel = new EditableLabel();
		mNameLabel.FontSize.Value = 12;
		mNameLabel.TextColor.Value = .(200, 205, 220, 255);
		AddView(mNameLabel, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

		// Registry badge
		mBadgeLabel = new Label();
		mBadgeLabel.FontSize.Value = 9;
		mBadgeLabel.TextColor.Value = .(80, 160, 80, 255);
		mBadgeLabel.HAlign.Value = .Right;
		AddView(mBadgeLabel, new FlexLayout.LayoutParams() { Width = .Wrap, Height = .Match });
	}

	public ~this()
	{
		CancelPending();
	}

	/// Wire the thumbnail service (called once by the adapter after CreateView).
	/// Non-owning - the EditorContext owns the service.
	public void SetThumbnailService(ThumbnailService service)
	{
		mThumbnails = service;
	}

	public void Bind(AssetContentItem item)
	{
		BoundItem = item;
		mNameLabel.SetText(item.Name);

		// Icon by type. EditorIcons.GetForExtension dispatches on folder
		// flag first, then extension, with an Unknown fallback for anything
		// unrecognized. The returned drawable is owned by EditorIcons -
		// we only hold a non-owning reference here.
		mIconView.Drawable = EditorIcons.GetForExtension(item.Extension, item.IsFolder);

		// Cancel any prior in-flight request - cells get recycled during
		// scroll, and a stale callback would write a thumbnail for the
		// previous item.
		CancelPending();

		// Request a thumbnail. Folder cells and items without a registered
		// Guid skip - we have no stable cache identity otherwise. The
		// returned handle is null on synchronous resolution (cache hit or
		// no generator); a non-null handle means we must Cancel on rebind.
		if (mThumbnails != null && !item.IsFolder && item.RegistryId != .())
		{
			let uri = scope String();
			uri.AppendF("{}://{}", item.Scheme, item.RelativePath);

			mPendingRequest = mThumbnails.Request(
				item.RegistryId, uri, item.Extension,
				/* w */ 32, /* h */ 32,
				new (drawable) => {
					if (drawable != null)
						mIconView.Drawable = drawable;
				},
				/* ownsCallback */ true,
				/* ownerSlot */ &mPendingRequest);
		}

		// Registry badge
		if (item.IsRegistered)
			mBadgeLabel.SetText("REG");
		else
			mBadgeLabel.SetText("");

		// Dim missing files (computed by the adapter from the mount).
		if (item.IsMissing)
			mNameLabel.TextColor.Value = .(200, 80, 80, 255);
		else
			mNameLabel.TextColor.Value = null; // Use default from style
	}

	private void CancelPending()
	{
		if (mPendingRequest != null && mThumbnails != null)
		{
			mThumbnails.Cancel(mPendingRequest);
			mPendingRequest = null;
		}
	}

	// === IDragSource ===

	public DragData CreateDragData()
	{
		if (BoundItem == null || BoundItem.IsFolder)
			return null;

		// Build URI from mount entry
		let uri = scope String();
		if (BoundItem.Entry != null)
			uri.AppendF("{}://{}", BoundItem.Entry.Scheme, BoundItem.RelativePath);

		return new AssetDragData(
			BoundItem.AbsolutePath ?? "",
			uri,
			BoundItem.Extension ?? "",
			BoundItem.RegistryId);
	}

	public View CreateDragVisual(DragData data)
	{
		if (BoundItem != null)
		{
			let label = new Label();
			label.FontSize.Value = 12;
			label.SetText(BoundItem.Name);
			label.TextColor.Value = .(200, 200, 210, 200);
			return label;
		}
		return null;
	}

	public void OnDragStarted(DragData data) { Opacity = 0.5f; }
	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled) { Opacity = 1.0f; }

}
