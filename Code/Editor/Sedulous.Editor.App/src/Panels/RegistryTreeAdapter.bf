namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Resources;

/// Tree adapter for the asset browser's registry pane.
/// Root nodes are mounted registries. Children are filesystem subdirectories
/// under each registry's root path.
///
/// Node ID scheme:
///   - Registry roots: 1..N (index + 1)
///   - Subdirectories: hash-based IDs (high bits set to avoid collision)
class RegistryTreeAdapter : ITreeAdapter
{
	/// A node in the tree (either a registry root or a subdirectory).
	private class TreeNode
	{
		public int32 Id;
		public int32 ParentId = -1;
		public String DisplayName ~ delete _;
		public String AbsolutePath ~ delete _;     // Full filesystem path
		public String RelativePath ~ delete _;     // Path relative to registry root
		public IResourceRegistry Registry;          // Which registry this belongs to
		public bool IsRegistryRoot;
		public bool IsLocked;                       // Builtin/project can't be removed
		public List<int32> ChildIds = new .() ~ delete _;
		public bool ChildrenLoaded;
	}

	private List<IResourceRegistry> mRegistries = new .() ~ delete _;
	private Dictionary<int32, TreeNode> mNodes = new .() ~ DeleteDictionaryAndValues!(_);
	private List<int32> mRootIds = new .() ~ delete _;
	private int32 mNextId = 1;
	private ITreeAdapterObserver mObserver;

	// Currently selected node
	private int32 mSelectedNodeId = -1;

	/// Fired when the user selects a tree node. Carries the registry and relative path.
	public Event<delegate void(IResourceRegistry, StringView)> OnFolderSelected ~ _.Dispose();

	/// Gets the selected node ID.
	public int32 SelectedNodeId => mSelectedNodeId;

	/// Rebuilds the tree from the current registry list.
	public void SetRegistries(List<IResourceRegistry> registries)
	{
		// Clear old state
		for (let kv in mNodes)
			delete kv.value;
		mNodes.Clear();
		mRootIds.Clear();
		mRegistries.Clear();
		mNextId = 1;

		for (let reg in registries)
		{
			mRegistries.Add(reg);
			let node = CreateRegistryRootNode(reg);
			mRootIds.Add(node.Id);
		}

		mObserver?.OnTreeDataChanged();
	}

	/// Refreshes the tree data (e.g. after mount/unmount).
	public void Refresh(List<IResourceRegistry> registries)
	{
		SetRegistries(registries);
	}

	/// Selects a node by ID and fires the OnFolderSelected event.
	public void SelectNode(int32 nodeId)
	{
		mSelectedNodeId = nodeId;

		if (mNodes.TryGetValue(nodeId, let node))
		{
			let relativePath = node.IsRegistryRoot ? "" : StringView(node.RelativePath);
			OnFolderSelected(node.Registry, relativePath);
		}
	}

	/// Gets the registry associated with a node.
	public IResourceRegistry GetRegistryForNode(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.Registry;
		return null;
	}

	/// Finds the root node ID for a registry. Returns -1 if not found.
	public int32 GetRootNodeForRegistry(IResourceRegistry registry)
	{
		for (let rootId in mRootIds)
		{
			if (mNodes.TryGetValue(rootId, let node) && node.Registry == registry)
				return rootId;
		}
		return -1;
	}

	/// Gets whether a node represents a locked registry (builtin/project).
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

		// Registry roots always show as expandable (lazy load)
		if (node.IsRegistryRoot)
			return true;

		// Check if directory has subdirectories
		if (node.AbsolutePath != null && Directory.Exists(node.AbsolutePath))
		{
			for (let entry in Directory.EnumerateDirectories(node.AbsolutePath))
				return true;
		}

		return false;
	}

	public View CreateView(int32 viewType)
	{
		let label = new Label();
		label.FontSize = 12;
		return label;
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let label = view as Label;
		if (label == null) return;

		if (!mNodes.TryGetValue(nodeId, let node)) return;

		label.SetText(node.DisplayName);

		// Highlight selected node
		if (nodeId == mSelectedNodeId)
			label.TextColor = .(220, 225, 240, 255);
		else if (node.IsRegistryRoot)
			label.TextColor = .(180, 185, 200, 255);
		else
			label.TextColor = .(160, 165, 180, 255);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;

	public void SetObserver(ITreeAdapterObserver observer)
	{
		mObserver = observer;
	}

	// === Internal ===

	private TreeNode CreateRegistryRootNode(IResourceRegistry registry)
	{
		let node = new TreeNode();
		node.Id = mNextId++;
		node.DisplayName = new String(registry.Name);
		node.AbsolutePath = new String(registry.RootPath);
		node.RelativePath = new String();
		node.Registry = registry;
		node.IsRegistryRoot = true;
		node.IsLocked = (registry.Name == "builtin" || registry.Name == "project");
		mNodes[node.Id] = node;
		return node;
	}

	/// Lazily loads subdirectory children for a node.
	private void EnsureChildrenLoaded(TreeNode node)
	{
		if (node.ChildrenLoaded)
			return;

		node.ChildrenLoaded = true;

		if (node.AbsolutePath == null || !Directory.Exists(node.AbsolutePath))
			return;

		// Enumerate subdirectories and create child nodes
		let sortedDirs = scope List<String>();
		defer { for (let s in sortedDirs) delete s; }

		for (let entry in Directory.EnumerateDirectories(node.AbsolutePath))
		{
			let dirName = scope String();
			entry.GetFileName(dirName);

			// Skip hidden directories
			if (dirName.StartsWith("."))
				continue;

			sortedDirs.Add(new String(dirName));
		}

		sortedDirs.Sort(scope (a, b) => a.CompareTo(b, true));

		for (let dirName in sortedDirs)
		{
			let childNode = new TreeNode();
			childNode.Id = mNextId++;
			childNode.ParentId = node.Id;
			childNode.DisplayName = new String(dirName);

			childNode.AbsolutePath = new String();
			Path.InternalCombine(childNode.AbsolutePath, node.AbsolutePath, dirName);

			childNode.RelativePath = new String();
			if (node.RelativePath.Length > 0)
				childNode.RelativePath.AppendF("{}/{}", node.RelativePath, dirName);
			else
				childNode.RelativePath.Set(dirName);

			childNode.Registry = node.Registry;
			childNode.IsRegistryRoot = false;
			childNode.IsLocked = false;

			mNodes[childNode.Id] = childNode;
			node.ChildIds.Add(childNode.Id);
		}
	}
}
