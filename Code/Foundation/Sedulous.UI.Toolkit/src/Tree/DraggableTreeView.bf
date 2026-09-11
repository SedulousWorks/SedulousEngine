using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A tree whose rows can be dragged: reordered among their siblings, or dropped into another
/// row to reparent.
///
/// It WRAPS a tree rather than subclassing one, and holds it as a visual child outside the
/// logical child list, so the drop indicator can be drawn over the rows without the tree's own
/// layout knowing anything about it.
///
/// The drop zones are the whole of the interaction design. Over a row, the middle half is
/// "drop INTO this row" and the two edge quarters are "insert at this boundary". Each zone
/// falls back to the other's meaning when its own is unsupported, so an adapter that only
/// reorders and one that only reparents both work anywhere on a row rather than in a band the
/// user has to find.
class DraggableTreeView : ViewGroup, IDragSource, IDropTarget
{
	/// Where a drop landed: a row to go inside, or a boundary to insert at.
	private struct DropResolution
	{
		/// Dropping into: the target row. Reordering: the insert-before boundary, from nought
		/// to the row count inclusive.
		public int32 Position = -1;
		public bool Into = false;
		public bool Valid = false;

		public this() {}

		public this(int32 position, bool into, bool valid)
		{
			Position = position;
			Into = into;
			Valid = valid;
		}
	}

	public Event<delegate void(DraggableTreeView, int32, int32)> OnItemReordered ~ _.Dispose();
	/// Fired after the adapter's DropInto ran.
	public Event<delegate void(DraggableTreeView, int32, int32)> OnItemDroppedInto ~ _.Dispose();

	/// OWNED, and a VISUAL child rather than a logical one.
	private TreeView mTreeView = new .() ~ _.ReleaseRef();
	/// BORROWED: the consumer owns the adapter.
	private IReorderableTreeAdapter mAdapter = null;

	private bool mDragEnabled = true;
	private int32 mDropIndicatorPos = -1;
	private int32 mDropIntoPos = -1;

	public this()
	{
		mTreeView.Parent = this;
	}

	public bool DragEnabled
	{
		get => mDragEnabled;
		set => mDragEnabled = value;
	}

	/// BORROWED.
	public TreeView InternalTreeView => mTreeView;

	public SelectionModel Selection => mTreeView.Selection;

	public float ItemHeight
	{
		get => mTreeView.ItemHeight;
		set => mTreeView.ItemHeight = value;
	}

	/// A row's content inset at a depth. Forwarded, so this stays the ONE place indentation is
	/// decided; an adapter writing a literal instead drifts from the tree's indent width and the
	/// chevron ends up under the text.
	public float ContentInset(int32 depth) => mTreeView.ContentInset(depth);

	/// BORROWED.
	public void SetAdapter(IReorderableTreeAdapter adapter)
	{
		mAdapter = adapter;
		mTreeView.SetAdapter(adapter);
	}

	public override int VisualChildCount => 1;

	public override View GetVisualChild(int index) => (index == 0) ? mTreeView : null;

	// ---- Drawing --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);

