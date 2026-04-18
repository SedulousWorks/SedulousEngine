namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Interface for tree adapters that support drag-to-reorder.
public interface IReorderableTreeAdapter : ITreeAdapter
{
	/// Whether the item at fromPosition can be moved.
	bool CanMove(int32 fromPosition, int32 toPosition);

	/// Move an item from one flat position to another.
	void MoveItem(int32 fromPosition, int32 toPosition);
}

/// Drag data for tree item reordering.
public class TreeDragData : DragData
{
	public int32 SourcePosition;

	public this(int32 sourcePosition) : base("tree/reorder")
	{
		SourcePosition = sourcePosition;
	}
}

/// TreeView with drag-to-reorder support.
/// Wraps a TreeView and implements IDragSource/IDropTarget.
public class DraggableTreeView : ViewGroup, IDragSource, IDropTarget
{
	private TreeView mTreeView ~ delete _;
	private IReorderableTreeAdapter mAdapter;
	private bool mDragEnabled = true;
	private int32 mDropIndicatorPos = -1;

	public Event<delegate void(DraggableTreeView, int32, int32)> OnItemReordered ~ _.Dispose();

	public bool DragEnabled
	{
		get => mDragEnabled;
		set => mDragEnabled = value;
	}

	public TreeView InternalTreeView => mTreeView;
	public SelectionModel Selection => mTreeView.Selection;

	public float ItemHeight
	{
		get => mTreeView.ItemHeight;
		set => mTreeView.ItemHeight = value;
	}

	public this()
	{
		mTreeView = new TreeView();
		mTreeView.Parent = this;
	}

	public void SetAdapter(IReorderableTreeAdapter adapter)
	{
		mAdapter = adapter;
		mTreeView.SetAdapter(adapter);
	}

	// === Visual children ===

	public override int VisualChildCount => 1;
	public override View GetVisualChild(int index) => (index == 0) ? mTreeView : null;

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		mTreeView.Measure(wSpec, hSpec);
		MeasuredSize = mTreeView.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		mTreeView.Layout(0, 0, right - left, bottom - top);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);

		// Drop indicator line.
		if (mDropIndicatorPos >= 0)
		{
			let indicatorColor = ctx.Theme?.GetColor("DraggableTreeView.DropIndicator") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
			let y = mDropIndicatorPos * mTreeView.ItemHeight;
			ctx.VG.FillRect(.(0, y, Width, 2), indicatorColor);
		}
	}

	// === IDragSource ===

	public DragData CreateDragData()
	{
		if (!mDragEnabled) return null;
		let sel = mTreeView.Selection.FirstSelected;
		if (sel < 0) return null;
		return new TreeDragData(sel);
	}

	public View CreateDragVisual(DragData data)
	{
		let label = new Label();
		label.SetText("Moving item");
		label.FontSize = 12;
		return label;
	}

	public void OnDragStarted(DragData data) { }
	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		mDropIndicatorPos = -1;
	}

	// === IDropTarget ===

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		if (data.Format != "tree/reorder") return .None;

		if (let treeDrag = data as TreeDragData)
		{
			let targetPos = (int32)(localY / mTreeView.ItemHeight);
			if (mAdapter != null && mAdapter.CanMove(treeDrag.SourcePosition, targetPos))
				return .Move;
		}
		return .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		UpdateDropIndicator(localY);
	}

	public void OnDragOver(DragData data, float localX, float localY)
	{
		UpdateDropIndicator(localY);
	}

	public void OnDragLeave(DragData data)
	{
		mDropIndicatorPos = -1;
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		mDropIndicatorPos = -1;

		if (let treeDrag = data as TreeDragData)
		{
			let targetPos = (int32)(localY / mTreeView.ItemHeight);
			if (mAdapter != null && mAdapter.CanMove(treeDrag.SourcePosition, targetPos))
			{
				mAdapter.MoveItem(treeDrag.SourcePosition, targetPos);
				OnItemReordered(this, treeDrag.SourcePosition, targetPos);
				return .Move;
			}
		}
		return .None;
	}

	private void UpdateDropIndicator(float localY)
	{
		mDropIndicatorPos = (int32)(localY / mTreeView.ItemHeight);
	}
}
