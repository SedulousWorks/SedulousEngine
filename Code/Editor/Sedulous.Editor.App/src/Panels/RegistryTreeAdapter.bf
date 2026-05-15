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
using Sedulous.Core.Mathematics;

/// Tree adapter for the asset browser's mount pane.
/// Root nodes are mounted entries (scheme + mount + index). Children are
/// filesystem subdirectories under the mount's root (when the mount is
/// disk-backed).
///
/// Node ID scheme:
///   - Mount roots: 1..N (index + 1)
///   - Subdirectories: hash-based IDs (high bits set to avoid collision)
class RegistryTreeAdapter : ITreeAdapter
{
	/// A node in the tree (either a mount root or a subdirectory).
	private class TreeNode
	{
		public int32 Id;
		public int32 ParentId = -1;
		public String DisplayName ~ delete _;
		public String AbsolutePath ~ delete _;     // Disk mounts only (shell reveal); empty otherwise
		public String RelativePath ~ delete _;     // Mount-relative locator (primary key)
		public MountEntry Entry;                    // Which mount this belongs to
		public bool IsMountRoot;
		public bool IsLocked;                       // Builtin/project can't be removed
		public List<int32> ChildIds = new .() ~ delete _;
		public bool ChildrenLoaded;
	}

	private List<MountEntry> mEntries = new .() ~ delete _;
	private Dictionary<int32, TreeNode> mNodes = new .() ~ DeleteDictionaryAndValues!(_);
	private List<int32> mRootIds = new .() ~ delete _;
	private int32 mNextId = 1;
	private ITreeAdapterObserver mObserver;

	// Currently selected node
	private int32 mSelectedNodeId = -1;

	/// Fired when the user selects a tree node. Carries the mount entry and relative path.
	public Event<delegate void(MountEntry, StringView)> OnFolderSelected ~ _.Dispose();

	/// Gets the selected node ID.
	public int32 SelectedNodeId => mSelectedNodeId;

	/// Rebuilds the tree from the current mount list.
	public void SetEntries(List<MountEntry> entries)
	{
		// Clear old state
		for (let kv in mNodes)
			delete kv.value;
		mNodes.Clear();
		mRootIds.Clear();
		mEntries.Clear();
		mNextId = 1;

		for (let entry in entries)
		{
			mEntries.Add(entry);
			let node = CreateMountRootNode(entry);
			mRootIds.Add(node.Id);
		}

		mObserver?.OnTreeDataChanged();
	}

	/// Refreshes the tree data (e.g. after mount/unmount).
	public void Refresh(List<MountEntry> entries)
	{
		SetEntries(entries);
	}

	/// Selects a node by ID and fires the OnFolderSelected event.
	public void SelectNode(int32 nodeId)
	{
		mSelectedNodeId = nodeId;

		if (mNodes.TryGetValue(nodeId, let node))
		{
			let relativePath = node.IsMountRoot ? "" : StringView(node.RelativePath);
			OnFolderSelected(node.Entry, relativePath);
		}
	}

	/// Gets the mount entry associated with a node.
	public MountEntry GetEntryForNode(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.Entry;
		return null;
	}

	/// Finds the root node ID for a mount entry. Returns -1 if not found.
	public int32 GetRootNodeForEntry(MountEntry entry)
	{
		for (let rootId in mRootIds)
		{
			if (mNodes.TryGetValue(rootId, let node) && node.Entry == entry)
				return rootId;
		}
		return -1;
	}

	/// Gets whether a node is a mount root (top level).
	public bool IsMountRoot(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.IsMountRoot;
		return false;
	}

