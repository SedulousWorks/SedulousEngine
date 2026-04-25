namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Engine.Core;
using Sedulous.Editor.Core;

/// Tree adapter that presents a Scene's entity hierarchy for TreeView.
/// Maintains a mapping from int32 nodeId to EntityHandle since ITreeAdapter
/// uses int32 node IDs and EntityHandle has Index + Generation.
class SceneHierarchyAdapter : ITreeAdapter
{
	private Scene mScene;
	private Dictionary<int32, EntityHandle> mNodeToEntity = new .() ~ delete _;
	private Dictionary<EntityHandle, int32> mEntityToNode = new .() ~ delete _;
	private int32 mNextNodeId;
	private ITreeAdapterObserver mObserver;

	/// The TreeView this adapter is attached to (set by ScenePageBuilder).
	public TreeView TreeView;

	/// Node ID currently being renamed, or -1.
	private int32 mRenamingNodeId = -1;

	/// Slow-click rename tracking.
	public int32 LastClickedNodeId = -1;
	public float LastClickTime = 0;

	public this(Scene scene)
	{
		mScene = scene;
		RebuildMapping();
	}

	/// Rebuild the entity-to-nodeId mapping. Call when scene changes.
	public void Rebuild()
	{
		RebuildMapping();
		mObserver?.OnTreeDataChanged();
	}

	/// Get the entity handle for a node ID.
	public EntityHandle GetEntityForNode(int32 nodeId)
	{
		if (mNodeToEntity.TryGetValue(nodeId, let handle))
			return handle;
		return .Invalid;
	}

	private void RebuildMapping()
	{
		mNodeToEntity.Clear();
		mEntityToNode.Clear();
		mNextNodeId = 0;

		for (let handle in mScene.Entities)
		{
			if (!mScene.IsValid(handle)) continue;
			let nodeId = mNextNodeId++;
			mNodeToEntity[nodeId] = handle;
			mEntityToNode[handle] = nodeId;
		}
	}

	private int32 GetNodeId(EntityHandle handle)
	{
		if (mEntityToNode.TryGetValue(handle, let id))
			return id;
		return -1;
	}

	private EntityHandle GetHandle(int32 nodeId)
	{
		if (mNodeToEntity.TryGetValue(nodeId, let handle))
			return handle;
		return .Invalid;
	}

	// === ITreeAdapter ===

	public int32 RootCount
	{
		get
		{
			int32 count = 0;
			for (let handle in mScene.Entities)
			{
				if (!mScene.IsValid(handle)) continue;
				if (mScene.GetParent(handle) == .Invalid)
					count++;
			}
			return count;
		}
	}

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1) return RootCount;

		let parent = GetHandle(nodeId);
		if (parent == .Invalid) return 0;

		int32 count = 0;
		for (let handle in mScene.Entities)
		{
			if (!mScene.IsValid(handle)) continue;
			if (mScene.GetParent(handle) == parent)
				count++;
		}
		return count;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		EntityHandle parentHandle = (parentId == -1) ? .Invalid : GetHandle(parentId);

		int32 i = 0;
		for (let handle in mScene.Entities)
		{
			if (!mScene.IsValid(handle)) continue;
			let entityParent = mScene.GetParent(handle);
			bool isChild = (parentId == -1) ? (entityParent == .Invalid) : (entityParent == parentHandle);
			if (isChild)
			{
				if (i == childIndex) return GetNodeId(handle);
				i++;
			}
		}
		return -1;
	}

	public int32 GetDepth(int32 nodeId)
	{
		let handle = GetHandle(nodeId);
		if (handle == .Invalid) return 0;

		int32 depth = 0;
		var current = mScene.GetParent(handle);
		while (current != .Invalid)
		{
			depth++;
			current = mScene.GetParent(current);
		}
		return depth;
	}

	public bool HasChildren(int32 nodeId)
	{
		let parent = GetHandle(nodeId);
		if (parent == .Invalid) return false;

		for (let handle in mScene.Entities)
		{
			if (!mScene.IsValid(handle)) continue;
			if (mScene.GetParent(handle) == parent)
				return true;
		}
		return false;
	}

	/// Start inline rename on the given entity.
	public void StartRename(EntityHandle entity)
	{
		let nodeId = GetNodeId(entity);
		if (nodeId < 0 || TreeView == null) return;

		mRenamingNodeId = nodeId;

		// Find the flat position for this node and get the active view
		let flatAdapter = TreeView.FlatAdapter;
		if (flatAdapter == null) return;

		for (int32 i = 0; i < flatAdapter.ItemCount; i++)
		{
			if (flatAdapter.GetNodeId(i) == nodeId)
			{
				let view = TreeView.InternalListView.GetActiveView(i);
				if (let item = view as HierarchyItemView)
					item.BeginEdit();
				break;
			}
		}
	}

	public View CreateView(int32 viewType)
	{
		let item = new HierarchyItemView();

		item.OnRenameCommitted.Add(new (view, newName) =>
		{
			if (mRenamingNodeId >= 0)
			{
				let handle = GetHandle(mRenamingNodeId);
				if (handle != .Invalid && mScene.IsValid(handle))
					mScene.SetEntityName(handle, newName);
				mRenamingNodeId = -1;
				Rebuild();
			}
		});

		item.OnRenameCancelled.Add(new (view) =>
		{
			mRenamingNodeId = -1;
		});

		return item;
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (let item = view as HierarchyItemView)
		{
			let handle = GetHandle(nodeId);
			if (handle != .Invalid && mScene.IsValid(handle))
				item.Set(mScene.GetEntityName(handle), depth);
			else
				item.Set("(invalid)", depth);

			// If this node is being renamed, enter edit mode
			if (nodeId == mRenamingNodeId)
				item.BeginEdit();
		}
	}

	public void SetObserver(ITreeAdapterObserver observer)
	{
		mObserver = observer;
	}
}
