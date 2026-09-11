using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[NodeGraphCanvas]]: every gesture the canvas offers, and the hit tests they rest on.
extension NodeGraphCanvas
{
	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		// A pending link is resolved by the NEXT press, whatever it is, so the mode can never
		// outlive the gesture that started it.
		if (mInteraction == .PendingLink)
		{
			CompletePendingLink(e);
			return;
		}

		if (e.Button == .Middle)
		{
			BeginPan(e);
			return;
		}

		if (e.Button == .Right)
		{
			RaiseContextMenu(e);
			return;
		}

		if (e.Button != .Left)
			return;

		if (e.ClickCount >= 2)
		{
			let nodeHit = HitTestNode(e.X, e.Y);
			if (nodeHit >= 0)
			{
				OnNodeDoubleClicked(nodeHit);
				e.Handled = true;
				return;
			}
		}

		// A read only canvas still PANS, zooms and raises menus; it just edits nothing, so the
		// press is swallowed here rather than earlier.
		if (ReadOnly)
		{
			e.Handled = true;
			return;
		}

		if (TryBeginPortDrag(e))
			return;

		if (TryBeginNodeDrag(e))
			return;

		if (TrySelectConnection(e))
			return;

		BeginBoxSelect(e);
	}

	private void CompletePendingLink(MouseEventArgs e)
	{
		let source = mLinkSourceNode;
		let target = (e.Button == .Left) ? HitTestNode(e.X, e.Y) : -1;

		mInteraction = .None;
		mLinkSourceNode = -1;

		// A link to NOWHERE, to the source itself, or by any other button, simply cancels.
		if ((source >= 0) && (target >= 0) && (target != source))
			OnNodeLinkRequested(source, target);

		Invalidate();
		e.Handled = true;
	}

	private void BeginPan(MouseEventArgs e)
	{
		mInteraction = .Panning;
		mPanStartMouse = .(e.X, e.Y);
		mPanStartOffset = mPanOffset;
		Capture();
		e.Handled = true;
	}

	/// A node's menu, an edge's, or the canvas's, in that order of specificity.
	private void RaiseContextMenu(MouseEventArgs e)
	{
		let nodeHit = HitTestNode(e.X, e.Y);
		if (nodeHit >= 0)
		{
			OnNodeContextMenu(nodeHit);
		}
		else
		{
			let connectionHit = HitTestConnection(e.X, e.Y);
			if (connectionHit >= 0)
			{
				OnConnectionContextMenu(connectionHit);
			}
			else
			{
				let canvasPos = ScreenToCanvas(.(e.X, e.Y));
				OnCanvasContextMenu(canvasPos.X, canvasPos.Y);
			}
		}

		e.Handled = true;
	}

	/// Ports take priority over the node under them, since they sit on its edge.
	private bool TryBeginPortDrag(MouseEventArgs e)
	{
		let portHit = HitTestPort(e.X, e.Y);
		if (!portHit.IsValid)
			return false;

		// Grabbing an INPUT that is already connected DETACHES the existing edge and continues
		// the drag from its original output, which is how a connection is re-routed rather than
		// deleted and drawn again.
		if (portHit.Direction == .Input)
		{
			let existing = FindConnectionToInput(portHit.NodeIndex, portHit.PortIndex);
			if (existing >= 0)
			{
				let connection = mConnections[existing];
				BeginGesture();
				RemoveConnection(existing);
				BeginConnectionDrag(e, connection.SourceNodeIndex, connection.SourcePortIndex,
					.Output);
				return true;
			}
		}

		BeginConnectionDrag(e, portHit.NodeIndex, portHit.PortIndex, portHit.Direction);
		return true;
	}

	private void BeginConnectionDrag(MouseEventArgs e, int32 nodeIndex, int32 portIndex,
		PortDirection direction)
	{
		mInteraction = .DraggingConnection;
		mDragSourceNode = nodeIndex;
		mDragSourcePort = portIndex;
		mDragSourceDirection = direction;
		mDragConnectionEnd = .(e.X, e.Y);
		Capture();
		e.Handled = true;
	}

	private bool TryBeginNodeDrag(MouseEventArgs e)
	{
		let nodeHit = HitTestNode(e.X, e.Y);
		if (nodeHit < 0)
			return false;

		let node = mNodes[nodeHit];
		let additive = e.Modifiers.HasFlag(.Shift);

		if (additive)
		{
			node.IsSelected = !node.IsSelected;
		}
		else if (!node.IsSelected)
		{
			// A press on an ALREADY selected node leaves the set alone, so a multi node drag
			// survives being started from any member of it.
			ClearNodeSelectionSilently();
			ClearConnectionSelectionSilently();
			node.IsSelected = true;
		}

		OnSelectionChanged();
		BringToFront(nodeHit);

		if (node.IsMovable)
			BeginNodeDrag(e);

		e.Handled = true;
		return true;
	}

	/// Every selected MOVABLE node moves together, each from its own starting position, so the
	/// group keeps its shape however far the drag goes.
	private void BeginNodeDrag(MouseEventArgs e)
	{
		mInteraction = .DraggingNode;
		mDragStartMouse = ScreenToCanvas(.(e.X, e.Y));
		mDragStarts.Clear();

		for (int32 i = 0; i < mNodes.Count; i++)
		{
			if (mNodes[i].IsSelected && mNodes[i].IsMovable)
				mDragStarts.Add(.(i, mNodes[i].Position));
		}

		BeginGesture();
		Capture();
	}

	private bool TrySelectConnection(MouseEventArgs e)
	{
		let connectionHit = HitTestConnection(e.X, e.Y);
		if (connectionHit < 0)
			return false;

		ClearNodeSelectionSilently();
		ClearConnectionSelectionSilently();
		mConnections[connectionHit].IsSelected = true;
		OnSelectionChanged();
		e.Handled = true;
		Invalidate();
		return true;
	}

	private void BeginBoxSelect(MouseEventArgs e)
	{
		if (!e.Modifiers.HasFlag(.Shift))
		{
			ClearNodeSelectionSilently();
			ClearConnectionSelectionSilently();
		}

		let canvasPos = ScreenToCanvas(.(e.X, e.Y));
		mInteraction = .BoxSelecting;
		mBoxSelectStart = canvasPos;
		mBoxSelectEnd = canvasPos;
		Capture();
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		switch (mInteraction)
		{
		case .PendingLink:
			mDragConnectionEnd = .(e.X, e.Y);
			Invalidate();
			e.Handled = true;

		case .Panning:
			mPanOffset = .(mPanStartOffset.X + (e.X - mPanStartMouse.X),
				mPanStartOffset.Y + (e.Y - mPanStartMouse.Y));
			Invalidate();
			e.Handled = true;

		case .DraggingNode:
			// Measured in CANVAS space from where the drag began, so the nodes keep pace with
			// the cursor at any zoom and nothing accumulates.
			let delta = ScreenToCanvas(.(e.X, e.Y)) - mDragStartMouse;
			for (let start in mDragStarts)
				mNodes[start.Index].Position = start.StartPos + delta;
			Invalidate();
			e.Handled = true;

		case .DraggingConnection:
			mDragConnectionEnd = .(e.X, e.Y);
			// The hovered port is tracked during the drag so the target lights up before the
			// release commits to it.
			UpdatePortHover(e.X, e.Y);
			Invalidate();
			e.Handled = true;

		case .BoxSelecting:
			mBoxSelectEnd = ScreenToCanvas(.(e.X, e.Y));
			Invalidate();
			e.Handled = true;

		case .None:
			UpdateHover(e.X, e.Y);
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		switch (mInteraction)
		{
		case .PendingLink:
			// Resolved on the press; the release is inert, so a click does not both aim and
			// fire the link.

		case .Panning:
			EndInteraction(e);

		case .DraggingNode:
			FinishNodeDrag(e);

		case .DraggingConnection:
			FinishConnectionDrag(e);

		case .BoxSelecting:
			FinishBoxSelect(e);

		case .None:
		}
	}

	/// Snapped on RELEASE rather than during the drag, so the node follows the cursor smoothly
	/// and lands on the grid.
	private void FinishNodeDrag(MouseEventArgs e)
	{
		if (SnapToGrid)
		{
			for (let start in mDragStarts)
			{
				let node = mNodes[start.Index];
				node.Position.X = Round(node.Position.X / GridSize) * GridSize;
				node.Position.Y = Round(node.Position.Y / GridSize) * GridSize;
			}
		}

		for (let start in mDragStarts)
			OnNodeMoved(start.Index);

		EndGesture();
		EndInteraction(e);
		Invalidate();
	}

	private void FinishConnectionDrag(MouseEventArgs e)
	{
		let portHit = HitTestPort(e.X, e.Y);

		// An OPPOSITE direction is required: an output never joins an output.
		if (portHit.IsValid && (portHit.Direction != mDragSourceDirection))
		{
			let fromOutput = mDragSourceDirection == .Output;
			let connection = NodeGraphConnection(
				fromOutput ? mDragSourceNode : portHit.NodeIndex,
				fromOutput ? mDragSourcePort : portHit.PortIndex,
				fromOutput ? portHit.NodeIndex : mDragSourceNode,
				fromOutput ? portHit.PortIndex : mDragSourcePort);

			// Already open when this drag began as a re-route; opening it again is harmless and
			// keeps the detach and the reconnect inside ONE undo step.
			BeginGesture();
			let index = AddConnection(connection);
			if (index >= 0)
				OnConnectionCreated(index);
		}

		EndGesture();
		mDragSourceNode = -1;
		EndInteraction(e);
		Invalidate();
	}

	/// Every node OVERLAPPING the box is taken, not only those wholly inside: a selection
	/// rectangle that demanded full containment would miss anything larger than itself.
	private void FinishBoxSelect(MouseEventArgs e)
	{
		let minX = Min(mBoxSelectStart.X, mBoxSelectEnd.X);
		let minY = Min(mBoxSelectStart.Y, mBoxSelectEnd.Y);
		let maxX = Max(mBoxSelectStart.X, mBoxSelectEnd.X);
		let maxY = Max(mBoxSelectStart.Y, mBoxSelectEnd.Y);

		for (let node in mNodes)
		{
			if ((node.Position.X + node.Size.X > minX) && (node.Position.X < maxX)
				&& (node.Position.Y + node.Size.Y > minY) && (node.Position.Y < maxY))
				node.IsSelected = true;
		}

		OnSelectionChanged();
		EndInteraction(e);
		Invalidate();
	}

	private void EndInteraction(MouseEventArgs e)
	{
		mInteraction = .None;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();

		e.Handled = true;
	}

	/// Zooms TOWARD the cursor: the canvas point under the pointer stays under it, so zooming
	/// moves toward what is being looked at rather than toward the origin.
	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		let oldZoom = mZoom;
		mZoom = Clamp(mZoom + (e.DeltaY * ZoomStep), MinZoom, MaxZoom);

		if (mZoom != oldZoom)
		{
			let mouse = Float2(e.X, e.Y);
			mPanOffset = mouse - ((mouse - mPanOffset) * (mZoom / oldZoom));
			Invalidate();
		}

		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (ReadOnly)
			return;

		if ((e.Key == .Escape) && (mInteraction == .PendingLink))
		{
			mInteraction = .None;
			mLinkSourceNode = -1;
			Invalidate();
			e.Handled = true;
			return;
		}

		if (e.Key == .Delete)
		{
			DeleteSelected();
			e.Handled = true;
			return;
		}

		if ((e.Key == .A) && e.Modifiers.HasFlag(.Ctrl))
		{
			for (let node in mNodes)
				node.IsSelected = true;

			OnSelectionChanged();
			Invalidate();
			e.Handled = true;
		}
	}

	/// Enters link mode: a rubber edge follows the pointer until a click lands on a node or
	/// Escape cancels. The gesture port-less state machine nodes are connected by.
	public void StartLinkFrom(int32 nodeIndex)
	{
		if (ReadOnly || (nodeIndex < 0) || (nodeIndex >= mNodes.Count))
			return;

		mInteraction = .PendingLink;
		mLinkSourceNode = nodeIndex;
		// Aimed at the source itself until the pointer first moves, so the rubber edge has
		// somewhere to be on the frame it appears.
		mDragConnectionEnd = NodeCenterScreen(nodeIndex);
		Invalidate();
	}

	/// Removes every selected connection and then every selected node.
	///
	/// CONNECTIONS FIRST, because removing a node renumbers the edges and a selected edge's
	/// index would no longer mean what it did.
	private void DeleteSelected()
	{
		BeginGesture();

		for (int i = mConnections.Count - 1; i >= 0; i--)
		{
			if (mConnections[i].IsSelected)
				RemoveConnection((int32)i);
		}

		for (int i = mNodes.Count - 1; i >= 0; i--)
		{
			if (mNodes[i].IsSelected && mNodes[i].IsDeletable)
				RemoveNode((int32)i);
		}

		EndGesture();
		OnSelectionChanged();
		Invalidate();
	}

	// ---- Helpers --------------------------------------------------------------------------------

	private void Capture()
	{
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
	}

	private void BeginGesture()
	{
		if (mInGesture)
			return;

		mInGesture = true;
		OnEditBegin();
	}

	private void EndGesture()
	{
		if (!mInGesture)
			return;

		mInGesture = false;
		OnEditEnd();
	}

	/// Raises a node to the end of the draw order, which is the FRONT. The order holds indices
	/// rather than nodes, so raising one renumbers nothing.
	private void BringToFront(int32 nodeIndex)
	{
		mDrawOrder.Remove(nodeIndex);
		mDrawOrder.Add(nodeIndex);
	}

	private int32 FindConnectionToInput(int32 nodeIndex, int32 portIndex)
	{
		for (int32 i = 0; i < mConnections.Count; i++)
		{
			if ((mConnections[i].DestNodeIndex == nodeIndex)
				&& (mConnections[i].DestPortIndex == portIndex))
				return i;
		}

		return -1;
	}
}
