namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Model-agnostic interactive node graph canvas. Renders nodes with typed
/// ports and bezier connections. Supports pan/zoom, selection, node dragging,
/// drag-to-connect, and context menus.
///
/// Follows the CurveCanvas pattern: the widget owns rendering and input;
/// callers push node/connection data in and listen to events.
public class NodeGraphCanvas : View
{
	// ========== Data ==========

	private List<NodeGraphNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<NodeGraphConnection> mConnections = new .() ~ delete _;
	private List<int32> mDrawOrder = new .() ~ delete _; // indices into mNodes, back-to-front

	// ========== Pan / Zoom ==========

	private Vector2 mPanOffset;
	private float mZoom = 1.0f;

	private const float MinZoom = 0.1f;
	private const float MaxZoom = 3.0f;
	private const float ZoomStep = 0.1f;

	// ========== Interaction state ==========

	private enum InteractionMode { None, DraggingNode, DraggingConnection, BoxSelecting, Panning }
	private InteractionMode mInteraction = .None;

	// Node dragging
	private List<(int32 idx, Vector2 startPos)> mDragStarts = new .() ~ delete _;
	private Vector2 mDragStartMouse;

	// Connection dragging
	private int32 mDragSourceNode = -1;
	private int32 mDragSourcePort = -1;
	private PortDirection mDragSourceDirection;
	private Vector2 mDragConnectionEnd;

	// Box selection
	private Vector2 mBoxSelectStart;
	private Vector2 mBoxSelectEnd;

	// Panning
	private Vector2 mPanStartMouse;
	private Vector2 mPanStartOffset;

	// Hover tracking
	private int32 mHoveredNodeIndex = -1;
	private int32 mHoveredPortNode = -1;
	private int32 mHoveredPortIndex = -1;
	private PortDirection mHoveredPortDir;
	private int32 mHoveredConnectionIndex = -1;

	// Gesture tracking (undo grouping)
	private bool mInGesture;

	// ========== Layout constants ==========

	private const float HeaderHeight = 26;
	private const float PortRadius = 5;
	private const float PortHitRadius = 10;
	private const float PortSpacing = 22;
	private const float PortMarginTop = 6;
	private const float NodeMinWidth = 120;
	private const float NodePadding = 10;
	private const float ConnectionHitDist = 8;
	private const float GridSize = 20;

	// ========== Configuration ==========

	/// Whether the graph is read-only (no editing, only visualization).
	public bool ReadOnly = false;

	/// Connection validation delegate. Default: same TypeId or either untyped.
	public delegate bool(NodeGraphPortType source, NodeGraphPortType dest) ConnectionValidator ~ delete _;

	/// Whether to draw a background grid.
	public bool ShowGrid = true;

	/// Whether to snap node positions to the grid on drag end.
	public bool SnapToGrid = false;

	// ========== Events ==========

	public Event<delegate void()> OnEditBegin ~ _.Dispose();
	public Event<delegate void()> OnEditEnd ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeMoved ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeDeleted ~ _.Dispose();
	public Event<delegate void(int32)> OnConnectionCreated ~ _.Dispose();
	public Event<delegate void(int32, int32, int32, int32)> OnConnectionRemoved ~ _.Dispose();
	public Event<delegate void()> OnSelectionChanged ~ _.Dispose();
	public Event<delegate void(float, float)> OnCanvasContextMenu ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeContextMenu ~ _.Dispose();
	public Event<delegate void(int32)> OnConnectionContextMenu ~ _.Dispose();
	public Event<delegate void(int32)> OnNodeDoubleClicked ~ _.Dispose();

	// ========== Constructor ==========

	public this()
	{
		IsFocusable = true;
	}

	// ========== Public API ==========

	public int32 NodeCount => (int32)mNodes.Count;
	public int32 ConnectionCount => (int32)mConnections.Count;
	public Vector2 PanOffset => mPanOffset;
	public float Zoom => mZoom;

	/// Adds a node and returns its index.
	public int32 AddNode(NodeGraphNode node)
	{
		let idx = (int32)mNodes.Count;
		mNodes.Add(node);
		mDrawOrder.Add(idx);
		AutoSizeNode(node);
		Invalidate();
		return idx;
	}

