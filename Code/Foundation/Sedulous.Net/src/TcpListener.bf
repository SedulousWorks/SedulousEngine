namespace Sedulous.Net;

using System;
using System.Net;

class TcpListener
{
	private Socket mSocket ~ delete _;
	private IPEndPoint mLocalEndPoint;
	private bool mListening;

	public this()
	{
		SocketInit.EnsureInitialized();
	}

	public bool IsListening => mListening;
	public IPEndPoint LocalEndPoint => mLocalEndPoint;
	public Socket RawSocket => mSocket;

	public Result<void, NetError> Start(uint16 port, int32 backlog = 5)
	{
		return Start(.(IPAddress.Any, port), backlog);
	}

	public Result<void, NetError> Start(IPEndPoint endPoint, int32 backlog = 5)
	{
		if (mListening)
			return .Err(.InvalidState);

		SocketInit.EnsureInitialized();

		mSocket = new Socket();
		mSocket.Blocking = false;

		if (mSocket.Listen(endPoint.Address.ToIPv4(), (int32)endPoint.Port, backlog) case .Err(let socketErr))
		{
			delete mSocket;
			mSocket = null;
			return .Err(NetError.FromSocketError(socketErr));
		}

		// Query actual bound endpoint (essential when port 0 is used)
		if (SocketInit.GetLocalEndPoint(mSocket.NativeSocket) case .Ok(let actualEndPoint))
			mLocalEndPoint = actualEndPoint;
		else
			mLocalEndPoint = endPoint;

		mListening = true;
		return .Ok;
	}

	/// Accept a pending connection. Returns .Err(.WouldBlock) if none pending.
	public Result<TcpClient, NetError> Accept()
	{
		if (mSocket == null || !mListening)
			return .Err(.InvalidState);

		let clientSocket = new Socket();
		Socket.SockAddr_in clientAddr = default;
		switch (clientSocket.AcceptFrom(mSocket, out clientAddr))
		{
		case .Ok:
			clientSocket.Blocking = false;
			let remoteEndPoint = IPEndPoint.FromSockAddr(clientAddr);
			return .Ok(new TcpClient(clientSocket, remoteEndPoint));
		case .Err(let socketErr):
			delete clientSocket;
			if (socketErr == .WouldBlock)
				return .Err(.WouldBlock);
			return .Err(NetError.FromSocketError(socketErr));
		}
	}

	/// Check if there are pending connections without accepting.
	public Result<bool, NetError> Pending(int timeoutMs = 0)
	{
		if (mSocket == null || !mListening)
			return .Err(.InvalidState);

		Socket.FDSet readSet = default;
		readSet.Add(mSocket.NativeSocket);
		let result = Socket.Select(&readSet, null, null, timeoutMs);
		if (result < 0)
			return .Err(.SocketError);
		return .Ok(result > 0 && readSet.IsSet(mSocket.NativeSocket));
	}

	public void Stop()
	{
		if (mSocket != null)
		{
			mSocket.Close();
			delete mSocket;
			mSocket = null;
		}
		mListening = false;
	}
}
