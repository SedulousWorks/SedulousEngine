namespace Sedulous.GUI.Toolkit;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Direction of a port on a node.
public enum PortDirection : uint8
{
	Input,
	Output
}

/// Describes a port type for connection validation and coloring.
/// Uses caller-defined int32 IDs so each domain (animation, audio, etc.)
/// can define its own type enums. TypeId 0 means "untyped" and connects
/// to anything.
public struct NodeGraphPortType
{
	/// Caller-defined type identifier. 0 = untyped (connects to anything).
	public int32 TypeId;

	/// Display color for the port circle and compatible connections.
	public Color Color;

	public this(int32 typeId, Color color)
	{
		TypeId = typeId;
		Color = color;
	}

	/// Untyped port - connects to anything.
	public static NodeGraphPortType Untyped => .(0, .(180, 180, 190, 255));
}

/// One port on a node.
public class NodeGraphPort
{
	/// Whether this is an input or output port.
	public PortDirection Direction;

	/// Type of this port (for connection validation and coloring).
	public NodeGraphPortType PortType = .Untyped;

	/// Display label shown next to the port (e.g., "Audio In", "Pose Out").
	public String Label = new .() ~ delete _;
}

/// A node in the graph. Lightweight data object rendered by the canvas.
public class NodeGraphNode
{
	/// Caller-assigned identifier. The canvas never interprets this;
	/// it is passed back in events so callers can map to their domain objects.
	public int64 UserHandle;

	/// Display title shown in the node's header bar.
	public String Title = new .() ~ delete _;

	/// Optional subtitle shown below the title in smaller text.
	public String Subtitle = new .() ~ delete _;

	/// Position in canvas space (before pan/zoom transform).
	public Vector2 Position;

	/// Size in canvas space. Auto-computed from ports/title unless set explicitly.
	public Vector2 Size = .(160, 80);

	/// Header bar color.
	public Color HeaderColor = .(70, 130, 200, 255);

	/// Whether this node is selected.
	public bool IsSelected;

	/// Input ports (ordered top to bottom on the left side).
	public List<NodeGraphPort> InputPorts = new .() ~ DeleteContainerAndItems!(_);

	/// Output ports (ordered top to bottom on the right side).
	public List<NodeGraphPort> OutputPorts = new .() ~ DeleteContainerAndItems!(_);

	/// Whether this node can be moved by the user.
	public bool IsMovable = true;

	/// Whether this node can be deleted by the user.
	public bool IsDeletable = true;
}

/// A connection between an output port on one node and an input port on another.
public struct NodeGraphConnection
{
	/// Source node index.
	public int32 SourceNodeIndex;
	/// Source output port index within that node.
	public int32 SourcePortIndex;
	/// Destination node index.
	public int32 DestNodeIndex;
	/// Destination input port index within that node.
	public int32 DestPortIndex;
	/// Whether this connection is selected.
	public bool IsSelected;
}
