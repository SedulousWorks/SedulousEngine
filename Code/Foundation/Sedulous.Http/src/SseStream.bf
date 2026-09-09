using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;

namespace Sedulous.Http;

/// A held Server-Sent Events connection.
///
/// REF COUNTED: the server holds one reference, dropped when the peer goes or the server
/// stops, and the consumer holds another and writes for as long as it likes. Neither has to
/// know when the other is finished, which is the whole point: a write after close is a safe
/// no-op returning false rather than a use after free.
///
/// Safe from any ONE writer thread at a time. Writes are serialised against Close internally.
class SseStream : RefCounted
{
	/// How many one millisecond waits a partial send will tolerate before giving up. On
	/// loopback this is never reached; it exists so a wedged peer cannot block the writer
	/// forever.
	private const int cSendPatience = 2000;

	private Monitor mMonitor = new .() ~ delete _;
	private TcpSocket mSocket ~ delete _;

	/// Takes OWNERSHIP of the socket.
	public this(TcpSocket socket)
	{
		mSocket = socket;
	}

	/// One event: an optional name, then one data field per line, then the blank line that
	/// terminates it. False once the peer is gone, and the stream closes itself.
	public bool WriteEvent(StringView eventName, StringView data)
	{
		using (mMonitor.Enter())
		{
			if (!mSocket.IsOpen)
				return false;

			let payload = scope List<uint8>();
			if (!eventName.IsEmpty)
			{
				AppendText(payload, "event: ");
				AppendText(payload, eventName);
				AppendText(payload, "\n");
			}

			// One data field PER LINE: that is the framing rule, and a raw newline inside a
			// field would otherwise terminate the event early.
			var lineStart = 0;
			for (int i = 0; i <= data.Length; i++)
			{
				if ((i == data.Length) || (data[i] == '\n'))
				{
					AppendText(payload, "data: ");
					AppendText(payload, data.Substring(lineStart, i - lineStart));
					AppendText(payload, "\n");
					lineStart = i + 1;
				}
			}
			AppendText(payload, "\n");
			return SendAll(payload);
		}
	}

	/// A comment line, which is the keep-alive idiom: it costs a few bytes and tells a proxy
	/// the stream is alive.
	public bool WriteComment(StringView text)
	{
		using (mMonitor.Enter())
		{
			if (!mSocket.IsOpen)
				return false;

			let payload = scope List<uint8>();
			AppendText(payload, ": ");
			AppendText(payload, text);
			AppendText(payload, "\n\n");
			return SendAll(payload);
		}
	}

	public bool IsOpen
	{
		get
		{
			using (mMonitor.Enter())
				return mSocket.IsOpen;
		}
	}

	/// A liveness probe that READS rather than writes.
	///
	/// A write into a freshly closed socket can still succeed, because the kernel buffers it
	/// until the reset arrives, so IsOpen alone lags behind reality. Reading is what notices
	/// promptly. False means the peer is gone and the stream has closed itself.
	public bool PollLive()
	{
		using (mMonitor.Enter())
		{
			if (!mSocket.IsOpen)
				return false;

			let buffer = scope uint8[256];
			for (;;)
			{
				let n = mSocket.Receive(buffer);
				// Would block: quiet, but alive.
				if (n == 0)
					return true;
				if (n < 0)
				{
					mSocket.Close();
					return false;
				}
				// An event stream client has nothing to say. Discard and keep probing.
			}
		}
	}

	public void Close()
	{
		using (mMonitor.Enter())
			mSocket.Close();
	}

	private static void AppendText(List<uint8> buffer, StringView text) =>
		buffer.AddRange(.((uint8*)text.Ptr, text.Length));

	/// Sends the whole buffer, tolerating partial writes. Closes and reports false when the
	/// peer is gone or has stopped reading for too long.
	private bool SendAll(List<uint8> bytes)
	{
		var sent = 0;
		var patience = cSendPatience;
		while (sent < bytes.Count)
		{
			let n = mSocket.Send(.(bytes.Ptr + sent, bytes.Count - sent));
			if (n < 0)
			{
				mSocket.Close();
				return false;
			}
			if (n == 0)
			{
				patience--;
				if (patience <= 0)
				{
					mSocket.Close();
					return false;
				}
				Thread.Sleep(1);
				continue;
			}
			sent += (int)n;
		}
		return true;
	}
}
