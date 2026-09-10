using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A tree, drawn as a list.
///
/// Underneath it is an ordinary ListView over a FlattenedTreeAdapter, so it inherits the
/// recycling and virtualisation rather than reimplementing them. All this adds is the indent,
/// the chevrons, and the expansion.
///
/// The tree adapter is BORROWED; the flattened one is built here and owned here.
class TreeView : ViewGroup
{
	/// BORROWED. Null detaches, which is what an owner does in its destructor so the view
	/// never outlives an adapter it does not own.
	public ITreeAdapter TreeAdapter = null;

	public Property<float> IndentWidth = new .(20.0f) ~ delete _;
	public Property<float> ArrowSize = new .(8.0f) ~ delete _;

	public Event<delegate void(TreeItemClickInfo)> OnItemClick ~ _.Dispose();
	/// (nodeId, localX, localY)
	public Event<delegate void(int32, float, float)> OnItemRightClick ~ _.Dispose();
	/// (nodeId, args). Marking the args handled suppresses the tree's own key handling.
	public Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown ~ _.Dispose();
	public Event<delegate void(int32)> OnItemToggled ~ _.Dispose();

	/// OWNED, and a VISUAL child rather than a logical one.
	private ListView mListView;
	/// OWNED, and rebuilt whenever the tree adapter changes.
	private FlattenedTreeAdapter mFlatAdapter = null;

	public this()
	{
		ClipsContent = true;
		// The arrows expand and collapse, so focus must not spend them on moving away.
		WantsArrowKeys = true;
		IndentWidth.SetOwner(this);
		ArrowSize.SetOwner(this);

		mListView = new ListView();
		mListView.Parent = this;

		mListView.OnItemClicked.Add(new (position, clickCount, localX, localY) =>
			{
				// A click in the chevron column TOGGLES and reports nothing else: expanding a
				// node is not selecting it.
				if (IsArrowHit(position, localX))
				{
					ToggleExpand(position);
					return;
				}

				OnItemClick(TreeItemClickInfo(NodeIdAt(position), clickCount));
			});

		mListView.OnItemRightClicked.Add(new (position, localX, localY) =>
			{
				OnItemRightClick(NodeIdAt(position), localX, localY);
			});
	}

	public ~this()
	{
		// The list holds a pointer to the flattened adapter, so it is detached before that
		// adapter is deleted.
		mListView.SetAdapter(null);
		delete mFlatAdapter;

		if (mListView.Context != null)
			mListView.Context.DetachView(mListView);
		mListView.Parent = null;
		mListView.ReleaseRef();
	}

	// ---- Indentation ------------------------------------------------------------------------

	/// Where a row at this depth must start its CONTENT so it clears the chevron column.
	///
	/// The chevron occupies one indent level, from depth*IndentWidth to (depth+1)*IndentWidth,
	/// so content begins one level further in.
	///
	/// A tree adapter MUST derive its row indent from this, through TextOffsetX on a label row
	/// or a left padding on a container row, and never from a hardcoded constant. A literal
	/// that drifts from IndentWidth is exactly how a chevron ends up drawn over the row text.
	/// This is the one source of truth for it.
	public float ContentInset(int32 depth) => (depth + 1) * IndentWidth.Value;

	// ---- Passthroughs -----------------------------------------------------------------------

	public SelectionModel Selection => mListView.Selection;

	public float ItemHeight
	{
		get => mListView.ItemHeight.Value;
		set => mListView.ItemHeight.Value = value;
	}

	/// Borrowed; may be null.
	public FlattenedTreeAdapter FlatAdapter => mFlatAdapter;
	/// Borrowed. The list underneath, for callers that need to scroll it.
	public ListView InternalListView => mListView;

	// ---- Adapter ----------------------------------------------------------------------------

	/// BORROWS the tree adapter and builds a flat view of it. Safe to call again; null detaches.
	public void SetAdapter(ITreeAdapter adapter)
	{
		TreeAdapter = adapter;

		// The list is detached from the OLD flattened adapter before that adapter is deleted:
		// ListView.SetAdapter calls SetObserver on the one it held, which would otherwise be a
		// use after free.
		mListView.SetAdapter(null);
		delete mFlatAdapter;
		mFlatAdapter = null;

		if (adapter == null)
			return;

		mFlatAdapter = new FlattenedTreeAdapter(adapter);
		mListView.SetAdapter(mFlatAdapter);
	}

	// ---- Expansion --------------------------------------------------------------------------

	/// Toggles the node at a flat position.
	public void ToggleExpand(int32 flatPosition)
	{
		if (mFlatAdapter == null)
			return;

		let nodeId = mFlatAdapter.GetNodeId(flatPosition);
		if (nodeId >= 0)
			ToggleNodePreservingSelection(nodeId);
	}

	/// Toggles a node, carrying the selection across the rebuild by NODE id.
	///
	/// The selection is positional, and collapsing a node above it shifts every flat index
	/// after. Without this remapping the highlight jumps to whichever row inherits the old
	/// index. Selected nodes that the collapse hides drop out rather than being remapped to
	/// something arbitrary.
	private void ToggleNodePreservingSelection(int32 nodeId)
	{
		let selection = mListView.Selection;

		// Captured as node ids, which survive a rebuild.
		let selectedNodes = scope List<int32>();
		let countBefore = mFlatAdapter.ItemCount;
		for (int32 position = 0; position < countBefore; position++)
		{
			if (selection.IsSelected(position))
				selectedNodes.Add(mFlatAdapter.GetNodeId(position));
		}

		mFlatAdapter.ToggleExpand(nodeId);
		mListView.NotifyDataChanged();

		// Back to positions. A node the collapse hid answers -1 and is dropped.
		let remapped = scope List<int32>();
		for (let selectedNode in selectedNodes)
		{
			let position = mFlatAdapter.PositionOfNode(selectedNode);
			if (position >= 0)
				remapped.Add(position);
		}

		selection.ReplaceAll(remapped);
		OnItemToggled(nodeId);
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mFlatAdapter == null)
			return;

