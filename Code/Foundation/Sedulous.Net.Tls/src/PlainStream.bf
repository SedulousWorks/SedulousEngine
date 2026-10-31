using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tls;

/// A bare TcpSocket as a stream (http://, ws://).
class PlainStream : INetByteStream
{
	/// OWNED.
	private TcpSocket mSocket ~ delete _;
	/// What the socket did not take yet.
	private List<uint8> mOut = new .() ~ delete _;
	private bool mConnected = false;
	private bool mDone = false;
	private String mFailure = new .() ~ delete _;

	/// Takes OWNERSHIP of `socket`.
	public this(TcpSocket socket)
	{
		mSocket = socket;
	}

	public bool Ready => mConnected && !mDone;
	public StringView Failure => mFailure;

	public bool Pump()
	{
		if (mDone)
			return false;
		let status = NetByteStreams.Connecting(mSocket, ref mConnected);
		if (status < 0)
		{
			mDone = true;
			mFailure.Set("the connection could not be made");
			return false;
		}
		if (status == 0)
			return true;
		if (!NetByteStreams.SendSome(mSocket, mOut))
		{
			mDone = true;
			mFailure.Set("the connection closed while sending");
		}
		return !mDone;
	}

	public int64 Send(Span<uint8> data)
	{
		if (mDone)
			return -1;
		mOut.AddRange(data);
		if (mConnected && !NetByteStreams.SendSome(mSocket, mOut))
		{
			mDone = true;
			mFailure.Set("the connection closed while sending");
			return -1;
		}
		return data.Length;
	}

	public int64 Receive(Span<uint8> outData)
	{
		if (mDone)
			return -1;
		if (!mConnected)
			return 0;
		let n = mSocket.Receive(outData);
		if (n < 0)
			mDone = true; // the peer closed (or the connection broke)
		return n;
	}

	public void Close()
	{
		NetByteStreams.SendSome(mSocket, mOut);
		mSocket.Close();
		mDone = true;
	}
}
