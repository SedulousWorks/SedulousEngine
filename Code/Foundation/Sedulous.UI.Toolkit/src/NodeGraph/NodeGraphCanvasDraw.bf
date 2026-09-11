using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[NodeGraphCanvas]]: the grid, the nodes, the edges and whatever is in flight.
///
/// The order matters. Grid, then edges, then the selection box, then nodes, then the rubber
/// edge of a drag: nodes sit OVER their edges so an edge never crosses a node's face, and the
/// thing being dragged sits over everything because it is what the eye is following.
extension NodeGraphCanvas
{
	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color.Rgb(28, 28, 33));

		ctx.PushClip(bounds);

		if (ShowGrid)
			DrawGrid(ctx);

		for (int32 i = 0; i < mConnections.Count; i++)
			DrawConnection(ctx, i, i == mHoveredConnectionIndex);

		if (mInteraction == .BoxSelecting)
			DrawSelectionBox(ctx);

		for (let index in mDrawOrder)
			DrawNode(ctx, index);

		DrawInFlightEdge(ctx);
		DrawHoveredPort(ctx);

		ctx.PopClip();
	}

	/// A minor grid with a heavier line every fifth, which is what makes distance readable
	/// without counting.
	///
	/// Both are SKIPPED when they would be too dense to read: a grid at one pixel a square is
	/// a grey wash that costs a line per column.
	private void DrawGrid(UIDrawContext ctx)
	{
		let step = GridSize * mZoom;
		if (step < 4.0f)
			return;

		let borderColor = ResolveStyleColor(.BorderColor, Color.Rgb(55, 55, 60));
		let minorColor = Color(borderColor.R * 0.7f, borderColor.G * 0.7f, borderColor.B * 0.7f,
			borderColor.A);
		let majorStep = step * 5.0f;

		DrawGridLines(ctx, Remainder(mPanOffset.X, step), Remainder(mPanOffset.Y, step), step,
			minorColor);

		if (majorStep >= 20.0f)
			DrawGridLines(ctx, Remainder(mPanOffset.X, majorStep),
				Remainder(mPanOffset.Y, majorStep), majorStep, borderColor);
	}

	private void DrawGridLines(UIDrawContext ctx, float startX, float startY, float step,
		Color color)
	{
		var x = startX;
		while (x < Width)
		{
			ctx.VG.DrawLine(.(x, 0), .(x, Height), color, 1);
			x += step;
		}

		var y = startY;
		while (y < Height)
		{
			ctx.VG.DrawLine(.(0, y), .(Width, y), color, 1);
			y += step;
		}
	}

	/// C's remainder, which keeps the SIGN of the dividend. Core has no fmod, and the floor
	/// based remainder would put the first grid line a whole step to the right whenever the pan
	/// is negative.
	private static float Remainder(float value, float divisor)
	{
		if (divisor == 0.0f)
			return 0.0f;

		let quotient = value / divisor;
		return value - (divisor * ((quotient >= 0.0f) ? Floor(quotient) : Ceil(quotient)));
	}

	private void DrawSelectionBox(UIDrawContext ctx)
	{
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(80, 140, 220));
		let a = CanvasToScreen(mBoxSelectStart);
		let b = CanvasToScreen(mBoxSelectEnd);
		let rect = Rectangle(Min(a.X, b.X), Min(a.Y, b.Y), Abs(b.X - a.X), Abs(b.Y - a.Y));

		ctx.VG.FillRect(rect, .(accent.R, accent.G, accent.B, 40 / 255.0f));
		ctx.VG.StrokeRect(rect, .(accent.R, accent.G, accent.B, 150 / 255.0f), 1);
	}

	private void DrawNode(UIDrawContext ctx, int32 nodeIndex)
	{
		let node = mNodes[nodeIndex];
		let pos = CanvasToScreen(node.Position);
		let size = node.Size * mZoom;
		let headerHeight = HeaderHeight * mZoom;
		// The radius SCALES with the zoom, so a node keeps its shape rather than growing
		// squarer as it is zoomed in.
		let cornerRadius = ResolveStyleFloat(.CornerRadius, 4.0f) * mZoom;
		let body = Rectangle(pos.X, pos.Y, size.X, size.Y);

		if (let bodyDrawable = ResolvePartDrawable("node-body", .Background, .Normal))
			bodyDrawable.Draw(ctx, body);
		else
			ctx.VG.FillRoundedRect(body, cornerRadius, Color.Rgb(38, 40, 48));

		// The header takes the NODE's own colour rather than the theme's: it is how a caller
		// classifies its nodes, and the canvas has no idea what the classes are.
		ctx.VG.FillRoundedRect(.(pos.X, pos.Y, size.X, headerHeight), cornerRadius,
			node.HeaderColor);
		// Its bottom corners are SQUARED off again, so the header meets the body flush instead
		// of pinching in above it.
		ctx.VG.FillRect(.(pos.X, pos.Y + headerHeight - cornerRadius, size.X, cornerRadius),
			node.HeaderColor);

		if (node.IsSelected)
			ctx.VG.StrokeRoundedRect(body, cornerRadius,
				ResolveStyleColor(.AccentColor, .(100 / 255.0f, 180 / 255.0f, 1.0f, 200 / 255.0f)),
				2);

		// The emphasis ring sits OUTSIDE the selection outline, so a node can be both selected
		// and highlighted and still read as both.
		if (node.IsHighlighted)
			ctx.VG.StrokeRoundedRect(.(pos.X - 3, pos.Y - 3, size.X + 6, size.Y + 6),
				cornerRadius + 3, node.HighlightColor, 3);

		if (ctx.FontService != null)
			DrawNodeText(ctx, nodeIndex, pos, size, headerHeight);
	}

	private void DrawNodeText(UIDrawContext ctx, int32 nodeIndex, Float2 pos, Float2 size,
		float headerHeight)
	{
		let node = mNodes[nodeIndex];
		let inset = 8.0f * mZoom;

		if (let titleFont = ctx.FontService.GetFont(11))
			ctx.VG.DrawText(node.Title, titleFont,
				.(pos.X + inset, pos.Y, size.X - (inset * 2.0f), headerHeight), .Left, .Middle,
				ResolveStyleColor(.TextColor, .(1.0f, 1.0f, 1.0f, 230 / 255.0f)));

		if (!node.Subtitle.IsEmpty)
		{
			if (let subtitleFont = ctx.FontService.GetFont(10))
				ctx.VG.DrawText(node.Subtitle, subtitleFont,
					.(pos.X + inset, pos.Y + headerHeight, size.X - (inset * 2.0f), 16.0f * mZoom),
					.Left, .Middle,
					ResolveStyleColor(.TextDimColor, .(180 / 255.0f, 180 / 255.0f, 190 / 255.0f,
						180 / 255.0f)));
		}

		let portFont = ctx.FontService.GetFont(10);
		DrawPorts(ctx, nodeIndex, node.InputPorts, .Input, portFont);
		DrawPorts(ctx, nodeIndex, node.OutputPorts, .Output, portFont);
	}

	/// A port's circle takes its TYPE's colour, which the caller defined, so compatible ports
	/// and the edges between them read as one family without the theme knowing about any of it.
	private void DrawPorts(UIDrawContext ctx, int32 nodeIndex, List<NodeGraphPort> ports,
		PortDirection direction, CachedFont font)
	{
		let labelColor = ResolveStyleColor(.TextDimColor,
			.(200 / 255.0f, 200 / 255.0f, 210 / 255.0f, 200 / 255.0f));
		let radius = PortRadius * mZoom;

		for (int32 i = 0; i < ports.Count; i++)
		{
			let port = ports[i];
			let center = GetPortScreenPos(nodeIndex, i, direction);

			ctx.VG.FillCircle(center, radius, port.PortType.Color);
			// A dark outline, so a pale port stays visible against a pale node.
			ctx.VG.StrokeCircle(center, radius, .(0, 0, 0, 100 / 255.0f), 1);

			if ((font == null) || port.Label.IsEmpty)
				continue;

			// Labels sit INSIDE the node: an input's to the right of its circle, an output's to
			// the left of it, so neither runs out over the canvas.
			let labelWidth = 80.0f * mZoom;
			let labelY = center.Y - (8.0f * mZoom);
			let gap = radius + (4.0f * mZoom);

			if (direction == .Input)
				ctx.VG.DrawText(port.Label, font,
					.(center.X + gap, labelY, labelWidth, 16.0f * mZoom), .Left, .Middle,
					labelColor);
			else
				ctx.VG.DrawText(port.Label, font,
					.(center.X - gap - labelWidth, labelY, labelWidth, 16.0f * mZoom), .Right,
					.Middle, labelColor);
		}
	}

	private void DrawConnection(UIDrawContext ctx, int32 connectionIndex, bool hovered)
	{
		let connection = mConnections[connectionIndex];
		if (!IsConnectionResolvable(connection))
			return;

		if (EdgeStyle == .StraightNodeToNode)
		{
			if (!ComputeStraightEdge(connectionIndex, let start, let end))
				return;

			DrawStraightEdge(ctx, start, end, StraightEdgeColor(connection, hovered));
			return;
		}

		DrawBezier(ctx,
			GetPortScreenPos(connection.SourceNodeIndex, connection.SourcePortIndex, .Output),
			GetPortScreenPos(connection.DestNodeIndex, connection.DestPortIndex, .Input),
			BezierEdgeColor(connection, hovered));
	}

	private Color StraightEdgeColor(NodeGraphConnection connection, bool hovered)
	{
		if (connection.IsSelected)
			return ResolveStyleColor(.AccentColor,
				.(100 / 255.0f, 180 / 255.0f, 1.0f, 230 / 255.0f));

		return hovered ? Color(230 / 255.0f, 230 / 255.0f, 240 / 255.0f, 230 / 255.0f)
			: NodeGraphPortType.Untyped().Color;
	}

	/// An edge takes its SOURCE port's colour, so following a colour across the graph follows
	/// one kind of value.
	private Color BezierEdgeColor(NodeGraphConnection connection, bool hovered)
	{
		if (connection.IsSelected)
			return ResolveStyleColor(.AccentColor,
				.(100 / 255.0f, 180 / 255.0f, 1.0f, 230 / 255.0f));

		var color = NodeGraphPortType.Untyped().Color;
		let source = mNodes[connection.SourceNodeIndex];
		if ((connection.SourcePortIndex >= 0)
			&& (connection.SourcePortIndex < source.OutputPorts.Count))
			color = source.OutputPorts[connection.SourcePortIndex].PortType.Color;

		// Hovering BRIGHTENS the edge's own colour rather than replacing it, so the edge stays
		// identifiable while it is highlighted.
		if (hovered)
			return .(Min(1.0f, color.R + (40 / 255.0f)), Min(1.0f, color.G + (40 / 255.0f)),
				Min(1.0f, color.B + (40 / 255.0f)), 230 / 255.0f);

		return color;
	}

	/// Horizontal tangents at both ends, so an edge leaves an output rightward and arrives at an
	/// input leftward whatever the nodes' relative positions. That is what makes the direction
	/// of flow readable from the shape.
	private void DrawBezier(UIDrawContext ctx, Float2 start, Float2 end, Color color)
	{
		let controlDistance = Max(Abs(end.X - start.X) * 0.5f, 50.0f * mZoom);

		ctx.VG.BeginPath();
		ctx.VG.MoveTo(start);
		ctx.VG.CubicTo(.(start.X + controlDistance, start.Y), .(end.X - controlDistance, end.Y),
			end);
		ctx.VG.Stroke(color, 2);
	}

	/// A line with an arrow at its MIDPOINT rather than its end: the end is buried against a
	/// node's edge, where an arrow is hard to see and harder to tell apart from its neighbour's.
	private void DrawStraightEdge(UIDrawContext ctx, Float2 start, Float2 end, Color color)
	{
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(start);
		ctx.VG.LineTo(end);
		ctx.VG.Stroke(color, 2);

		let delta = end - start;
		let length = Length(delta);
		// Too short to carry one; an arrow as long as the edge reads as a blob.
		if (length < 12.0f)
			return;

		let direction = delta * (1.0f / length);
		let perpendicular = Float2(-direction.Y, direction.X);
		let mid = (start + end) * 0.5f;
		let arm = 7.0f * mZoom;

		ctx.VG.BeginPath();
		ctx.VG.MoveTo(mid + (direction * arm));
		ctx.VG.LineTo(mid - (direction * arm) + (perpendicular * arm));
		ctx.VG.LineTo(mid - (direction * arm) - (perpendicular * arm));
		ctx.VG.ClosePath();
		ctx.VG.Fill(color);
	}

	private void DrawInFlightEdge(UIDrawContext ctx)
	{
		let dimColor = ResolveStyleColor(.TextDimColor,
			.(180 / 255.0f, 200 / 255.0f, 220 / 255.0f, 180 / 255.0f));

		if ((mInteraction == .PendingLink) && (mLinkSourceNode >= 0))
		{
			DrawStraightEdge(ctx, NodeCenterScreen(mLinkSourceNode), mDragConnectionEnd, dimColor);
			return;
		}

		if ((mInteraction != .DraggingConnection) || (mDragSourceNode < 0))
			return;

		// Drawn in the SAME direction the finished edge would run, so the curve does not flip
		// the moment the drag is released.
		let sourcePos = GetPortScreenPos(mDragSourceNode, mDragSourcePort, mDragSourceDirection);
		let fromOutput = mDragSourceDirection == .Output;
		DrawBezier(ctx, fromOutput ? sourcePos : mDragConnectionEnd,
			fromOutput ? mDragConnectionEnd : sourcePos, dimColor);
	}

	/// A halo behind a hovered port, shown only when NOTHING is being dragged: during a
	/// connection drag the rubber edge already says where it would land.
	private void DrawHoveredPort(UIDrawContext ctx)
	{
		if ((mHoveredPortNode < 0) || (mInteraction != .None))
			return;

		ctx.VG.FillCircle(
			GetPortScreenPos(mHoveredPortNode, mHoveredPortIndex, mHoveredPortDirection),
			(PortRadius * mZoom) + 3.0f, .(1.0f, 1.0f, 1.0f, 60 / 255.0f));
	}
}
