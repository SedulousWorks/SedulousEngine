namespace Sedulous.Net.Tests;

using System;
using System.Threading;
using Sedulous.Net;

class UdpTests
{
	[Test]
	public static void Bind_AndClose()
	{
		let socket = scope UdpSocket();
		Test.Assert(!socket.IsBound);
		Test.Assert(socket.Bind(0) case .Ok); // port 0 = OS picks
		Test.Assert(socket.IsBound);
		socket.Close();
		Test.Assert(!socket.IsBound);
	}

	[Test]
	public static void SendTo_RecvFrom_Localhost()
	{
		let receiver = scope UdpSocket();
		Test.Assert(receiver.Bind(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);

		let sender = scope UdpSocket();

		// Send data to receiver
		let message = "Hello UDP!";
		// We need the actual bound port - UDP doesn't expose it easily via our API,
		// so bind receiver on a known port range. Use a high port.
		receiver.Close();

		// Retry with specific port
		let recvSocket = scope UdpSocket();
		// Try to find an available port
		var boundPort = uint16(0);
		for (uint16 p = 50100; p < 50200; p++)
		{
			if (recvSocket.Bind(.(IPAddress(127, 0, 0, 1), p)) case .Ok)
			{
				boundPort = p;
				break;
			}
		}

		if (boundPort == 0)
		{
			// Skip if no port available
			return;
		}

		let sendDest = IPEndPoint(127, 0, 0, 1, boundPort);
		Test.Assert(sender.SendTo(Span<uint8>((uint8*)message.Ptr, message.Length), sendDest) case .Ok(let sent));
		Test.Assert(sent == message.Length);

		// Give time for delivery
		Thread.Sleep(50);

		uint8[64] recvBuf = default;
		IPEndPoint senderAddr = default;
		switch (recvSocket.RecvFrom(Span<uint8>(&recvBuf, 64), out senderAddr))
		{
		case .Ok(let received):
			Test.Assert(received == message.Length);
			let recvStr = scope String();
			recvStr.Append((char8*)&recvBuf, received);
			Test.Assert(recvStr.Equals(message));
		case .Err:
			Test.Assert(false);
		}

		sender.Close();
		recvSocket.Close();
	}

	[Test]
	public static void RecvFrom_WouldBlock()
	{
		let socket = scope UdpSocket();
		Test.Assert(socket.Bind(0) case .Ok);

		uint8[16] buf = default;
		IPEndPoint sender = default;
		Test.Assert(socket.RecvFrom(Span<uint8>(&buf, 16), out sender) case .Err(.WouldBlock));
		socket.Close();
	}

	[Test]
	public static void Poll_NoData()
	{
		let socket = scope UdpSocket();
		Test.Assert(socket.Bind(0) case .Ok);
		Test.Assert(socket.Poll(0) case .Ok(false));
		socket.Close();
	}

	[Test]
	public static void AutoBind_OnSendTo()
	{
		let socket = scope UdpSocket();
		Test.Assert(!socket.IsBound);

		// SendTo should auto-bind
		uint8[4] data = .(1, 2, 3, 4);
		let dest = IPEndPoint(127, 0, 0, 1, 50999);
		// This should succeed (auto-binds) even if destination isn't listening
		let result = socket.SendTo(Span<uint8>(&data, 4), dest);
		Test.Assert(result case .Ok);
		Test.Assert(socket.IsBound);

		socket.Close();
	}
}
