using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// A FLAT list behind a tree adapter, so the draggable tree can reorder it.
///
/// Nothing here nests: the tree is being used for its drag handling, not its hierarchy, which is
/// the common case for a reorderable list.
class ReorderableListAdapter : IReorderableTreeAdapter
{
	private List<String> mItems = new .() ~ DeleteContainerAndItems!(_);
	private ITreeAdapterObserver mObserver = null;

	public this(params StringView[] items)
	{
		for (let item in items)
			mItems.Add(new String(item));
	}

	public int32 RootCount => (int32)mItems.Count;

	public int32 GetChildCount(int32 nodeId) => (nodeId == -1) ? (int32)mItems.Count : 0;

	public int32 GetChildId(int32 parentId, int32 childIndex) => childIndex;

	public int32 GetDepth(int32 nodeId) => 0;

	public bool HasChildren(int32 nodeId) => false;

	public View CreateView(int32 viewType) => new Label();

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (let label = view as Label)
		{
			if ((nodeId >= 0) && (nodeId < mItems.Count))
				label.SetText(mItems[nodeId]);
		}
	}

	public int32 GetItemViewType(int32 nodeId) => 0;

	public void SetObserver(ITreeAdapterObserver observer) => mObserver = observer;

	public bool CanMove(int32 fromPosition, int32 toPosition)
	{
		let count = (int32)mItems.Count;
		// The destination may be ONE past the end, which is what dropping below the last row
		// means.
		return (fromPosition >= 0) && (fromPosition < count) && (toPosition >= 0) &&
			(toPosition <= count) && (fromPosition != toPosition);
	}

	public void MoveItem(int32 fromPosition, int32 toPosition)
	{
		if (!CanMove(fromPosition, toPosition))
			return;

		let item = mItems[fromPosition];
		mItems.RemoveAt(fromPosition);

		// Taking the item out shifts everything after it down, so a destination past the source
		// has to come back one.
		let insertAt = (toPosition > fromPosition) ? (toPosition - 1) : toPosition;
		mItems.Insert(Math.Min(insertAt, (int32)mItems.Count), item);
	}
}