		// SCROLL CORRECTED, matching how the drop was resolved: the indicator is positioned in
		// row space and the list may be scrolled under it.
		let scrollY = mTreeView.InternalListView.ScrollY;
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(80, 160, 255));

		if (mDropIndicatorPos >= 0)
			ctx.VG.FillRect(.(0, (mDropIndicatorPos * mTreeView.ItemHeight) - scrollY, Width, 2),
				accent);

		if (mDropIntoPos >= 0)
			DrawDropIntoHighlight(ctx, (mDropIntoPos * mTreeView.ItemHeight) - scrollY, accent);
	}

	/// A washed fill with an outline, rather than a line: dropping INTO a row is a different
	/// operation from inserting between two, and must not look like one.
	private void DrawDropIntoHighlight(UIDrawContext ctx, float y, Color accent)
	{
		let row = Rectangle(0, y, Width, mTreeView.ItemHeight);
		let fill = Color(accent.R, accent.G, accent.B, 0.25f);
		let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);

		if (cornerRadius > 0.0f)
		{
			ctx.VG.FillRoundedRect(row, cornerRadius, fill);
			ctx.VG.StrokeRoundedRect(row, cornerRadius, accent, 1.0f);
		}
		else
		{
			ctx.VG.FillRect(row, fill);
			ctx.VG.StrokeRect(row, accent, 1.0f);
		}
	}

	// ---- IDragSource ----------------------------------------------------------------------------

	public override IDragSource AsDragSource() => this;

	public DragData CreateDragData()
	{
		if (!mDragEnabled)
			return null;

		let selected = mTreeView.Selection.FirstSelected();
		if (selected < 0)
			return null;

		return new TreeDragData(selected);
	}

	public View CreateDragVisual(DragData data)
	{
		let label = new Label();
		label.SetText("Moving item");
		return label;
	}

	public void OnDragStarted(DragData data) {}

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		mDropIndicatorPos = -1;
	}

	// ---- IDropTarget ----------------------------------------------------------------------------

	public override IDropTarget AsDropTarget() => this;

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		if (data.Format != "tree/reorder")
			return .None;

		if (let treeDrag = data as TreeDragData)
			return ResolveDrop(treeDrag.SourcePosition, localY).Valid ? .Move : .None;

		return .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY) =>
		UpdateDropIndicator(data, localY);

	public void OnDragOver(DragData data, float localX, float localY) =>
		UpdateDropIndicator(data, localY);

	public void OnDragLeave(DragData data)
	{
		mDropIndicatorPos = -1;
		mDropIntoPos = -1;
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		mDropIndicatorPos = -1;
		mDropIntoPos = -1;

		let treeDrag = data as TreeDragData;
		if (treeDrag == null)
			return .None;

		let drop = ResolveDrop(treeDrag.SourcePosition, localY);
		if (!drop.Valid)
			return .None;

		if (drop.Into)
		{
			mAdapter.DropInto(treeDrag.SourcePosition, drop.Position);
			OnItemDroppedInto(this, treeDrag.SourcePosition, drop.Position);
			return .Move;
		}

		mAdapter.MoveItem(treeDrag.SourcePosition, drop.Position);
		OnItemReordered(this, treeDrag.SourcePosition, drop.Position);
		return .Move;
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		mTreeView.Measure(constraints);
		MeasuredSize = mTreeView.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mTreeView.Layout(0, 0, width, height);
	}

	// ---- Drop resolution ------------------------------------------------------------------------

	/// Which zone a point falls in, in ROW space rather than screen space, so the answer is the
	/// same however the list is scrolled.
	private DropResolution ResolveDrop(int32 fromPosition, float localY)
	{
		if (mAdapter == null)
			return .();

		let count = (mTreeView.FlatAdapter != null) ? mTreeView.FlatAdapter.ItemCount : 0;
		let rows = (localY + mTreeView.InternalListView.ScrollY) / mTreeView.ItemHeight;
		let row = (int32)rows;
		let fraction = rows - (float)row;

		// Below the last row there is only one thing a drop can mean.
		if (row >= count)
			return .(count, false, mAdapter.CanMove(fromPosition, count));

		let wantsInto = (fraction >= 0.25f) && (fraction <= 0.75f);
		let boundary = (fraction < 0.5f) ? row : (row + 1);

		if (wantsInto && mAdapter.CanDropInto(fromPosition, row))
			return .(row, true, true);

		if (mAdapter.CanMove(fromPosition, boundary))
			return .(boundary, false, true);

		// The FALLBACK: an edge band means reparenting too, when the adapter only reparents.
		if (!wantsInto && mAdapter.CanDropInto(fromPosition, row))
			return .(row, true, true);

		return .(boundary, false, false);
	}

	private void UpdateDropIndicator(DragData data, float localY)
	{
		mDropIndicatorPos = -1;
		mDropIntoPos = -1;

		let treeDrag = data as TreeDragData;
		if (treeDrag == null)
			return;

		let drop = ResolveDrop(treeDrag.SourcePosition, localY);
		if (!drop.Valid)
			return;

		if (drop.Into)
			mDropIntoPos = drop.Position;
		else
			mDropIndicatorPos = drop.Position;
	}
}
