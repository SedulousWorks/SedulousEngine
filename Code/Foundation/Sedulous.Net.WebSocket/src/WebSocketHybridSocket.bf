using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.WebSocket;

/// ONE datagram socket carrying both native UDP peers and browser websocket peers.
///
/// This is the whole point of the module. A browser cannot open a raw UDP socket, so its only
/// game usable transport is a websocket over TCP; presenting both behind the datagram seam
/// means the session, reliability and replication layers above CANNOT TELL THEM APART and
/// need no branch of their own.
///
/// The reliability layer runs unchanged over a websocket. TCP already guarantees delivery, so
/// the resends simply never fire: acks still flow, which is redundant but correct, and that
/// is cheaper than a second protocol path to keep honest.
class WebSocketHybridSocket : IDatagramSocket
{
	private UdpSocket mUdp ~ delete _;
	private WebSocketServerGateway mGateway ~ delete _;
	private WsGatewayEvent mScratchEvent = new .() ~ delete _;

	/// Binds the UDP socket and the websocket listener. Either port may be nought to let the
	/// operating system choose. Check IsOpen.
	public this(uint16 udpPort, uint16 webSocketPort)
	{
		mUdp = new .(udpPort);
		mGateway = new .(webSocketPort);
	}

	public bool IsOpen => mUdp.IsOpen && mGateway.IsOpen;
	public uint16 BoundPort => mUdp.BoundPort;
	public uint16 WebSocketBoundPort => mGateway.BoundPort;
	public WebSocketServerGateway Gateway => mGateway;

	public void Send(DatagramEndpoint to, Span<uint8> data)
	{
		if (WebSocketEndpoint.IsWebSocket(to))
			mGateway.SendBinary(WebSocketEndpoint.Client(to), data);
		else
			mUdp.Send(to, data);
	}

	public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData)
	{
		if (mUdp.Receive(out outFrom, outData))
			return true;

		// The session drains Receive to exhaustion every frame, so pumping the gateway here
		// keeps it serviced without adding an update hook to the datagram seam.
		mGateway.Pump();

		while (mGateway.Poll(mScratchEvent))
		{
			// Presence at the session level comes from session packets, not from the TCP
			// connection coming and going.
			if (mScratchEvent.Kind != .Message)
				continue;

			outFrom = WebSocketEndpoint.Make(mScratchEvent.Client);
			outData.Clear();
			outData.AddRange(mScratchEvent.Payload);
			return true;
		}

		outFrom = .();
		return false;
	}

	public DatagramEndpoint LocalEndpoint => mUdp.LocalEndpoint;
}
