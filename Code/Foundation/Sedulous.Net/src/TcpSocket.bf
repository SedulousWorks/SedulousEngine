using System;
using System.Net;

namespace Sedulous.Net;

/// A connected TCP stream: a client connection, or one a listener accepted.
///
/// For the HTTP, WebSocket and debugger transports, NOT for the UDP game transport. IPv4
/// only.
class TcpSocket
{
	private Socket mSocket = new .() ~ delete _;
	private bool mConnectFailed = false;

	/// An unconnected socket. Connect fills one in.
	public this() {}

	/// Adopts an already connected socket, taking OWNERSHIP of it.
	public this(Socket adopted)
	{
		delete mSocket;
		mSocket = adopted;
	}

	public ~this()
	{
		mSocket.Close();
	}

	/// Connects to a host and port. The host may be a dotted quad or a name; THE NAME LOOKUP
	/// BLOCKS, so this belongs at a connect edge rather than in a frame.
	///
	/// Not open when the host does not resolve.
	public static TcpSocket Connect(StringView host, uint16 port)
	{
		let result = new TcpSocket();
		if (!NetAddress.ResolveHostIPv4(host, let ip))
		{
			result.mConnectFailed = true;
			return result;
		}

		let dotted = scope $"{(uint8)(ip >> 24)}.{(uint8)(ip >> 16)}.{(uint8)(ip >> 8)}.{(uint8)ip}";
		Socket.Init();
		if (result.mSocket.Connect(dotted, (int32)port) case .Err)
		{
			result.mConnectFailed = true;
			return result;
		}
		result.mSocket.Blocking = false;
		return result;
	}

	public bool IsOpen => mSocket.IsOpen;

	/// One when connected, nought while still connecting, minus one when it failed.
	public int32 ConnectStatus
	{
		get
		{
			if (mConnectFailed)
				return -1;
			if (!mSocket.IsOpen)
				return -1;
			return mSocket.IsConnected ? 1 : 0;
		}
	}

	/// Bytes sent, which MAY BE FEWER than asked for; nought means try again, and minus one
	/// means the peer is gone.
	public int64 Send(Span<uint8> data)
	{
		if (!mSocket.IsOpen)
			return -1;
		if (mSocket.Send(data.Ptr, data.Length) case .Ok(let sent))
			return (int64)sent;
		return -1;
	}

	/// Bytes read; nought means nothing yet, and minus one means closed.
	public int64 Receive(Span<uint8> outData)
	{
		if (!mSocket.IsOpen)
			return -1;
		if (mSocket.Recv(outData.Ptr, outData.Length) case .Ok(let received))
			return (int64)received;
		return -1;
	}

	public void Close() => mSocket.Close();

	/// The socket underneath, for a caller that needs to poll several at once.
	public Socket Handle => mSocket;
}