	/// Removes a node by index. Also removes all connections to/from it.
	public void RemoveNode(int32 index)
	{
		if (index < 0 || index >= mNodes.Count) return;

		OnNodeDeleted(index);

		// Remove connections referencing this node
		for (int i = mConnections.Count - 1; i >= 0; i--)
		{
			let c = mConnections[i];
			if (c.SourceNodeIndex == index || c.DestNodeIndex == index)
				mConnections.RemoveAt(i);
		}

		// Remap connection indices above the removed node
		for (int i = 0; i < mConnections.Count; i++)
		{
			var c = ref mConnections[i];
			if (c.SourceNodeIndex > index) c.SourceNodeIndex--;
			if (c.DestNodeIndex > index) c.DestNodeIndex--;
		}

		// Remove from draw order and remap
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

	public NodeGraphNode GetNode(int32 index)
	{
		if (index >= 0 && index < mNodes.Count) return mNodes[index];
		return null;
	}

	/// Adds a connection. Returns its index, or -1 if validation fails.
	public int32 AddConnection(NodeGraphConnection conn)
	{
		if (!ValidateConnection(conn)) return -1;
		let idx = (int32)mConnections.Count;
		mConnections.Add(conn);
		Invalidate();
		return idx;
	}

	public void RemoveConnection(int32 index)
	{
		if (index < 0 || index >= mConnections.Count) return;
		let c = mConnections[index];
		OnConnectionRemoved(c.SourceNodeIndex, c.SourcePortIndex, c.DestNodeIndex, c.DestPortIndex);
		mConnections.RemoveAt(index);
		Invalidate();
	}

	public NodeGraphConnection GetConnection(int32 index)
	{
		if (index >= 0 && index < mConnections.Count) return mConnections[index];
		return default;
	}

	public void Clear()
	{
		mConnections.Clear();
		//mConnections = new .();
		DeleteContainerAndItems!(mNodes);
		mNodes = new .();
		mDrawOrder.Clear();
		Invalidate();
	}

	public void GetSelectedNodes(List<int32> outIndices)
	{
		for (int32 i = 0; i < mNodes.Count; i++)
			if (mNodes[i].IsSelected) outIndices.Add(i);
	}

	public void SelectNode(int32 index, bool addToSelection = false)
	{
		if (!addToSelection)
			ClearSelectionSilent();
		if (index >= 0 && index < mNodes.Count)
			mNodes[index].IsSelected = true;
		OnSelectionChanged();
		Invalidate();
	}

	public void ClearSelection()
	{
		ClearSelectionSilent();
		ClearConnectionSelection();
		OnSelectionChanged();
		Invalidate();
	}

	/// Pans to center all nodes in view.
	public void FrameAll()
	{
		if (mNodes.Count == 0) return;
		var minP = Vector2(float.MaxValue, float.MaxValue);
		var maxP = Vector2(float.MinValue, float.MinValue);
		for (let node in mNodes)
		{
			minP.X = Math.Min(minP.X, node.Position.X);
			minP.Y = Math.Min(minP.Y, node.Position.Y);
			maxP.X = Math.Max(maxP.X, node.Position.X + node.Size.X);
			maxP.Y = Math.Max(maxP.Y, node.Position.Y + node.Size.Y);
		}
		let center = (minP + maxP) * 0.5f;
		let viewCenter = Vector2(Width * 0.5f, Height * 0.5f);
		mPanOffset = viewCenter - center * mZoom;
		Invalidate();
	}

	public void FrameNode(int32 index)
	{
		if (index < 0 || index >= mNodes.Count) return;
		let node = mNodes[index];
		let center = node.Position + node.Size * 0.5f;
		let viewCenter = Vector2(Width * 0.5f, Height * 0.5f);
		mPanOffset = viewCenter - center * mZoom;
		Invalidate();
	}

	// ========== Coordinate transforms ==========

	public Vector2 ScreenToCanvas(Vector2 screen)
	{
		return .((screen.X - mPanOffset.X) / mZoom, (screen.Y - mPanOffset.Y) / mZoom);
	}

	public Vector2 CanvasToScreen(Vector2 canvas)
	{
		return .(canvas.X * mZoom + mPanOffset.X, canvas.Y * mZoom + mPanOffset.Y);
	}

	// ========== Measure ==========

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(400), constraints.ConstrainHeight(300));
	}

	// ========== Hit testing ==========

	public override View HitTest(Vector2 localPoint)
	{
		if (!IsInteractionEnabled || Visibility != .Visible) return null;
		if (localPoint.X < 0 || localPoint.Y < 0 || localPoint.X >= Width || localPoint.Y >= Height)
			return null;
		return this; // Canvas handles all input internally
	}

	// ========== Drawing ==========

	public override void OnDraw(UIDrawContext ctx)
	{
		// Background
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, .(0, 0, Width, Height));
		else
			ctx.VG.FillRect(.(0, 0, Width, Height), .(28, 28, 33, 255));

		ctx.VG.PushClipRect(.(0, 0, Width, Height));

		// Grid
		if (ShowGrid)
			DrawGrid(ctx);

		// Connections
		for (int i = 0; i < mConnections.Count; i++)
			DrawConnection(ctx, mConnections[i], i == mHoveredConnectionIndex);

		// Box selection
		if (mInteraction == .BoxSelecting)
		{
			let accentColor = ResolveStyleColor(.AccentColor, .(80, 140, 220, 255));
			let s1 = CanvasToScreen(mBoxSelectStart);
			let s2 = CanvasToScreen(mBoxSelectEnd);
			let rect = RectangleF(
				Math.Min(s1.X, s2.X), Math.Min(s1.Y, s2.Y),
				Math.Abs(s2.X - s1.X), Math.Abs(s2.Y - s1.Y));
			ctx.VG.FillRect(rect, Color32(accentColor.R, accentColor.G, accentColor.B, 40));
			ctx.VG.StrokeRect(rect, Color32(accentColor.R, accentColor.G, accentColor.B, 150), 1);
		}

		// Nodes (in draw order)
		for (let drawIdx in mDrawOrder)
			DrawNode(ctx, drawIdx);

		// Connection being dragged
		if (mInteraction == .DraggingConnection && mDragSourceNode >= 0)
		{
			let srcPort = GetPortScreenPos(mDragSourceNode, mDragSourcePort, mDragSourceDirection);
			let endPos = mDragConnectionEnd;
			let isOutput = (mDragSourceDirection == .Output);
			let dragColor = ResolveStyleColor(.TextDimColor, .(180, 200, 220, 180));
			DrawBezier(ctx, isOutput ? srcPort : endPos, isOutput ? endPos : srcPort, dragColor);
		}

		// Hovered port highlight
		if (mHoveredPortNode >= 0 && mInteraction == .None)
		{
			let pos = GetPortScreenPos(mHoveredPortNode, mHoveredPortIndex, mHoveredPortDir);
			ctx.VG.FillCircle(pos, PortRadius * mZoom + 3, .(255, 255, 255, 60));
		}

		ctx.VG.PopClip();
	}

	private void DrawGrid(UIDrawContext ctx)
	{
		let gridStep = GridSize * mZoom;
		if (gridStep < 4) return; // Too zoomed out

		let borderColor = ResolveStyleColor(.BorderColor, .(55, 55, 60, 255));
		let gridColor = Color32((uint8)(borderColor.R * 0.7f), (uint8)(borderColor.G * 0.7f), (uint8)(borderColor.B * 0.7f), borderColor.A);
		let startX = mPanOffset.X % gridStep;
		let startY = mPanOffset.Y % gridStep;

		let majorStep = gridStep * 5;
		let majorStartX = mPanOffset.X % majorStep;
		let majorStartY = mPanOffset.Y % majorStep;

		// Minor grid
		var x = startX;
		while (x < Width) { ctx.VG.DrawLine(.(x, 0), .(x, Height), gridColor, 1); x += gridStep; }
		var y = startY;
		while (y < Height) { ctx.VG.DrawLine(.(0, y), .(Width, y), gridColor, 1); y += gridStep; }

		// Major grid
		if (majorStep >= 20)
		{
			x = majorStartX;
			while (x < Width) { ctx.VG.DrawLine(.(x, 0), .(x, Height), borderColor, 1); x += majorStep; }
			y = majorStartY;
			while (y < Height) { ctx.VG.DrawLine(.(0, y), .(Width, y), borderColor, 1); y += majorStep; }
		}
	}

	private void DrawNode(UIDrawContext ctx, int32 nodeIdx)
	{
		let node = mNodes[nodeIdx];
		let pos = CanvasToScreen(node.Position);
		let size = node.Size * mZoom;
		let headerH = HeaderHeight * mZoom;
		let cornerR = ResolveStyleFloat(.CornerRadius, 4) * mZoom;

		// Body
		let contentDrawable = ResolvePartDrawable("node-body", .Background, .Normal);
		if (contentDrawable != null)
			contentDrawable.Draw(ctx, .(pos.X, pos.Y, size.X, size.Y));
		else
			ctx.VG.FillRoundedRect(.(pos.X, pos.Y, size.X, size.Y), cornerR, .(38, 40, 48, 255));

		// Header (uses node's HeaderColor - caller controls this per node)
		ctx.VG.FillRoundedRect(.(pos.X, pos.Y, size.X, headerH), cornerR, node.HeaderColor);
		// Square off bottom corners of header
		ctx.VG.FillRect(.(pos.X, pos.Y + headerH - cornerR, size.X, cornerR), node.HeaderColor);

		// Selection highlight
		if (node.IsSelected)
		{
			let accentColor = ResolveStyleColor(.AccentColor, .(100, 180, 255, 200));
			ctx.VG.StrokeRoundedRect(.(pos.X, pos.Y, size.X, size.Y), cornerR, accentColor, 2);
		}

		// Title text
		if (ctx.FontService != null)
		{
			let textColor = ResolveStyleColor(.TextColor, .(255, 255, 255, 230));
			let titleFont = ctx.FontService.GetFont(11);
			if (titleFont != null)
				ctx.VG.DrawText(node.Title, titleFont, .(pos.X + 8 * mZoom, pos.Y, size.X - 16 * mZoom, headerH), .Left, .Middle, textColor);

			// Subtitle
			if (node.Subtitle.Length > 0)
			{
				let dimColor = ResolveStyleColor(.TextDimColor, .(180, 180, 190, 180));
				let subFont = ctx.FontService.GetFont(10);
				if (subFont != null)
					ctx.VG.DrawText(node.Subtitle, subFont, .(pos.X + 8 * mZoom, pos.Y + headerH, size.X - 16 * mZoom, 16 * mZoom), .Left, .Middle, dimColor);
			}

			// Ports
			let portFont = ctx.FontService.GetFont(10);
			DrawPorts(ctx, nodeIdx, node.InputPorts, .Input, pos, size, portFont);
			DrawPorts(ctx, nodeIdx, node.OutputPorts, .Output, pos, size, portFont);
		}
	}

	private void DrawPorts(UIDrawContext ctx, int32 nodeIdx, List<NodeGraphPort> ports, PortDirection dir,
		Vector2 nodeScreenPos, Vector2 nodeScreenSize, CachedFont portFont)
	{
		let portLabelColor = ResolveStyleColor(.TextDimColor, .(200, 200, 210, 200));

		for (int32 i = 0; i < ports.Count; i++)
		{
			let port = ports[i];
			let portPos = GetPortScreenPos(nodeIdx, i, dir);
			let r = PortRadius * mZoom;

			// Port circle (colored by port type - not themed, since callers define type colors)
			ctx.VG.FillCircle(portPos, r, port.PortType.Color);
			ctx.VG.StrokeCircle(portPos, r, .(0, 0, 0, 100), 1);

			// Port label
			if (portFont != null && port.Label.Length > 0)
			{
				let labelW = 80 * mZoom;
				if (dir == .Input)
				{
					let labelX = portPos.X + r + 4 * mZoom;
					ctx.VG.DrawText(port.Label, portFont, .(labelX, portPos.Y - 8 * mZoom, labelW, 16 * mZoom), .Left, .Middle, portLabelColor);
				}
				else
				{
					let labelX = portPos.X - r - 4 * mZoom - labelW;
					ctx.VG.DrawText(port.Label, portFont, .(labelX, portPos.Y - 8 * mZoom, labelW, 16 * mZoom), .Right, .Middle, portLabelColor);
				}
			}
		}
	}

	private void DrawConnection(UIDrawContext ctx, NodeGraphConnection conn, bool hovered)
	{
		if (conn.SourceNodeIndex < 0 || conn.SourceNodeIndex >= mNodes.Count) return;
		if (conn.DestNodeIndex < 0 || conn.DestNodeIndex >= mNodes.Count) return;

		let startPos = GetPortScreenPos(conn.SourceNodeIndex, conn.SourcePortIndex, .Output);
		let endPos = GetPortScreenPos(conn.DestNodeIndex, conn.DestPortIndex, .Input);

		// Color from source port type (port types are caller-defined, not themed)
		var color = NodeGraphPortType.Untyped.Color;
		let srcNode = mNodes[conn.SourceNodeIndex];
		if (conn.SourcePortIndex >= 0 && conn.SourcePortIndex < srcNode.OutputPorts.Count)
			color = srcNode.OutputPorts[conn.SourcePortIndex].PortType.Color;

		if (conn.IsSelected)
			color = ResolveStyleColor(.AccentColor, .(100, 180, 255, 230));
		else if (hovered)
			color = Color32(Math.Min((uint8)255, color.R + 40), Math.Min((uint8)255, color.G + 40), Math.Min((uint8)255, color.B + 40), 230);

		DrawBezier(ctx, startPos, endPos, color);
	}

	private void DrawBezier(UIDrawContext ctx, Vector2 start, Vector2 end, Color32 color)
	{
		let dx = Math.Abs(end.X - start.X);
		let ctrlDist = Math.Max(dx * 0.5f, 50 * mZoom);

		ctx.VG.BeginPath();
		ctx.VG.MoveTo(start);
		ctx.VG.CubicTo(
			Vector2(start.X + ctrlDist, start.Y),
			Vector2(end.X - ctrlDist, end.Y),
			end);
		ctx.VG.Stroke(color, 2);
	}

	// ========== Port position helpers ==========

	private Vector2 GetPortScreenPos(int32 nodeIdx, int32 portIdx, PortDirection dir)
	{
		let node = mNodes[nodeIdx];
		let canvasX = (dir == .Input) ? node.Position.X : node.Position.X + node.Size.X;
		let canvasY = node.Position.Y + HeaderHeight + PortMarginTop + portIdx * PortSpacing + PortSpacing * 0.5f;
		return CanvasToScreen(.(canvasX, canvasY));
	}

	private Vector2 GetPortCanvasPos(int32 nodeIdx, int32 portIdx, PortDirection dir)
	{
		let node = mNodes[nodeIdx];
		let x = (dir == .Input) ? node.Position.X : node.Position.X + node.Size.X;
		let y = node.Position.Y + HeaderHeight + PortMarginTop + portIdx * PortSpacing + PortSpacing * 0.5f;
		return .(x, y);
	}

	// ========== Input ==========

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		let canvasPos = ScreenToCanvas(.(e.X, e.Y));

		// Middle button: pan
		if (e.Button == .Middle)
		{
			mInteraction = .Panning;
			mPanStartMouse = .(e.X, e.Y);
			mPanStartOffset = mPanOffset;
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
			return;
		}

		if (e.Button == .Right)
		{
			// Context menus
			let nodeHit = HitTestNode(e.X, e.Y);
			let connHit = HitTestConnection(e.X, e.Y);

			if (nodeHit >= 0)
				OnNodeContextMenu(nodeHit);
			else if (connHit >= 0)
				OnConnectionContextMenu(connHit);
			else
				OnCanvasContextMenu(canvasPos.X, canvasPos.Y);

			e.Handled = true;
			return;
		}

		if (e.Button != .Left) return;

		// Double click
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

		if (ReadOnly) { e.Handled = true; return; }

		// Port hit - start connection drag
		let portHit = HitTestPort(e.X, e.Y);
		if (portHit.nodeIdx >= 0)
		{
			// If dragging from an input port that already has a connection,
			// detach the existing connection and drag from the original source
			// output port instead - allows re-routing.
			if (portHit.dir == .Input)
			{
				let existingIdx = FindConnectionToInput(portHit.nodeIdx, portHit.portIdx);
				if (existingIdx >= 0)
				{
					let existing = mConnections[existingIdx];
					let srcNode = existing.SourceNodeIndex;
					let srcPort = existing.SourcePortIndex;

					BeginGesture();
					RemoveConnection(existingIdx);

					mInteraction = .DraggingConnection;
					mDragSourceNode = srcNode;
					mDragSourcePort = srcPort;
					mDragSourceDirection = .Output;
					mDragConnectionEnd = .(e.X, e.Y);
					Context?.FocusManager.SetCapture(this);
					e.Handled = true;
					return;
				}
			}

			mInteraction = .DraggingConnection;
			mDragSourceNode = portHit.nodeIdx;
			mDragSourcePort = portHit.portIdx;
			mDragSourceDirection = portHit.dir;
			mDragConnectionEnd = .(e.X, e.Y);
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
			return;
		}

		// Node hit - select and start drag
		let nodeHit = HitTestNode(e.X, e.Y);
		if (nodeHit >= 0)
		{
			let node = mNodes[nodeHit];
			let shift = e.Modifiers.HasFlag(.Shift);

			if (shift)
			{
				node.IsSelected = !node.IsSelected;
			}
			else if (!node.IsSelected)
			{
				ClearSelectionSilent();
				ClearConnectionSelection();
				node.IsSelected = true;
			}
			OnSelectionChanged();

			// Bring to front in draw order
			BringToFront(nodeHit);

			// Start drag if the clicked node is movable
			if (node.IsMovable)
			{
				mInteraction = .DraggingNode;
				mDragStartMouse = canvasPos;
				mDragStarts.Clear();
				for (int32 i = 0; i < mNodes.Count; i++)
				{
					if (mNodes[i].IsSelected && mNodes[i].IsMovable)
						mDragStarts.Add((i, mNodes[i].Position));
				}
				BeginGesture();
				Context?.FocusManager.SetCapture(this);
			}

			e.Handled = true;
			return;
		}

		// Connection hit - select
		let connHit = HitTestConnection(e.X, e.Y);
		if (connHit >= 0)
		{
			ClearSelectionSilent();
			ClearConnectionSelection();
			mConnections[connHit].IsSelected = true;
			OnSelectionChanged();
			e.Handled = true;
			Invalidate();
			return;
		}

		// Empty space - start box selection
		if (!e.Modifiers.HasFlag(.Shift))
		{
			ClearSelectionSilent();
			ClearConnectionSelection();
		}
		mInteraction = .BoxSelecting;
		mBoxSelectStart = canvasPos;
		mBoxSelectEnd = canvasPos;
		Context?.FocusManager.SetCapture(this);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let canvasPos = ScreenToCanvas(.(e.X, e.Y));

		switch (mInteraction)
		{
		case .Panning:
			let dx = e.X - mPanStartMouse.X;
			let dy = e.Y - mPanStartMouse.Y;
			mPanOffset = .(mPanStartOffset.X + dx, mPanStartOffset.Y + dy);
			Invalidate();
			e.Handled = true;

		case .DraggingNode:
			let delta = canvasPos - mDragStartMouse;
			for (let entry in mDragStarts)
				mNodes[entry.idx].Position = entry.startPos + delta;
			Invalidate();
			e.Handled = true;

		case .DraggingConnection:
			mDragConnectionEnd = .(e.X, e.Y);
			// Update hover for drop target feedback
			UpdatePortHover(e.X, e.Y);
			Invalidate();
			e.Handled = true;

		case .BoxSelecting:
			mBoxSelectEnd = canvasPos;
			Invalidate();
			e.Handled = true;

		case .None:
			// Update hover state
			UpdateHover(e.X, e.Y);
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		switch (mInteraction)
		{
		case .Panning:
			mInteraction = .None;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;

		case .DraggingNode:
			// Snap to grid if enabled
			if (SnapToGrid)
			{
				for (let entry in mDragStarts)
				{
					var pos = ref mNodes[entry.idx].Position;
					pos.X = Math.Round(pos.X / GridSize) * GridSize;
					pos.Y = Math.Round(pos.Y / GridSize) * GridSize;
				}
			}
			for (let entry in mDragStarts)
				OnNodeMoved(entry.idx);
			EndGesture();
			mInteraction = .None;
			Context?.FocusManager.ReleaseCapture();
			Invalidate();
			e.Handled = true;

		case .DraggingConnection:
			// Try to connect
			let portHit = HitTestPort(e.X, e.Y);
			if (portHit.nodeIdx >= 0 && portHit.dir != mDragSourceDirection)
			{
				NodeGraphConnection conn = .();
				if (mDragSourceDirection == .Output)
				{
					conn.SourceNodeIndex = mDragSourceNode;
					conn.SourcePortIndex = mDragSourcePort;
					conn.DestNodeIndex = portHit.nodeIdx;
					conn.DestPortIndex = portHit.portIdx;
				}
				else
				{
					conn.SourceNodeIndex = portHit.nodeIdx;
					conn.SourcePortIndex = portHit.portIdx;
					conn.DestNodeIndex = mDragSourceNode;
					conn.DestPortIndex = mDragSourcePort;
				}

				// BeginGesture may already be active (detach-and-reroute case)
				BeginGesture();
				let idx = AddConnection(conn);
				if (idx >= 0)
					OnConnectionCreated(idx);
			}
			// End gesture (covers both fresh connect and detach-reroute)
			EndGesture();
			mDragSourceNode = -1;
			mInteraction = .None;
			Context?.FocusManager.ReleaseCapture();
			Invalidate();
			e.Handled = true;

		case .BoxSelecting:
			// Select nodes in box
			let minX = Math.Min(mBoxSelectStart.X, mBoxSelectEnd.X);
			let minY = Math.Min(mBoxSelectStart.Y, mBoxSelectEnd.Y);
			let maxX = Math.Max(mBoxSelectStart.X, mBoxSelectEnd.X);
			let maxY = Math.Max(mBoxSelectStart.Y, mBoxSelectEnd.Y);

			for (int32 i = 0; i < mNodes.Count; i++)
			{
				let node = mNodes[i];
				let nr = node.Position;
				let ns = node.Size;
				// Check overlap
				if (nr.X + ns.X > minX && nr.X < maxX && nr.Y + ns.Y > minY && nr.Y < maxY)
					node.IsSelected = true;
			}
			OnSelectionChanged();
			mInteraction = .None;
			Context?.FocusManager.ReleaseCapture();
			Invalidate();
			e.Handled = true;

		case .None:
		}
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		// Zoom toward cursor
		let oldZoom = mZoom;
		let delta = e.DeltaY * ZoomStep;
		mZoom = Math.Clamp(mZoom + delta, MinZoom, MaxZoom);

		if (mZoom != oldZoom)
		{
			let mousePos = Vector2(e.X, e.Y);
			mPanOffset = mousePos - (mousePos - mPanOffset) * (mZoom / oldZoom);
			Invalidate();
		}
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (ReadOnly) return;

		if (e.Key == .Delete)
		{
			DeleteSelected();
			e.Handled = true;
		}
		else if (e.Key == .A && e.Modifiers.HasFlag(.Ctrl))
		{
			// Select all
			for (let node in mNodes) node.IsSelected = true;
			OnSelectionChanged();
			Invalidate();
			e.Handled = true;
		}
	}

	// ========== Hit testing ==========

	private (int32 nodeIdx, int32 portIdx, PortDirection dir) HitTestPort(float screenX, float screenY)
	{
		let hitR = PortHitRadius * mZoom;
		for (int32 ni = (int32)mNodes.Count - 1; ni >= 0; ni--)
		{
			let node = mNodes[ni];
			for (int32 pi = 0; pi < node.InputPorts.Count; pi++)
			{
				let pos = GetPortScreenPos(ni, pi, .Input);
				if (Vector2.Distance(.(screenX, screenY), pos) <= hitR)
					return (ni, pi, .Input);
			}
			for (int32 pi = 0; pi < node.OutputPorts.Count; pi++)
			{
				let pos = GetPortScreenPos(ni, pi, .Output);
				if (Vector2.Distance(.(screenX, screenY), pos) <= hitR)
					return (ni, pi, .Output);
			}
		}
		return (-1, -1, .Input);
	}

	private int32 HitTestNode(float screenX, float screenY)
	{
		// Check in reverse draw order (front to back)
		for (int i = mDrawOrder.Count - 1; i >= 0; i--)
		{
			let idx = mDrawOrder[i];
			let node = mNodes[idx];
			let pos = CanvasToScreen(node.Position);
			let size = node.Size * mZoom;
			if (screenX >= pos.X && screenX < pos.X + size.X &&
				screenY >= pos.Y && screenY < pos.Y + size.Y)
				return idx;
		}
		return -1;
	}

	private int32 HitTestConnection(float screenX, float screenY)
	{
		let hitDist = ConnectionHitDist * mZoom;
		for (int32 i = 0; i < mConnections.Count; i++)
		{
			let conn = mConnections[i];
			if (conn.SourceNodeIndex < 0 || conn.SourceNodeIndex >= mNodes.Count) continue;
			if (conn.DestNodeIndex < 0 || conn.DestNodeIndex >= mNodes.Count) continue;

			let start = GetPortScreenPos(conn.SourceNodeIndex, conn.SourcePortIndex, .Output);
			let end = GetPortScreenPos(conn.DestNodeIndex, conn.DestPortIndex, .Input);

			if (DistanceToBezier(.(screenX, screenY), start, end) <= hitDist)
				return i;
		}
		return -1;
	}

	private float DistanceToBezier(Vector2 point, Vector2 start, Vector2 end)
	{
		let dx = Math.Abs(end.X - start.X);
		let ctrlDist = Math.Max(dx * 0.5f, 50 * mZoom);
		let cp1 = Vector2(start.X + ctrlDist, start.Y);
		let cp2 = Vector2(end.X - ctrlDist, end.Y);

		float minDist = float.MaxValue;
		let steps = 24;
		for (int s = 0; s <= steps; s++)
		{
			let t = (float)s / (float)steps;
			let it = 1 - t;
			let p = start * (it * it * it) + cp1 * (3 * it * it * t) + cp2 * (3 * it * t * t) + end * (t * t * t);
			let dist = Vector2.Distance(point, p);
			if (dist < minDist) minDist = dist;
		}
		return minDist;
	}

	// ========== Hover updates ==========

	private void UpdateHover(float screenX, float screenY)
	{
		let oldNode = mHoveredNodeIndex;
		let oldConn = mHoveredConnectionIndex;
		let oldPortNode = mHoveredPortNode;

		let portHit = HitTestPort(screenX, screenY);
		mHoveredPortNode = portHit.nodeIdx;
		mHoveredPortIndex = portHit.portIdx;
		mHoveredPortDir = portHit.dir;

		mHoveredNodeIndex = (portHit.nodeIdx < 0) ? HitTestNode(screenX, screenY) : -1;
		mHoveredConnectionIndex = (mHoveredNodeIndex < 0 && portHit.nodeIdx < 0) ? HitTestConnection(screenX, screenY) : -1;

		if (mHoveredNodeIndex != oldNode || mHoveredConnectionIndex != oldConn || mHoveredPortNode != oldPortNode)
			Invalidate();
	}

	private void UpdatePortHover(float screenX, float screenY)
	{
		let portHit = HitTestPort(screenX, screenY);
		let oldPortNode = mHoveredPortNode;
		mHoveredPortNode = portHit.nodeIdx;
		mHoveredPortIndex = portHit.portIdx;
		mHoveredPortDir = portHit.dir;
		if (mHoveredPortNode != oldPortNode) Invalidate();
	}

	/// Finds the index of a connection targeting the given input port, or -1.
	private int32 FindConnectionToInput(int32 nodeIdx, int32 portIdx)
	{
		for (int32 i = 0; i < mConnections.Count; i++)
		{
			let c = mConnections[i];
			if (c.DestNodeIndex == nodeIdx && c.DestPortIndex == portIdx)
				return i;
		}
		return -1;
	}

	// ========== Internal helpers ==========

	private void AutoSizeNode(NodeGraphNode node)
	{
		let maxPorts = Math.Max(node.InputPorts.Count, node.OutputPorts.Count);
		let portsH = HeaderHeight + PortMarginTop + maxPorts * PortSpacing + 8;
		node.Size.Y = Math.Max(node.Size.Y, portsH);
		node.Size.X = Math.Max(node.Size.X, NodeMinWidth);
	}

	private bool ValidateConnection(NodeGraphConnection conn)
	{
		// No self-connections
		if (conn.SourceNodeIndex == conn.DestNodeIndex) return false;

		// Bounds check
		if (conn.SourceNodeIndex < 0 || conn.SourceNodeIndex >= mNodes.Count) return false;
		if (conn.DestNodeIndex < 0 || conn.DestNodeIndex >= mNodes.Count) return false;

		let srcNode = mNodes[conn.SourceNodeIndex];
		let dstNode = mNodes[conn.DestNodeIndex];

		if (conn.SourcePortIndex < 0 || conn.SourcePortIndex >= srcNode.OutputPorts.Count) return false;
		if (conn.DestPortIndex < 0 || conn.DestPortIndex >= dstNode.InputPorts.Count) return false;

		// No duplicate connections
		for (let existing in mConnections)
		{
			if (existing.SourceNodeIndex == conn.SourceNodeIndex &&
				existing.SourcePortIndex == conn.SourcePortIndex &&
				existing.DestNodeIndex == conn.DestNodeIndex &&
				existing.DestPortIndex == conn.DestPortIndex)
				return false;
		}

		// Type validation
		let srcType = srcNode.OutputPorts[conn.SourcePortIndex].PortType;
		let dstType = dstNode.InputPorts[conn.DestPortIndex].PortType;

		if (ConnectionValidator != null)
			return ConnectionValidator(srcType, dstType);

		// Default: same TypeId or either untyped
		if (srcType.TypeId == 0 || dstType.TypeId == 0) return true;
		return srcType.TypeId == dstType.TypeId;
	}

	private void ClearSelectionSilent()
	{
		for (let node in mNodes) node.IsSelected = false;
	}

	private void ClearConnectionSelection()
	{
		for (var i = 0; i < mConnections.Count; i++)
			mConnections[i].IsSelected = false;
	}

	private void BringToFront(int32 nodeIdx)
	{
		mDrawOrder.Remove(nodeIdx);
		mDrawOrder.Add(nodeIdx);
	}

	private void DeleteSelected()
	{
		BeginGesture();

		// Delete selected connections first
		for (int i = mConnections.Count - 1; i >= 0; i--)
		{
			if (mConnections[i].IsSelected)
				RemoveConnection((int32)i);
		}

		// Delete selected nodes (reverse order to keep indices stable)
		for (int32 i = (int32)mNodes.Count - 1; i >= 0; i--)
		{
			if (mNodes[i].IsSelected && mNodes[i].IsDeletable)
				RemoveNode(i);
		}

		EndGesture();
		OnSelectionChanged();
	}

	private void BeginGesture()
	{
		if (!mInGesture)
		{
			mInGesture = true;
			OnEditBegin();
		}
	}

	private void EndGesture()
	{
		if (mInGesture)
		{
			mInGesture = false;
			OnEditEnd();
		}
	}
}
