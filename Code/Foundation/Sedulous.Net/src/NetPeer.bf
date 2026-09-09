namespace Sedulous.Net;

/// A connected remote in a session.
struct NetPeer
{
	public PeerId Id = InvalidPeer;
	public double ConnectedAtMs = 0.0;

	public this() {}

	public this(PeerId id, double connectedAtMs)
	{
		Id = id;
		ConnectedAtMs = connectedAtMs;
	}
}
