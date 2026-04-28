namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;

/// Represents one item in the asset browser content view.
class AssetContentItem
{
	public enum ItemKind { Folder, File }

	public String Name ~ delete _;              // Display name (filename or folder name)
	public String AbsolutePath ~ delete _;      // Full filesystem path
	public String RelativePath ~ delete _;      // Path relative to registry root
	public String Extension ~ delete _;         // File extension (e.g. ".mesh"), empty for folders
	public ItemKind Kind;
	public Guid RegistryId;                     // GUID if registered, default Guid if not
	public bool IsRegistered;                   // Has a GUID in the active registry

	public bool IsFolder => Kind == .Folder;
}

/// List adapter for the asset browser content pane.
/// Shows files and folders in the selected directory, merged with registry entries.
///
/// Items come from two sources:
///   1. Filesystem: files and subdirectories at the current path
///   2. Registry: entries whose relative path matches the current folder
///
/// Folders always sort before files. Within each group, items are sorted alphabetically.
class AssetContentAdapter : ListAdapterBase
{
	private List<AssetContentItem> mItems = new .() ~ DeleteContainerAndItems!(_);
	private IResourceRegistry mRegistry;
	private String mCurrentFolder = new .() ~ delete _;  // Relative path within registry (e.g. "primitives")
	private String mAbsoluteRoot = new .() ~ delete _;   // Absolute root of active registry

	/// Gets the number of items.
	public override int32 ItemCount => (int32)mItems.Count;

	/// Gets the item at a position.
	public AssetContentItem GetItem(int32 position)
	{
		if (position < 0 || position >= mItems.Count)
			return null;
		return mItems[position];
	}

	/// Gets the current folder path (relative to registry root).
	public StringView CurrentFolder => mCurrentFolder;

	/// Gets the active registry.
	public IResourceRegistry ActiveRegistry => mRegistry;

	/// The owning ListView (set by AssetBrowserBuilder after construction).
	public ListView OwnerListView { get; set; }

	/// Sets the active registry and navigates to a folder within it.
	public void SetFolder(IResourceRegistry registry, StringView relativePath)
	{
		mRegistry = registry;
		mCurrentFolder.Set(relativePath);
		mAbsoluteRoot.Clear();
		if (registry != null)
			mAbsoluteRoot.Set(registry.RootPath);

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

	/// Rebuilds the item list from filesystem + registry.
	public void Rebuild()
	{
		ClearItems();

		if (mRegistry == null || mAbsoluteRoot.Length == 0)
		{
			NotifyDataSetChanged();
			return;
		}

		// Build absolute path for current folder
		let absDir = scope String();
		if (mCurrentFolder.Length > 0)
			Path.InternalCombine(absDir, mAbsoluteRoot, mCurrentFolder);
		else
			absDir.Set(mAbsoluteRoot);

		// Collect registry entries for this folder
		let registryPrefix = scope String();
		if (mCurrentFolder.Length > 0)
			registryPrefix.AppendF("{}/", mCurrentFolder);

		let registryEntries = scope List<(Guid id, StringView path, StringView name)>();
		if (let concreteReg = mRegistry as ResourceRegistry)
			concreteReg.GetEntriesInFolder(registryPrefix, registryEntries);

		// Build a set of registry-known filenames for quick lookup
		let registryNames = scope Dictionary<StringView, Guid>();
		for (let entry in registryEntries)
			registryNames[entry.name] = entry.id;

		// Scan filesystem
		if (Directory.Exists(absDir))
		{
			// Subdirectories
			let dirs = scope List<String>();
			defer { for (let s in dirs) delete s; }

			for (let entry in Directory.EnumerateDirectories(absDir))
			{
				let dirName = scope String();
				entry.GetFileName(dirName);
				if (dirName.StartsWith("."))
					continue;
				dirs.Add(new String(dirName));
			}
			dirs.Sort(scope (a, b) => a.CompareTo(b, true));

			for (let dirName in dirs)
			{
				let item = new AssetContentItem();
				item.Name = new String(dirName);
				item.Kind = .Folder;
				item.Extension = new String();

				item.AbsolutePath = new String();
				Path.InternalCombine(item.AbsolutePath, absDir, dirName);

				item.RelativePath = new String();
				if (mCurrentFolder.Length > 0)
					item.RelativePath.AppendF("{}/{}", mCurrentFolder, dirName);
				else
					item.RelativePath.Set(dirName);

				mItems.Add(item);
			}

			// Files
			let files = scope List<String>();
			defer { for (let s in files) delete s; }

			for (let entry in Directory.EnumerateFiles(absDir))
			{
				let fileName = scope String();
				entry.GetFileName(fileName);
				if (fileName.StartsWith("."))
					continue;
				// Skip .registry and .meta files from the content view
				if (fileName.EndsWith(".registry") || fileName.EndsWith(".meta"))
					continue;
				files.Add(new String(fileName));
			}
			files.Sort(scope (a, b) => a.CompareTo(b, true));

			for (let fileName in files)
			{
				let item = new AssetContentItem();
				item.Name = new String(fileName);
				item.Kind = .File;

				item.Extension = new String();
				let dotIdx = fileName.LastIndexOf('.');
				if (dotIdx >= 0)
					item.Extension.Set(fileName[dotIdx...]);

				item.AbsolutePath = new String();
				Path.InternalCombine(item.AbsolutePath, absDir, fileName);

				item.RelativePath = new String();
				if (mCurrentFolder.Length > 0)
					item.RelativePath.AppendF("{}/{}", mCurrentFolder, fileName);
				else
					item.RelativePath.Set(fileName);

				// Check if this file is in the registry
				if (registryNames.TryGetValueAlt(StringView(fileName), let guid))
				{
					item.IsRegistered = true;
					item.RegistryId = guid;
				}

				mItems.Add(item);
			}
		}

		// Add registry entries that point to missing files (warning items)
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
				let item = new AssetContentItem();
				item.Name = new String(entry.name);
				item.Kind = .File;

				item.Extension = new String();
				let dotIdx = entry.name.LastIndexOf('.');
				if (dotIdx >= 0)
					item.Extension.Set(entry.name[dotIdx...]);

				item.AbsolutePath = new String();
				Path.InternalCombine(item.AbsolutePath, mAbsoluteRoot, entry.path);

				item.RelativePath = new String(entry.path);
				item.IsRegistered = true;
				item.RegistryId = entry.id;

				mItems.Add(item);
			}
		}

