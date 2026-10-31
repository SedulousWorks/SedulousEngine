using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A thousand numbered labels, which is the point: the list view builds a handful of rows and
/// recycles them, so the count costs nothing.
class DemoListAdapter : ListAdapterBase
{
	private int32 mCount;

	public this(int32 count)
	{
		mCount = count;
	}

	public override int32 ItemCount => mCount;

	public override View CreateView(int32 viewType) => new Label();

	public override void BindView(View view, int32 position)
	{
		if (let label = view as Label)
			label.SetText(scope $"Item {position + 1}");
	}
}

/// Five folders of three files, with a subfolder under the first, which is enough shape to
/// exercise depth, expansion and stable ids.
///
/// The id ranges ARE the hierarchy: roots below five, a subfolder at fifty, a folder's files at
/// a hundred plus, and the subfolder's at five hundred plus. That is what lets depth be read
/// from an id alone, with no parent lookup.
class DemoTreeAdapter : ITreeAdapter
{
	/// BORROWED: the tree owns itself and outlives this.
	private TreeView mTree = null;
	private ITreeAdapterObserver mObserver = null;

	public void SetTree(TreeView tree) => mTree = tree;

	public int32 RootCount => 5;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return 5;

		if ((nodeId >= 0) && (nodeId < 5))
			return (nodeId == 0) ? 4 : 3; // the first folder carries the subfolder too

		if (nodeId == 50)
			return 2;

		return 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1)
			return childIndex;

		if ((parentId >= 0) && (parentId < 5))
		{
			if ((parentId == 0) && (childIndex == 3))
				return 50;

			return 100 + (parentId * 10) + childIndex;
		}

		if (parentId == 50)
			return 500 + childIndex;

		return -1;
	}

	public int32 GetDepth(int32 nodeId)
	{
		if (nodeId >= 500)
			return 2;

		if ((nodeId >= 100) || (nodeId == 50))
			return 1;

		return 0;
	}

	public bool HasChildren(int32 nodeId) => ((nodeId >= 0) && (nodeId < 5)) || (nodeId == 50);

	public View CreateView(int32 viewType) => new TreeItemView();

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		// The adapter made it, so the type is known.
		let item = (TreeItemView)view;
		let prefix = HasChildren(nodeId) ? "Folder" : "File";
		item.Set(mTree, scope $"{prefix} {nodeId}", depth);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;

	public void SetObserver(ITreeAdapterObserver observer) => mObserver = observer;
}

/// Two hundred colour cells, stepped by three coprime strides so no row repeats the one above.
class DemoGridAdapter : ListAdapterBase
{
	private int32 mCount;

	public this(int32 count)
	{
		mCount = count;
	}

	public override int32 ItemCount => mCount;

	public override View CreateView(int32 viewType) => new ColorView(Color.Rgb(100, 100, 100));

	public override void BindView(View view, int32 position)
	{
		if (let cell = view as ColorView)
		{
			cell.Color.Value = Color.Rgb(
				(uint8)(60 + ((position * 7) % 160)),
				(uint8)(80 + ((position * 13) % 140)),
				(uint8)(100 + ((position * 23) % 120)));
		}
	}
}
