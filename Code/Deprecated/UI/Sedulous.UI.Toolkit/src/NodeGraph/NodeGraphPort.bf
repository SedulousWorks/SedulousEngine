using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// One port on a node.
class NodeGraphPort
{
	public PortDirection Direction = .Input;
	public NodeGraphPortType PortType = NodeGraphPortType.Untyped();
	/// Shown beside the port circle: "Audio In", "Pose Out".
	public String Label = new .() ~ delete _;

	public this() {}

	public this(PortDirection direction, StringView label)
	{
		Direction = direction;
		Label.Set(label);
	}

	public this(PortDirection direction, StringView label, NodeGraphPortType portType)
		: this(direction, label)
	{
		PortType = portType;
	}
}
