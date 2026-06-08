namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Drop-zone hint for the particle tree drag-reorder UI. We don't allow
/// reparenting (initializers can't become behaviors etc.), so there's no
/// Inside zone - only Above / Below for sibling reorders.
enum ParticleTreeDropZone
{
	None,
	Above,
	Below
}

/// Drag payload for reordering nodes inside the particle tree. Carries the
/// nodeId of the source row so the drop handler can resolve the underlying
/// model object via the adapter.
class ParticleNodeDragData : DragData
{
	public int32 SourceNodeId;

	public this(int32 sourceNodeId) : base("particle/node")
	{
		SourceNodeId = sourceNodeId;
	}
}

/// Wraps TreeView with drag-to-reorder constrained to same-parent siblings.
/// Mirrors the SceneHierarchyView shape: thin ViewGroup, internal TreeView,
/// custom IDragSource + IDropTarget. Reordering only fires for System /
/// Initializer / Behavior nodes; folders / emitter / root are non-draggable
/// and non-droppable.
class ParticleTreeView : ViewGroup, IDragSource, IDropTarget
{
	private TreeView mTreeView; // owned via AddView
	private ParticleEffectTreeAdapter mAdapter; // non-owning
	private ParticleEditorPage mPage; // non-owning

	private int32 mDropTargetPosition = -1;
	private ParticleTreeDropZone mDropZone = .None;

	public this(ParticleEditorPage page)
	{
		mPage = page;
		mTreeView = new TreeView();
		AddView(mTreeView);
	}

	public TreeView InternalTreeView => mTreeView;
	public float ItemHeight { get => mTreeView.ItemHeight; set => mTreeView.ItemHeight = value; }

	public void SetAdapter(ParticleEffectTreeAdapter adapter)
	{
		mAdapter = adapter;
		mTreeView.SetAdapter(adapter);
	}

	// Forward TreeView events so the factory wires single-click and right-click.
	public ref Event<delegate void(TreeView.ItemClickInfo)> OnItemClick => ref mTreeView.OnItemClick;
	public ref Event<delegate void(int32, float, float)> OnItemRightClick => ref mTreeView.OnItemRightClick;

	// === Visual children ===
	public override int VisualChildCount => 1;
	public override View GetVisualChild(int index) => (index == 0) ? mTreeView : null;

	// === Layout ===
	protected override void OnMeasure(BoxConstraints constraints)
	{
		mTreeView.Measure(constraints);
		MeasuredSize = mTreeView.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mTreeView.Layout(0, 0, width, height);
	}

