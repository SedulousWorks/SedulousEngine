using System;
using System.Net;

namespace Sedulous.Net;

/// A listening TCP socket. Accept hands back pending connections without blocking.
class TcpListener
{
	private Socket mSocket = new .() ~ delete _;
	private uint16 mBoundPort = 0;

	/// Listens on a port. Nought lets the operating system choose, and BoundPort then says
	/// which, which is how a test pairs a client to a server without picking a fixed port.
	public this(uint16 port = 0)
	{
		Socket.Init();
		// The IPv4 overload EXPLICITLY: corlib's Listen(port) binds IPv6 with a dual stack
		// flag, and this module is IPv4 only, from the endpoint packing up.
		if (mSocket.Listen(Socket.INADDR_ANY, (int32)port) case .Ok)
		{
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

	/// One pending connection, or null when none is waiting. The caller OWNS what comes back.
	public TcpSocket Accept()
	{
		if (!mSocket.IsOpen)
			return null;

		let accepted = new Socket();
		if (accepted.AcceptFrom(mSocket) case .Err)
		{
			delete accepted;
			return null;
		}
		accepted.Blocking = false;
		return new TcpSocket(accepted);
	}
}
