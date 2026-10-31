using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tls;

/// A connection's plaintext, over whatever carries it: Pump moves the bytes (and the connect and
/// the handshake on), then Send and Receive work as a TcpSocket's do (bytes moved, nought for
/// would-block, minus one when done). PlainStream is a bare socket, TlsStream a socket carrying a
/// session, so the HTTP client and the WebSocket client are written once for http and https, ws
/// and wss. Single-threaded.
interface INetByteStream
{
	/// Moves what it can, connecting and shaking hands as it goes; false once it is done (closed,
	/// or failed: Failure says why), true while it lives.
	bool Pump();
	/// Connected, and for TLS the handshake done: what is sent now goes at once.
	bool Ready { get; }
	/// Plaintext to send: all of it taken (`data.Length`), or minus one when the stream is done.
	int64 Send(Span<uint8> data);
	/// Plaintext received: bytes read, nought when none is ready yet, minus one when the stream is
	/// done.
	int64 Receive(Span<uint8> outData);
	void Close();
	StringView Failure { get; }
}

/// What the streams share over their socket.
static class NetByteStreams
{
	/// As much of `pending` as the socket takes now, the rest kept; false when the socket is gone.
	public static bool SendSome(TcpSocket socket, List<uint8> pending)
	{
		int sent = 0;
		while (sent < pending.Count)
		{
			let n = socket.Send(.(pending.Ptr + sent, pending.Count - sent));
			if (n < 0)
				return false;
			if (n == 0)
				break; // would block: the rest on the next Pump
			sent += (int)n;
		}
		if (sent > 0)
			pending.RemoveRange(0, sent);
		return true;
	}

	/// The socket's connect, polled: one connected, nought still connecting, minus one failed.
	public static int32 Connecting(TcpSocket socket, ref bool connected)
	{
		if (connected)
			return 1;
		if (!socket.IsOpen)
			return -1;
		let status = socket.ConnectStatus;
		if (status > 0)
			connected = true;
		return status;
	}
}
