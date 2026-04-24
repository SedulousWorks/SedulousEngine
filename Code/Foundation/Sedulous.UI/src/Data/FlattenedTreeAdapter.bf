namespace Sedulous.UI;

using System;
using System.Collections;

/// Wraps ITreeAdapter to present as IListAdapter for ListView virtualization.
/// Maintains expansion state and a flat list of currently visible nodes.
public class FlattenedTreeAdapter : IListAdapter, ITreeAdapterObserver
{
	private ITreeAdapter mSource;

	/// Flat list of visible nodeIds in display order.
	private List<int32> mVisibleNodes = new .() ~ delete _;

	/// Set of expanded nodeIds.
	private HashSet<int32> mExpanded = new .() ~ delete _;

	/// Depth per visible node (parallel to mVisibleNodes).
	private List<int32> mDepths = new .() ~ delete _;

	public ITreeAdapter Source => mSource;

	public this(ITreeAdapter source)
	{
		mSource = source;
		mSource.SetObserver(this);
		RebuildVisibleList();
	}

	private IListAdapterObserver mObserver;

	// === IListAdapter ===

	public void SetObserver(IListAdapterObserver observer) { mObserver = observer; }

	public int32 ItemCount => (int32)mVisibleNodes.Count;

	public int32 GetItemViewType(int32 position)
	{
		if (position < 0 || position >= mVisibleNodes.Count) return 0;
		return mSource.GetItemViewType(mVisibleNodes[position]);
	}

	public View CreateView(int32 viewType) => mSource.CreateView(viewType);

	public void BindView(View view, int32 position)
	{
		if (position < 0 || position >= mVisibleNodes.Count) return;
		let nodeId = mVisibleNodes[position];
		let depth = mDepths[position];
		let expanded = mExpanded.Contains(nodeId);
		mSource.BindView(view, nodeId, depth, expanded);
	}

	// === Expansion ===

	/// Whether a node is currently expanded.
	public bool IsExpanded(int32 nodeId) => mExpanded.Contains(nodeId);

	/// Toggle expansion of a node. Rebuilds the flat list.
	public void ToggleExpand(int32 nodeId)
	{
		if (mExpanded.Contains(nodeId))
			mExpanded.Remove(nodeId);
		else if (mSource.HasChildren(nodeId))
			mExpanded.Add(nodeId);
		RebuildVisibleList();
	}

	/// Expand a node (no-op if already expanded or no children).
	public void Expand(int32 nodeId)
	{
		if (!mExpanded.Contains(nodeId) && mSource.HasChildren(nodeId))
		{
			mExpanded.Add(nodeId);
			RebuildVisibleList();
		}
	}

	/// Collapse a node.
	public void Collapse(int32 nodeId)
	{
		if (mExpanded.Remove(nodeId))
			RebuildVisibleList();
	}

	/// Get the nodeId at a flat position.
	public int32 GetNodeId(int32 position)
	{
		if (position < 0 || position >= mVisibleNodes.Count) return -1;
		return mVisibleNodes[position];
	}

	/// Get the depth at a flat position.
	public int32 GetDepth(int32 position)
	{
		if (position < 0 || position >= mDepths.Count) return 0;
		return mDepths[position];
	}

	/// Rebuild the flat visible list by walking expanded nodes.
	/// Notifies the observer that the data set changed.
	public void RebuildVisibleList()
	{
		mVisibleNodes.Clear();
		mDepths.Clear();

		let rootCount = mSource.RootCount;
		for (int32 i = 0; i < rootCount; i++)
		{
			let nodeId = mSource.GetChildId(-1, i);
			AddNodeRecursive(nodeId, 0);
		}

		mObserver?.OnDataSetChanged();
	}

	// === ITreeAdapterObserver ===

	public void OnTreeDataChanged()
	{
		RebuildVisibleList();
	}

	private void AddNodeRecursive(int32 nodeId, int32 depth)
	{
		mVisibleNodes.Add(nodeId);
		mDepths.Add(depth);

		if (mExpanded.Contains(nodeId))
		{
			let childCount = mSource.GetChildCount(nodeId);
			for (int32 i = 0; i < childCount; i++)
			{
				let childId = mSource.GetChildId(nodeId, i);
				AddNodeRecursive(childId, depth + 1);
			}
		}
	}
}
