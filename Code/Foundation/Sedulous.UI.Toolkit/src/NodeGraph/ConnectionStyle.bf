namespace Sedulous.UI.Toolkit;

/// How edges are anchored and drawn, which is the difference between the two kinds of graph
/// this canvas serves.
enum ConnectionStyle
{
	/// The DATAFLOW look: a curve from an output port to an input port, leaving and arriving
	/// horizontally, so the direction of flow reads from the shape alone.
	BezierPorts,
	/// The STATE MACHINE look: a straight line between node centres, clipped to their
	/// rectangles, offset sideways so two edges between the same pair stay apart, with an arrow
	/// at the midpoint. Such nodes usually have no ports at all and are linked by gesture.
	StraightNodeToNode
}
