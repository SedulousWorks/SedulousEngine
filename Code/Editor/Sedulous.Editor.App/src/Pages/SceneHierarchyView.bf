namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;

/// Drop zone within a tree item row.
enum HierarchyDropZone
{
	/// No valid drop zone.
	None,
	/// Top third of row: insert before this item (reorder).
	Above,
	/// Middle third of row: reparent under this item.
	Inside,
	/// Bottom third of row: insert after this item (reorder).
	Below
}

/// Wraps TreeView with drag-to-reorder and drag-to-reparent support.
/// Implements IDragSource and IDropTarget for hierarchy manipulation.
class SceneHierarchyView : ViewGroup, IDragSource, IDropTarget
{
	private TreeView mTreeView; // Owned by ViewGroup (added via AddView)
	private SceneHierarchyAdapter mAdapter;
	private Scene mScene;

	// Drop indicator state
	private int32 mDropTargetPosition = -1;
	private HierarchyDropZone mDropZone = .None;

	// Forward TreeView properties
	public TreeView InternalTreeView => mTreeView;
	public SelectionModel Selection => mTreeView.Selection;
	public float ItemHeight { get => mTreeView.ItemHeight; set => mTreeView.ItemHeight = value; }
	public float IndentWidth { get => mTreeView.IndentWidth; set => mTreeView.IndentWidth = value; }

	public this(Scene scene)
	{
		mScene = scene;
		mTreeView = new TreeView();
		AddView(mTreeView);
	}

	public void SetAdapter(SceneHierarchyAdapter adapter)
	{
		mAdapter = adapter;
		mTreeView.SetAdapter(adapter);
	}

	// === Forward TreeView events ===

