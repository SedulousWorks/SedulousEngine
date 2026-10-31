using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tls;

/// A TcpSocket carrying a TLS session (https://, wss://): the session's bytes to and from the
/// socket, the socket's connect first. Plaintext sent before the handshake ends waits in the
/// session.
class TlsStream : INetByteStream
{
	/// OWNED.
	private TcpSocket mSocket ~ delete _;
	/// OWNED.
	private ITlsSession mSession ~ delete _;
	/// Ciphertext the socket did not take yet.
	private List<uint8> mOut = new .() ~ delete _;
	private bool mConnected = false;
	private bool mSocketGone = false;
	private String mFailure = new .() ~ delete _;

	/// Takes OWNERSHIP of `socket` and `session`.
	public this(TcpSocket socket, ITlsSession session)
	{
		mSocket = socket;
		mSession = session;
	}

	/// BORROWED: the stream's own.
	public ITlsSession Session => mSession;

	public bool Ready => mConnected && !mSocketGone && (mSession.State == .Open);
	public StringView Failure => !mFailure.IsEmpty ? mFailure : mSession.Failure;

	/// The session's bytes to the socket; false when the socket is gone.
	private bool Flush()
	{
		mSession.TakeOutgoing(mOut);
		if (!mConnected || mSocketGone)
			return !mSocketGone;
		if (!NetByteStreams.SendSome(mSocket, mOut))
			mSocketGone = true;
		return !mSocketGone;
	}

	public bool Pump()
	{
		if ((mSession.State == .Failed) || mSocketGone)
			return false;
		let status = NetByteStreams.Connecting(mSocket, ref mConnected);
		if (status < 0)
		{
			mSocketGone = true;
			mFailure.Set("the connection could not be made");
			return false;
		}
		if (status == 0)
			return true;
		Flush();
		uint8[16 * 1024] buffer = ?;
		while (!mSocketGone)
		{
			let n = mSocket.Receive(.(&buffer[0], buffer.Count));
			if (n == 0)
				break;
			if (n < 0)
			{
				mSocketGone = true;
				break;
			}
			mSession.Receive(.(&buffer[0], (int)n)).IgnoreError();
		}
		Flush(); // the handshake's answers
		let state = mSession.State;
		return (state != .Failed) && (state != .Closed) && !mSocketGone;
	}

	public int64 Send(Span<uint8> data)
	{
		let state = mSession.State;
		if (mSocketGone || (state == .Failed) || (state == .Closed))
			return -1;
		if (mSession.Write(data) case .Err)
			return -1;
		Flush();
		return data.Length;
	}

	public int64 Receive(Span<uint8> outData)
	{
		let n = mSession.Read(outData);
		if (n > 0)
			return n;
		let state = mSession.State;
		if ((state == .Failed) || (state == .Closed) || mSocketGone)
			return -1;
		return 0;
	}

	public void Close()
	{
		mSession.Close();
		Flush(); // the close_notify
		mSocket.Close();
		mSocketGone = true;
	}
}
