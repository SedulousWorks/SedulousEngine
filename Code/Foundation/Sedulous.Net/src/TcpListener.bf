using System;
using System.Net;

namespace Sedulous.Net;

/// A listening TCP socket. Accept hands back pending connections without blocking.
class TcpListener
{
	private Socket mSocket = new .() ~ delete _;
	private uint16 mBoundPort = 0;
	private uint32 mBoundIp = 0;

	/// Listens on a port. Nought lets the operating system choose, and BoundPort then says
	/// which, which is how a test pairs a client to a server without picking a fixed port.
	///
	/// `loopbackOnly` binds 127.0.0.1 alone, so nothing off this machine can connect: what a
	/// local tool's server wants. Otherwise every interface, what a game server wants.
	///
	/// The port is reusable at once (SO_REUSEADDR): a server restarted after a crash or a
	/// quit does not wait out its previous run's closing connections, which the kernel holds
	/// in TIME_WAIT for about a minute. Not on Windows, where the option instead lets a
	/// second socket take a port that is live, and a closing one does not block a bind.
	public this(uint16 port = 0, bool loopbackOnly = false)
	{
		Socket.Init();
		// The IPv4 overload EXPLICITLY: corlib's Listen(port) binds IPv6 with a dual stack
		// flag, and this module is IPv4 only, from the endpoint packing up.
		let address = loopbackOnly ? Socket.IPv4Address(127, 0, 0, 1) : Socket.INADDR_ANY;
#if BF_PLATFORM_WINDOWS
		let opened = mSocket.OpenEx(address, (int32)port, .Stream, .TCP, cBacklog);
#else
		let opened = mSocket.OpenEx(address, (int32)port, .Stream, .TCP, cBacklog,
			Socket.SockOpt((int32)Socket.SOL_SOCKET, (int32)Socket.SO_REUSEADDR, (int32)1));
#endif
		if (opened case .Ok)
		{
			mSocket.Blocking = false;
			mBoundPort = NetAddress.BoundPort(mSocket);
			mBoundIp = NetAddress.BoundIp(mSocket);
		}
	}

	/// corlib's Listen default.
	private const int32 cBacklog = 5;

	public ~this()
	{
		mSocket.Close();
	}

	public bool IsOpen => mSocket.IsOpen;
	public uint16 BoundPort => mBoundPort;
	/// The bound address, packed (NetAddress.PackIPv4); nought is every interface.
	public uint32 BoundIp => mBoundIp;

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