		NotifyDataSetChanged();
	}

	// === ListAdapterBase ===

	public override View CreateView(int32 viewType)
	{
		return new AssetContentItemView();
	}

	public override void BindView(View view, int32 position)
	{
		let itemView = view as AssetContentItemView;
		if (itemView == null) return;

		let item = GetItem(position);
		if (item == null) return;

		itemView.Bind(item);
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
/// Shows: [icon] [name] [registry badge]
class AssetContentItemView : LinearLayout
{
	private Label mIconLabel;
	private Label mNameLabel;
	private Label mBadgeLabel;

	public this()
	{
		Orientation = .Horizontal;
		Spacing = 4;
		Padding = .(4, 2, 4, 2);

		// Icon (text-based for now, replaced with proper icons in Phase 4e)
		mIconLabel = new Label();
		mIconLabel.FontSize = 11;
		mIconLabel.TextColor = .(140, 145, 165, 255);
		AddView(mIconLabel, new LayoutParams() { Width = 20, Height = Sedulous.UI.LayoutParams.MatchParent });

		// Name
		mNameLabel = new Label();
		mNameLabel.FontSize = 12;
		mNameLabel.TextColor = .(200, 205, 220, 255);
		AddView(mNameLabel, new LinearLayout.LayoutParams() { Width = 0, Height = Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });

		// Registry badge
		mBadgeLabel = new Label();
		mBadgeLabel.FontSize = 9;
		mBadgeLabel.TextColor = .(80, 160, 80, 255);
		mBadgeLabel.HAlign = .Right;
		AddView(mBadgeLabel, new LayoutParams() { Width = Sedulous.UI.LayoutParams.WrapContent, Height = Sedulous.UI.LayoutParams.MatchParent });
	}

	public void Bind(AssetContentItem item)
	{
		mNameLabel.SetText(item.Name);

		// Icon by type
		if (item.IsFolder)
		{
			mIconLabel.SetText("[D]");
			mIconLabel.TextColor = .(200, 180, 80, 255);
		}
		else
		{
			let icon = GetIconForExtension(item.Extension);
			mIconLabel.SetText(icon);
			mIconLabel.TextColor = GetIconColor(item.Extension);
		}

		// Registry badge
		if (item.IsRegistered)
			mBadgeLabel.SetText("REG");
		else
			mBadgeLabel.SetText("");

		// Dim missing files
		if (item.IsRegistered && !item.IsFolder && item.AbsolutePath != null && !System.IO.File.Exists(item.AbsolutePath))
			mNameLabel.TextColor = .(200, 80, 80, 255);
		else
			mNameLabel.TextColor = .(200, 205, 220, 255);
	}

	private StringView GetIconForExtension(StringView ext)
	{
		if (ext == ".mesh" || ext == ".staticmesh") return "[M]";
		if (ext == ".skinnedmesh") return "[S]";
		if (ext == ".material") return "[*]";
		if (ext == ".texture") return "[T]";
		if (ext == ".skeleton") return "[B]";
		if (ext == ".animation") return "[A]";
		if (ext == ".scene") return "[W]";
		if (ext == ".png" || ext == ".jpg" || ext == ".hdr" || ext == ".tga") return "[I]";
		if (ext == ".gltf" || ext == ".glb" || ext == ".fbx" || ext == ".obj") return "[3]";
		return "[.]";
	}

	private Color GetIconColor(StringView ext)
	{
		if (ext == ".mesh" || ext == ".staticmesh" || ext == ".skinnedmesh") return .(100, 180, 220, 255);
		if (ext == ".material") return .(220, 140, 60, 255);
		if (ext == ".texture" || ext == ".png" || ext == ".jpg" || ext == ".hdr") return .(140, 200, 100, 255);
		if (ext == ".skeleton" || ext == ".animation") return .(200, 120, 200, 255);
		if (ext == ".scene") return .(220, 200, 80, 255);
		if (ext == ".gltf" || ext == ".glb" || ext == ".fbx") return .(180, 180, 220, 255);
		return .(140, 145, 165, 255);
	}
}
