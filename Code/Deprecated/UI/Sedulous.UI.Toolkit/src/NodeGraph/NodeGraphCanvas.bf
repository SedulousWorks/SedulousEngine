using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A pannable, zoomable graph of nodes and the edges between them.
///
/// DOMAIN AGNOSTIC. A node carries a handle the canvas never interprets, ports carry caller
/// defined type numbers, and connections are validated through a delegate the caller supplies.
/// So one canvas serves an animation state machine, an audio graph and a shader graph without
/// knowing what any of them mean.
///
/// Nodes are DATA, not views: a graph may hold hundreds and none of them needs its own layout,
/// styling or hit testing. The canvas draws and hit tests them all itself, and claims every
/// press, which is why it overrides hit testing to answer with itself.
///
/// Connections address their endpoints by INDEX, which is what makes removing a node an
/// operation on every edge in the graph: the ones touching it go, and the ones pointing past it
/// are renumbered.
class NodeGraphCanvas : View
{
	private const float MinZoom = 0.1f;
	private const float MaxZoom = 3.0f;
	private const float ZoomStep = 0.1f;

	private const float HeaderHeight = 26.0f;
	private const float PortRadius = 5.0f;
	private const float PortHitRadius = 10.0f;
	private const float PortSpacing = 22.0f;
	private const float PortMarginTop = 6.0f;
	private const float NodeMinWidth = 120.0f;
	private const float NodePadding = 10.0f;
	private const float ConnectionHitDistance = 8.0f;
	private const float GridSize = 20.0f;

	private enum InteractionMode
	{
		None,
		DraggingNode,
		DraggingConnection,
		BoxSelecting,
		Panning,
		/// A rubber edge follows the pointer from a source node until a click or Escape.
		PendingLink
	}

	private struct DragStart
	{
		public int32 Index = 0;
		public Float2 StartPos = .Zero;

		public this() {}

		public this(int32 index, Float2 startPos)
		{
			Index = index;
			StartPos = startPos;
		}
	}

	private struct PortHit
	{
		public int32 NodeIndex = -1;
		public int32 PortIndex = -1;
		public PortDirection Direction = .Input;

		public this() {}

		public bool IsValid => (NodeIndex >= 0) && (PortIndex >= 0);
	}

	// ---- Configuration --------------------------------------------------------------------------

	/// Visualise only: no editing of any kind.
	public bool ReadOnly = false;

	/// OWNED. Decides whether two ports may be joined. Null takes the default: the same type, or
	/// either of them untyped.
	public delegate bool(NodeGraphPortType, NodeGraphPortType) ConnectionValidator ~ delete _;

	public bool ShowGrid = true;
	/// Snap a node to the grid when its drag ENDS rather than while it moves, so the node
	/// follows the cursor smoothly and lands on the grid.
	public bool SnapToGrid = false;

	public ConnectionStyle EdgeStyle = .BezierPorts;

	// ---- Events ---------------------------------------------------------------------------------

	public Event<delegate void()> OnEditBegin ~ _.Dispose();
	public Event<delegate void()> OnEditEnd ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeMoved ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeDeleted ~ _.Dispose();
	public Event<delegate void(int32)> OnConnectionCreated ~ _.Dispose();
	public Event<delegate void(int32, int32, int32, int32)> OnConnectionRemoved ~ _.Dispose();

	/// Fired at the START of a removal, carrying the connection's INDEX while it is still valid.
	///
	/// It exists because OnConnectionRemoved carries only endpoints, and two parallel edges
	/// between the same pair of nodes share those. A caller keeping its own list alongside the
	/// connections cannot tell which one went without this.
	public Event<delegate void(int32)> OnConnectionDeleting ~ _.Dispose();

	public Event<delegate void()> OnSelectionChanged ~ _.Dispose();
	public Event<delegate void(float, float)> OnCanvasContextMenu ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeContextMenu ~ _.Dispose();
	public Event<delegate void(int32)> OnConnectionContextMenu ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeDoubleClicked ~ _.Dispose();

	/// A link gesture landed on a node, carrying the source and the target. The CALLER decides
	/// what linking means, which is usually adding both a transition and a connection.
	public Event<delegate void(int32, int32)> OnNodeLinkRequested ~ _.Dispose();

	// ---- State ----------------------------------------------------------------------------------

	/// OWNED.
	private List<NodeGraphNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<NodeGraphConnection> mConnections = new .() ~ delete _;
	/// Indices into the node list, BACK TO FRONT, so clicking a node can raise it without
	/// renumbering anything that refers to it.
	private List<int32> mDrawOrder = new .() ~ delete _;

	private Float2 mPanOffset = .Zero;
	private float mZoom = 1.0f;

	private InteractionMode mInteraction = .None;

	private List<DragStart> mDragStarts = new .() ~ delete _;
	private Float2 mDragStartMouse = .Zero;

