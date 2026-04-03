namespace Sedulous.Net.Tests;

using System;
using System.Threading;
using Sedulous.Net;

class TcpTests
{
	[Test]
	public static void Listener_StartStop()
	{
		let listener = scope TcpListener();
		Test.Assert(!listener.IsListening);
		Test.Assert(listener.Start(0) case .Ok); // port 0 = OS picks available port
		Test.Assert(listener.IsListening);
		listener.Stop();
		Test.Assert(!listener.IsListening);
	}

	[Test]
	public static void Listener_NoPending()
	{
		let listener = scope TcpListener();
		Test.Assert(listener.Start(0) case .Ok);
		Test.Assert(listener.Pending(0) case .Ok(false));
		listener.Stop();
	}

	[Test]
	public static void Client_NotConnected()
	{
		let client = scope TcpClient();
		Test.Assert(!client.IsConnected);
		uint8[4] buf = default;
		Test.Assert(client.Send(Span<uint8>(&buf, 4)) case .Err(.NotConnected));
		Test.Assert(client.Recv(Span<uint8>(&buf, 4)) case .Err(.NotConnected));
	}

	[Test]
	public static void ConnectAndAccept()
	{
		let listener = scope TcpListener();
		Test.Assert(listener.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);

		// Get the actual port assigned
		let port = listener.LocalEndPoint.Port;
		Test.Assert(port > 0);

		let client = scope TcpClient();
		Test.Assert(client.Connect("127.0.0.1", port) case .Ok);
		Test.Assert(client.IsConnected);

		// Give listener a moment to register the connection
		Thread.Sleep(50);

		Test.Assert(listener.Pending(100) case .Ok(true));

		switch (listener.Accept())
		{
		case .Ok(let serverClient):
			Test.Assert(serverClient.IsConnected);
			delete serverClient;
		case .Err(let err):
			Test.Assert(false); // Should not fail
		}

		client.Close();
		listener.Stop();
	}

	[Test]
	public static void SendRecv_Roundtrip()
	{
		let listener = scope TcpListener();
		Test.Assert(listener.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = listener.LocalEndPoint.Port;

		let client = scope TcpClient();
		Test.Assert(client.Connect("127.0.0.1", port) case .Ok);

		Thread.Sleep(50);

		TcpClient serverClient = null;
		defer { delete serverClient; }

		switch (listener.Accept())
		{
		case .Ok(let sc):
			serverClient = sc;
		case .Err:
			Test.Assert(false);
			return;
		}

		// Client sends data
		let message = "Hello TCP!";
		Test.Assert(client.SendAll(Span<uint8>((uint8*)message.Ptr, message.Length)) case .Ok);

		// Server receives data
		Thread.Sleep(50);
		uint8[64] recvBuf = default;
		switch (serverClient.Recv(Span<uint8>(&recvBuf, 64)))
		{
		case .Ok(let received):
			Test.Assert(received == message.Length);
			let recvStr = scope String();
			recvStr.Append((char8*)&recvBuf, received);
			Test.Assert(recvStr.Equals(message));
		case .Err:
			Test.Assert(false);
		}

		client.Close();
		serverClient.Close();
		listener.Stop();
	}

	[Test]
	public static void SendAll_LargerData()
	{
		let listener = scope TcpListener();
		Test.Assert(listener.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = listener.LocalEndPoint.Port;

		let client = scope TcpClient();
		Test.Assert(client.Connect("127.0.0.1", port) case .Ok);

		Thread.Sleep(50);

		TcpClient serverClient = null;
		defer { delete serverClient; }

		switch (listener.Accept())
		{
		case .Ok(let sc):
			serverClient = sc;
		case .Err:
			Test.Assert(false);
			return;
		}

		// Send a larger message
		uint8[256] sendData = default;
		for (int i = 0; i < 256; i++)
			sendData[i] = (uint8)(i & 0xFF);
		Test.Assert(client.SendAll(Span<uint8>(&sendData, 256)) case .Ok);

		// Receive all data (may come in chunks)
		Thread.Sleep(100);
		uint8[256] recvData = default;
		int totalReceived = 0;
		for (int attempt = 0; attempt < 10 && totalReceived < 256; attempt++)
		{
			switch (serverClient.Recv(Span<uint8>(&recvData[totalReceived], 256 - totalReceived)))
			{
			case .Ok(let received):
				totalReceived += received;
			case .Err(.WouldBlock):
				Thread.Sleep(20);
			case .Err:
				break;
			}
		}
		Test.Assert(totalReceived == 256);
		for (int i = 0; i < 256; i++)
			Test.Assert(recvData[i] == (uint8)(i & 0xFF));

		client.Close();
		serverClient.Close();
		listener.Stop();
	}

	[Test]
	public static void Client_Close()
	{
		let client = scope TcpClient();
		// Close on an unconnected client should be safe
		client.Close();
		Test.Assert(!client.IsConnected);
	}

	[Test]
	public static void MultipleConnections()
	{
		let listener = scope TcpListener();
		Test.Assert(listener.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = listener.LocalEndPoint.Port;

		let client1 = scope TcpClient();
		let client2 = scope TcpClient();
		Test.Assert(client1.Connect("127.0.0.1", port) case .Ok);
		Test.Assert(client2.Connect("127.0.0.1", port) case .Ok);

		Thread.Sleep(100);

		// Accept both
		TcpClient sc1 = null;
		TcpClient sc2 = null;
		defer { delete sc1; delete sc2; }

		switch (listener.Accept())
		{
		case .Ok(let sc):
			sc1 = sc;
		case .Err:
			Test.Assert(false);
		}

		switch (listener.Accept())
		{
		case .Ok(let sc):
			sc2 = sc;
		case .Err:
			Test.Assert(false);
		}

		Test.Assert(sc1 != null && sc1.IsConnected);
		Test.Assert(sc2 != null && sc2.IsConnected);

		client1.Close();
		client2.Close();
		sc1?.Close();
		sc2?.Close();
		listener.Stop();
	}
}
