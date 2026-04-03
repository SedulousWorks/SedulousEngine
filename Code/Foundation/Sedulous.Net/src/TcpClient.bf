namespace Sedulous.Net;

using System;
using System.Net;

class TcpClient
{
	private Socket mSocket ~ delete _;
	private bool mConnected;
	private IPEndPoint mRemoteEndPoint;

	public this()
	{
		SocketInit.EnsureInitialized();
	}

	/// Wrap an existing connected socket (used by TcpListener.Accept)
	public this(Socket socket, IPEndPoint remoteEndPoint)
	{
		mSocket = socket;
		mConnected = true;
		mRemoteEndPoint = remoteEndPoint;
	}

	public bool IsConnected => mConnected;
	public IPEndPoint RemoteEndPoint => mRemoteEndPoint;
	public Socket RawSocket => mSocket;

	// NoDelay can be set via raw socket options if needed

	public Result<void, NetError> Connect(StringView host, uint16 port)
	{
		if (mConnected)
			return .Err(.AlreadyConnected);

		SocketInit.EnsureInitialized();

		mSocket = new Socket();
		if (mSocket.Connect(host, (int32)port) case .Err(let socketErr))
		{
			delete mSocket;
			mSocket = null;
			return .Err(NetError.FromSocketError(socketErr));
		}

		mSocket.Blocking = false;
		mConnected = true;
		// Store remote endpoint for reference
		mRemoteEndPoint = .(.Loopback, port); // Simplified; actual address resolved internally
		return .Ok;
	}

	public Result<void, NetError> Connect(IPEndPoint endPoint)
	{
		if (mConnected)
			return .Err(.AlreadyConnected);

		SocketInit.EnsureInitialized();

		mSocket = new Socket();
		var sockAddr = endPoint.ToSockAddr();
		if (mSocket.ConnectEx(&sockAddr, sizeof(Socket.SockAddr_in), .Stream, .TCP) case .Err(let socketErr))
		{
			delete mSocket;
			mSocket = null;
			return .Err(NetError.FromSocketError(socketErr));
		}

		mSocket.Blocking = false;
		mConnected = true;
		mRemoteEndPoint = endPoint;
		return .Ok;
	}

	public Result<int, NetError> Send(Span<uint8> data)
	{
		if (mSocket == null || !mConnected)
			return .Err(.NotConnected);

		switch (mSocket.Send(data.Ptr, data.Length))
		{
		case .Ok(let sent):
			return .Ok(sent);
		case .Err(let socketErr):
			if (socketErr == .WouldBlock)
				return .Err(.WouldBlock);
			CheckDisconnect(socketErr);
			return .Err(NetError.FromSocketError(socketErr));
		}
	}

	public Result<int, NetError> Send(StringView str)
	{
		return Send(Span<uint8>((uint8*)str.Ptr, str.Length));
	}

	public Result<void, NetError> SendAll(Span<uint8> data)
	{
		int totalSent = 0;
		while (totalSent < data.Length)
		{
			let remaining = Span<uint8>(data.Ptr + totalSent, data.Length - totalSent);
			switch (Send(remaining))
			{
			case .Ok(let sent):
				totalSent += sent;
			case .Err(let err):
				if (err == .WouldBlock)
					continue; // Retry
				return .Err(err);
			}
		}
		return .Ok;
	}

	public Result<int, NetError> Recv(Span<uint8> buffer)
	{
		if (mSocket == null || !mConnected)
			return .Err(.NotConnected);

		switch (mSocket.Recv(buffer.Ptr, buffer.Length))
		{
		case .Ok(let received):
			return .Ok(received);
		case .Err(let socketErr):
			if (socketErr == .WouldBlock)
				return .Err(.WouldBlock);
			CheckDisconnect(socketErr);
			return .Err(NetError.FromSocketError(socketErr));
		}
	}

	/// Poll for readability (has data or connection events).
	/// Returns true if data is available.
	public Result<bool, NetError> Poll(int timeoutMs)
	{
		if (mSocket == null)
			return .Err(.NotConnected);

		Socket.FDSet readSet = default;
		readSet.Add(mSocket.NativeSocket);
		let result = Socket.Select(&readSet, null, null, timeoutMs);
		if (result < 0)
			return .Err(.SocketError);
		return .Ok(result > 0 && readSet.IsSet(mSocket.NativeSocket));
	}

	public void Close()
	{
		if (mSocket != null)
		{
			mSocket.Close();
			delete mSocket;
			mSocket = null;
		}
		mConnected = false;
	}

	private void CheckDisconnect(Socket.SocketError err)
	{
		switch (err)
		{
		case .ConnectionReset, .ConnectionAborted, .ConnectionClosed:
			mConnected = false;
		default:
		}
	}
}