	/// Gets the absolute path for a node. Empty for non-disk mounts.
	public StringView GetNodeAbsolutePath(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node) && node.AbsolutePath != null)
			return node.AbsolutePath;
		return "";
	}

	/// Gets the relative path for a node within its mount.
	public StringView GetNodeRelativePath(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node) && node.RelativePath != null)
			return node.RelativePath;
		return "";
	}

	/// Gets whether a node represents a locked entry (builtin/project).
	public bool IsNodeLocked(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.IsLocked;
		return false;
	}

	// === ITreeAdapter ===

	public int32 RootCount => (int32)mRootIds.Count;

	public int32 GetChildCount(int32 nodeId)
	{
		// Root level (FlattenedTreeAdapter never calls this with -1, but be safe)
		if (nodeId == -1)
			return (int32)mRootIds.Count;

		if (!mNodes.TryGetValue(nodeId, let node))
			return 0;

		EnsureChildrenLoaded(node);
		return (int32)node.ChildIds.Count;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		// Root nodes: parentId == -1
		if (parentId == -1)
		{
			if (childIndex < 0 || childIndex >= mRootIds.Count)
				return -1;
			return mRootIds[childIndex];
		}

		if (!mNodes.TryGetValue(parentId, let node))
			return -1;

		EnsureChildrenLoaded(node);
		if (childIndex < 0 || childIndex >= node.ChildIds.Count)
			return -1;

		return node.ChildIds[childIndex];
	}

	public int32 GetDepth(int32 nodeId)
	{
		int32 depth = 0;
		var currentId = nodeId;
		while (mNodes.TryGetValue(currentId, let node) && node.ParentId >= 0)
		{
			depth++;
			currentId = node.ParentId;
		}
		return depth;
	}

	public bool HasChildren(int32 nodeId)
	{
		if (!mNodes.TryGetValue(nodeId, let node))
			return false;

		// Mount roots always show as expandable (lazy load)
		if (node.IsMountRoot)
			return true;

		// Has subdirectories? Probe through the mount (locator-space).
		let probe = scope List<String>();
		defer { for (let s in probe) delete s; }
		if (EnumerateChildDirs(node, probe) && probe.Count > 0)
			return true;

		return false;
	}

	public View CreateView(int32 viewType)
	{
		return new RegistryTreeItemView();
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let itemView = view as RegistryTreeItemView;
		if (itemView == null) return;

		if (!mNodes.TryGetValue(nodeId, let node)) return;

		itemView.Set(node.DisplayName, depth);

		// Highlight selected node
		if (nodeId == mSelectedNodeId)
			itemView.TextColor = .(220, 225, 240, 255);
		else if (node.IsMountRoot)
			itemView.TextColor = .(180, 185, 200, 255);
		else
			itemView.TextColor = .(160, 165, 180, 255);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;

	public void SetObserver(ITreeAdapterObserver observer)
	{
		mObserver = observer;
	}

	// === Internal ===

	/// Enumerates immediate subdirectory display names under `node`'s
	/// folder through the node's mount (locator-space). Returns false if
	/// the mount isn't enumerable. Caller owns the appended strings.
	private bool EnumerateChildDirs(TreeNode node, List<String> outDirNames)
	{
		if (node.Entry == null) return false;
		let em = node.Entry.Mount as IEnumerableMount;
		if (em == null) return false;

		let folderLoc = scope String();
		if (node.RelativePath != null && node.RelativePath.Length > 0)
		{
			folderLoc.Set(node.RelativePath);
			folderLoc.Append('/');
		}

		let entries = scope List<String>();
		defer { for (let s in entries) delete s; }
		em.Enumerate(folderLoc, entries);

		for (let e in entries)
		{
			if (!e.EndsWith('/')) continue; // directories only
			let body = e.Substring(0, e.Length - 1);
			let slash = body.LastIndexOf('/');
			let name = (slash >= 0) ? body.Substring(slash + 1) : body;
			if (name.StartsWith("."))
				continue;
			outDirNames.Add(new String(name));
		}
		return true;
	}

	private TreeNode CreateMountRootNode(MountEntry entry)
	{
		let node = new TreeNode();
		node.Id = mNextId++;
		node.DisplayName = new String(entry.Scheme);
		node.AbsolutePath = new String();
		// Only disk-backed mounts have a meaningful filesystem root.
		if (let fsMount = entry.Mount as FileSystemMount)
			node.AbsolutePath.Set(fsMount.RootPath);
		node.RelativePath = new String();
		node.Entry = entry;
		node.IsMountRoot = true;
		node.IsLocked = entry.IsLocked;
		mNodes[node.Id] = node;
		return node;
	}

	/// Lazily loads subdirectory children for a node.
	private void EnsureChildrenLoaded(TreeNode node)
	{
		if (node.ChildrenLoaded)
			return;

		node.ChildrenLoaded = true;

		let sortedDirs = scope List<String>();
		defer { for (let s in sortedDirs) delete s; }
		if (!EnumerateChildDirs(node, sortedDirs))
			return;
		sortedDirs.Sort(scope (a, b) => a.CompareTo(b, true));

		// Disk-backed mounts get a real AbsolutePath (shell reveal);
		// otherwise it stays empty, mirroring CreateMountRootNode.
		let fsMount = (node.Entry != null) ? node.Entry.Mount as FileSystemMount : null;

		for (let dirName in sortedDirs)
		{
			let childNode = new TreeNode();
			childNode.Id = mNextId++;
			childNode.ParentId = node.Id;
			childNode.DisplayName = new String(dirName);

			childNode.RelativePath = new String();
			if (node.RelativePath.Length > 0)
				childNode.RelativePath.AppendF("{}/{}", node.RelativePath, dirName);
			else
				childNode.RelativePath.Set(dirName);

			childNode.AbsolutePath = new String();
			if (fsMount != null)
				Path.InternalCombine(childNode.AbsolutePath, fsMount.RootPath, childNode.RelativePath);

			childNode.Entry = node.Entry;
			childNode.IsMountRoot = false;
			childNode.IsLocked = false;

			mNodes[childNode.Id] = childNode;
			node.ChildIds.Add(childNode.Id);
		}
	}
}

/// Simple tree item view for the registry tree.
/// Draws text with depth-based indentation so it doesn't overlap with the TreeView's arrows.
class RegistryTreeItemView : View
{
	private String mText = new .() ~ delete _;
	private int32 mDepth;
	private float mIndentWidth = 20;

	public Color TextColor = .(180, 185, 200, 255);

	public void Set(StringView text, int32 depth)
	{
		mText.Set(text);
		mDepth = depth;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mText.Length == 0 || ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(12);
		if (font == null) return;

		let indent = (mDepth + 1) * mIndentWidth;
		let bounds = RectangleF(indent, 0, Width - indent, Height);
		ctx.VG.DrawText(mText, font, bounds, .Left, .Middle, TextColor);
	}
}