	private int32 mDragSourceNode = -1;
	private int32 mDragSourcePort = -1;
	private PortDirection mDragSourceDirection = .Input;
	private Float2 mDragConnectionEnd = .Zero;

	private Float2 mBoxSelectStart = .Zero;
	private Float2 mBoxSelectEnd = .Zero;

	private Float2 mPanStartMouse = .Zero;
	private Float2 mPanStartOffset = .Zero;

	private int32 mHoveredNodeIndex = -1;
	private int32 mHoveredPortNode = -1;
	private int32 mHoveredPortIndex = -1;
	private PortDirection mHoveredPortDirection = .Input;
	private int32 mHoveredConnectionIndex = -1;
	private int32 mLinkSourceNode = -1;

	private bool mInGesture = false;

	public this()
	{
		IsFocusable = true;
	}

	public int32 NodeCount => (int32)mNodes.Count;

	public int32 ConnectionCount => (int32)mConnections.Count;

	public Float2 PanOffset => mPanOffset;

	public float Zoom => mZoom;

	// ---- Nodes ----------------------------------------------------------------------------------

	/// Appends a node and returns its index. CONSUMES the node.
	public int32 AddNode(NodeGraphNode node)
	{
		let index = (int32)mNodes.Count;
		mNodes.Add(node);
		mDrawOrder.Add(index);
		AutoSizeNode(node);
		Invalidate();
		return index;
	}

	/// BORROWED, or null.
	public NodeGraphNode GetNode(int32 index) =>
		((index >= 0) && (index < mNodes.Count)) ? mNodes[index] : null;

	/// Removes a node, along with every connection that touched it.
	///
	/// Everything holding an index past the removed one is RENUMBERED, which is the price of
	/// addressing nodes positionally and has to happen in one pass so no intermediate state is
	/// ever observed.
	public void RemoveNode(int32 index)
	{
		if ((index < 0) || (index >= mNodes.Count))
			return;

		OnNodeDeleted(index);

		for (int i = mConnections.Count - 1; i >= 0; i--)
		{
			if ((mConnections[i].SourceNodeIndex == index)
				|| (mConnections[i].DestNodeIndex == index))
				mConnections.RemoveAt(i);
		}

		for (int i = 0; i < mConnections.Count; i++)
		{
			if (mConnections[i].SourceNodeIndex > index)
				mConnections[i].SourceNodeIndex--;
			if (mConnections[i].DestNodeIndex > index)
				mConnections[i].DestNodeIndex--;
		}

		mDrawOrder.Remove(index);
		for (int i = 0; i < mDrawOrder.Count; i++)
		{
			if (mDrawOrder[i] > index)
				mDrawOrder[i]--;
		}

		delete mNodes[index];
		mNodes.RemoveAt(index);
		Invalidate();
	}

	// ---- Connections ----------------------------------------------------------------------------

	/// Appends a connection, or returns minus one when it does not validate.
	public int32 AddConnection(NodeGraphConnection connection)
	{
		if (!ValidateConnection(connection))
			return -1;

		let index = (int32)mConnections.Count;
		mConnections.Add(connection);
		Invalidate();
		return index;
	}

	public void RemoveConnection(int32 index)
	{
		if ((index < 0) || (index >= mConnections.Count))
			return;

		// The INDEX goes out first, while it still means something, and the endpoints after.
		OnConnectionDeleting(index);

		let connection = mConnections[index];
		OnConnectionRemoved(connection.SourceNodeIndex, connection.SourcePortIndex,
			connection.DestNodeIndex, connection.DestPortIndex);

		mConnections.RemoveAt(index);
		Invalidate();
	}

	public NodeGraphConnection GetConnection(int32 index) =>
		((index >= 0) && (index < mConnections.Count)) ? mConnections[index] : NodeGraphConnection();

	/// Whether a connection may exist.
	///
	/// The checks fall in order of how fundamental they are: never to itself, never to a node
	/// that is not there, then, in the port based mode only, real ports, no duplicate, and a
	/// type the caller accepts.
	///
	/// STRAIGHT edges are PORT LESS, so node bounds and no self edge are the whole contract.
	/// Parallel duplicates are legal there and drawn in offset lanes, because two transitions
	/// between the same pair of states are two different transitions.
	private bool ValidateConnection(NodeGraphConnection connection)
	{
		if (connection.SourceNodeIndex == connection.DestNodeIndex)
			return false;

		if ((connection.SourceNodeIndex < 0) || (connection.SourceNodeIndex >= mNodes.Count))
			return false;
		if ((connection.DestNodeIndex < 0) || (connection.DestNodeIndex >= mNodes.Count))
			return false;

		if (EdgeStyle == .StraightNodeToNode)
			return true;

		let source = mNodes[connection.SourceNodeIndex];
		let dest = mNodes[connection.DestNodeIndex];

		if ((connection.SourcePortIndex < 0)
			|| (connection.SourcePortIndex >= source.OutputPorts.Count))
			return false;
		if ((connection.DestPortIndex < 0) || (connection.DestPortIndex >= dest.InputPorts.Count))
			return false;

		if (IsDuplicate(connection))
			return false;

		let sourceType = source.OutputPorts[connection.SourcePortIndex].PortType;
		let destType = dest.InputPorts[connection.DestPortIndex].PortType;

		if (ConnectionValidator != null)
			return ConnectionValidator(sourceType, destType);

		// Untyped connects to ANYTHING, which is what makes a graph that never declared types
		// work with no validator at all.
		return (sourceType.TypeId == 0) || (destType.TypeId == 0)
			|| (sourceType.TypeId == destType.TypeId);
	}

