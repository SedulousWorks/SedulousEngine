using System.Collections;

namespace Sedulous.UI;

/// Presents a TREE as a flat list, so a tree view is an ordinary list view underneath and
/// inherits its recycling and virtualisation rather than reimplementing them.
///
/// The flat list holds only the VISIBLE nodes: a collapsed node's descendants are absent
/// entirely rather than hidden, which is what keeps a large collapsed tree cheap.
class FlattenedTreeAdapter : IListAdapter, ITreeAdapterObserver
{
	/// BORROWED: the caller owns the source tree.
	private ITreeAdapter mSource;
	private List<int32> mVisibleNodes = new .() ~ delete _;
	private List<int32> mDepths = new .() ~ delete _;
	private HashSet<int32> mExpanded = new .() ~ delete _;
	/// BORROWED.
	private IListAdapterObserver mObserver = null;

	public this(ITreeAdapter source)
	{
		mSource = source;
		mSource.SetObserver(this);
		RebuildVisibleList();
	}

	public ITreeAdapter Source => mSource;

	// ---- IListAdapter -------------------------------------------------------------------------

	public void SetObserver(IListAdapterObserver observer) => mObserver = observer;

	public int32 ItemCount => (int32)mVisibleNodes.Count;

	public int32 GetItemViewType(int32 position)
	{
		if ((position < 0) || (position >= mVisibleNodes.Count))
			return 0;
		return mSource.GetItemViewType(mVisibleNodes[position]);
	}

	public int32 ViewTypeCount => 1;

	public float GetItemHeight(int32 position) => -1.0f;

	public View CreateView(int32 viewType) => mSource.CreateView(viewType);

	public void BindView(View view, int32 position)
	{
		if ((position < 0) || (position >= mVisibleNodes.Count))
			return;

		let nodeId = mVisibleNodes[position];
		mSource.BindView(view, nodeId, mDepths[position], mExpanded.Contains(nodeId));
	}

	// ---- Expansion ----------------------------------------------------------------------------

	public bool IsExpanded(int32 nodeId) => mExpanded.Contains(nodeId);

	/// A node with no children cannot be expanded, so asking is a no op rather than leaving an
	/// expanded flag on a leaf that would confuse the chevron.
	public void Expand(int32 nodeId)
	{
		if (!mExpanded.Contains(nodeId) && mSource.HasChildren(nodeId))
		{
			mExpanded.Add(nodeId);
			RebuildVisibleList();
		}
	}

	public void Collapse(int32 nodeId)
	{
		if (mExpanded.Remove(nodeId))
			RebuildVisibleList();
	}

	public void ToggleExpand(int32 nodeId)
	{
		if (mExpanded.Contains(nodeId))
			mExpanded.Remove(nodeId);
		else if (mSource.HasChildren(nodeId))
			mExpanded.Add(nodeId);

		RebuildVisibleList();
	}

	// ---- Positions and nodes ------------------------------------------------------------------

	public int32 GetNodeId(int32 position)
	{
		if ((position < 0) || (position >= mVisibleNodes.Count))
			return -1;
		return mVisibleNodes[position];
	}

	/// A node's flat position in the CURRENT visible list, or -1 when a collapsed ancestor
	/// hides it. The inverse of GetNodeId, and what remaps a positional selection across an
	/// expand or collapse.
	public int32 PositionOfNode(int32 nodeId)
	{
		for (int i < mVisibleNodes.Count)
		{
			if (mVisibleNodes[i] == nodeId)
				return (int32)i;
		}
		return -1;
	}

	/// The depth of the node at a POSITION, which is what the binder indents by.
	public int32 GetDepth(int32 position)
	{
		if ((position < 0) || (position >= mDepths.Count))
			return 0;
		return mDepths[position];
	}

	// ---- Saving and restoring the expansion ---------------------------------------------------

	public void GetExpandedNodes(HashSet<int32> outNodes)
	{
		for (let nodeId in mExpanded)
			outNodes.Add(nodeId);
	}

	/// Restores a saved expansion, dropping any node that no longer HAS children: a tree
	/// reloaded from changed data must not carry an expanded flag on what is now a leaf.
	public void SetExpandedNodes(HashSet<int32> nodes)
	{
		mExpanded.Clear();
		for (let nodeId in nodes)
		{
			if (mSource.HasChildren(nodeId))
				mExpanded.Add(nodeId);
		}
		RebuildVisibleList();
	}

	/// Rebuilds the flat list by walking the expanded nodes, then tells the observer.
	public void RebuildVisibleList()
	{
		mVisibleNodes.Clear();
		mDepths.Clear();

		let rootCount = mSource.RootCount;
		for (int32 i = 0; i < rootCount; i++)
			AddNodeRecursive(mSource.GetChildId(-1, i), 0);

		if (mObserver != null)
			mObserver.OnDataSetChanged();
	}

	private void AddNodeRecursive(int32 nodeId, int32 depth)
	{
		mVisibleNodes.Add(nodeId);
		mDepths.Add(depth);

		if (!mExpanded.Contains(nodeId))
			return;

		let childCount = mSource.GetChildCount(nodeId);
		for (int32 i = 0; i < childCount; i++)
			AddNodeRecursive(mSource.GetChildId(nodeId, i), depth + 1);
	}

	// ---- ITreeAdapterObserver -----------------------------------------------------------------

	public void OnTreeDataChanged() => RebuildVisibleList();
}
