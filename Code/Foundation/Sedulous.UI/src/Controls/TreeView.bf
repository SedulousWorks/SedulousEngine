namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Tree view using FlattenedTreeAdapter for virtualization.
/// Internally uses a ListView with the flattened adapter.
/// Draws indent + expand/collapse arrows. Single-click on arrow toggles expansion.
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

	/// Fired when an item is clicked (left button). Parameters: (nodeId, clickCount).
	public Event<delegate void(ItemClickInfo)> OnItemClick ~ _.Dispose();

	/// Fired when an item is right-clicked. Parameters: (nodeId, localX, localY).
	public Event<delegate void(int32, float, float)> OnItemRightClick ~ _.Dispose();

	/// Fired when a key is pressed with an item selected. Parameters: (nodeId, KeyEventArgs).
	/// Set e.Handled = true to prevent default TreeView key handling.
	public Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown ~ _.Dispose();

	/// Fired when a node is expanded or collapsed. Parameter: nodeId.
	public Event<delegate void(int32)> OnItemToggled ~ _.Dispose();

	private FlattenedTreeAdapter mFlatAdapter ~ delete _;
	private ListView mListView ~ delete _;
	private float mIndentWidth = 20;
	private float mArrowSize = 8;

	public float IndentWidth { get => mIndentWidth; set => mIndentWidth = value; }
	public float ArrowSize { get => mArrowSize; set => mArrowSize = value; }
	public FlattenedTreeAdapter FlatAdapter => mFlatAdapter;
	public ListView InternalListView => mListView;

	public this()
	{
		ClipsContent = true;

		mListView = new ListView();
		mListView.Parent = this;

		mListView.OnItemClicked.Add(new (position, clickCount, localX, localY) =>
		{
			// Check if click is in the arrow zone - toggle expand/collapse
			if (IsArrowHit(position, localX))
			{
				ToggleExpand(position);
				return;
			}

			// Resolve flat position to node ID and notify listeners
			let nodeId = (mFlatAdapter != null) ? mFlatAdapter.GetNodeId(position) : position;
			OnItemClick(.(){NodeId=nodeId, ClickCount=clickCount});
		});

		mListView.OnItemRightClicked.Add(new (position, localX, localY) =>
		{
			let nodeId = (mFlatAdapter != null) ? mFlatAdapter.GetNodeId(position) : position;
			OnItemRightClick(nodeId, localX, localY);
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

	/// Checks if a click at localX is in the arrow zone for the given flat position.
	private bool IsArrowHit(int32 position, float localX)
	{
		if (mFlatAdapter == null || TreeAdapter == null) return false;

		let nodeId = mFlatAdapter.GetNodeId(position);
		if (nodeId < 0 || !TreeAdapter.HasChildren(nodeId)) return false;

		let depth = mFlatAdapter.GetDepth(position);
		let arrowLeft = depth * mIndentWidth;
		let arrowRight = arrowLeft + mIndentWidth;

		return localX >= arrowLeft && localX < arrowRight;
	}

	// === Keyboard: Left/Right expand/collapse ===

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mFlatAdapter == null) return;
		let sel = mListView.Selection.FirstSelected;
		if (sel < 0) return;

		let nodeId = mFlatAdapter.GetNodeId(sel);
		if (nodeId < 0) return;

		// Let subscribers handle keys first (Delete, F2, etc.)
		OnItemKeyDown(nodeId, e);
		if (e.Handled) return;

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
		DrawTreeOverlay(ctx);
	}

	/// Draws expand/collapse arrows and indent guides for visible items.
	private void DrawTreeOverlay(UIDrawContext ctx)
	{
		if (mFlatAdapter == null || TreeAdapter == null) return;

		let arrowColor = ctx.Theme?.Palette.TextDim ?? .(160, 165, 180, 255);
		let scrollY = mListView.ScrollY;
		let itemH = mListView.ItemHeight;
		let viewportH = Height;

		// Calculate visible range
		let firstVisible = (int32)(scrollY / itemH);
		let lastVisible = Math.Min(firstVisible + (int32)(viewportH / itemH) + 1, mFlatAdapter.ItemCount - 1);

		for (int32 i = firstVisible; i <= lastVisible; i++)
		{
			let nodeId = mFlatAdapter.GetNodeId(i);
			if (nodeId < 0) continue;
			if (!TreeAdapter.HasChildren(nodeId)) continue;

			let depth = mFlatAdapter.GetDepth(i);
			let itemY = i * itemH - scrollY;
			let arrowX = depth * mIndentWidth + (mIndentWidth - mArrowSize) * 0.5f;
			let arrowCY = itemY + itemH * 0.5f;
			let halfSize = mArrowSize * 0.5f;

			ctx.VG.BeginPath();
			if (mFlatAdapter.IsExpanded(nodeId))
			{
				// Down-pointing triangle (v)
				ctx.VG.MoveTo(arrowX, arrowCY - halfSize * 0.6f);
				ctx.VG.LineTo(arrowX + mArrowSize, arrowCY - halfSize * 0.6f);
				ctx.VG.LineTo(arrowX + halfSize, arrowCY + halfSize * 0.6f);
			}
			else
			{
				// Right-pointing triangle (>)
				ctx.VG.MoveTo(arrowX, arrowCY - halfSize * 0.8f);
				ctx.VG.LineTo(arrowX + mArrowSize * 0.6f, arrowCY);
				ctx.VG.LineTo(arrowX, arrowCY + halfSize * 0.8f);
			}
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}
	}
}