	private bool IsDuplicate(NodeGraphConnection connection)
	{
		for (let existing in mConnections)
		{
			if ((existing.SourceNodeIndex == connection.SourceNodeIndex)
				&& (existing.SourcePortIndex == connection.SourcePortIndex)
				&& (existing.DestNodeIndex == connection.DestNodeIndex)
				&& (existing.DestPortIndex == connection.DestPortIndex))
				return true;
		}

		return false;
	}

	public void Clear()
	{
		mConnections.Clear();
		ClearAndDeleteItems!(mNodes);
		mDrawOrder.Clear();
		Invalidate();
	}

	// ---- Selection ------------------------------------------------------------------------------

	public void GetSelectedNodes(List<int32> outIndices)
	{
		for (int32 i = 0; i < mNodes.Count; i++)
		{
			if (mNodes[i].IsSelected)
				outIndices.Add(i);
		}
	}

	public void SelectNode(int32 index, bool addToSelection = false)
	{
		if (!addToSelection)
			ClearNodeSelectionSilently();

		if ((index >= 0) && (index < mNodes.Count))
			mNodes[index].IsSelected = true;

		OnSelectionChanged();
		Invalidate();
	}

	public void ClearSelection()
	{
		ClearNodeSelectionSilently();
		ClearConnectionSelectionSilently();
		OnSelectionChanged();
		Invalidate();
	}

	private void ClearNodeSelectionSilently()
	{
		for (let node in mNodes)
			node.IsSelected = false;
	}

	private void ClearConnectionSelectionSilently()
	{
		for (int i = 0; i < mConnections.Count; i++)
			mConnections[i].IsSelected = false;
	}

	// ---- Framing --------------------------------------------------------------------------------

	/// Pans so every node is in view. Does NOT change the zoom: a graph framed by zooming out
	/// far enough to fit an outlier becomes unreadable, and panning is recoverable.
	public void FrameAll()
	{
		if (mNodes.IsEmpty)
			return;

		var min = Float2(FloatMax, FloatMax);
		var max = Float2(-FloatMax, -FloatMax);

		for (let node in mNodes)
		{
			min.X = Min(min.X, node.Position.X);
			min.Y = Min(min.Y, node.Position.Y);
			max.X = Max(max.X, node.Position.X + node.Size.X);
			max.Y = Max(max.Y, node.Position.Y + node.Size.Y);
		}

		CenterOn((min + max) * 0.5f);
	}

	public void FrameNode(int32 index)
	{
		let node = GetNode(index);
		if (node == null)
			return;

		CenterOn(node.Position + (node.Size * 0.5f));
	}

	private void CenterOn(Float2 canvasPoint)
	{
		mPanOffset = Float2(Width * 0.5f, Height * 0.5f) - (canvasPoint * mZoom);
		Invalidate();
	}

	// ---- Coordinates ----------------------------------------------------------------------------

	public Float2 ScreenToCanvas(Float2 screen) =>
		.((screen.X - mPanOffset.X) / mZoom, (screen.Y - mPanOffset.Y) / mZoom);

	public Float2 CanvasToScreen(Float2 canvas) =>
		.((canvas.X * mZoom) + mPanOffset.X, (canvas.Y * mZoom) + mPanOffset.Y);

	/// The canvas claims EVERY press inside it, because it handles all of its own interaction
	/// and has no child views for a hit test to reach.
	public override View HitTest(Float2 localPoint)
	{
		if (!IsInteractionEnabled || (Visibility != .Visible))
			return null;

		if ((localPoint.X < 0) || (localPoint.Y < 0) || (localPoint.X >= Width)
			|| (localPoint.Y >= Height))
			return null;

		return this;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(400.0f), constraints.ConstrainHeight(300.0f));
	}

	/// Grows a node to fit its ports, never shrinking one the caller sized deliberately.
	///
	/// The taller SIDE decides: a node with one input and four outputs is four ports tall.
	private void AutoSizeNode(NodeGraphNode node)
	{
		let portCount = (int32)Max(node.InputPorts.Count, node.OutputPorts.Count);
		let needed = HeaderHeight + PortMarginTop + (portCount * PortSpacing) + 8.0f;

		node.Size.X = Max(node.Size.X, NodeMinWidth);
		node.Size.Y = Max(node.Size.Y, needed);
	}
}
