using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;

namespace Sedulous.Net.WebSocket.Tests;

/// A browser's half of the conversation, spoken over a real loopback socket.
///
/// Deliberately HAND ROLLED rather than built on WebSocketClientSocket: the point of these
/// cases is the gateway, and a client sharing the gateway's own codec would agree with it
/// about a wrong answer as readily as a right one. The handshake is a literal, the frames are
/// encoded here, and the replies are decoded by reading the two header bytes directly.
///
/// Every wait PUMPS THE GATEWAY. Both ends live on this one thread, so a sleep that does not
/// pump is a deadlock: the gateway only ever moves when it is asked to.
class WsLoopbackClient
{
	/// RFC 6455's own example key, whose accept value the handshake tests already pin.
	private const String cHandshake =
		"""
		GET /game HTTP/1.1\r
		Host: localhost\r
		Upgrade: websocket\r
		Connection: Upgrade\r
		Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
		Sec-WebSocket-Version: 13\r
		\r

		""";

	public TcpSocket Socket ~ delete _;

	/// Connects, sends the upgrade request and reads the response head. True only on a 101.
	public bool ConnectAndUpgrade(WebSocketServerGateway gateway, uint16 port)
	{
		Socket = TcpSocket.Connect("127.0.0.1", port);
		if (!Socket.IsOpen)
			return false;

		for (int i = 0; (i < 300) && (Socket.ConnectStatus == 0); i++)
		{
			gateway.Pump();
			Thread.Sleep(1);
		}
		if (Socket.ConnectStatus != 1)
			return false;

		let request = scope List<uint8>();
		for (let c in cHandshake.RawChars)
			request.Add((uint8)c);
		if (Socket.Send(.(request.Ptr, request.Count)) != (int64)request.Count)
			return false;

		// Read until the blank line that ends the response head.
		let response = scope List<uint8>();
		for (int i < 500)
		{
			gateway.Pump();

			uint8[512] chunk = ?;
			let got = Socket.Receive(.(&chunk[0], chunk.Count));
			for (int64 j = 0; j < got; j++)
				response.Add(chunk[j]);

			if (response.Count >= 4)
			{
				let n = response.Count;
				if ((response[n - 4] == '\r') && (response[n - 3] == '\n')
					&& (response[n - 2] == '\r') && (response[n - 1] == '\n'))
					break;
			}
			Thread.Sleep(1);
		}

		let text = StringView((char8*)response.Ptr, response.Count);
		return text.StartsWith("HTTP/1.1 101");
	}

	/// A masked binary frame, because a client's frames MUST be masked and the gateway is
	/// entitled to drop one that is not.
	public void SendBinary(Span<uint8> payload, uint32 maskingKey = 0xDEADBEEF)
	{
		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, payload, true, maskingKey, wire);
		Socket.Send(.(wire.Ptr, wire.Count));
	}

	/// Raw bytes, for the cases that speak something other than a well formed frame.
	public void SendRaw(Span<uint8> bytes)
	{
		Socket.Send(bytes);
	}

	/// Reads ONE unmasked server frame, answering false if the gateway never sent one or sent
	/// something that is not binary.
	///
	/// The length is read as the small form only. Every payload these cases exchange is a
	/// short string, so a seven bit length is the whole of what a correct gateway can send
	/// back, and reading it directly keeps the codec under test out of the assertion.
	public bool ReceiveBinary(WebSocketServerGateway gateway, List<uint8> outPayload)
	{
		let wire = scope List<uint8>();
		for (int i < 500)
		{
			gateway.Pump();

			uint8[512] chunk = ?;
			let got = Socket.Receive(.(&chunk[0], chunk.Count));
			for (int64 j = 0; j < got; j++)
				wire.Add(chunk[j]);

			if (wire.Count >= 2)
			{
				let length = (int)(wire[1] & 0x7F);
				if (wire.Count >= 2 + length)
				{
					if ((wire[0] & 0x0F) != 0x2) // not a binary frame
						return false;

					outPayload.Clear();
					outPayload.AddRange(Span<uint8>(wire.Ptr + 2, length));
					return true;
				}
			}
			Thread.Sleep(1);
		}
		return false;
	}

	/// Pumps until a frame with the given opcode arrives, answering its payload length.
	/// Negative means it never came.
	public int WaitForOpcode(WebSocketServerGateway gateway, uint8 opcode)
	{
		let wire = scope List<uint8>();
		for (int i < 500)
		{
			gateway.Pump();

			uint8[64] chunk = ?;
			let got = Socket.Receive(.(&chunk[0], chunk.Count));
			for (int64 j = 0; j < got; j++)
				wire.Add(chunk[j]);

			if (wire.Count >= 2)
			{
				let length = (int)(wire[1] & 0x7F);
				if ((wire.Count >= 2 + length) && ((wire[0] & 0x0F) == opcode))
					return length;
			}
			Thread.Sleep(1);
		}
		return -1;
	}
}
