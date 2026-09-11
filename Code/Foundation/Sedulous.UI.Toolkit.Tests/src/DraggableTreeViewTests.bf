using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The reorderable tree: its wiring, what it accepts, and where a drop lands.
class DraggableTreeViewTests
{
	/// Three flat rows that allow every move, recording what it was asked to do.
	private class FlatReorderAdapter : IReorderableTreeAdapter
	{
		public int32 LastFrom = -1;
		public int32 LastTo = -1;
		public int32 MoveCount = 0;
		public int32 IntoCount = 0;
		/// When set, the adapter also reparents, which is what turns the middle band on.
		public bool AllowInto = false;

		public int32 RootCount => 3;
		public int32 GetChildCount(int32 nodeId) => 0;
		public int32 GetChildId(int32 parentId, int32 childIndex) => childIndex;
		public int32 GetDepth(int32 nodeId) => 0;
		public bool HasChildren(int32 nodeId) => false;
		public View CreateView(int32 viewType) => new Label();
		public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded) {}
		public int32 GetItemViewType(int32 nodeId) => 0;
		public void SetObserver(ITreeAdapterObserver observer) {}

		public bool CanMove(int32 fromPosition, int32 toPosition) => true;

		public void MoveItem(int32 fromPosition, int32 toPosition)
		{
			LastFrom = fromPosition;
			LastTo = toPosition;
			MoveCount++;
		}

		public bool CanDropInto(int32 fromPosition, int32 toPosition) => AllowInto;

		public void DropInto(int32 fromPosition, int32 toPosition)
		{
			LastFrom = fromPosition;
			LastTo = toPosition;
			IntoCount++;
		}
	}

	[Test]
	public static void ItConstructsAndItsPropertiesRoundTrip()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		Test.Assert(view.DragEnabled);
		view.DragEnabled = false;
		Test.Assert(!view.DragEnabled);
		view.DragEnabled = true;

		view.ItemHeight = 28.0f;
		Test.Assert(view.ItemHeight == 28.0f);
		Test.Assert(view.InternalTreeView != null);
	}

	[Test]
	public static void SetAdapterReachesTheInnerTree()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		let adapter = scope FlatReorderAdapter();
		view.SetAdapter(adapter);
		Test.Assert(view.InternalTreeView.TreeAdapter == adapter);
	}

	/// Only this tree's own payload is accepted, which is what stops a drag from elsewhere in
	/// the editor landing in a tree that cannot make sense of it.
	[Test]
	public static void OnlyATreeReorderPayloadIsAccepted()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		let adapter = scope FlatReorderAdapter();
		view.SetAdapter(adapter);
		view.ItemHeight = 20.0f;

		let target = view.AsDropTarget();
		Test.Assert(target != null);

		// NOT scope: drag data is reference counted, and a scoped one destructs with a count
		// still standing.
		let treeDrag = new TreeDragData(0);
		defer treeDrag.ReleaseRef();
		Test.Assert(target.CanAcceptDrop(treeDrag, 5.0f, 25.0f) == .Move);

		let other = new DragData("text/plain");
		defer other.ReleaseRef();
		Test.Assert(target.CanAcceptDrop(other, 5.0f, 25.0f) == .None);
	}

	[Test]
	public static void DroppingOnABoundaryMovesTheItem()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		let adapter = scope FlatReorderAdapter();
		view.SetAdapter(adapter);
		view.ItemHeight = 20.0f;

		var firedFrom = -1;
		var firedTo = -1;
		var fires = 0;
		view.OnItemReordered.Add(new [&](sender, from, to) =>
			{
				firedFrom = from;
				firedTo = to;
				fires++;
			});

		let treeDrag = new TreeDragData(0);
		defer treeDrag.ReleaseRef();
		// Forty five over a row height of twenty is row two, a quarter of the way down, which
		// is an edge band and so the boundary before it.
		Test.Assert(view.AsDropTarget().OnDrop(treeDrag, 5.0f, 45.0f) == .Move);

		Test.Assert(adapter.MoveCount == 1);
		Test.Assert(adapter.LastFrom == 0);
		Test.Assert(adapter.LastTo == 2);
		Test.Assert(fires == 1);
		Test.Assert(firedFrom == 0);
		Test.Assert(firedTo == 2);
	}

	/// The middle half of a row REPARENTS when the adapter allows it, and the edge quarters
	/// still reorder.
	[Test]
	public static void TheMiddleBandDropsIntoARowWhenTheAdapterAllowsIt()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		let adapter = scope FlatReorderAdapter();
		adapter.AllowInto = true;
		view.SetAdapter(adapter);
		view.ItemHeight = 20.0f;

		var intoFires = 0;
		view.OnItemDroppedInto.Add(new [&](sender, from, to) => { intoFires++; });

		let treeDrag = new TreeDragData(0);
		defer treeDrag.ReleaseRef();
		let target = view.AsDropTarget();

		// Halfway down row one is the middle band.
		Test.Assert(target.OnDrop(treeDrag, 5.0f, 30.0f) == .Move);
		Test.Assert(adapter.IntoCount == 1);
		Test.Assert(adapter.LastTo == 1, "into the row itself, not a boundary");
		Test.Assert(intoFires == 1);

		// The top edge of row one is still a boundary.
		Test.Assert(target.OnDrop(treeDrag, 5.0f, 21.0f) == .Move);
		Test.Assert(adapter.MoveCount == 1);
		Test.Assert(adapter.LastTo == 1, "the boundary before row one");
	}

	/// Below the last row there is only one thing a drop can mean: the end of the list.
	[Test]
	public static void DroppingBelowTheLastRowAppends()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		let adapter = scope FlatReorderAdapter();
		view.SetAdapter(adapter);
		view.ItemHeight = 20.0f;

		let treeDrag = new TreeDragData(0);
		defer treeDrag.ReleaseRef();
		Test.Assert(view.AsDropTarget().OnDrop(treeDrag, 5.0f, 500.0f) == .Move);
		Test.Assert(adapter.LastTo == 3, "one past the last of three rows");
	}

	/// With dragging off, the view produces no payload, so nothing can start.
	[Test]
	public static void DisablingDraggingRefusesToProduceAPayload()
	{
		let view = new DraggableTreeView();
		defer view.ReleaseRef();

		let adapter = scope FlatReorderAdapter();
		view.SetAdapter(adapter);
		view.Selection.Select(0);

		view.DragEnabled = false;
		Test.Assert(view.AsDragSource().CreateDragData() == null);
	}
}
