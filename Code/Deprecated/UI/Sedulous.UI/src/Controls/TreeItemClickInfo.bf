namespace Sedulous.UI;

/// What a TreeView reports when a row is clicked.
///
/// The node id rather than the flat position, because a position means nothing once anything
/// above it has been expanded or collapsed.
struct TreeItemClickInfo
{
	public int32 NodeId = 0;
	public int32 ClickCount = 0;

	public this() {}

	public this(int32 nodeId, int32 clickCount)
	{
		NodeId = nodeId;
		ClickCount = clickCount;
	}
}
