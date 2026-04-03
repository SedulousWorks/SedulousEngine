namespace Sedulous.Net;

using System;
using System.Net;

class UdpSocket
{
	private Socket mSocket ~ delete _;
	private bool mBound;

	public this()
	{
		SocketInit.EnsureInitialized();
	}

	public bool IsBound => mBound;
	public Socket RawSocket => mSocket;

	public Result<void, NetError> Bind(uint16 port)
	{
		return Bind(.(IPAddress.Any, port));
	}

	public Result<void, NetError> Bind(IPEndPoint endPoint)
	{
		if (mBound)
			return .Err(.InvalidState);

		SocketInit.EnsureInitialized();

		mSocket = new Socket();
		mSocket.Blocking = false;

		if (mSocket.OpenUDP((int32)endPoint.Port) case .Err(let socketErr))
		{
			delete mSocket;
			mSocket = null;
			return .Err(NetError.FromSocketError(socketErr));
		}

		mBound = true;
		return .Ok;
	}

	public Result<int, NetError> SendTo(Span<uint8> data, IPEndPoint destination)
	{
		if (mSocket == null)
		{
			// Auto-bind if not yet bound
			if (Bind(0) case .Err(let err))
				return .Err(err);
		}

		var destAddr = destination.ToSockAddr();
		switch (mSocket.SendTo(data.Ptr, data.Length, destAddr))
		{
		case .Ok(let sent):
			return .Ok(sent);
		case .Err(let socketErr):
			return .Err(NetError.FromSocketError(socketErr));
		}
	}

	public Result<int, NetError> RecvFrom(Span<uint8> buffer, out IPEndPoint sender)
	{
		sender = default;
		if (mSocket == null || !mBound)
			return .Err(.InvalidState);

		Socket.SockAddr_in fromAddr = default;
		switch (mSocket.RecvFrom(buffer.Ptr, buffer.Length, out fromAddr))
		{
		case .Ok(let received):
			sender = IPEndPoint.FromSockAddr(fromAddr);
			return .Ok(received);
		case .Err(let socketErr):
			if (socketErr == .WouldBlock)
				return .Err(.WouldBlock);
			return .Err(NetError.FromSocketError(socketErr));
		}
	}

	public Result<int, NetError> Broadcast(Span<uint8> data, uint16 port)
	{
		return SendTo(data, .(IPAddress.Broadcast, port));
	}

	public Result<bool, NetError> Poll(int timeoutMs)
	{
		if (mSocket == null)
			return .Err(.InvalidState);

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
		mBound = false;
	}
}