	// === Drawing (overlay the drop indicator on top of the children) ===
	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);
		DrawDropIndicator(ctx);
	}

	private void DrawDropIndicator(UIDrawContext ctx)
	{
		if (mDropTargetPosition < 0 || mDropZone == .None) return;
		let scrollY = mTreeView.InternalListView.ScrollY;
		let itemH = mTreeView.ItemHeight;
		let itemY = mDropTargetPosition * itemH - scrollY;
		let accent = ResolveStyleColor(.AccentColor, .(80, 160, 255, 255));
		switch (mDropZone)
		{
		case .Above: ctx.VG.FillRect(.(0, itemY - 1, Width, 2), accent);
		case .Below: ctx.VG.FillRect(.(0, itemY + itemH - 1, Width, 2), accent);
		case .None:
		}
	}

	// === IDragSource ===

	public DragData CreateDragData()
	{
		if (mAdapter == null) return null;
		let sel = mTreeView.Selection.FirstSelected;
		if (sel < 0 || mTreeView.FlatAdapter == null) return null;
		let nodeId = mTreeView.FlatAdapter.GetNodeId(sel);
		if (nodeId < 0) return null;

		// Only reorderable kinds may initiate a drag.
		let kind = mAdapter.GetNodeKind(nodeId);
		if (kind != .System && kind != .Initializer && kind != .Behavior)
			return null;

		return new ParticleNodeDragData(nodeId);
	}

	public View CreateDragVisual(DragData data)
	{
		let label = new Label();
		label.FontSize.Value = 12;
		label.TextColor.Value = .(200, 200, 210, 220);
		if (let drag = data as ParticleNodeDragData)
		{
			let target = mAdapter?.GetNodeTarget(drag.SourceNodeId);
			if (target != null)
			{
				let typeName = target.GetType().GetName(.. scope .());
				let display = scope String(typeName);
				if (display.EndsWith("Initializer")) display.RemoveFromEnd(11);
				else if (display.EndsWith("Behavior")) display.RemoveFromEnd(8);
				label.SetText(display);
			}
		}
		return label;
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
		if (data.Format != "particle/node") return .None;
		let drag = data as ParticleNodeDragData;
		if (drag == null || mAdapter == null) return .None;
		let (pos, zone, targetNode) = HitTestDropZone(localX, localY);
		if (pos < 0 || zone == .None || targetNode < 0) return .None;
		return IsValidReorder(drag.SourceNodeId, targetNode) ? .Move : .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY) { UpdateDropIndicator(localX, localY); }
	public void OnDragOver(DragData data, float localX, float localY) { UpdateDropIndicator(localX, localY); }
	public void OnDragLeave(DragData data) { mDropTargetPosition = -1; mDropZone = .None; }

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		let (pos, zone, targetNode) = HitTestDropZone(localX, localY);
		mDropTargetPosition = -1;
		mDropZone = .None;

		if (data.Format != "particle/node") return .None;
		let drag = data as ParticleNodeDragData;
		if (drag == null || mAdapter == null) return .None;
		if (pos < 0 || zone == .None || targetNode < 0) return .None;
		if (!IsValidReorder(drag.SourceNodeId, targetNode)) return .None;

		PerformReorder(drag.SourceNodeId, targetNode, zone);
		return .Move;
	}

	// === Internal ===

	private void UpdateDropIndicator(float localX, float localY)
	{
		let (pos, zone, _) = HitTestDropZone(localX, localY);
		mDropTargetPosition = pos;
		mDropZone = zone;
	}

	/// Resolve the row under (localX, localY) into a (flat position, zone,
	/// nodeId) triple. Returns -1 for invalid positions.
	private (int32 pos, ParticleTreeDropZone zone, int32 nodeId) HitTestDropZone(float localX, float localY)
	{
		let listView = mTreeView.InternalListView;
		let pos = listView.GetItemAtY(localY);
		if (pos < 0 || mTreeView.FlatAdapter == null) return (-1, .None, -1);
		if (pos >= mTreeView.FlatAdapter.ItemCount) return (-1, .None, -1);

		let scrollY = listView.ScrollY;
		let itemH = mTreeView.ItemHeight;
		let itemY = pos * itemH - scrollY;
		let relY = localY - itemY;

		let nodeId = mTreeView.FlatAdapter.GetNodeId(pos);
		if (nodeId < 0) return (pos, .None, -1);

		let zone = relY < itemH * 0.5f ? ParticleTreeDropZone.Above : ParticleTreeDropZone.Below;
		return (pos, zone, nodeId);
	}

	private bool IsValidReorder(int32 sourceId, int32 targetId)
	{
		if (sourceId == targetId) return false;
		let srcKind = mAdapter.GetNodeKind(sourceId);
		let dstKind = mAdapter.GetNodeKind(targetId);
		// Same kind = same logical container (Systems / Initializers / Behaviors).
		if (srcKind != dstKind) return false;
		if (srcKind != .System && srcKind != .Initializer && srcKind != .Behavior)
			return false;
		// Sibling check: same parent node id (the parent System for inits/behaviors,
		// the effect root for systems).
		return mAdapter.GetParentNodeId(sourceId) == mAdapter.GetParentNodeId(targetId);
	}

	/// Apply the reorder. Translates the (target node, zone) into an
	/// insertion index in the underlying data list, calls the matching
	/// Move API, rebuilds the tree, and restores selection on the moved
	/// object.
	private void PerformReorder(int32 sourceId, int32 targetId, ParticleTreeDropZone zone)
	{
		let effect = mPage?.EffectResource?.Effect;
		if (effect == null || mAdapter == null) return;

		let srcKind = mAdapter.GetNodeKind(sourceId);
		let srcIdx = mAdapter.GetDataIndex(sourceId);
		var dstIdx = mAdapter.GetDataIndex(targetId);
		if (srcIdx < 0 || dstIdx < 0) return;
		if (zone == .Below) dstIdx++;
		// Removing the source before inserting at dstIdx shifts subsequent
		// indices down by one - compensate when dropping past the source.
		if (srcIdx < dstIdx) dstIdx--;
		if (dstIdx == srcIdx) return;

		let target = mAdapter.GetNodeTarget(sourceId);
		mPage.SelectObject(null);

		switch (srcKind)
		{
		case .System:
			effect.MoveSystem(srcIdx, dstIdx);
		case .Initializer:
			let owner = mAdapter.GetOwningSystem(sourceId);
			if (owner == null) return;
			owner.MoveInitializer(srcIdx, dstIdx);
		case .Behavior:
			let owner = mAdapter.GetOwningSystem(sourceId);
			if (owner == null) return;
			owner.MoveBehavior(srcIdx, dstIdx);
		default:
			return;
		}

		mAdapter.Rebuild();
		let newId = mAdapter.FindNodeForTarget(target);
		if (newId >= 0)
			mAdapter.SelectNode(newId);
		mPage.MarkDirty();
		mPage.Restart();
	}
}
