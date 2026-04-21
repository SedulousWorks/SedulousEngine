namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Tree view using FlattenedTreeAdapter for virtualization.
/// Internally uses a ListView with the flattened adapter.
/// Double-click expands/collapses nodes.
public class TreeView : ViewGroup
{
	public ITreeAdapter TreeAdapter;
	public SelectionModel Selection => mListView.Selection;
	public float ItemHeight { get => mListView.ItemHeight; set => mListView.ItemHeight = value; }

	public struct ItemClickInfo
	{
		public int32 NodeId;
		public int32 ClickCount;
	}

	/// Fired when an item is clicked. Parameters: (nodeId, clickCount).
	public Event<delegate void(ItemClickInfo)> OnItemClick ~ _.Dispose();

	/// Fired when a node is expanded or collapsed. Parameter: nodeId.
	public Event<delegate void(int32)> OnItemToggled ~ _.Dispose();

	private FlattenedTreeAdapter mFlatAdapter ~ delete _;
	private ListView mListView ~ delete _;
	private float mIndentWidth = 20;

	public float IndentWidth { get => mIndentWidth; set => mIndentWidth = value; }
	public FlattenedTreeAdapter FlatAdapter => mFlatAdapter;

	public this()
	{
		ClipsContent = true;

		mListView = new ListView();
		mListView.Parent = this;

		mListView.OnItemClicked.Add(new (position, clickCount) =>
		{
			// Resolve flat position to node ID
			let nodeId = (mFlatAdapter != null) ? mFlatAdapter.GetNodeId(position) : position;

			// Single click - notify listeners
			OnItemClick(.(){NodeId=nodeId, ClickCount=clickCount});

			// Double-click - toggle expansion
			if (clickCount >= 2)
				ToggleExpand(position);
		});
	}

	/// Set the tree adapter and build the flat list.
	public void SetAdapter(ITreeAdapter adapter)
	{
		TreeAdapter = adapter;
		delete mFlatAdapter;
		mFlatAdapter = new FlattenedTreeAdapter(adapter);
		mListView.Adapter = mFlatAdapter;
	}

	/// Toggle expansion of the node at the given flat position.
	public void ToggleExpand(int32 flatPosition)
	{
		if (mFlatAdapter == null) return;
		let nodeId = mFlatAdapter.GetNodeId(flatPosition);
		if (nodeId >= 0)
		{
			mFlatAdapter.ToggleExpand(nodeId);
			mListView.NotifyDataChanged();
			OnItemToggled(nodeId);
		}
	}

	// === Keyboard: Left/Right expand/collapse ===
	// Key events bubble from the inner ListView to TreeView.

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mFlatAdapter == null) return;
		let sel = mListView.Selection.FirstSelected;
		if (sel < 0) return;

		let nodeId = mFlatAdapter.GetNodeId(sel);
		if (nodeId < 0) return;

		switch (e.Key)
		{
		case .Right:
			if (TreeAdapter.HasChildren(nodeId) && !mFlatAdapter.IsExpanded(nodeId))
			{
				mFlatAdapter.ToggleExpand(nodeId);
				mListView.NotifyDataChanged();
				e.Handled = true;
			}
		case .Left:
			if (TreeAdapter.HasChildren(nodeId) && mFlatAdapter.IsExpanded(nodeId))
			{
				mFlatAdapter.ToggleExpand(nodeId);
				mListView.NotifyDataChanged();
				e.Handled = true;
			}
		default:
		}
	}

	// === Visual children: the internal ListView ===

	public override int VisualChildCount => 1;
	public override View GetVisualChild(int index) => (index == 0) ? mListView : null;

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		mListView.Measure(wSpec, hSpec);
		MeasuredSize = mListView.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		mListView.Layout(0, 0, right - left, bottom - top);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);
	}
}
