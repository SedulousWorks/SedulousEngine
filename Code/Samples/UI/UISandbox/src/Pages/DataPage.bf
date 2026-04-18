namespace UISandbox;

using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using System;
using System.Collections;

/// Simple flat list that supports drag-to-reorder.
class ReorderableListAdapter : IReorderableTreeAdapter
{
	private List<String> mItems = new .() ~ { for (let s in _) delete s; delete _; };

	public this(Span<StringView> items)
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
			if (nodeId >= 0 && nodeId < mItems.Count)
				label.SetText(mItems[nodeId]);
		}
	}

	public bool CanMove(int32 fromPosition, int32 toPosition)
	{
		return fromPosition >= 0 && fromPosition < mItems.Count &&
			   toPosition >= 0 && toPosition <= mItems.Count &&
			   fromPosition != toPosition;
	}

	public void MoveItem(int32 fromPosition, int32 toPosition)
	{
		if (!CanMove(fromPosition, toPosition)) return;
		let item = mItems[fromPosition];
		mItems.RemoveAt(fromPosition);
		let insertAt = (toPosition > fromPosition) ? toPosition - 1 : toPosition;
		mItems.Insert(Math.Min(insertAt, mItems.Count), item);
	}
}

/// Demo page: ScrollView, ListView, TreeView, DraggableTreeView.
class DataPage : DemoPage
{
	private SandboxListAdapter mListAdapter ~ delete _;
	private SandboxTreeAdapter mTreeAdapter ~ delete _;
	private ReorderableListAdapter mReorderAdapter ~ delete _;

	public this(DemoContext demo) : base(demo)
	{
		AddSection("ScrollView");
		{
			let sv = new ScrollView();
			sv.VScrollPolicy = .Auto;
			mLayout.AddView(sv, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 120 });

			let content = new LinearLayout();
			content.Orientation = .Vertical;
			content.Spacing = 4;
			sv.AddView(content, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent });

			for (int i = 0; i < 20; i++)
			{
				let label = new Label();
				let text = scope String();
				text.AppendF("Scrollable item {}", i + 1);
				label.SetText(text);
				content.AddView(label, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 22 });
			}
		}

		AddSeparator();
		AddSection("ListView (1000 items, virtualized)");
		{
			mListAdapter = new SandboxListAdapter(1000);
			let list = new ListView();
			list.ItemHeight = 22;
			list.Adapter = mListAdapter;
			mLayout.AddView(list, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 180 });
		}

		AddSeparator();
		AddSection("TreeView (dbl-click to expand)");
		{
			mTreeAdapter = new SandboxTreeAdapter();
			let tree = new TreeView();
			tree.ItemHeight = 22;
			tree.SetAdapter(mTreeAdapter);
			mLayout.AddView(tree, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 150 });
		}

		AddSeparator();
		AddSection("DraggableTreeView (drag to reorder)");
		{
			mReorderAdapter = new ReorderableListAdapter(
				StringView[]("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot"));
			let dragTree = new DraggableTreeView();
			dragTree.ItemHeight = 22;
			dragTree.SetAdapter(mReorderAdapter);
			mLayout.AddView(dragTree, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 150 });
		}
	}
}