	public ref Event<delegate void(TreeView.ItemClickInfo)> OnItemClick => ref mTreeView.OnItemClick;
	public ref Event<delegate void(int32, float, float)> OnItemRightClick => ref mTreeView.OnItemRightClick;
	public ref Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown => ref mTreeView.OnItemKeyDown;
	public ref Event<delegate void(int32)> OnItemToggled => ref mTreeView.OnItemToggled;

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
		DrawDropIndicator(ctx);
	}

	private void DrawDropIndicator(UIDrawContext ctx)
	{
		if (mDropTargetPosition < 0 || mDropZone == .None) return;

		let flatAdapter = mTreeView.FlatAdapter;
		if (flatAdapter == null) return;

		let scrollY = mTreeView.InternalListView.ScrollY;
		let itemH = mTreeView.ItemHeight;
		let itemY = mDropTargetPosition * itemH - scrollY;

		let depth = flatAdapter.GetDepth(mDropTargetPosition);
		let indent = (depth + 1) * mTreeView.IndentWidth;

		let accentColor = ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);

		switch (mDropZone)
		{
		case .Above:
			// Line above the item
			ctx.VG.FillRect(.(indent, itemY - 1, Width - indent, 2), accentColor);
		case .Below:
			// Line below the item
			ctx.VG.FillRect(.(indent, itemY + itemH - 1, Width - indent, 2), accentColor);
		case .Inside:
			// Highlight the entire row
			let highlightColor = Color(accentColor.R, accentColor.G, accentColor.B, 40);
			ctx.VG.FillRect(.(indent, itemY, Width - indent, itemH), highlightColor);
			ctx.VG.StrokeRect(.(indent, itemY, Width - indent, itemH), accentColor, 1);
		case .None:
		}
	}

	// === Hit testing for drop zones ===

	private (int32 position, HierarchyDropZone zone) HitTestDropZone(float localX, float localY)
	{
		let listView = mTreeView.InternalListView;
		let position = listView.GetItemAtY(localY);

		if (position < 0 || mTreeView.FlatAdapter == null || position >= mTreeView.FlatAdapter.ItemCount)
			return (-1, .None);

		let scrollY = listView.ScrollY;
		let itemH = mTreeView.ItemHeight;
		let itemY = position * itemH - scrollY;
		let relY = localY - itemY;

		// Divide row into thirds
		let third = itemH / 3.0f;

		if (relY < third)
			return (position, .Above);
		else if (relY > itemH - third)
			return (position, .Below);
		else
			return (position, .Inside);
	}

	/// Check if dropping entity at the given zone would create a cycle.
	private bool WouldCreateCycle(EntityHandle dragEntity, EntityHandle targetEntity)
	{
		// Can't drop onto self
		if (dragEntity == targetEntity) return true;

		// Can't drop onto a descendant
		var current = targetEntity;
		while (current.IsAssigned && mScene.IsValid(current))
		{
			current = mScene.GetParent(current);
			if (current == dragEntity) return true;
		}
		return false;
	}

	// === IDragSource ===

	public DragData CreateDragData()
	{
		let sel = mTreeView.Selection.FirstSelected;
		if (sel < 0 || mTreeView.FlatAdapter == null) return null;

		let nodeId = mTreeView.FlatAdapter.GetNodeId(sel);
		if (nodeId < 0 || mAdapter == null) return null;

		let entity = mAdapter.GetEntityForNode(nodeId);
		if (entity == .Invalid) return null;

		return new HierarchyDragData(entity, nodeId);
	}

	public View CreateDragVisual(DragData data)
	{
		if (let hierData = data as HierarchyDragData)
		{
			let label = new Label();
			label.FontSize = 12;
			let name = mScene.GetEntityName(hierData.Entity);
			label.SetText(name.Length > 0 ? name : "Entity");
			label.TextColor = .(200, 200, 210, 200);
			return label;
		}
		return null;
	}

	public void OnDragStarted(DragData data) { }

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		mDropTargetPosition = -1;
		mDropZone = .None;
	}

	// === IDropTarget ===

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		if (data.Format != "hierarchy/entity") return .None;
		if (let hierData = data as HierarchyDragData)
		{
			let (pos, zone) = HitTestDropZone(localX, localY);
			if (pos < 0 || zone == .None) return .None;

			let targetNodeId = mTreeView.FlatAdapter.GetNodeId(pos);
			let targetEntity = mAdapter.GetEntityForNode(targetNodeId);
			if (targetEntity == .Invalid) return .None;

			if (WouldCreateCycle(hierData.Entity, targetEntity))
				return .None;

			// Can't reorder above/below self
			if (hierData.Entity == targetEntity && zone != .Inside)
				return .None;

			return .Move;
		}
		return .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		UpdateDropIndicator(localX, localY);
	}

	public void OnDragOver(DragData data, float localX, float localY)
	{
		UpdateDropIndicator(localX, localY);
	}

	public void OnDragLeave(DragData data)
	{
		mDropTargetPosition = -1;
		mDropZone = .None;
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		let dropPos = mDropTargetPosition;
		let dropZone = mDropZone;
		mDropTargetPosition = -1;
		mDropZone = .None;

		if (data.Format != "hierarchy/entity") return .None;
		if (let hierData = data as HierarchyDragData)
		{
			if (dropPos < 0 || dropZone == .None) return .None;

			let flatAdapter = mTreeView.FlatAdapter;
			if (flatAdapter == null) return .None;

			let targetNodeId = flatAdapter.GetNodeId(dropPos);
			let targetEntity = mAdapter.GetEntityForNode(targetNodeId);
			if (targetEntity == .Invalid) return .None;

			let dragEntity = hierData.Entity;
			if (WouldCreateCycle(dragEntity, targetEntity))
				return .None;

			switch (dropZone)
			{
			case .Inside:
				// Reparent: make dragEntity a child of targetEntity
				mScene.SetParent(dragEntity, targetEntity);

			case .Above:
				// Insert before targetEntity among its siblings
				let targetParent = mScene.GetParent(targetEntity);
				mScene.SetParent(dragEntity, targetParent);
				let targetIndex = mScene.GetSiblingIndex(targetEntity);
				mScene.SetSiblingIndex(dragEntity, targetIndex);

			case .Below:
				// Insert after targetEntity among its siblings
				let targetParent = mScene.GetParent(targetEntity);
				mScene.SetParent(dragEntity, targetParent);
				let targetIndex = mScene.GetSiblingIndex(targetEntity);
				mScene.SetSiblingIndex(dragEntity, targetIndex + 1);

			case .None:
				return .None;
			}

			mAdapter.Rebuild();
			return .Move;
		}

		return .None;
	}

	private void UpdateDropIndicator(float localX, float localY)
	{
		let (pos, zone) = HitTestDropZone(localX, localY);
		mDropTargetPosition = pos;
		mDropZone = zone;
	}
}