		let selected = mListView.Selection.FirstSelected();
		if (selected < 0)
			return;

		let nodeId = mFlatAdapter.GetNodeId(selected);
		if (nodeId < 0)
			return;

		// The row gets FIRST refusal, so a consumer can bind its own keys without the tree
		// having to know about them.
		OnItemKeyDown(nodeId, e);
		if (e.Handled)
			return;

		if (!TreeAdapter.HasChildren(nodeId))
			return;

		// Right OPENS and Left CLOSES, and neither is handled when there is nothing to do, so
		// Right on a leaf can still reach the list's own navigation.
		switch (e.Key)
		{
		case .Right:
			if (!mFlatAdapter.IsExpanded(nodeId))
			{
				ToggleNodePreservingSelection(nodeId);
				e.Handled = true;
			}
		case .Left:
			if (mFlatAdapter.IsExpanded(nodeId))
			{
				ToggleNodePreservingSelection(nodeId);
				e.Handled = true;
			}
		default:
		}
	}

	/// Whether a local X falls in the chevron column of the row at a flat position.
	public bool IsArrowHit(int32 position, float localX)
	{
		if ((mFlatAdapter == null) || (TreeAdapter == null))
			return false;

		let nodeId = mFlatAdapter.GetNodeId(position);
		if ((nodeId < 0) || !TreeAdapter.HasChildren(nodeId))
			return false;

		let arrowLeft = mFlatAdapter.GetDepth(position) * IndentWidth.Value;
		return (localX >= arrowLeft) && (localX < arrowLeft + IndentWidth.Value);
	}

	// ---- Layout and draw --------------------------------------------------------------------

	public override int VisualChildCount => 1;

	public override View GetVisualChild(int index) => (index == 0) ? mListView : null;

	protected override void OnMeasure(BoxConstraints constraints)
	{
		mListView.Measure(constraints);
		MeasuredSize = mListView.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mListView.Layout(0, 0, width, height);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);
		// The chevrons are drawn OVER the rows, so an adapter's views need know nothing about
		// being in a tree.
		DrawChevrons(ctx);
	}

	private void DrawChevrons(UIDrawContext ctx)
	{
		if ((mFlatAdapter == null) || (TreeAdapter == null))
			return;

		let itemHeight = mListView.ItemHeight.Value;
		if (itemHeight <= 0)
			return;

		let scrollY = mListView.ScrollY;
		let firstVisible = (int32)(scrollY / itemHeight);
		let lastVisible = Min(firstVisible + (int32)(Height / itemHeight) + 1,
			mFlatAdapter.ItemCount - 1);

		for (int32 i = firstVisible; i <= lastVisible; i++)
		{
			let nodeId = mFlatAdapter.GetNodeId(i);
			// A leaf gets no chevron, which is what makes one mean "there is more here".
			if ((nodeId < 0) || !TreeAdapter.HasChildren(nodeId))
				continue;

			DrawChevron(ctx, i, nodeId, itemHeight, scrollY);
		}
	}

	private void DrawChevron(UIDrawContext ctx, int32 position, int32 nodeId, float itemHeight,
		float scrollY)
	{
		let depth = mFlatAdapter.GetDepth(position);
		let arrowSize = ArrowSize.Value;
		let halfSize = arrowSize * 0.5f;

		// Centred in its indent column, and on the row.
		let arrowX = depth * IndentWidth.Value + (IndentWidth.Value - arrowSize) * 0.5f;
		let arrowCY = position * itemHeight - scrollY + itemHeight * 0.5f;

		let isExpanded = mFlatAdapter.IsExpanded(nodeId);

		// Expanded reads as Checked, so a theme styles the two directions as one part with a
		// state rather than as two drawables.
		var chevronState = GetControlState();
		if (isExpanded)
			chevronState |= .Checked;

		if (let chevron = ResolvePartDrawable("chevron", .Background, chevronState))
		{
			chevron.Draw(ctx, .(arrowX, arrowCY - halfSize, arrowSize, arrowSize));
			return;
		}

		let color = ResolveStyleColor(.TextDimColor, Color(160 / 255.0f, 165 / 255.0f, 180 / 255.0f, 1.0f));

		ctx.VG.BeginPath();
		if (isExpanded)
		{
			// Pointing down.
			ctx.VG.MoveTo(arrowX, arrowCY - halfSize * 0.6f);
			ctx.VG.LineTo(arrowX + arrowSize, arrowCY - halfSize * 0.6f);
			ctx.VG.LineTo(arrowX + halfSize, arrowCY + halfSize * 0.6f);
		}
		else
		{
			// Pointing right.
			ctx.VG.MoveTo(arrowX, arrowCY - halfSize * 0.8f);
			ctx.VG.LineTo(arrowX + arrowSize * 0.6f, arrowCY);
			ctx.VG.LineTo(arrowX, arrowCY + halfSize * 0.8f);
		}
		ctx.VG.ClosePath();
		ctx.VG.Fill(color);
	}

	/// The node at a flat position, falling back to the position itself when there is no
	/// adapter to ask.
	private int32 NodeIdAt(int32 position) =>
		(mFlatAdapter != null) ? mFlatAdapter.GetNodeId(position) : position;
}
