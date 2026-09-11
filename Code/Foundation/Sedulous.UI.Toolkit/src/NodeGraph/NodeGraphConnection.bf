namespace Sedulous.UI.Toolkit;

/// An edge from one node's output to another's input.
///
/// Endpoints are INDICES into the canvas's own lists, which is why removing a node has to
/// renumber every connection that pointed past it.
struct NodeGraphConnection
{
	public int32 SourceNodeIndex = 0;
	public int32 SourcePortIndex = 0;
	public int32 DestNodeIndex = 0;
	public int32 DestPortIndex = 0;
	public bool IsSelected = false;

	public this() {}

	public this(int32 sourceNode, int32 sourcePort, int32 destNode, int32 destPort)
	{
		SourceNodeIndex = sourceNode;
		SourcePortIndex = sourcePort;
		DestNodeIndex = destNode;
		DestPortIndex = destPort;
	}
}
