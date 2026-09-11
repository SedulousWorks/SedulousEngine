using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[NodeGraphCanvas]]: where ports and edges are in screen space, and what is under a point.
extension NodeGraphCanvas
{
	/// A port's position: the node's left or right edge, stepped down by its index.
	private Float2 GetPortCanvasPos(int32 nodeIndex, int32 portIndex, PortDirection direction)
	{
		let node = mNodes[nodeIndex];
		let x = (direction == .Input) ? node.Position.X : (node.Position.X + node.Size.X);
		let y = node.Position.Y + HeaderHeight + PortMarginTop + (portIndex * PortSpacing)
			+ (PortSpacing * 0.5f);
		return .(x, y);
	}

	private Float2 GetPortScreenPos(int32 nodeIndex, int32 portIndex, PortDirection direction) =>
		CanvasToScreen(GetPortCanvasPos(nodeIndex, portIndex, direction));

	private Float2 NodeCenterScreen(int32 nodeIndex)
	{
		let node = mNodes[nodeIndex];
		return CanvasToScreen(node.Position + (node.Size * 0.5f));
	}

	/// Where a ray leaving a node's centre crosses its edge, which is where a straight edge
	/// should start rather than at the centre itself.
	private Float2 ClipToNodeRect(int32 nodeIndex, Float2 center, Float2 direction)
	{
		let node = mNodes[nodeIndex];
		let pos = CanvasToScreen(node.Position);
		let size = node.Size * mZoom;
		var t = FloatMax;

		if (Abs(direction.X) > 0.0001f)
		{
			let edge = (direction.X > 0) ? (pos.X + size.X) : pos.X;
			t = Min(t, Max((edge - center.X) / direction.X, 0.0f));
		}

		if (Abs(direction.Y) > 0.0001f)
		{
			let edge = (direction.Y > 0) ? (pos.Y + size.Y) : pos.Y;
			t = Min(t, Max((edge - center.Y) / direction.Y, 0.0f));
		}

		return (t == FloatMax) ? center : (center + (direction * t));
	}

	/// A straight edge's two endpoints, offset SIDEWAYS by its lane so parallel edges between
	/// the same pair of nodes stay apart, then clipped to both node rectangles.
	///
	/// An edge running the other way between the same pair shifts to its own side
	/// automatically, because its perpendicular flips with its direction.
	///
	/// False means degenerate: a self edge, or nodes so close there is nothing to draw.
	private bool ComputeStraightEdge(int32 connectionIndex, out Float2 start, out Float2 end)
	{
		start = .Zero;
		end = .Zero;

		let connection = mConnections[connectionIndex];
		if (connection.SourceNodeIndex == connection.DestNodeIndex)
			return false;

		let centerA = NodeCenterScreen(connection.SourceNodeIndex);
		let centerB = NodeCenterScreen(connection.DestNodeIndex);
		let delta = centerB - centerA;
		let length = Length(delta);
		if (length < 1.0f)
			return false;

		let direction = delta * (1.0f / length);
		let perpendicular = Float2(-direction.Y, direction.X);
		let shift = LateralShift(connectionIndex, connection);

		start = ClipToNodeRect(connection.SourceNodeIndex, centerA + (perpendicular * shift),
			direction);
		end = ClipToNodeRect(connection.DestNodeIndex, centerB + (perpendicular * shift),
			direction * -1.0f);

		return Distance(start, end) >= 2.0f;
	}

	/// How far off the centre line this edge sits: its LANE among the edges sharing its ordered
	/// pair. A lone group is centred; a pair that also has an edge coming back is pushed to one
	/// side so the two do not overlap.
	private float LateralShift(int32 connectionIndex, NodeGraphConnection connection)
	{
		var lane = 0;
		var sameCount = 0;
		var hasOpposite = false;

		for (int32 i = 0; i < mConnections.Count; i++)
		{
			let other = mConnections[i];

			if ((other.SourceNodeIndex == connection.SourceNodeIndex)
				&& (other.DestNodeIndex == connection.DestNodeIndex))
			{
				if (i < connectionIndex)
					lane++;
				sameCount++;
			}
			else if ((other.SourceNodeIndex == connection.DestNodeIndex)
				&& (other.DestNodeIndex == connection.SourceNodeIndex))
			{
				hasOpposite = true;
			}
		}

		let spacing = 14.0f * mZoom;
		// NAMED offset, not base: base is a Beef keyword.
		let offset = hasOpposite ? (spacing * 0.5f) : (-spacing * 0.5f * (float)(sameCount - 1));
		return offset + (spacing * (float)lane);
	}

	// ---- Hit testing ----------------------------------------------------------------------------

	/// Tested FRONT TO BACK over the node list, so a port on a node drawn later wins.
	private PortHit HitTestPort(float screenX, float screenY)
	{
		let point = Float2(screenX, screenY);
		let radius = PortHitRadius * mZoom;

		for (int32 nodeIndex = (int32)mNodes.Count - 1; nodeIndex >= 0; nodeIndex--)
		{
			let node = mNodes[nodeIndex];

			for (int32 i = 0; i < node.InputPorts.Count; i++)
			{
				if (Distance(point, GetPortScreenPos(nodeIndex, i, .Input)) <= radius)
					return .() { NodeIndex = nodeIndex, PortIndex = i, Direction = .Input };
			}

			for (int32 i = 0; i < node.OutputPorts.Count; i++)
			{
				if (Distance(point, GetPortScreenPos(nodeIndex, i, .Output)) <= radius)
					return .() { NodeIndex = nodeIndex, PortIndex = i, Direction = .Output };
			}
		}

		return .();
	}

