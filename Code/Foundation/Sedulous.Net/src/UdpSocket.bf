using System;
using System.Collections;
using System.Net;

namespace Sedulous.Net;

/// A real UDP socket presented as an IDatagramSocket.
///
/// This is what lets ReliableTransport, proven against the deterministic sim, run over an
/// actual network with NO protocol changes. Non blocking; IPv4 only.
class UdpSocket : IDatagramSocket
{
	/// Comfortably larger than the reliable transport's packet budget, so a datagram is never
	/// truncated by the receive buffer.
	private const int cMaxDatagram = 2048;

	private Socket mSocket = new .() ~ delete _;
	private uint16 mBoundPort = 0;
	private List<uint8> mScratch = new .() ~ delete _;

	/// Binds to a port. Nought lets the operating system choose, and BoundPort then says
	/// which. Check IsOpen afterwards.
	public this(uint16 port = 0)
	{
		Socket.Init();
		if (mSocket.OpenUDP((int32)port) case .Ok)
		{
			SocketInheritance.KeepFromChildren(mSocket);
			mSocket.Blocking = false;
			mBoundPort = NetAddress.BoundPort(mSocket);
		}
	}

	public ~this()
	{
		mSocket.Close();
	}

	public bool IsOpen => mSocket.IsOpen;
	public uint16 BoundPort => mBoundPort;

	public void Send(DatagramEndpoint to, Span<uint8> data)
	{
		if (!mSocket.IsOpen)
			return;

		Socket.SockAddr_in address = default;
		address.sin_family = Socket.AF_INET;
		address.sin_port = (uint16)Socket.htons((int16)NetAddress.EndpointPort(to));
		address.sin_addr = NetAddress.UnpackIPv4(NetAddress.EndpointIp(to));
		// A failed send is a dropped datagram, which is exactly what this layer promises.
		mSocket.SendTo(data.Ptr, data.Length, address).IgnoreError();
	}

	public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData)
	{
		outFrom = .();
		if (!mSocket.IsOpen)
			return false;

		mScratch.Count = cMaxDatagram;
		Socket.SockAddr_in from = default;
		int received = 0;
		switch (mSocket.RecvFrom(mScratch.Ptr, cMaxDatagram, out from))
		{
		case .Ok(let count):
			received = count;
		case .Err(let error):
			// The socket reads recvfrom's 0 as a closed stream, but for a datagram socket 0 is an
			// EMPTY DATAGRAM, not "none waiting": reading it as none stopped the receive loop with
			// the rest still queued, so a stream of them held back every real packet. Would-block
			// and real errors are none.
			if (error != .ConnectionClosed)
				return false;
			received = 0;
		}

		outData.Clear();
		if (received > 0)
			outData.AddRange(Span<uint8>(mScratch.Ptr, received));
		outFrom = NetAddress.MakeEndpoint(NetAddress.PackIPv4(from.sin_addr),
			(uint16)Socket.htons((int16)from.sin_port));
		return true;
	}

	/// Loopback plus the bound port: the address a peer ON THIS HOST connects to. A real
	/// remote needs the machine's public or LAN address, which comes from ResolveEndpoint.
	public DatagramEndpoint LocalEndpoint =>
		NetAddress.MakeEndpoint(0x7F000001, mBoundPort);
}