	/// Walked in REVERSE draw order, which is front to back, so the node on top takes the click.
	private int32 HitTestNode(float screenX, float screenY)
	{
		for (int i = mDrawOrder.Count - 1; i >= 0; i--)
		{
			let index = mDrawOrder[i];
			let node = mNodes[index];
			let pos = CanvasToScreen(node.Position);
			let size = node.Size * mZoom;

			if ((screenX >= pos.X) && (screenX < pos.X + size.X) && (screenY >= pos.Y)
				&& (screenY < pos.Y + size.Y))
				return index;
		}

		return -1;
	}

	private int32 HitTestConnection(float screenX, float screenY)
	{
		let point = Float2(screenX, screenY);
		let hitDistance = ConnectionHitDistance * mZoom;

		for (int32 i = 0; i < mConnections.Count; i++)
		{
			let connection = mConnections[i];
			if (!IsConnectionResolvable(connection))
				continue;

			if (EdgeStyle == .StraightNodeToNode)
			{
				if (ComputeStraightEdge(i, let start, let end)
					&& (DistanceToSegment(point, start, end) <= hitDistance))
					return i;

				continue;
			}

			let start = GetPortScreenPos(connection.SourceNodeIndex, connection.SourcePortIndex,
				.Output);
			let end = GetPortScreenPos(connection.DestNodeIndex, connection.DestPortIndex, .Input);
			if (DistanceToBezier(point, start, end) <= hitDistance)
				return i;
		}

		return -1;
	}

	private bool IsConnectionResolvable(NodeGraphConnection connection) =>
		(connection.SourceNodeIndex >= 0) && (connection.SourceNodeIndex < mNodes.Count)
			&& (connection.DestNodeIndex >= 0) && (connection.DestNodeIndex < mNodes.Count);

	private static float DistanceToSegment(Float2 point, Float2 a, Float2 b)
	{
		let ab = b - a;
		let lengthSquared = LengthSquared(ab);
		if (lengthSquared < 0.0001f)
			return Distance(point, a);

		let t = Clamp(Dot(point - a, ab) / lengthSquared, 0.0f, 1.0f);
		return Distance(point, a + (ab * t));
	}

	/// SAMPLED rather than solved: the nearest point on a cubic has no closed form worth the
	/// trouble, and two dozen samples is well under the eight pixel tolerance this feeds.
	private float DistanceToBezier(Float2 point, Float2 start, Float2 end)
	{
		let controlDistance = Max(Abs(end.X - start.X) * 0.5f, 50.0f * mZoom);
		let control1 = Float2(start.X + controlDistance, start.Y);
		let control2 = Float2(end.X - controlDistance, end.Y);

		const int32 Steps = 24;
		var nearest = FloatMax;

		for (int32 s = 0; s <= Steps; s++)
		{
			let t = (float)s / Steps;
			let inverse = 1.0f - t;
			let sample = (start * (inverse * inverse * inverse))
				+ (control1 * (3.0f * inverse * inverse * t))
				+ (control2 * (3.0f * inverse * t * t))
				+ (end * (t * t * t));

			nearest = Min(nearest, Distance(point, sample));
		}

		return nearest;
	}

	// ---- Hover ----------------------------------------------------------------------------------

	/// Ports, then nodes, then edges: the most specific thing under the pointer wins, and only
	/// one of the three is ever hovered at a time.
	private void UpdateHover(float screenX, float screenY)
	{
		let previousNode = mHoveredNodeIndex;
		let previousConnection = mHoveredConnectionIndex;
		let previousPortNode = mHoveredPortNode;

		let portHit = HitTestPort(screenX, screenY);
		mHoveredPortNode = portHit.NodeIndex;
		mHoveredPortIndex = portHit.PortIndex;
		mHoveredPortDirection = portHit.Direction;

		mHoveredNodeIndex = portHit.IsValid ? -1 : HitTestNode(screenX, screenY);
		mHoveredConnectionIndex = ((mHoveredNodeIndex < 0) && !portHit.IsValid)
			? HitTestConnection(screenX, screenY) : -1;

		if ((mHoveredNodeIndex != previousNode) || (mHoveredConnectionIndex != previousConnection)
			|| (mHoveredPortNode != previousPortNode))
			Invalidate();
	}

	/// During a connection drag only the PORT matters, so the node and edge hover are left
	/// alone rather than flickering under the rubber edge.
	private void UpdatePortHover(float screenX, float screenY)
	{
		let portHit = HitTestPort(screenX, screenY);
		let previousPortNode = mHoveredPortNode;

		mHoveredPortNode = portHit.NodeIndex;
		mHoveredPortIndex = portHit.PortIndex;
		mHoveredPortDirection = portHit.Direction;

		if (mHoveredPortNode != previousPortNode)
			Invalidate();
	}
}
